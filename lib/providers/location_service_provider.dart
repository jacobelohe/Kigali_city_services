import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class UserPosition {
  final double lat;
  final double lng;
  UserPosition(this.lat, this.lng);

  double distanceTo(double lat2, double lng2) {
    return Geolocator.distanceBetween(lat, lng, lat2, lng2) / 1000;
  }
}

final userPositionProvider = StateProvider<UserPosition?>((ref) => null);
