import 'package:flutter/material.dart';

class ContactUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Contact Us")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Have any questions or feedback?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text("📧 Email: support@genwiseapp.com"),
            Text("📱 Phone: +91 98765 43210"),
            Text("🌐 Website: www.genwiseapp.com"),
          ],
        ),
      ),
    );
  }
}
