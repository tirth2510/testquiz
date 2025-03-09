import os
from flask import Flask, jsonify
from firebase_admin import credentials, firestore, initialize_app
import google.generativeai as genai
from flask import request
# Set up Google API key for Gemini
os.environ["GOOGLE_API_KEY"] = "AIzaSyCfzCErNSYRZY1aKt4l-gzpQmS_oy4T00U"
genai.configure(api_key=os.environ["GOOGLE_API_KEY"])

# Initialize Firebase and Flask for formatting app
cred = credentials.Certificate('../aiquizgenerator-b8817-firebase-adminsdk-bml1x-9a92c0b273.json')  # Replace with Firebase credentials path
initialize_app(cred)
db = firestore.client()
app = Flask(__name__)



def parse_mcqs_text(mcqs_text):
    """
    Parse the plain text MCQs string into a structured format for JSON response.
    This function will convert the string into a list of dictionaries, each representing an MCQ.
    """
    mcqs = []
    current_mcq = {}
    lines = mcqs_text.splitlines()

    for line in lines:
        line = line.strip()
        if line.startswith("## MCQ"):
            if current_mcq:
                mcqs.append(current_mcq)
            current_mcq = {"question": "", "options": [], "correctAnswer": "", "difficulty": ""}
        
        elif line.startswith("[Easy]") or line.startswith("[Medium]") or line.startswith("[Hard]"):
            parts = line.split("Question:")
            if len(parts) > 1:
                current_mcq["difficulty"] = parts[0].strip("[] ")
                current_mcq["question"] = parts[1].strip()
        
        elif line.startswith("A)") or line.startswith("B)") or line.startswith("C)") or line.startswith("D)"):
            current_mcq["options"].append(line)
        
        elif line.startswith("Correct Answer:"):
            current_mcq["correctAnswer"] = line.split(":", 1)[1].strip()

    if current_mcq:
        mcqs.append(current_mcq)
    
    return mcqs

@app.route('/fetch_quiz//<user_email>/<quiz_id>', methods=['GET'])
def fetch_quiz(user_email, quiz_id):
    try:
        # Access MCQs from Firebase
        quiz_doc_ref = db.collection('quiz').document(quiz_id)
        doc = quiz_doc_ref.get()
        
        if doc.exists:
            mcqs_text = doc.to_dict().get('mcqs')
            
            # Parse the MCQs text into structured format
            formatted_mcqs = parse_mcqs_text(mcqs_text)

            # Save the formatted MCQs JSON in the nested structure in Firestore
            user_res_doc_ref = db.collection('res').document(quiz_id).collection('user_email').document(user_email)
            user_res_doc_ref.set({
                "mcqs": formatted_mcqs
            })

            return jsonify({"mcqs": formatted_mcqs, "message": "MCQs saved to res collection in nested structure"}), 200
        else:
            return jsonify({"error": "Quiz not found"}), 404
    except Exception as e:
        print(f"Error fetching quiz: {e}")
        return jsonify({"error": "Failed to fetch quiz"}), 500

if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5001)  # Run on a different port (5001)
