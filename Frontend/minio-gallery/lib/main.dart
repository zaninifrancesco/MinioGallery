import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minio Gallery Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Backend Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _response = 'Press the button to test API';

  Future<void> _callApiTest() async {
    setState(() {
      _response = 'Loading...';
    });
    try {
      // IMPORTANT: Replace with your actual backend IP/hostname if not running on localhost
      // or if testing on a physical device.
      // For Android emulator, localhost usually maps to 10.0.2.2
      // For iOS simulator, localhost usually works directly.
      final url = Uri.parse('http://localhost:8080/api/test');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _response = 'Response from backend: ${response.body}';
        });
      } else {
        setState(() {
          _response = 'Error: ${response.statusCode}\n${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_response, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _callApiTest,
              child: const Text('Call /api/test'),
            ),
          ],
        ),
      ),
    );
  }
}
