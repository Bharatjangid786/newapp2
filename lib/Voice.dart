import 'dart:async';
import 'dart:math';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:newapp2/constant.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String serverUrl =
    'http://127.0.0.1:5000/predict'; // Update with your server IP

class VoiceScreen extends StatefulWidget {
  @override
  _VoiceScreenState createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;
  String _storedText = '';

  final String url = 'http://127.0.0.1:5000/predict';
  Map<String, dynamic> data = {'paragraph': ''};
  String accuracy = '';
  double finalaccuracy = 0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<int> countDocumentsInCollection() async {
    CollectionReference dataCollection =
        FirebaseFirestore.instance.collection('data');

    QuerySnapshot querySnapshot = await dataCollection.get();

    return querySnapshot.docs.length;
  }

  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('data');

  Future<void> storeUserDataInFirebase(double accuracy, String data) async {
    print("Start");

    // Get the current user
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("No user is signed in.");
      return;
    }

    // Reference to the user's document
    DocumentReference userDoc = _userCollection.doc(currentUser.uid);

    try {
      // Get the user's document
      DocumentSnapshot docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        // If document exists, update the existing fields
        print("Document exists. Updating the document.");

        Map<String, dynamic> dataToUpdate =
            docSnapshot.data() as Map<String, dynamic>;
        int count = dataToUpdate.length ~/
            2; // Assuming each accuracy-data pair counts as 2 fields
        count++;

        dataToUpdate['$count'] = accuracy;
        dataToUpdate['data$count'] = data;

        await userDoc.update(dataToUpdate);
        print("Updated document with count $count.");
      } else {
        // If document doesn't exist, create a new document
        print("Document does not exist. Creating a new document.");

        await userDoc.set({
          '1': accuracy,
          'data1': data,
        });
        print("Created new document.");
      }
    } catch (e) {
      print("Error occurred:");
      log(e.toString() as num);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        reverse: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Container(
                  height: 400,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: TextHighlight(
                      text: _text,
                      words: {},
                      textStyle: const TextStyle(
                        fontSize: 24.0,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 400,
              child: ElevatedButton(
                onPressed: _isListening
                    ? null
                    : () async {
                        await _fetchData(_storedText);
                        await storeUserDataInFirebase(
                            finalaccuracy, _storedText);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 25, 142, 196),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Submit Text',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            if (finalaccuracy != 0) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Accuracy: ${finalaccuracy.toStringAsFixed(2)}%',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              AccuracyChart(finalaccuracy),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Accuracy: ${finalaccuracy.toStringAsFixed(2)}%',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ],
            )
            // if()
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        animate: _isListening,
        glowColor: Theme.of(context).primaryColor,
        duration: const Duration(milliseconds: 2000),
        repeat: true,
        child: FloatingActionButton(
          backgroundColor: AppConstants.primaryColor,
          onPressed: _isListening ? _stop : _listen,
          child: Icon(_isListening ? Icons.mic : Icons.mic_none),
        ),
      ),
    );
  }

  void _listen() async {
    print("Start");
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    }
  }

  void _stop() {
    _speech.stop();
    setState(() => _isListening = false);
    _storeText(_text);
  }

  void _storeText(String text) {
    _storedText = text;
    print('Stored Text: $_storedText');
  }

  Future<void> _fetchData(String text) async {
    setState(() {
      data['paragraph'] = text;
    });

    try {
      http.Response response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        setState(() {
          accuracy = jsonDecode(response.body)['accuracy'];
          finalaccuracy = double.parse(accuracy.replaceAll('%', ''));
        });

        print(jsonDecode(response.body));
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (error) {
      print('Request failed with error: $error');
    }
  }
}

class AccuracyChart extends StatelessWidget {
  final double accuracy;

  AccuracyChart(this.accuracy);

  @override
  Widget build(BuildContext context) {
    List<charts.Series<AccuracyData, String>> series = [
      charts.Series(
        id: "Accuracy",
        data: [
          AccuracyData('Accuracy', accuracy),
        ],
        domainFn: (AccuracyData series, _) => series.title,
        measureFn: (AccuracyData series, _) => series.value,
      )
    ];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: charts.BarChart(
        series,
        animate: true,
        barRendererDecorator: charts.BarLabelDecorator<String>(),
      ),
    );
  }
}

class AccuracyData {
  final String title;
  final double value;

  AccuracyData(this.title, this.value);
}
