import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TickSoundType { click, beep, woodBlock }

extension TickSoundTypeExtension on TickSoundType {
  String get displayName {
    switch (this) {
      case TickSoundType.click:
        return 'Click';
      case TickSoundType.beep:
        return 'Beep';
      case TickSoundType.woodBlock:
        return 'Wood Block';
    }
  }
}

class MetronomeService extends ChangeNotifier {
  int _bpm = 120;
  bool _isPlaying = false;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  TickSoundType _selectedTickSound = TickSoundType.click;
  bool _isLoaded = false;

  int get bpm => _bpm;
  bool get isPlaying => _isPlaying;
  TickSoundType get selectedTickSound => _selectedTickSound;
  bool get isLoaded => _isLoaded;

  // PCM generation parameters
  static const int _sampleRate = 44100;
  static const int _numChannels = 1;
  static const int _bitsPerSample = 16;

  MetronomeService() {
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _loadTickSoundPreference();
  }

  Future<void> _loadTickSoundPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final soundTypeString = prefs.getString('selectedTickSound') ?? TickSoundType.click.toString();
    _selectedTickSound = TickSoundType.values.firstWhere(
      (e) => e.toString() == soundTypeString,
      orElse: () => TickSoundType.click,
    );
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveTickSoundPreference(TickSoundType soundType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTickSound', soundType.toString());
  }

  void _writeString(ByteData data, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  Uint8List _generateWavHeader(int pcmLength) {
    final int byteRate = _sampleRate * _numChannels * _bitsPerSample ~/ 8;
    final int blockAlign = _numChannels * _bitsPerSample ~/ 8;
    final int subchunk2Size = pcmLength;
    final int chunkSize = 36 + subchunk2Size;

    final ByteData header = ByteData(44);

    _writeString(header, 0, "RIFF");
    header.setUint32(4, chunkSize, Endian.little);
    _writeString(header, 8, "WAVE");
    _writeString(header, 12, "fmt ");
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, _numChannels, Endian.little);
    header.setUint32(24, _sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, _bitsPerSample, Endian.little);
    _writeString(header, 36, "data");
    header.setUint32(40, subchunk2Size, Endian.little);

    return header.buffer.asUint8List();
  }

  Uint8List _generateTickSoundData(TickSoundType soundType) {
    double frequency;
    int tickDurationMs;
    double amplitude;

    switch (soundType) {
      case TickSoundType.click:
        frequency = 1000;
        tickDurationMs = 50;
        amplitude = 0.5;
        break;
      case TickSoundType.beep:
        frequency = 2000;
        tickDurationMs = 100;
        amplitude = 0.6;
        break;
      case TickSoundType.woodBlock:
        frequency = 1500;
        tickDurationMs = 30;
        amplitude = 0.7;
        break;
    }

    final int numSamples = (_sampleRate * tickDurationMs / 1000).round();
    final ByteData pcmByteData = ByteData(numSamples * 2);

    for (int i = 0; i < numSamples; i++) {
      final double time = i / _sampleRate;
      double sample = amplitude * sin(2 * pi * frequency * time);

      if (soundType == TickSoundType.woodBlock) {
        sample = sample * (1 - (i / numSamples));
      }

      final int pcmValue = (sample * 32767).round();
      pcmByteData.setInt16(i * 2, pcmValue, Endian.little);
    }

    final Uint8List pcmData = pcmByteData.buffer.asUint8List();
    final Uint8List wavHeader = _generateWavHeader(pcmData.length);

    final Uint8List completeWav = Uint8List(wavHeader.length + pcmData.length);
    completeWav.setRange(0, wavHeader.length, wavHeader);
    completeWav.setRange(wavHeader.length, completeWav.length, pcmData);

    return completeWav;
  }

  void startStop() {
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      _timer = Timer.periodic(Duration(milliseconds: 60000 ~/ _bpm), (timer) {
        _playSound();
      });
    } else {
      _timer?.cancel();
      _audioPlayer.stop();
    }
    notifyListeners();
  }

  void _playSound() {
    _audioPlayer.play(BytesSource(_generateTickSoundData(_selectedTickSound)));
  }

  void changeBpm(double newBpm) {
    _bpm = newBpm.round();
    if (_isPlaying) {
      _timer?.cancel();
      _timer = Timer.periodic(Duration(milliseconds: 60000 ~/ _bpm), (timer) {
        _playSound();
      });
    }
    notifyListeners();
  }

  void changeTickSound(TickSoundType newSound) {
    _selectedTickSound = newSound;
    _saveTickSoundPreference(newSound);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}