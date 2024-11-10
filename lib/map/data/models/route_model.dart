class Geometry {
  final List<List<double>> coordinates;
  final String type;

  Geometry({
    required this.coordinates,
    required this.type,
  });

  factory Geometry.fromMap(Map<String, dynamic> map) {

    if (map['coordinates'] == null || map['coordinates'].isEmpty) {
      throw Exception("Coordinates are missing or invalid");
    }


    var coordinates = List<List<double>>.from(
      map['coordinates']?.map((x) => List<double>.from(x)) ?? [],
    );

    if (coordinates.isEmpty || coordinates.any((list) => list.length < 2)) {
      throw Exception("Invalid coordinates data");
    }

    return Geometry(
      coordinates: coordinates,
      type: map['type'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coordinates': coordinates.map((x) => List<dynamic>.from(x)).toList(),
      'type': type,
    };
  }
}

class RouteMatchModel {
  final Geometry geometry;
  final double distance;
  final int status;

  RouteMatchModel({
    required this.geometry,
    required this.distance,
    required this.status,
  });

  factory RouteMatchModel.fromMap(Map<String, dynamic> map, {required double distance}) {

    if (map['geometry'] == null) {
      throw Exception("Geometry data is missing");
    }


    return RouteMatchModel(
      geometry: Geometry.fromMap(map['geometry']),
      distance: map['distance']?.toDouble() ?? 0.0,
      status: map['status']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'geometry': geometry.toMap(),
      'distance': distance,
      'status': status,
    };
  }
}
