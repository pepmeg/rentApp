import 'dart:convert';
import 'package:http/http.dart' as http;

class YandexGeocoderService {
  static const String _baseUrl = 'https://geocode-maps.yandex.ru/1.x/';
  final String _apiKey;

  YandexGeocoderService(this._apiKey);

  Map<String, String> get _headers => {
    'User-Agent': 'AppRent/1.0',
    'Referer': 'https://apprent.ru',
  };

  Future<List<YandexSuggestItem>> getSuggestions(String query, {
    double? userLat,
    double? userLon,
  }) async {
    String url = '$_baseUrl?apikey=$_apiKey&format=json&geocode=$query&results=10&lang=ru&sco=latlong';
    if (userLat != null && userLon != null) {
      url += '&ll=$userLon,$userLat&spn=0.5,0.5';
    }
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseSuggestions(data);
    } else {
      throw Exception('Ошибка получения подсказок');
    }
  }

  Future<YandexLocation> getCoordinatesByAddress(String address) async {
    final url = Uri.parse(
        '$_baseUrl?apikey=$_apiKey&format=json&geocode=$address&sco=latlong&kind=locality&results=1');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return _parseLocation(data);
    } else {
      throw Exception('Ошибка геокодирования');
    }
  }
  Future<String> getAddressByCoordinates(double latitude, double longitude) async {
    final url = Uri.parse(
        '$_baseUrl?apikey=$_apiKey&format=json&geocode=$longitude,$latitude&sco=latlong&results=1&lang=ru');
    final response = await http.get(url, headers: _headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> geoObjects =
      data['response']['GeoObjectCollection']['featureMember'];
      if (geoObjects.isEmpty) return 'Местоположение не найдено';
      final geoObject = geoObjects.first['GeoObject'];
      final fullDescription = geoObject['description'] as String?;
      final name = geoObject['name'] as String?;

      if (fullDescription != null && fullDescription.isNotEmpty) {
        final parts = fullDescription.split(',').map((s) => s.trim()).toList();
        if (parts.length > 1) {
          return parts.sublist(0, parts.length - 1).join(', ');
        }
        return fullDescription;
      }
      return name ?? 'Местоположение не найдено';
    } else {
      throw Exception('Ошибка обратного геокодирования');
    }
  }

  List<YandexSuggestItem> _parseSuggestions(Map<String, dynamic> data) {
    final List<dynamic> geoObjects =
    data['response']['GeoObjectCollection']['featureMember'];
    return geoObjects.map((obj) {
      final geoObject = obj['GeoObject'];
      final name = geoObject['name'] ?? '';
      final description = geoObject['description'] as String?;
      final pos = geoObject['Point']['pos'];
      final coords = pos.split(' ');
      final kind = geoObject['metaDataProperty']?['GeocoderMetaData']?['kind'] as String? ?? '';

      String? subtitle = _buildCleanSubtitle(description, kind);

      return YandexSuggestItem(
        title: name,
        subtitle: subtitle,
        latitude: double.parse(coords[1]),
        longitude: double.parse(coords[0]),
      );
    }).toList();
  }

  String? _buildCleanSubtitle(String? description, String kind) {
    if (description == null || description.isEmpty) return null;

    final parts = description
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !_isCountryOrSimilar(s))
        .toList();

    if (parts.isEmpty) return null;

    if (kind == 'street' || kind == 'house' || kind == 'address') {
      if (parts.length >= 3) {
        return parts[1];
      } else if (parts.length == 2) {
        return parts[1];
      } else {
        return parts[0];
      }
    } else if (kind == 'locality') {
      if (parts.length >= 2) {
        return parts[0];
      } else {
        return parts[0];
      }
    }
    if (parts.length >= 2) {
      final last = parts.last.toLowerCase();
      if (!last.contains('область') && !last.contains('край') && !last.contains('республика')) {
        parts.removeLast();
      }
    }
    return parts.join(', ');
  }

  bool _isCountryOrSimilar(String s) {
    final lower = s.toLowerCase();
    const countries = [
      'россия', 'russia', 'украина', 'беларусь', 'казахстан',
      'сша', 'usa', 'united states', 'великобритания', 'китай', 'индия',
    ];
    return countries.contains(lower);
  }

  YandexLocation _parseLocation(Map<String, dynamic> data) {
    final List<dynamic> geoObjects =
    data['response']['GeoObjectCollection']['featureMember'];
    if (geoObjects.isEmpty) throw Exception('Адрес не найден');
    final geoObject = geoObjects.first['GeoObject'];
    final pos = geoObject['Point']['pos'];
    final coords = pos.split(' ');
    return YandexLocation(
      latitude: double.parse(coords[1]),
      longitude: double.parse(coords[0]),
      address: geoObject['name'],
    );
  }
}

class YandexSuggestItem {
  final String title;
  final String? subtitle;
  final double latitude;
  final double longitude;
  YandexSuggestItem({
    required this.title,
    this.subtitle,
    required this.latitude,
    required this.longitude,
  });
}

class YandexLocation {
  final double latitude;
  final double longitude;
  final String address;
  YandexLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}