import 'dart:async';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:newapp2/Voice.dart';
import 'package:newapp2/constant.dart';
import 'package:newapp2/history.dart';
import 'package:newapp2/login.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

const String serverUrl =
    'http://127.0.0.1:5000/predict'; // Update with your server IP

class HomeScreen extends StatefulWidget {
  late final Map<String, dynamic> userData;

  HomeScreen({required this.userData});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  PageController _pageController = PageController();

  List<Widget> _pages = [];
  Map<String, dynamic> userData = {};
  @override
  void initState() {
    super.initState();
    userData = widget.userData;
   
    // Initialize _pages after data is initialized
    _pages = [
      VoiceScreen(),
      Center(
        child: HistoryChart(userData),
      ),
    ];
  }

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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Logout"),
          content: Text("Are you sure you want to logout?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Logout"),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginPage()));
              },
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      fetchData();
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: Center(
            child: const Text(
          "Speech Recognizer",
          style: TextStyle(fontWeight: FontWeight.bold),
        )),
        actions: [
          IconButton(
              onPressed: () async {
                _showLogoutDialog(context);
              },
              icon: Icon(Icons.logout))
        ],
      ),
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
            fetchData();
          });
        },
      ),
      bottomNavigationBar: AnimatedBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class AnimatedBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const AnimatedBottomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: AnimatedIconWidget(
              icon: Icons.home,
              selected: selectedIndex == 0,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: AnimatedIconWidget(
              icon: Icons.history,
              selected: selectedIndex == 1,
            ),
            label: 'History',
          ),
        ],
        selectedItemColor: const Color.fromARGB(255, 21, 114, 156),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        backgroundColor: Colors.white,
      ),
    );
  }
}

class AnimatedIconWidget extends StatelessWidget {
  final IconData icon;
  final bool selected;

  const AnimatedIconWidget({
    Key? key,
    required this.icon,
    required this.selected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: selected ? const EdgeInsets.all(8.0) : const EdgeInsets.all(0.0),
      decoration: BoxDecoration(
        color:
            selected ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 30),
    );
  }
}

class SpeechScreen extends StatefulWidget {
  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        reverse: true,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.0), // Adjust the padding as needed
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
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

       
            ElevatedButton(
              onPressed: _isListening ? null : () => _fetchData(_storedText),
              child: const Text('Submit Text'),
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
    // Store the recognized text when listening stops
    _storeText(_text);
  }

  void _storeText(String text) {
    _storedText = text;
    print('Stored Text: $_storedText');
  }

  void _fetchData(String text) {
    setState(() {
      data['paragraph'] = text;
    });

    http
        .post(Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data))
        .then((http.Response response) {
      if (response.statusCode == 200) {
        setState(() {
          accuracy = jsonDecode(response.body)['accuracy'];
          finalaccuracy = double.parse(accuracy.replaceAll('%', ''));
        });
        print(jsonDecode(response.body));
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    }).catchError((error) {
      print('Request failed with error: $error');
    });
  }
}

class AccuracyChart extends StatefulWidget {
  final double accuracy;

  AccuracyChart(this.accuracy);

  @override
  State<AccuracyChart> createState() => _AccuracyChartState();
}

class _AccuracyChartState extends State<AccuracyChart> {
  @override
  Widget build(BuildContext context) {
    List<charts.Series<AccuracyData, String>> series = [
      charts.Series(
        id: "Accuracy",
        data: [
          AccuracyData('Accuracy', widget.accuracy),
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
