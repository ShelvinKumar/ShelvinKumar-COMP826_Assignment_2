import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Traffic Lights',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TrafficLightScreen(),
    );
  }
}

class TrafficLightScreen extends StatefulWidget {
  @override
  _TrafficLightScreenState createState() => _TrafficLightScreenState();
}

class _TrafficLightScreenState extends State<TrafficLightScreen> {
  String junctionId = "junction_1";
  String status = "red"; // Initial status
  int timeLeft = 10; // Initial time left
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
    fetchTrafficLightStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        changeTrafficLightState();
      }
    });
  }

  void changeTrafficLightState() {
    setState(() {
      if (status == "red") {
        status = "green";
        timeLeft = 10; // Reset time for green light
      } else if (status == "green") {
        status = "yellow";
        timeLeft = 5; // Reset time for yellow light
      } else if (status == "yellow") {
        status = "red";
        timeLeft = 15; // Reset time for red light
      }
    });
  }

  Future<void> fetchTrafficLightStatus() async {
    final response = await http.get(
      Uri.parse('http://172.23.39.233:5000/traffic_light/$junctionId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        status = data['status'];
        timeLeft = data['time_left'];
      });
    } else {
      throw Exception('Failed to load traffic light status');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Traffic Lights'),
        centerTitle: true, // Center the app bar title
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            // Junction ID and Traffic Light Status
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
              child: Column(
                children: [
                  Text(
                    'Junction: $junctionId',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  // Traffic Light Display
                  Container(
                    width: 120,
                    height: 320,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          Icons.circle,
                          color: status == "red" ? Colors.red : Colors.grey[800],
                          size: 80,
                        ),
                        Icon(
                          Icons.circle,
                          color: status == "yellow" ? Colors.yellow : Colors.grey[800],
                          size: 80,
                        ),
                        Icon(
                          Icons.circle,
                          color: status == "green" ? Colors.green : Colors.grey[800],
                          size: 80,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Time Left: $timeLeft sec',
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: fetchTrafficLightStatus,
                    child: Text('Refresh Status'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      showAlert(context, "Emergency vehicle nearby", "GIVE WAY");
                    },
                    child: Text('Emergency vehicle nearby'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      showAlert(context, "Road Closure Ahead", "Drive safe");
                    },
                    child: Text('Road Closer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            // Notification Area
            Expanded(
              child: Container(
                margin: EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Notification Area',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showAlert(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
