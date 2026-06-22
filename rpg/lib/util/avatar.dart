// 아바타 유틸 — 첨부파일(이미지) 선택 → 64x64 PNG 로 축소/인코딩, 디코딩.
// 작게 저장해 인벤토리 저장/네트워크 전송 부담을 줄이고, 렌더 시 캐릭터 크기 안에 그린다.
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';

const int avatarPixels = 64;

class AvatarData {
  final Uint8List pngBytes;
  final ui.Image image;
  const AvatarData(this.pngBytes, this.image);
}

// 바이트 → 64x64 PNG 로 재인코딩(축소).
Future<Uint8List> _toThumbnailPng(Uint8List src) async {
  final codec = await ui.instantiateImageCodec(src, targetWidth: avatarPixels, targetHeight: avatarPixels);
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

// 파일 선택 → base64(64x64 PNG) 반환. 취소/실패 시 null.
Future<String?> pickAvatarBase64() async {
  final result = await FilePicker.pickFiles(type: FileType.image, withData: true);
  final bytes = result?.files.single.bytes;
  if (bytes == null) return null;
  final png = await _toThumbnailPng(bytes);
  return base64Encode(png);
}

// PNG 바이트 → ui.Image.
Future<ui.Image> decodeImage(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final frame = await codec.getNextFrame();
  return frame.image;
}

// base64 → AvatarData(바이트 + 이미지).
Future<AvatarData?> decodeAvatar(String base64Str) async {
  try {
    final bytes = base64Decode(base64Str);
    final img = await decodeImage(bytes);
    return AvatarData(bytes, img);
  } catch (_) {
    return null;
  }
}
