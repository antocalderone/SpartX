import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'metronome_service.dart';

class MetronomePage extends StatelessWidget {
  const MetronomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final metronomeService = Provider.of<MetronomeService>(context);

    if (!metronomeService.isLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Metronomo')),
        body: const Center(child: CircularProgressIndicator()),
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
              '${metronomeService.bpm} BPM',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Slider(
              value: metronomeService.bpm.toDouble(),
              min: 40,
              max: 240,
              divisions: 200,
              label: metronomeService.bpm.round().toString(),
              onChanged: (newBpm) => metronomeService.changeBpm(newBpm),
            ),
            const SizedBox(height: 20),
            DropdownButton<TickSoundType>(
              value: metronomeService.selectedTickSound,
              onChanged: (TickSoundType? newValue) {
                if (newValue != null) {
                  metronomeService.changeTickSound(newValue);
                }
              },
              items: TickSoundType.values
                  .map<DropdownMenuItem<TickSoundType>>((TickSoundType value) {
                return DropdownMenuItem<TickSoundType>(
                  value: value,
                  child: Text(value.displayName),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => metronomeService.startStop(),
              child: Text(metronomeService.isPlaying ? 'Stop' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}