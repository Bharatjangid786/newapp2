import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:newapp2/constant.dart';
import 'package:newapp2/home.dart';
import 'package:newapp2/login.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController confrompasswordController = TextEditingController();

  late Map<String, dynamic> userData;

  Future<void> fetchData() async {
    try {
      var docSnapshot = await FirebaseFirestore.instance
          .collection('data')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          userData = docSnapshot.data() as Map<String, dynamic>;
        });
        print("userData");
        print(userData);
      } else {
        userData = {};
        print('Document does not exist');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  Future<void> registerUser() async {
    try {
      print("object");
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      print("object2");

      await fetchData();
      print("end");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomeScreen(
                  userData: userData,
                )),
      );

      print('User registered: ${userCredential.user}');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    return Scaffold(
      backgroundColor: AppConstants.primaryColor, // Light blue color
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: screenHeight * .1),
              _buildLogo(screenHeight, screenWidth),
              // const SizedBox(height: 20),
              SingleChildScrollView(
                  child: _buildLoginForm(screenHeight, screenWidth)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(screenHeight, screenWidth) {
    return Column(
      children: [
        Image.asset(
          'assets/logo.png',
        ),
      ],
    );
  }

  Widget _buildLoginForm(screenHeight, screenWidth) {
    return Container(
        height: screenHeight * .623,
        decoration: const BoxDecoration(
          color: AppConstants.secColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(50),
          ),
        ),
        width: double.infinity,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Text(
              "Create Account",
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.TColor),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 10, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                      ),
                      obscureText: true,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: TextField(
                      controller: confrompasswordController,
                      decoration: InputDecoration(
                        labelText: 'Conform Password',
                        hintText: 'Enter your password',
                      ),
                      obscureText: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        if (confrompasswordController.text.trim() ==
                            passwordController.text.trim()) {
                          registerUser();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppConstants.TColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: Container(
                color: AppConstants.secColor,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(),
                      ),
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: "Have an account? ",
                          style: TextStyle(color: Colors.black),
                        ),
                        TextSpan(
                          text: 'Login now',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ));
  }
}
