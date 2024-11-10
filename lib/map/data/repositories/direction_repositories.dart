import 'package:bari_koi/map/data/models/route_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class   DirectionsRepositoryProvider with ChangeNotifier {
  static const String _baseUrl = 'https://barikoi.xyz/v2/api/routing/matching';
  static String apiKey = dotenv.env['BARIKOI_API_KEY'] ?? '';
  final Dio _dio;

  DirectionsRepositoryProvider({required Dio dio}) : _dio = dio;

  Future<RouteMatchModel?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {

      if (apiKey.isEmpty) {
        throw Exception('API Key is missing');
      }


      String coordinates = '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';

      final response = await _sendRequest(coordinates);

      if (response.statusCode == 200) {
        print('API Response: ${response.data}');
        if (response.data != null && response.data['geometry'] != null) {
          // Extracting distance and status from the response
          double distance = response.data['distance']?.toDouble() ?? 0.0;
          int status = response.data['status'] ?? 0;

          if (status == 200) {
            print('Distance: $distance meters');
            return RouteMatchModel.fromMap(response.data, distance: distance);
          } else {
            throw Exception('Error: Status code is not 200');
          }
        } else {
          throw Exception('GeoJSON geometry missing in response');
        }
      } else {
        throw Exception('Failed to load directions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching directions: $e");
      return null;
    }
  }



  Future<Response> _sendRequest(String coordinates, {int retryCount = 0}) async {
    const int maxRetries = 2;
    const int maxBackoff = 4;

    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'api_key': apiKey,
          'points': coordinates,
          'geometries': 'geojson',
        },
      );
      return response;
    } on DioException catch (e) {
      print("Error during request: ${e.message}");

      if (e.response != null) {
        int statusCode = e.response!.statusCode ?? 0;
        switch (statusCode) {
          case 400:
            print('Error 400: Missing parameter. Response: ${e.response!.data}');
            throw Exception('Parameter missing. Ensure all required parameters are included.');
          case 401:
            print('Error 401: Invalid or No Registered Key. Response: ${e.response!.data}');
            throw Exception('Invalid or no registered API key. Please check your API key.');
          case 402:
            print('Error 402: Payment exception. Response: ${e.response!.data}');
            throw Exception('Payment exception occurred. Ensure your billing information is correct.');
          case 503:
            if (retryCount < maxRetries) {
              int backoffTime = (1 << retryCount);
              print('Server error (503). Retrying in $backoffTime seconds...');
              await Future.delayed(Duration(seconds: backoffTime));
              return _sendRequest(coordinates, retryCount: retryCount + 1);
            }
            break;
          default:
            if (statusCode >= 500 && retryCount < maxRetries) {
              print('Server error (${statusCode}). Retrying...');
              await Future.delayed(Duration(seconds: 2));
              return _sendRequest(coordinates, retryCount: retryCount + 1);
            } else {
              print('Non-retriable error or max retries reached');
              throw Exception('Error ${statusCode}: ${e.response!.data['message'] ?? 'An error occurred'}');
            }
        }
      } else {
        throw Exception('No response received from the server. Please check your connection.');
      }
    }

    throw Exception('Request failed after all retry attempts.');
  }}
