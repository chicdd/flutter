import 'dart:convert';
import 'package:http/http.dart' as http;
import 'Album.dart';

class RestApiService {
  static final RestApiService _instance = RestApiService._internal();
  factory RestApiService() => _instance;
  RestApiService._internal();

  Future<List<Album>> fetchAlbums() async {
    final response = await http.get(
      Uri.http('jsonplaceholder.typicode.com', '/albums'),
    );
    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => Album.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch albums');
    }
  }

  void main() async {
    List<Album> albums = await fetchAlbums();

    for (var album in albums) {
      print('id: ${album.id}, title: ${album.title}');
    }
  }
}
