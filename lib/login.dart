import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:newapp2/Home.dart';
import 'package:newapp2/constant.dart';
import 'package:newapp2/sign_up.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("Start");

      await fetchData();
      print("end");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomeScreen(
                  userData: userData,
                )),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

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

  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    // Retrieve width and height
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
              SingleChildScrollView(
                  child: _buildLoginForm(screenHeight, screenWidth, context)),
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

  Widget _buildLoginForm(screenHeight, screenWidth, context) {
    return Container(
        height: screenHeight * .623,
        decoration: const BoxDecoration(
          color: AppConstants.secColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50), // Radius for top left corner
            topRight: Radius.circular(50), // Radius for top right corner
          ),
        ),
        width: double.infinity,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const Text(
              "Login",
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.TColor),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                      ),
                      obscureText: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await signInWithEmailAndPassword(
                          emailController.text.trim(),
                          passwordController.text.trim());
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppConstants.TColor, // Text color
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(0), // Rectangular border
                      ),
                    ),
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 37,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Container(
                  color: AppConstants.secColor,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignUpPage(),
                        ),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(color: Colors.black),
                          ),
                          TextSpan(
                            text: 'Create now',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ));
  }
}
