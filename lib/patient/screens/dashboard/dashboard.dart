import 'package:armstrong/widgets/cards/welcome_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:armstrong/widgets/cards/mood_graph.dart';
import 'package:armstrong/widgets/cards/journal_card.dart';
import 'package:armstrong/widgets/buttons/survey_button.dart';
import 'package:armstrong/widgets/cards/article_list.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:armstrong/config/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey _journalKey = GlobalKey();
  final GlobalKey _articleKey = GlobalKey();
  final GlobalKey _quickTestKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  void _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasCompletedOnboarding =
        prefs.getBool('hasCompletedOnboarding') ?? false;

    if (!hasCompletedOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShowCaseWidget.of(context)
            .startShowCase([_journalKey, _articleKey, _quickTestKey]);
      });

      // Set onboarding as completed
      await prefs.setBool('hasCompletedOnboarding', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              //Welcome Card
              const WelcomeSection(),

              const SizedBox(height: 30),

              // Highlight Survey Card
              Showcase(
                key: _quickTestKey,
                description:
                    "Tap here to take a quick mental health assessment.",
                textColor: Colors.white,
                tooltipBackgroundColor: buttonColor,
                targetPadding: EdgeInsets.all(12),
                targetShapeBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(child: QuickTestButton()),
              ),
              const SizedBox(height: 30),

              Center(
                child: const Text(
                  'Write about your day!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Highlight Journal Card
              Showcase(
                key: _journalKey,
                description:
                    "Write your thoughts and feelings in your personal journal.",
                textColor: Colors.white,
                tooltipBackgroundColor: buttonColor,
                targetPadding: EdgeInsets.all(10),
                targetShapeBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: JournalSection(),
              ),

              const SizedBox(height: 30),

              Center(
                child: const Text(
                  'Articles',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Highlight Article List
              Showcase(
                key: _articleKey,
                description:
                    "Check out the latest articles recommended for you.",
                textColor: Colors.white,
                tooltipBackgroundColor: buttonColor,
                targetPadding: EdgeInsets.all(10),
                targetShapeBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ArticleList(),
              ),
              const SizedBox(height: 30),

              Center(
                child: const Text(
                  'Weekly Mood Chart',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                height: 300, 
                child: MoodChartScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
