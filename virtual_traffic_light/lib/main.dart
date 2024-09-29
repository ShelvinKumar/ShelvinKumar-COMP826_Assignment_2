import 'dart:async';
import 'dart:convert';
// import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'constants.dart';

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
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: TrafficLightScreen(),
    );
  }
}

class TrafficLightScreen extends StatelessWidget {
  final Completer<GoogleMapController> _controller = Completer();

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<TrafficLightModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Traffic Lights'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.5,
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
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 20),
                          AnimatedContainer(
                            duration: Duration(seconds: 1),
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
                                  color: model.status == "red"
                                      ? Colors.red
                                      : Colors.grey[800],
                                  size: 80,
                                ),
                                Icon(
                                  Icons.circle,
                                  color: model.status == "yellow"
                                      ? Colors.yellow
                                      : Colors.grey[800],
                                  size: 80,
                                ),
                                Icon(
                                  Icons.circle,
                                  color: model.status == "green"
                                      ? Colors.green
                                      : Colors.grey[800],
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
                              model.showAlert(context,
                                  "Emergency vehicle nearby", "GIVE WAY");
                            },
                            child: Text('Emergency vehicle nearby'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                            ),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              model.showAlert(
                                  context, "Road Closure Ahead", "Drive safe");
                            },
                            child: Text('Road Closure'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                            ),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              model.getDirections(
                                  'Current Location', model.selectedStreet);
                            },
                            child: Text('Get Directions'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
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
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(-36.8485, 174.7633),
                zoom: 14.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              markers: model.markers,
              polylines: model.polylines,
            ),
          ),
        ],
      ),
    );
  }
}

class TrafficLightModel with ChangeNotifier {
  String selectedStreet = "Queen Street";
  String status = "red";
  int timeLeft = 15;
  Timer? _timer;
  Timer? _fetchTimer;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  TrafficLightModel() {
    startTimer();
    fetchTrafficLightStatusPeriodically();
    initializeMarkers();
  }

  void setSelectedStreet(String street) {
    selectedStreet = street;
    fetchTrafficLightStatus();
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
      timeLeft = 20;
    } else if (status == "green") {
      status = "yellow";
      timeLeft = 4;
    } else if (status == "yellow") {
      status = "red";
      timeLeft = 15;
    }
    updateMarkers();
    notifyListeners();
  }

  void fetchTrafficLightStatusPeriodically() {
    _fetchTimer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      fetchTrafficLightStatus();
    });
  }

  Future<void> fetchTrafficLightStatus() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://maps.googleapis.com/maps/api/directions/json?origin=origin&destination=destination&key=$googleMapsApiKey'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data != null &&
            data['currentStatus'] != null &&
            data['timeLeft'] != null) {
          status = data['currentStatus'];
          timeLeft = data['timeLeft'];
        }
      } else {
        throw Exception('Failed to load traffic light status');
      }
    } catch (e) {
      print('Error fetching traffic light status: $e');
    }
    updateMarkers();
    notifyListeners();
  }

  Future<void> getDirections(String origin, String destination) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final polylinePoints =
              data['routes'][0]['overview_polyline']['points'];
          final decodedPoints = _decodePolyline(polylinePoints);
          final polyline = Polyline(
            polylineId: PolylineId('directions'),
            color: Colors.blue,
            width: 5,
            points: decodedPoints,
          );
          polylines.clear();
          polylines.add(polyline);
        }

        print(data);
      } else {
        print('Failed to get directions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }

    notifyListeners();
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  void initializeMarkers() {
    markers.add(Marker(
      markerId: MarkerId('marker_1'),
      position: LatLng(-36.850905, 174.764496),
      infoWindow: InfoWindow(
        title: 'Virtual Traffic Light',
        snippet: 'Status: $status',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        status == "red"
            ? BitmapDescriptor.hueRed
            : status == "yellow"
                ? BitmapDescriptor.hueYellow
                : BitmapDescriptor.hueGreen,
      ),
    ));
    notifyListeners();
  }

  void updateMarkers() {
    markers.clear();
    markers.add(Marker(
      markerId: MarkerId('marker_1'),
      position: LatLng(-36.850905, 174.764496),
      infoWindow: InfoWindow(
        title: 'Virtual Traffic Light',
        snippet: 'Status: $status',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        status == "red"
            ? BitmapDescriptor.hueRed
            : status == "yellow"
                ? BitmapDescriptor.hueYellow
                : BitmapDescriptor.hueGreen,
      ),
    ));
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
