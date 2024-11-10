import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bari_koi/map/data/repositories/direction_repositories.dart';
import 'package:bari_koi/map/data/models/route_model.dart';

class MapProvider with ChangeNotifier {

  CameraPosition initialPosition = const CameraPosition(
    target: LatLng(23.835677, 90.380325),
    zoom: 12,
  );

  MaplibreMapController? mController;
  Dio dio = Dio();
  DirectionsRepositoryProvider? directionsRepository;
  static const styleId = 'osm-liberty';
  static String apiKey = dotenv.env['BARIKOI_API_KEY'] ?? '';
  static final mapUrl =
      'https://map.barikoi.com/styles/$styleId/style.json?key=$apiKey';
  String currentAddress = 'Click on the map to get the address';
  LatLng? selectedLocation;
  LatLng? currentLatLng;
  Symbol? originMarker;
  String originAddress = '';
  String destinationAddress = '';
  Symbol? destinationMarker;
  LatLng originCoordinates = LatLng(0.0, 0.0); // Store the origin coordinates
  LatLng destinationCoordinates = LatLng(0.0, 0.0);
  String? routeLineId;
  bool isSettingOrigin = true;
  bool isCustomMarkerAdded = false;
  bool isLoading = false; // for loading state
  String errorMessage = '';

  // Initializes the map provider and checks location permissions.
  MapProvider() {
    directionsRepository = DirectionsRepositoryProvider(dio: dio);
    _checkLocationPermission();
  }

  // Checks and requests location permissions, then gets the current location.
  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      await getCurrentLocation();
    } else if (status.isDenied || status.isPermanentlyDenied) {
      print('Location permission denied');
    }
  }

  // Animates the map camera to specified coordinates and zoom.
  void _setNewLatlngZoom(LatLng targetLatLng) {
    mController?.animateCamera(
      CameraUpdate.newLatLngZoom(targetLatLng, 12),
      duration: const Duration(milliseconds: 300),
    );
  }

  // Gets the device's current location and updates the map camera.
  Future<void> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      currentLatLng = LatLng(position.latitude, position.longitude);

      // Move camera to current location
      _setNewLatlngZoom(currentLatLng!);

      _addMarker(currentLatLng!, 'My Current Location', isOrigin: true);
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

// Fetches an address from coordinates and updates relevant address variables.
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
      // Handle error by setting an error message
      errorMessage = 'Failed to fetch address. Please try again later.';
      notifyListeners();

      // Notify the UI via snackbar using the context
      _showErrorSnackbar(context);
    } finally {
      isLoading = false; // Set loading to false when done
      notifyListeners();
    }
  }

// Displays an error message as a Snackbar in the UI.
  void _showErrorSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Loads a custom marker icon from assets.
  Future<void> addImageFromAsset(String name, String path) async {
    final ByteData bytes = await rootBundle.load(path);
    final Uint8List list = bytes.buffer.asUint8List();
    await mController?.addImage(name, list);
    isCustomMarkerAdded = true;
    notifyListeners();
  }

// Adds a route line to the map using GeoJSON data.

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

  // Retrieves route data from the API and displays it on the map.

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

  // Adds a marker to the map and updates origin or destination.

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
      // Store the coordinates for the origin

      currentLatLng = coordinates;
      notifyListeners();

      // If both origin and destination are set, fetch directions automatically
      if (destinationMarker != null) {
        getDirections();
      }
    } else {
      if (destinationMarker != null) {
        mController?.removeSymbol(destinationMarker!);
      }
      destinationMarker = newMarker;
      // Store the coordinates for the destination

      selectedLocation = coordinates;
      notifyListeners();

      // If both origin and destination are set, fetch directions automatically
      if (originMarker != null) {
        getDirections();
      }
    }
  }
}
