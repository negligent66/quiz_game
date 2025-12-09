import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (ctx) => const HomeScreen(),
        '/quiz': (ctx) => const QuizScreen(),
        '/score': (ctx) => const ScoreScreen(),
      },
    );
  }
}
class MainScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget body;
  final String title;
  const MainScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
    required this.title,
  });

  void _onTap(BuildContext context, int idx) {
    final route = idx == 0 ? '/' : idx == 1 ? '/quiz' : '/score';
    if (ModalRoute.of(context)?.settings.name != route) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (idx) => _onTap(context, idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.score), label: 'Punteggio'),
        ],
      ),
    );
  }
}
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 0,
      title: 'Home',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Benvenuto al Quiz!', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/quiz');
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Inizia Quiz'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Avvia quiz rapido con default
                Navigator.pushReplacementNamed(context, '/quiz');
              },
              child: const Text('Quiz veloce (10 domande)'),
            ),
          ]),
        ),
      ),
    );
  }
}
class Question {
  final String question;
  final String correctAnswer;
  final List<String> allAnswers;

  Question({
    required this.question,
    required this.correctAnswer,
    required this.allAnswers,
  });

  factory Question.fromMap(Map<String, dynamic> m) {
    final unescape = HtmlUnescape();
    final q = unescape.convert(m['question'] as String);
    final correct = unescape.convert(m['correct_answer'] as String);
    final incorrect = (m['incorrect_answers'] as List<dynamic>)
        .map((e) => unescape.convert(e as String))
        .toList();
    final answers = List<String>.from(incorrect)..add(correct);
    answers.shuffle();
    return Question(
      question: q,
      correctAnswer: correct,
      allAnswers: answers,
    );
  }
}
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> _questions = [];
  int _index = 0;
  int _score = 0;
  bool _loading = true;
  int? _selected; // index selezionato per la domanda corrente
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions({int amount = 10}) async {
    setState(() {
      _loading = true;
      _questions = [];
      _index = 0;
      _score = 0;
      _selected = null;
      _answered = false;
    });
    final uri = Uri.parse('https://opentdb.com/api.php?amount=$amount&type=multiple');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>;
      _questions = results.map((e) => Question.fromMap(e as Map<String, dynamic>)).toList();
    }
    setState(() {
      _loading = false;
    });
  }

  void _selectAnswer(int idx) {
    if (_answered) return;
    setState(() {
      _selected = idx;
      _answered = true;
      final selectedText = _questions[_index].allAnswers[idx];
      if (selectedText == _questions[_index].correctAnswer) {
        _score++;
      }
    });
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      Navigator.pushReplacementNamed(context, '/score', arguments: {'score': _score, 'total': _questions.length});
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 1,
      title: 'Quiz',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Text('Domanda ${_index + 1} / ${_questions.length}', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Text(_questions[_index].question, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          ..._questions[_index].allAnswers.asMap().entries.map((e) {
            final idx = e.key;
            final text = e.value;
            Color? color;
            if (_answered) {
              if (text == _questions[_index].correctAnswer) {
                color = Colors.green;
              } else if (_selected == idx) {
                color = Colors.red;
              } else {
                color = null;
              }
            }
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _answered ? null : () => _selectAnswer(idx),
                child: Text(text),
              ),
            );
          }),
          const Spacer(),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _answered ? _next : null,
                child: Text(_index + 1 >= _questions.length ? 'Termina' : 'Prossima'),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _fetchQuestions(),
              child: const Text('Ricarica'),
            )
          ])
        ]),
      ),
    );
  }
}
class ScoreScreen extends StatelessWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {'score': 0, 'total': 0};
    final int score = args['score'] as int;
    final int total = args['total'] as int;

    return MainScaffold(
      currentIndex: 2,
      title: 'Punteggio',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Hai totalizzato', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text('$score / $total', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text('Torna alla Home'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/quiz');
              },
              child: const Text('Gioca di nuovo'),
            ),
          ]),
        ),
      ),
    );
  }
}