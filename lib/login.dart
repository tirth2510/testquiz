import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mcq_generator.dart';
import 'mcq_code.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;

  Future<User?> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      setState(() {
        _isLoading = false;
      });
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    final User? user = userCredential.user;

    if (user != null) {
      await _saveUserToFirestore(user);
    }

    setState(() {
      _isLoading = false;
    });

    return user;
  }

  Future<void> _saveUserToFirestore(User user) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.email);

    final isTeacher = await _showRoleSelectionDialog();
    await userRef.set({
      'email': user.email,
      'role': isTeacher ? 'teacher' : 'student',
    });
  }

  Future<bool> _showRoleSelectionDialog() async {
    bool isTeacher = false;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: Center(child: Text('Select Your Role', style: TextStyle(fontWeight: FontWeight.bold))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Teacher', style: TextStyle(fontSize: 16)),
                    leading: Radio<bool>(
                      value: true,
                      groupValue: isTeacher,
                      onChanged: (bool? value) {
                        setState(() {
                          isTeacher = value!;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Student', style: TextStyle(fontSize: 16)),
                    leading: Radio<bool>(
                      value: false,
                      groupValue: isTeacher,
                      onChanged: (bool? value) {
                        setState(() {
                          isTeacher = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text('Confirm', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    return isTeacher;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to the MCQ App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: Icon(Icons.login, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () async {
                        User? user = await _signInWithGoogle();
                        if (user != null) {
                          // Navigate to the next screen based on role
                          FirebaseFirestore.instance.collection('users').doc(user.email).get().then((doc) {
                            if (doc.exists) {
                              var role = doc['role'];
                              if (role == 'teacher') {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => MCQGenerator()),
                                );
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => MCQCode()),
                                );
                              }
                            }
                          });
                        }
                      },
                      label: Text('Sign In with Google', style: TextStyle(fontSize: 16)),
                    ),
              SizedBox(height: 20),
              Text(
                'Please sign in to continue and choose your role.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
