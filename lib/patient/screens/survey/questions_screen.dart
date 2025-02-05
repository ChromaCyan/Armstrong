import 'package:flutter/material.dart';
import 'package:armstrong/widgets/forms/question_form.dart';
import 'package:armstrong/patient/screens/survey/submission_page.dart';
import 'package:armstrong/services/api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class QuestionScreen extends StatefulWidget {
  @override
  _QuestionScreenState createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  PageController _pageController = PageController();
  Map<int, String> _selectedAnswers = {};
  String? _userId;
  List<Map<String, dynamic>> _questions = [];
  final ApiRepository _apiRepository = ApiRepository();
  bool _isLoading = true;
  String _category = '';

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _fetchQuestions();
  }

  Future<void> _loadUserId() async {
    final FlutterSecureStorage storage = FlutterSecureStorage();
    final userId = await storage.read(key: 'userId');
    setState(() {
      _userId = userId;
    });
  }

  Future<void> _fetchQuestions() async {
    try {
      final surveys = await _apiRepository.getSurveys();

      if (surveys.isNotEmpty && surveys[0] != null) {
        final survey = surveys[0];

        // Ensure that category is properly assigned, otherwise set a fallback
        _category = survey['category'] ?? 'No Category'; // Set default if null
        _questions = List<Map<String, dynamic>>.from(survey['questions'] ?? []);

        // Ensure the category and questions are properly populated before continuing
        if (_category == 'No Category' || _questions.isEmpty) {
          print("Category or questions are missing!");
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        print('No surveys found or survey format is invalid');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching surveys: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _nextQuestion(int index) {
    if (index < _questions.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitAnswers();
    }
  }

  Future<void> _submitAnswers() async {
    List<Map<String, dynamic>> responses = [];

    final category = _category.isNotEmpty ? _category : '';

    _selectedAnswers.forEach((questionIndex, choiceId) {
      final question = _questions[questionIndex];
      final questionId = question['_id'];

      final selectedChoice = question['choices'].firstWhere(
          (choice) => choice['_id'] == choiceId,
          orElse: () => null);

      if (selectedChoice != null) {
        final score = selectedChoice['score'] ?? 0;

        responses.add({
          'questionId': questionId,
          'choiceId': selectedChoice['_id'],
          'score': score,
        });
      } else {
        print('Invalid choice selected for question $questionId');
      }
    });

    final patientId = _userId!;

    // Get the surveyId from the survey data, not from the first question
    final surveyId = _questions.isNotEmpty ? _questions[0]['surveyId'] : null;

    if (patientId == null || surveyId == null || responses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Missing required data')),
      );
      return;
    }

    try {
      await _apiRepository.submitSurveyResponse(
          patientId, surveyId, responses, category);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SubmissionScreen()),
      );
    } catch (e) {
      // Handle error submission
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting answers: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Survey - $_category'),
        backgroundColor: Color(0xFF81C784),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : PageView.builder(
              controller: _pageController,
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final question = _questions[index];
                final choices = question['choices'] ?? [];
                final answers = List<Map<String, dynamic>>.from(choices);

                return QuestionWidget(
                  question: question['questionText'],
                  choices: answers,
                  selectedChoiceId: _selectedAnswers[index] ?? '',
                  onAnswerSelected: (choiceId) {
                    setState(() {
                      _selectedAnswers[index] = choiceId;
                    });
                    Future.delayed(Duration(milliseconds: 300), () {
                      _nextQuestion(index);
                    });
                  },
                );
              },
            ),
    );
  }
}
