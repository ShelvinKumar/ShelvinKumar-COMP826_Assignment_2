# ShelvinKumar-COMP826_Assignment_2 Developer

# Mobile-Based Virtual Traffic Light System

## Overview
The **Mobile-Based Virtual Traffic Light** system is a cross-platform mobile application designed to enhance road safety by simulating real-time traffic light controls. The system integrates features such as emergency vehicle alerts, road closure warnings, and navigation guidance using the Google Maps API. It provides users with a visual representation of traffic light statuses, helping them make informed decisions on the road.

## Features
- **Real-time Traffic Light Simulation**: Displays traffic light changes (red, yellow, green) with dynamic timers.
- **Emergency Alerts**: Notifies users of nearby emergency vehicles with visual and audio alerts.
- **Road Closure Alerts**: Provides real-time updates on road closures to ensure safe driving.
- **Get Directions**: Offers turn-by-turn navigation using the Google Maps API.


## Installation
### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Google Maps API Key](https://developers.google.com/maps/documentation/javascript/get-api-key)

### Steps
1. **Clone the Repository**
   ```bash
   git clone https://github.com/ShelvinKumar/ShelvinKumar-COMP826_Assignment_2/tree/main
   cd virtual-traffic-light

## Install Dependencies

Copy code
flutter pub get
Configure Google Maps API

## Open the constants.dart file.
Replace the googleMapsApiKey variable with your Google Maps API key.
dart

const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
Run the App

## Use the following command to run the app on an emulator or physical device:

flutter run