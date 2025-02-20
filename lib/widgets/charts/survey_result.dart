import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:armstrong/services/api.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SurveyScoreChart extends StatefulWidget {
  final String patientId;

  const SurveyScoreChart({Key? key, required this.patientId}) : super(key: key);

  @override
  _SurveyScoreChartState createState() => _SurveyScoreChartState();
}

class _SurveyScoreChartState extends State<SurveyScoreChart> {
  final _storage = const FlutterSecureStorage();
  final ApiRepository _apiRepository = ApiRepository();
  late Future<Map<String, dynamic>> surveyData;

  @override
  void initState() {
    super.initState();
    surveyData = fetchSurveyData(widget.patientId);
  }

  Future<Map<String, dynamic>> fetchSurveyData(String patientId) async {
    try {
      return await _apiRepository.getPatientSurveyResults(patientId);
    } catch (e) {
      return {'totalScore': 0, 'interpretation': 'No Data'};
    }
  }

  Map<String, dynamic> getInterpretation(int score, ColorScheme colorScheme) {
    if (score >= 85) {
      return {
        'text': "Minimal or No Signs of Mental Health Problems",
        'color': Colors.green
      };
    } else if (score >= 70) {
      return {
        'text': "Mild Mental Health Concerns",
        'color': Colors.orange
      };
    } else if (score >= 50) {
      return {
        'text': "Moderate Mental Health Concerns",
        'color': Colors. purple
      };
    } else {
      return {
        'text': "Severe Mental Health Concerns",
        'color': Colors. red
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<Map<String, dynamic>>(
      future: surveyData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              "No survey results found.",
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            ),
          );
        }

        final int score = snapshot.data!['totalScore'];
        final interpretationData = getInterpretation(score, colorScheme);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.scrollText, color: colorScheme.primary, size: 30),
                    const SizedBox(width: 10),
                    Text(
                      "Survey Score",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "$score / 100",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  interpretationData['text'],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: interpretationData['color'],
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: score.toDouble(),
                          color: colorScheme.primary,
                          title: '$score%',
                          radius: 50,
                          titleStyle: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        PieChartSectionData(
                          value: (100 - score).toDouble(),
                          color: colorScheme.secondaryContainer,
                          title: '${100 - score}%',
                          radius: 50,
                          titleStyle: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
