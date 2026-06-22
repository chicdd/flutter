// 귀여운 효과음 WAV 생성기. `dart run tool/gen_sounds.dart` 로 assets/audio/ 에 출력.
// 절차적 합성(사인/삼각/사각 + 지수 감쇠 + 피치 글라이드) — 짧고 높은 톤의 깜찍한 컨셉.
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 22050;

List<double> tone({
  required double freq,
  required double dur,
  double freqEnd = -1,
  String wave = 'sine',
  double decay = 6,
  double vol = 0.5,
}) {
  final n = (dur * sampleRate).round();
  final out = List<double>.filled(n, 0);
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final f = freqEnd < 0 ? freq : freq + (freqEnd - freq) * (i / n);
    phase += 2 * pi * f / sampleRate;
    double w;
    switch (wave) {
      case 'square':
        w = sin(phase) >= 0 ? 1 : -1;
        break;
      case 'tri':
        w = 2 / pi * asin(sin(phase));
        break;
      default:
        w = sin(phase);
    }
    out[i] = w * exp(-decay * t) * vol;
  }
  return out;
}

List<double> concat(List<List<double>> parts) {
  final out = <double>[];
  for (final p in parts) {
    out.addAll(p);
  }
  return out;
}

List<double> mix(List<double> a, List<double> b) {
  final n = max(a.length, b.length);
  final out = List<double>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    out[i] = (i < a.length ? a[i] : 0) + (i < b.length ? b[i] : 0);
  }
  return out;
}

Uint8List wav(List<double> samples) {
  final n = samples.length;
  final dataLen = n * 2;
  final b = BytesBuilder();
  void str(String s) => b.add(s.codeUnits);
  void u32(int v) => b.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  void u16(int v) => b.add((ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());
  str('RIFF');
  u32(36 + dataLen);
  str('WAVE');
  str('fmt ');
  u32(16);
  u16(1);
  u16(1);
  u32(sampleRate);
  u32(sampleRate * 2);
  u16(2);
  u16(16);
  str('data');
  u32(dataLen);
  final pcm = ByteData(dataLen);
  for (var i = 0; i < n; i++) {
    pcm.setInt16(i * 2, (samples[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  b.add(pcm.buffer.asUint8List());
  return b.toBytes();
}

void main() {
  final dir = Directory('assets/audio');
  dir.createSync(recursive: true);

  final sounds = <String, List<double>>{
    // 무기 공격.
    'sword': tone(freq: 760, freqEnd: 320, dur: 0.16, wave: 'tri', decay: 11, vol: 0.5),
    'spear': tone(freq: 1250, freqEnd: 950, dur: 0.09, wave: 'tri', decay: 20, vol: 0.5),
    'bow': tone(freq: 520, freqEnd: 980, dur: 0.12, wave: 'tri', decay: 15, vol: 0.5),
    'axe': mix(tone(freq: 165, dur: 0.18, wave: 'square', decay: 10, vol: 0.5),
        tone(freq: 330, dur: 0.1, wave: 'tri', decay: 16, vol: 0.25)),
    'staff': tone(freq: 620, freqEnd: 1500, dur: 0.2, wave: 'sine', decay: 7, vol: 0.45),
    // 전투/UI.
    'hit': tone(freq: 320, dur: 0.06, wave: 'square', decay: 26, vol: 0.5),
    'monster': tone(freq: 920, freqEnd: 520, dur: 0.12, wave: 'tri', decay: 13, vol: 0.45),
    'skill': concat([
      tone(freq: 880, dur: 0.06, decay: 14, vol: 0.4),
      tone(freq: 1320, dur: 0.10, decay: 10, vol: 0.4),
    ]),
    'level': concat([
      tone(freq: 660, dur: 0.09, decay: 9, vol: 0.45),
      tone(freq: 880, dur: 0.09, decay: 9, vol: 0.45),
      tone(freq: 1100, dur: 0.09, decay: 9, vol: 0.45),
      tone(freq: 1320, dur: 0.16, decay: 6, vol: 0.45),
    ]),
    'coin': concat([
      tone(freq: 1180, dur: 0.05, decay: 16, vol: 0.4),
      tone(freq: 1560, dur: 0.10, decay: 12, vol: 0.4),
    ]),
    'potion': tone(freq: 420, freqEnd: 860, dur: 0.18, wave: 'sine', decay: 6, vol: 0.4),
  };

  sounds.forEach((name, samples) {
    File('${dir.path}/$name.wav').writeAsBytesSync(wav(samples));
    stdout.writeln('wrote assets/audio/$name.wav (${samples.length} samples)');
  });
}
