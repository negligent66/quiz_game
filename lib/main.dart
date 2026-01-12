import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const QuizApp());
}

class GameSession {
  static int answered = 0;
  static int correct = 0;
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  final pages = const [QuizPage(), ScorePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Infinite Quiz")),
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: "Quiz"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Sessione"),
        ],
      ),
    );
  }
}

/* ---------------- QUIZ ---------------- */
String decodeHtml(String text) {
  return text
      .replaceAll("&quot;", "\"")
      .replaceAll("&#039;", "'")
      .replaceAll("&amp;", "&")
      .replaceAll("&lt;", "<")
      .replaceAll("&gt;", ">");
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  Map question = {};
  List<String> options = [];

  bool loading = true;
  bool locked = false;
  String selected = "";

  @override
  void initState() {
    super.initState();
    loadQuestion();
  }

  Future<void> loadQuestion() async {
    try {
      final url = Uri.parse("https://opentdb.com/api.php?amount=1&type=multiple");
      final res = await http.get(url);

      final data = json.decode(res.body);

      if (data == null ||
          data['response_code'] != 0 ||
          data['results'] == null ||
          data['results'].isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        return loadQuestion();
      }

      question = data['results'][0];

      options = List<String>.from(question['incorrect_answers']);
      options.add(question['correct_answer']);
      options.shuffle();

      if (!mounted) return;

      setState(() {
        loading = false;
        locked = false;
        selected = "";
      });
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) loadQuestion();
    }
  }

  void answer(String value) {
    if (locked) return;

    locked = true;
    selected = value;
    GameSession.answered++;

    if (value == question['correct_answer']) {
      GameSession.correct++;
    }

    setState(() {});

    Future.delayed(const Duration(milliseconds: 900), () {
      setState(() => loading = true);
      loadQuestion();
    });
  }

  Color getColor(String value) {
    if (!locked) return Colors.lightBlueAccent;

    if (value == question['correct_answer']) return Colors.green;
    if (value == selected) return Colors.red;

    return Colors.lightBlueAccent;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            decodeHtml(question['question']),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 30),

          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.8,
            children: options.map((o) {
              return ElevatedButton(
                onPressed: () => answer(o),
                style: ElevatedButton.styleFrom(
                  backgroundColor: getColor(o),
                ),
                child: Text(decodeHtml(o), textAlign: TextAlign.center),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/* ---------------- SCORE ---------------- */

class ScorePage extends StatelessWidget {
  const ScorePage({super.key});

  @override
  Widget build(BuildContext context) {
    double accuracy = GameSession.answered == 0
        ? 0
        : (GameSession.correct / GameSession.answered) * 100;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Domande risposte: ${GameSession.answered}",
              style: const TextStyle(fontSize: 22)),
          Text("Corrette: ${GameSession.correct}",
              style: const TextStyle(fontSize: 22)),
          Text("Precisione: ${accuracy.toStringAsFixed(1)}%",
              style: const TextStyle(fontSize: 22)),
        ],
      ),
    );
  }
}
