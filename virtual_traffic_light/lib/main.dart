import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TrafficLightModel(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Traffic Lights',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light, // Light theme
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark, // Dark theme
      ),
      themeMode: ThemeMode.system, // Use system theme
      home: TrafficLightScreen(),
    );
  }
}

class TrafficLightScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = Provider.of<TrafficLightModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Traffic Lights'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            // Responsive Street Name Selector
            DropdownButton<String>(
              value: model.selectedStreet,
              onChanged: (String? newValue) {
                model.setSelectedStreet(newValue!);
              },
              items: model.streetNames.map<DropdownMenuItem<String>>((String street) {
                return DropdownMenuItem<String>(
                  value: street,
                  child: Text(street),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            // Responsive Traffic Light Display
            Container(
              width: MediaQuery.of(context).size.width * 0.5, // Responsive width
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.height * 0.02,
                horizontal: MediaQuery.of(context).size.width * 0.05,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    'Street: ${model.selectedStreet}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  AnimatedContainer(
                    duration: Duration(seconds: 1), // Smooth transition for color changes
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
                          color: model.status == "red" ? Colors.red : Colors.grey[800],
                          size: 80,
                        ),
                        Icon(
                          Icons.circle,
                          color: model.status == "yellow" ? Colors.yellow : Colors.grey[800],
                          size: 80,
                        ),
                        Icon(
                          Icons.circle,
                          color: model.status == "green" ? Colors.green : Colors.grey[800],
                          size: 80,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Time Left: ${model.timeLeft} sec',
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: model.fetchTrafficLightStatus,
                    child: Text('Refresh Status'),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      model.showAlert(context, "Emergency vehicle nearby", "GIVE WAY");
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
                      model.showAlert(context, "Road Closure Ahead", "Drive safe");
                    },
                    child: Text('Road Closure'),
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
}

class TrafficLightModel with ChangeNotifier {
  List<String> streetNames = [
    "Queen Street",
    "Lambton Quay",
    "Ponsonby Road",
    "Cuba Street",
    "George Street"
  ]; // List of New Zealand street names

  String selectedStreet = "Queen Street"; // Default selected street
  String status = "red"; // Initial status
  int timeLeft = 15; // Initial time left for red light
  Timer? _timer;
  Timer? _fetchTimer; // Timer for fetching real-time updates
  final String apiKey = "ZlCCGO33mGSVKIOzd6AGzUSi2FAQkA8y"; // TomTom API Key

  TrafficLightModel() {
    startTimer();
    fetchTrafficLightStatusPeriodically(); // Start fetching data periodically
  }

  void setSelectedStreet(String street) {
    selectedStreet = street;
    fetchTrafficLightStatus(); // Fetch new status when street changes
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (timeLeft > 0) {
        timeLeft--;
      } else {
        changeTrafficLightState();
      }
      notifyListeners();
    });
  }

  void changeTrafficLightState() {
    if (status == "red") {
      status = "green";
      timeLeft = 20; // Duration for green light
    } else if (status == "green") {
      status = "yellow";
      timeLeft = 4; // Duration for yellow light
    } else if (status == "yellow") {
      status = "red";
      timeLeft = 15; // Duration for red light
    }
    notifyListeners();
  }

  void fetchTrafficLightStatusPeriodically() {
    _fetchTimer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      fetchTrafficLightStatus();
    });
  }

  Future<void> fetchTrafficLightStatus() async {
    try {
      // Construct the URL using the selected street and API key
      final response = await http.get(
        Uri.parse(
            'https://api.tomtom.com/junction-analytics/junctions/1/preview?key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Parse the response based on the actual data structure returned by the API
        // Assuming that 'currentStatus' and 'timeLeft' are the fields in the response
        if (data != null && data['currentStatus'] != null && data['timeLeft'] != null) {
          status = data['currentStatus']; // Replace 'currentStatus' with actual field
          timeLeft = data['timeLeft'];    // Replace 'timeLeft' with actual field
        }
      } else {
        throw Exception('Failed to load traffic light status');
      }
    } catch (e) {
      print('Error fetching traffic light status: $e');
    }
    notifyListeners(); // Notify listeners after updating status
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
