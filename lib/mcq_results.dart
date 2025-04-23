import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MCQResults extends StatelessWidget {
  final String mcqs;
  final String randomCode;

  MCQResults({required this.mcqs, required this.randomCode});

  List<Map<String, String>> _parseMCQs(String mcqsText) {
    final List<Map<String, String>> parsedMCQs = [];
    final mcqEntries = mcqsText.split('## MCQ').where((entry) => entry.trim().isNotEmpty);

    for (var entry in mcqEntries) {
      final lines = entry.split('\n').where((line) => line.trim().isNotEmpty).toList();
      String question = '';
      String difficulty = '';
      List<String> options = [];
      String correctAnswer = '';

      for (var line in lines) {
        if (line.startsWith("[Easy]") || line.startsWith("[Medium]") || line.startsWith("[Hard]")) {
          difficulty = line.split(" ")[0];
          question = line.substring(line.indexOf("Question:") + 9).trim();
        } else if (line.startsWith("A)") || line.startsWith("B)") || line.startsWith("C)") || line.startsWith("D)")) {
          options.add(line);
        } else if (line.startsWith("Correct Answer:")) {
          correctAnswer = line.split(":")[1].trim();
        }
      }

      parsedMCQs.add({
        'difficulty': difficulty,
        'question': question,
        'options': options.join('\n'),
        'correctAnswer': correctAnswer,
      });
    }

    return parsedMCQs;
  }

  @override
  Widget build(BuildContext context) {
    final mcqList = _parseMCQs(mcqs);

    return Scaffold(
      appBar: AppBar(
        title: Text('MCQ Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'MCQs Generated',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  QrImageView(
                    data: randomCode,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Random Code: $randomCode',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Divider(),
            SizedBox(height: 20),
            ...mcqList.map((mcq) => _buildMCQCard(mcq)).toList(),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Go Back'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.orange,
              ),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                _generateAndDownloadPDF(mcqList);
              },
              child: Text('Download PDF'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMCQCard(Map<String, String> mcq) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mcq['question'] ?? '',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                mcq['difficulty'] ?? 'Unknown',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange[800]),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Options:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 5),
            ...mcq['options']!.split('\n').map((option) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    option,
                    style: TextStyle(fontSize: 16),
                  ),
                )),
            SizedBox(height: 10),
            Text(
              'Correct Answer: ${mcq['correctAnswer']}',
              style: TextStyle(fontSize: 16, color: Colors.green[700], fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _generateAndDownloadPDF(List<Map<String, String>> mcqList) async {
    final pdfDoc = pw.Document();

    pdfDoc.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Text('MCQ Questions',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 20),
          ...mcqList.map((mcq) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Question: ${mcq['question']}",
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text("Difficulty: ${mcq['difficulty']}",
                        style: pw.TextStyle(fontSize: 14, color: PdfColors.orange)),
                    pw.SizedBox(height: 5),
                    pw.Text("Options:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ...mcq['options']!.split('\n').map((opt) => pw.Text(opt)),
                    pw.SizedBox(height: 5),
                    pw.Text("Correct Answer: ${mcq['correctAnswer']}",
                        style: pw.TextStyle(color: PdfColors.green, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfDoc.save());
  }
}
