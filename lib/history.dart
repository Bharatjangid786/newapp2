import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:highlight_text/highlight_text.dart';

class HistoryChart extends StatefulWidget {
  final Map<String, dynamic> accuracy;

  HistoryChart(this.accuracy);

  @override
  _HistoryChartState createState() => _HistoryChartState();
}

class _HistoryChartState extends State<HistoryChart> {
  String? data;

  @override
  Widget build(BuildContext context) {
    List<AccuracyData> chartData = [];

    widget.accuracy.forEach((key, value) {
      if (value is double) {
        chartData.add(AccuracyData(key, value));
      }
    });

    List<charts.Series<AccuracyData, String>> series = [
      charts.Series<AccuracyData, String>(
        id: "Accuracy",
        data: chartData,
        domainFn: (AccuracyData data, _) => data.title,
        measureFn: (AccuracyData data, _) => data.value,
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        labelAccessorFn: (AccuracyData data, _) => '${data.value.toString()}%',
      )
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: 400,
            padding: const EdgeInsets.all(16),
            child: charts.BarChart(
              series,
              animate: true,
              barRendererDecorator: charts.BarLabelDecorator<String>(),
              domainAxis: const charts.OrdinalAxisSpec(
                renderSpec: charts.SmallTickRendererSpec(
                  labelAnchor: charts.TickLabelAnchor.before,
                ),
              ),
              primaryMeasureAxis: const charts.NumericAxisSpec(
                tickProviderSpec: charts.BasicNumericTickProviderSpec(
                  desiredTickCount: 10, // Show ticks with a gap of 10
                ),
              ),
              behaviors: [
                charts.SelectNearest(),
                charts.DomainHighlighter(),
                charts.ChartTitle('Accuracy',
                    behaviorPosition: charts.BehaviorPosition.bottom),
                charts.ChartTitle('Attempts',
                    behaviorPosition: charts.BehaviorPosition.start),
              ],
              selectionModels: [
                charts.SelectionModelConfig(
                  changedListener: (charts.SelectionModel model) {
                    if (model.hasDatumSelection) {
                      final selectedDatum = model.selectedDatum[0];
                      String s = "data${selectedDatum.datum.title}";

                      setState(() {
                        data = widget.accuracy[s]?.toString();
                        print(data);
                      });
                      print(s);
                    }
                  },
                ),
              ],
            ),
          ),
          if (data != null)
            Padding(
              padding:
                  const EdgeInsets.all(16.0), // Adjust the padding as needed
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: const Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: Container(
                  // Additional properties for the container
                  height: 400,
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: TextHighlight(
                      text: data!,
                      words: {},
                      textStyle: const TextStyle(
                        fontSize: 24.0,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  // Your child widget goes here
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AccuracyData {
  final String title;
  final double value;

  AccuracyData(this.title, this.value);
}
