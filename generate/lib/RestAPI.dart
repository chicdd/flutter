import 'dart:convert';
import 'dart:ffi';
import 'package:http/http.dart' as http;

import 'globals.dart';

class RestApiService {
  static final RestApiService _instance = RestApiService._internal();
  factory RestApiService() => _instance;
  RestApiService._internal();

  Future<List<DynamicModel>> fetch(String request) async {
    final String baseUrl = "https://10.0.2.2:7204";
    final String page = request;
    final url = Uri.parse("$baseUrl/$page");
    var response = await http.get(url);
    print(url);
    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => DynamicModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch albums');
    }
  }
}
