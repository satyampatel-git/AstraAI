import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
        ),
      ),
      home: const VoiceHomeScreen(),
    );
  }
}

class VoiceHomeScreen extends StatefulWidget {
  const VoiceHomeScreen({super.key});

  @override
  State<VoiceHomeScreen> createState() => _VoiceHomeScreenState();
}

class _VoiceHomeScreenState extends State<VoiceHomeScreen> {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;

  bool _isListening = false;
  String _spokenText = "Mic button dabaiye aur boliye...";
  String _aiResponse = "";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
  }

  Future<void> _speak(String text) async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _spokenText = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _processCommand(_spokenText);
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _processCommand(String command) {
    String response = "Maine suna: $command. Abhi main is par kaam kar raha hoon!";
    setState(() {
      _aiResponse = response;
    });
    _speak(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AstraAI Assistant'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              size: 80,
              color: _isListening ? Colors.redAccent : Colors.deepPurpleAccent,
            ),
            const SizedBox(height: 30),
            Text(
              _spokenText,
              style: const TextStyle(fontSize: 18, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_aiResponse.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _aiResponse,
                  style: const TextStyle(fontSize: 16, color: Colors.purpleAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 40),
            FloatingActionButton.extended(
              onPressed: _listen,
              icon: Icon(_isListening ? Icons.stop : Icons.mic),
              label: Text(_isListening ? "Listening..." : "Start Talking"),
              backgroundColor: Colors.deepPurpleAccent,
            ),
          ],
        ),
      ),
    );
  }
}
