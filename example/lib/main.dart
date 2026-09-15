import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lid_effect/flutter_lid_effect.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});
  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final _preview = StreamController<LidAngleReading>.broadcast();
  bool _simulate = false;
  bool _enabled = true;
  double _angle = 130;

  @override
  void dispose() {
    _preview.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('MacBook lid effect')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Enable effect'),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          SwitchListTile(
            title: const Text('Simulate angle'),
            value: _simulate,
            onChanged: (value) {
              setState(() {
                _simulate = value;
                _angle = 130;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _simulate) {
                  _preview.add(const LidAngleReading(angle: 130, reset: true));
                }
              });
            },
          ),
          if (_simulate)
            Slider(
              value: _angle,
              min: 0,
              max: 130,
              label: '${_angle.round()}°',
              onChanged: (value) {
                setState(() => _angle = value);
                _preview.add(LidAngleReading(angle: value));
              },
            )
          else
            StreamBuilder<LidAngleReading>(
              stream: LidAngleSensor.readings,
              builder: (context, snapshot) => Text(
                snapshot.data?.angle == null
                    ? 'Waiting for a visible built-in display and compatible sensor'
                    : '${snapshot.data!.angle!.toStringAsFixed(2)}°',
              ),
            ),
          Expanded(
            child: LidAngleEffect(
              enabled: _enabled,
              angles: _simulate ? _preview.stream : null,
              child: const ColoredBox(
                color: Color(0xfff2f5fa),
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        'Close below 90°, then open again',
                        style: TextStyle(fontSize: 28),
                      ),
                      SizedBox(height: 24),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'This input stays intact',
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Only this content is transformed. The controls above remain usable.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
