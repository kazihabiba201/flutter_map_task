# Bari Koi Map

The goal is to create a Flutter application that displays a full-screen Barikoi map on the home page. The app should request location permissions upon opening, show the current location, and handle user interactions for reverse geolocation and directions.

![Screenshot 2023-11-08 045306](https://github.com/user-attachments/assets/8464129c-c76b-4b3e-9ada-1c3824cd47e4)


## Core Packages Used
The following packages are used in the project:

- `maplibre_gl: ^0.19.0:` For rendering Barikoi maps in the application.
- `location: ^7.0.1:` For retrieving the current location of the user.
- `dio: ^5.7.0:` For making HTTP requests to Barikoi APIs.
- `flutter_map: ^7.0.2:` For mapping features with integration for Barikoi.
- `geolocator: ^13.0.1:` For accessing the geolocation of the user.
- `flutter_dotenv: ^5.2.1:` For managing environment variables, such as the API key, securely.
- `permission_handler: ^11.3.1:` For handling location permissions.
- `provider: ^6.1.2:` For state management using the ChangeNotifier pattern.

## Getting Started

### Prerequisites
Before you begin, make sure you have Flutter installed on your system. If you need installation guidance, visit the official Flutter Website [click the image!] [![Flutter Website](https://meterpreter.org/wp-content/uploads/2018/09/flutter.png)](https://docs.flutter.dev/get-started/install).
## Installation 

To launch the CraftyBay Application, follow these steps:

Clone this repository to your computer:
```bash
  git clone https://github.com/kazihabiba201/flutter_map_task

```
Navigate to the project folder:
```bash
 cd bari_koi

```
    
Install dependencies:
```bash
 flutter pub get
```

### Installable APK

[![drive](https://img.shields.io/badge/Click_Here_to_download_APK-000?style=for-the-badge&logo=flutter&logoColor=white)](https://drive.google.com/file/d/1IHbSV-s5hN7SfKOJKdWwUceHRUFcxzfc/view?usp=sharing)

### Executing the Code

Follow these steps to connect your device or emulator and launch the app using the following command:

```bash
flutter run
```


## Setup Instructions
Before using this app, you need to set up environment variables:

- `Install dependencies:` Add the dependencies to your pubspec.yaml file:
```
yaml

dependencies:
  flutter:
    sdk: flutter
  maplibre_gl: ^0.19.0
  location: ^7.0.1
  dio: ^5.7.0
  geolocator: ^13.0.1
  flutter_dotenv: ^5.2.1
  permission_handler: ^11.3.1
  provider: ^6.1.2

```
- `Create a .env file:` In the root directory of your Flutter project, create a file named .env and add your API key:

```
makefile

API_KEY=your_barikoi_api_key

```
- `Load Environment Variables:` In your main.dart file, import flutter_dotenv, and load the environment variables before running the app:

```
dart

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
    try {
    await dotenv.load(fileName: ".env");
    print('Environment variables loaded successfully.');
  } catch (e) {
    print('Error loading .env file: $e');
  }
  runApp(MyApp());
}

```
- `Access the API Key:` You can now access the API key anywhere in your project using:

```
dart

String apiKey = dotenv.env['API_KEY']!;

```
##

## Detailed Class Documentation
### MapProvider
This class handles the map-related state, including retrieving the user’s location, reverse geocoding, and routing. It uses Dio for making API requests and ChangeNotifier for state management.

### Attributes
- `CameraPosition initialPosition:` Initial camera position when the map is first loaded.
- `MaplibreMapController? mController:` Controller for interacting with the map.
- `Dio dio:` HTTP client used to make API requests.
- `LatLng? currentLatLng:` Stores the current location of the user.
- `Symbol? originMarker, destinationMarker:` Markers on the map for the origin and destination.
- `bool isLoading:` Tracks the loading state during API calls.
- `String apiKey:` API key loaded from .env file.

### Key Methods
1. `_checkLocationPermission()`
- Requests permission to access the user's location and calls getCurrentLocation() if granted.

```
Future<void> _checkLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      await getCurrentLocation();
    } else if (status.isDenied || status.isPermanentlyDenied) {
      print('Location permission denied');
    }
  }

```
2. `_setNewLatlngZoom()`
-  Animates the map camera to specified coordinates and zoom.

```
  void _setNewLatlngZoom(LatLng targetLatLng) {
    mController?.animateCamera(
      CameraUpdate.newLatLngZoom(targetLatLng, 12),
      duration: const Duration(milliseconds: 300),
    );
  }

```
3. `getCurrentLocation()`
- Gets the device's current location and updates the map camera.

```
  Future<void> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      currentLatLng = LatLng(position.latitude, position.longitude);

    
      _setNewLatlngZoom(currentLatLng!);

      _addMarker(currentLatLng!, 'My Current Location', isOrigin: true);
    } catch (e) {
      print('Error getting current location: $e');
    }
  }


```
4. `getAddressFromCoordinates()`
- Fetches an address from coordinates and updates relevant address variables.

```

  Future<void> getAddressFromCoordinates(
      LatLng coordinates, BuildContext context) async {
    final String apiUrl =
        'https://barikoi.xyz/v2/api/search/reverse/geocode?key=$apiKey&longitude=${coordinates.longitude}&latitude=${coordinates.latitude}';

    try {
      final response = await dio.get(apiUrl);
      if (response.statusCode == 200) {
        final data = response.data;
        final address = data['place'] is Map
            ? data['place'].toString()
            : data['place'] ?? 'Address not found';

        if (isSettingOrigin) {
          originAddress = address;
          originCoordinates = coordinates;
        } else {
          destinationAddress = address;
          destinationCoordinates = coordinates;
        }

        notifyListeners();

        if (isSettingOrigin) {
          isSettingOrigin = false;
          _addMarker(coordinates, 'Origin: $address', isOrigin: true);
        } else {
          isSettingOrigin = true;
          _addMarker(coordinates, 'Destination: $address', isOrigin: false);
        }
      } else {
        throw Exception('Failed to load address');
      }
    } catch (e) {
   
      errorMessage = 'Failed to fetch address. Please try again later.';
      notifyListeners();

      _showErrorSnackbar(context);
    } finally {
      isLoading = false; 
      notifyListeners();
    }
  }

```
5. `_showErrorSnackbar()`
- Displays an error message as a Snackbar in the UI.

```
  void _showErrorSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        duration: Duration(seconds: 3),
      ),
    );
  }

```
6. `addImageFromAsset()`
- Loads a custom marker icon from assets.

```
  Future<void> addImageFromAsset(String name, String path) async {
    final ByteData bytes = await rootBundle.load(path);
    final Uint8List list = bytes.buffer.asUint8List();
    await mController?.addImage(name, list);
    isCustomMarkerAdded = true;
    notifyListeners();
  }
```
7. `_addRouteToMap()`
- Adds a route line to the map using GeoJSON data.

```
 Future<void> _addRouteToMap(RouteMatchModel route) async {
    if (mController != null) {
      final geoJson = {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {
              "type": "LineString",
              "coordinates": route.geometry.coordinates,
            }
          }
        ]
      };

      try {
        mController?.removeLayer('route-layer');
        mController?.removeSource('route-source');
      } catch (e) {
        print('Error removing old route layer or source: $e');
      }

      try {
        await mController?.addSource(
          'route-source',
          GeojsonSourceProperties(data: geoJson),
        );

        await mController?.addLineLayer(
          'route-source',
          'route-layer',
          const LineLayerProperties(
            lineColor: '#ff0000',
            lineWidth: 5.0,
            lineOpacity: 0.7,
          ),
        );
        print('Route layer added successfully');
      } catch (e) {
        print('Error adding GeoJSON source or line layer: $e');
      }
    } else {
      print('Map controller is not initialized');
    }
  }

```
8. `getDirections()`
- Retrieves route data from the API and displays it on the map.

```
Future<void> getDirections() async {
    if (originMarker != null &&
        destinationMarker != null &&
        currentLatLng != null &&
        selectedLocation != null) {
      RouteMatchModel? route = await directionsRepository?.getDirections(
        origin: currentLatLng!,
        destination: selectedLocation!,
      );

      if (route != null) {
        _addRouteToMap(route);
      }
    }
  }

```
9. `_addMarker()`
- Adds a marker to the map and updates the origin or destination.

```
void _addMarker(LatLng coordinates, String address,
      {required bool isOrigin}) async {
    SymbolOptions symbolOptions = SymbolOptions(
      geometry: coordinates,
      iconImage: 'custom-marker',
      iconSize: 0.4,
      textField: address,
      textSize: 12.5,
      textOffset: const Offset(0, 1.2),
      textAnchor: 'top',
      textColor: '#000000',
      textHaloBlur: 1,
      textHaloColor: '#ffffff',
      textHaloWidth: 0.8,
    );

    if (!isCustomMarkerAdded) {
      await addImageFromAsset("custom-marker", "assets/images/marker.png");
    }

    Symbol newMarker = await mController!.addSymbol(symbolOptions);

    if (isOrigin) {
      if (originMarker != null) {
        mController?.removeSymbol(originMarker!);
      }
      originMarker = newMarker;


      currentLatLng = coordinates;
      notifyListeners();

   automatically
      if (destinationMarker != null) {
        getDirections();
      }
    } else {
      if (destinationMarker != null) {
        mController?.removeSymbol(destinationMarker!);
      }
      destinationMarker = newMarker;


      selectedLocation = coordinates;
      notifyListeners();

automatically
      if (originMarker != null) {
        getDirections();
      }
    }
  }

```
## APIs Used
#### Map Display API

- `Endpoint:` 'https://map.barikoi.com/styles/$styleId/style.json?key=$apiKey'
- `Purpose:` Fetches the styled map for rendering in the app.
#### Reverse Geolocation API

- `Endpoint:` 'https://barikoi.xyz/v2/api/search/reverse/geocode?key=$apiKey&longitude=${coordinates.longitude}&latitude=${coordinates.latitude}'
- `Purpose:` Fetches the address for the given coordinates.
#### Routing API

- `Endpoint:` 'https://barikoi.xyz/v2/api/routing/matching'
- `Purpose:` Fetches route matching information for displaying paths on the map.

## State Management
- `Provider (ChangeNotifier):` MapProvider class extends ChangeNotifier and is used for managing and notifying changes in state, such as the current location or map markers.
- `Reactivity:` Methods like getAddressFromCoordinates() and getDirections() trigger notifyListeners() to update the UI when the data changes.

## HTTP Client (Dio)
#### Initialization:
```
dart

Dio dio = Dio();

```
#### `API Calls:` Used for making GET requests to the Barikoi APIs for reverse geolocation and routing.

##

## Custom PNG Marker on Map
<img src="https://github.com/user-attachments/assets/eacd9063-c386-47bf-b8e2-098f0310f0d2" height="100"/>

## Map Screens
<img src="https://github.com/user-attachments/assets/091d69b9-e384-4c58-9532-3f39930c555b" height="500"/>
<img src="https://github.com/user-attachments/assets/f632944c-23da-42f9-8d49-f86ff291eae5" height="500"/>
<img src="https://github.com/user-attachments/assets/478dc4d3-bc2e-423c-9df6-d9598d369126" height="500"/>

