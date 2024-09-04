import 'package:flutter/material.dart';
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
  String status = "red";
  int timeLeft = 25;

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
  void initState() {
    super.initState();
    fetchTrafficLightStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Traffic Lights'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Junction ID and Traffic Light Status
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  Text(
                    'Junction: $junctionId',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, color: Colors.red, size: 50),
                      Icon(Icons.circle, color: Colors.yellow, size: 50),
                      Icon(Icons.circle, color: Colors.green, size: 50),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Time Left: $timeLeft sec',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 10),
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
