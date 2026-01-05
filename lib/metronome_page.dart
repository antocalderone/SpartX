import 'dart:async';
import 'dart:typed_data'; // Import for Uint8List
import 'dart:math'; // Import for sin function
import 'package:flutter/material.dart';
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

class MetronomePage extends StatefulWidget {
  const MetronomePage({super.key});

  @override
  _MetronomePageState createState() => _MetronomePageState();
}

class _MetronomePageState extends State<MetronomePage> {
  int _bpm = 120;
  bool _isPlaying = false;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  TickSoundType _selectedTickSound = TickSoundType.click;
  bool _isLoaded = false;

  // PCM generation parameters (common)
  static const int _sampleRate = 44100; // samples per second
  static const int _numChannels = 1; // Mono audio
  static const int _bitsPerSample = 16; // 16-bit audio

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _loadTickSoundPreference();
  }

  Future<void> _loadTickSoundPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final soundTypeString = prefs.getString('selectedTickSound') ?? TickSoundType.click.toString();
    setState(() {
      _selectedTickSound = TickSoundType.values.firstWhere(
        (e) => e.toString() == soundTypeString,
        orElse: () => TickSoundType.click,
      );
      _isLoaded = true;
    });
  }

  Future<void> _saveTickSoundPreference(TickSoundType soundType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTickSound', soundType.toString());
  }

  // Helper function to write a string into ByteData
  void _writeString(ByteData data, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  // Generates a WAV header
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

  // Generates PCM data for different tick sounds
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
        frequency = 1500; // Higher frequency for a sharper sound
        tickDurationMs = 30; // Very short for a percussive feel
        amplitude = 0.7; // Slightly louder
        break;
    }

    final int numSamples = (_sampleRate * tickDurationMs / 1000).round();
    final ByteData pcmByteData = ByteData(numSamples * 2);

    for (int i = 0; i < numSamples; i++) {
      final double time = i / _sampleRate;
      double sample = amplitude * sin(2 * pi * frequency * time);

      // Apply a decay for wood block effect
      if (soundType == TickSoundType.woodBlock) {
        sample = sample * (1 - (i / numSamples)); // Linear decay
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

  void _startStop() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _timer = Timer.periodic(Duration(milliseconds: 60000 ~/ _bpm), (timer) {
          _playSound();
        });
      } else {
        _timer?.cancel();
        _audioPlayer.stop();
      }
    });
  }

  void _playSound() {
    _audioPlayer.play(BytesSource(_generateTickSoundData(_selectedTickSound)));
  }

  void _onBpmChanged(double newBpm) {
    setState(() {
      _bpm = newBpm.round();
      if (_isPlaying) {
        _timer?.cancel();
        _timer = Timer.periodic(Duration(milliseconds: 60000 ~/ _bpm), (timer) {
          _playSound();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return Scaffold( // Removed const here
        appBar: AppBar(title: Text('Metronomo')),
        body: const Center(child: const CircularProgressIndicator()), // Added const to Center and CircularProgressIndicator
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metronomo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$_bpm BPM',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Slider(
              value: _bpm.toDouble(),
              min: 40,
              max: 240,
              divisions: 200,
              label: _bpm.round().toString(),
              onChanged: _onBpmChanged,
            ),
            const SizedBox(height: 20),
            DropdownButton<TickSoundType>(
              value: _selectedTickSound,
              onChanged: (TickSoundType? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedTickSound = newValue;
                  });
                  _saveTickSoundPreference(newValue);
                }
              },
              items: TickSoundType.values.map<DropdownMenuItem<TickSoundType>>((TickSoundType value) {
                return DropdownMenuItem<TickSoundType>(
                  value: value,
                  child: Text(value.displayName),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startStop,
              child: Text(_isPlaying ? 'Stop' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}