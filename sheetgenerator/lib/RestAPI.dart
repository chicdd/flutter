import 'dart:convert';
import 'dart:ffi';
import 'package:http/http.dart' as http;

import 'globals.dart';

class RestApiService {
  static final RestApiService _instance = RestApiService._internal();
  factory RestApiService() => _instance;
  RestApiService._internal();

  Future<List<Customer>> fetchCustomer() async {
    final String baseUrl = "https://10.0.2.2:7204";
    final String today = "customer";
    final url = Uri.parse("$baseUrl/$today");
    var response = await http.get(url);
    // print(Uri.http.toString());
    // print(response.statusCode);
    //print("데이터" + response.body);
    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => Customer.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch albums');
    }
  }

  Future<List<Manager>> fetchManager() async {
    final String baseUrl = "https://10.0.2.2:7204";
    final String today = "manager";
    final url = Uri.parse("$baseUrl/$today");
    var response = await http.get(url);
    // print(Uri.http.toString());
    // print(response.statusCode);
    //print("데이터" + response.body);
    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => Manager.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch albums');
    }
  }

  Future<List<Map<String, dynamic>>> fetch(String tree) async {
    final String baseUrl = "https://10.0.2.2:7204";
    final String today = tree;
    final url = Uri.parse("$baseUrl/$today");
    print(url);
    var response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      print(jsonList);
      return jsonList.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch $tree');
    }
  }

  // void main() async {
  //   List<Customer> Customers = await fetchAlbums();
  //
  //   for (var Customer in Customers) {
  //     print('remoterequestResult: ${Customer.code}, ${Customer.name}');
  //   }
  // }
}
