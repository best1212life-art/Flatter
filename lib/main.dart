import 'package:flutter/material.dart';

void main() => runApp(const QuizApp());

class Question {
  const Question(this.text, this.options, this.answer);
  final String text;
  final List<String> options;
  final int answer;
}

const questions = [
  Question('What is the capital of Egypt?', ['Alexandria', 'Cairo', 'Giza', 'Luxor'], 1),
  Question('Which language does Flutter use?', ['Java', 'Kotlin', 'Dart', 'Swift'], 2),
  Question('How many continents are there?', ['5', '6', '7', '8'], 2),
  Question('Which planet is closest to the Sun?', ['Venus', 'Mercury', 'Mars', 'Earth'], 1),
];

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const QuizPage(),
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _index = 0;
  int _score = 0;
  int? _picked;

  void _pick(int i) {
    if (_picked != null) return;
    setState(() {
      _picked = i;
      if (i == questions[_index].answer) _score++;
    });
  }

  Color? _tileColor(int i) {
    final picked = _picked;
    if (picked == null) return null;
    if (i == questions[_index].answer) return Colors.green.shade100;
    if (i == picked) return Colors.red.shade100;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= questions.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Score: $_score of ' + questions.length.toString(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => setState(() {
                  _index = 0;
                  _score = 0;
                  _picked = null;
                }),
                child: const Text('Play again'),
              ),
            ],
          ),
        ),
      );
    }

    final q = questions[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Question ' + (_index + 1).toString() + ' of ' + questions.length.toString(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(q.text, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            for (var i = 0; i < q.options.length; i++)
              Card(
                color: _tileColor(i),
                child: ListTile(
                  title: Text(q.options[i]),
                  onTap: () => _pick(i),
                ),
              ),
            const Spacer(),
            if (_picked != null)
              FilledButton(
                onPressed: () => setState(() {
                  _index++;
                  _picked = null;
                }),
                child: Text(_index == questions.length - 1 ? 'See result' : 'Next'),
              ),
          ],
        ),
      ),
    );
  }
}
