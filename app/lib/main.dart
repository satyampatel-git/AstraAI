import 'package:flutter/material.dart';

void main() {
  runApp(const AstraAI());
}

class AstraAI extends StatelessWidget {
  const AstraAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AstraAI',
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("AstraAI Assistant"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.smart_toy,
                size: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                "Hello, I am AstraAI",
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                child: const Text("🎤 Speak"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
