import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Служба геолокации выключена');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw Exception('Нет разрешения на геолокацию');
      }
    }
    return await Geolocator.getCurrentPosition();
  }

  static Future<String> addressFromPosition(Position pos) async {
    final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
    if (placemarks.isEmpty) return 'Неизвестно';
    final place = placemarks.first;
    return '${place.locality ?? ''}, ${place.street ?? ''}';
  }
}