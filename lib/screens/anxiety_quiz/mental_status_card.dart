import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/helpers/app_config.dart';

class MentalStatusCard extends StatefulWidget {
  final String userId;

  const MentalStatusCard({super.key, required this.userId});

  @override
  State<MentalStatusCard> createState() => _MentalStatusCardState();
}

class _MentalStatusCardState extends State<MentalStatusCard> {
  List<double> scores = [];
  List<String> dates = [];
  bool isLoading = true;
  String baseUrl = AppConfig.instance()!.baseUrl!;

  @override
  void initState() {
    super.initState();
    fetchResults();
  }

  Future<void> fetchResults() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/quiz/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>;

        scores = results.map((e) => (e['score'] as num).toDouble()).toList();
        dates = results
            .map((e) => DateTime.parse(e['created_at']))
            .map((d) => "${d.day}/${d.month}")
            .toList();
      }
    } catch (e) {
      print("Erreur lors de la récupération : $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("🧠 Mon état mental",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (scores.isEmpty)
                const Text("Aucun résultat disponible.")
              else
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < dates.length) {
                                return Text(dates[index],
                                    style: const TextStyle(fontSize: 10));
                              }
                              return const Text('');
                            },
                            reservedSize: 32,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) =>
                                Text("${value.toInt()}%"),
                            reservedSize: 40,
                          ),
                        ),
                      ),
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: scores.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value);
                          }).toList(),
                          isCurved: true,
                          barWidth: 3,
                          color: Colors.blue,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}
