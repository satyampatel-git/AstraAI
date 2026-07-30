import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const AstraAIApp());
}

class AstraAIApp extends StatelessWidget {
  const AstraAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AstraAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0F12),
        primaryColor: const Color(0xFF6C5CE7),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {"role": "assistant", "content": "Hello! Main AstraAI hoon. Main bol bhi sakta hoon aur sun bhi sakta hoon. Poochiye kya puchna hai?"}
  ];
  
  bool _isLoading = false;
  bool _isSpeaking = false;
  
  static const String _apiKey = "YOUR_GEMINI_API_KEY_HERE";
  GenerativeModel? _model;
  ChatSession? _chat;

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _requestMicrophonePermission();
    if (_apiKey != "YOUR_GEMINI_API_KEY_HERE") {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );
      _chat = _model!.startChat();
    }
  }

  void _initTts() {
    _flutterTts.setStartHandler(() => setState(() => _isSpeaking = true));
    _flutterTts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _flutterTts.setErrorHandler((msg) => setState(() => _isSpeaking = false));
    _flutterTts.setLanguage("hi-IN"); // Default Hindi/English friendly accent
    _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() => _isSpeaking = false);
  }

  Future<void> _requestMicrophonePermission() async {
    await Permission.microphone.request();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
            if (_controller.text.isNotEmpty) {
              _sendMessage();
            }
          }
        },
        onError: (error) => setState(() => _isListening = false),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (_isSpeaking) _stopSpeaking();

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isLoading = true;
      _controller.clear();
    });

    try {
      if (_model == null) {
        await Future.delayed(const Duration(seconds: 1));
        const fallbackText = "API Key set nahi hai! Kripya 'YOUR_GEMINI_API_KEY_HERE' ko apni API Key se replace karein.";
        setState(() {
          _messages.add({"role": "assistant", "content": fallbackText});
        });
        _speak(fallbackText);
      } else {
        final content = Content.text(text);
        final response = await _chat!.sendMessage(content);
        final aiResponse = response.text ?? "Mujhe samajh nahi aaya.";
        
        setState(() {
          _messages.add({"role": "assistant", "content": aiResponse});
        });
        _speak(aiResponse);
      }
    } catch (e) {
      final errorMsg = "Error: Response fetch nahi ho paya. ($e)";
      setState(() {
        _messages.add({"role": "assistant", "content": errorMsg});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF161A23),
        elevation: 0,
        title: Text('AstraAI', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        actions: [
          if (_isSpeaking)
            IconButton(
              icon: const Icon(Icons.volume_off, color: Colors.redAccent),
              onPressed: _stopSpeaking,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isUser = _messages[index]["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF6C5CE7) : const Color(0xFF1E2230),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _messages[index]["content"]!,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SpinKitThreeBounce(color: Color(0xFF6C5CE7), size: 24.0),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask AstraAI...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      filled: true,
                      fillColor: const Color(0xFF1E2230),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isListening ? Colors.red : const Color(0xFF6C5CE7),
                  radius: 24,
                  child: IconButton(
                    onPressed: _listen,
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF6C5CE7),
                  radius: 24,
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
