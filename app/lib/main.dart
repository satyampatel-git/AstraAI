import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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
    {"role": "assistant", "content": "Hello! Main AstraAI hoon. Main aapki kya madad kar sakta hoon?"}
  ];
  
  bool _isLoading = false;
  
  // Replace with your API key
  static const String _apiKey = "YOUR_GEMINI_API_KEY_HERE";
  GenerativeModel? _model;
  ChatSession? _chat;

  // Speech to Text members
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _requestMicrophonePermission();
    if (_apiKey != "YOUR_GEMINI_API_KEY_HERE") {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );
      _chat = _model!.startChat();
    }
  }

  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission denied. Voice feature unavailable.")),
      );
    }
  }

  void _listen() async {
    if (!_isListening) {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') {
            setState(() => _isListening = false);
            if(_controller.text.isNotEmpty) {
               _sendMessage();
            }
          }
        },
        onError: (error) => print('Error: $error'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
            });
          },
          listenMode: stt.ListenMode.confirmation,
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

    if(_speech.isListening){
       _speech.stop();
       setState(() => _isListening = false);
    }

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isLoading = true;
      _controller.clear();
    });

    try {
      if (_model == null) {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _messages.add({
            "role": "assistant",
            "content": "API Key abhi set nahi hai! Kripya code mein 'YOUR_GEMINI_API_KEY_HERE' ko apni API Key se replace karein."
          });
        });
      } else {
        final content = Content.text(text);
        final response = await _chat!.sendMessage(content);
        setState(() {
          _messages.add({
            "role": "assistant", 
            "content": response.text ?? "Mujhe samajh nahi aaya, kripya dobara poochein."
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "assistant",
          "content": "Error: Response fetch nahi ho paya. ($e)"
        });
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
        title: Text(
          'AstraAI',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
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
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
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
              child: SpinKitThreeBounce(
                color: Color(0xFF6C5CE7),
                size: 24.0,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'AstraAI se kuch bhi poochein...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      filled: true,
                      fillColor: const Color(0xFF1E2230),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
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
                    icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white, size: 24),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  const SizedBox(width: 8),
                if (_controller.text.isNotEmpty)
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
