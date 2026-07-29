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
          title: const Text("AstraAI"),
        ),
        body: const Center(
          child: Text(
            "Hello, I am AstraAI 🚀",
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}


