import 'dart:math';

import 'package:neosecurity/globals.dart';

String random4Number() {
  final random = Random();
  int number = random.nextInt(10000); // 0 ~ 9999
  certNumber = number.toString().padLeft(4, '0');

  //print("certNumber : " + certNumber);
  return certNumber;
}
