import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SensorChart extends StatefulWidget {
  final String uid;
  final String deviceId;
  const SensorChart({super.key, required this.uid, required this.deviceId});

  @override
  State<SensorChart> createState() => _SensorChartState();
}

class _SensorChartState extends State<SensorChart> {
  List<FlSpot> tempData = [];
  List<FlSpot> humData = [];

  @override
  void initState() {
    super.initState();
    listenSensorUpdates();
  }

  void listenSensorUpdates() {
    FirebaseFirestore.instance
        .collection("users")
        .doc(widget.uid)
        .collection("devices")
        .doc(widget.deviceId)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data()?["sensorData"];
      if (data != null) {
        final t = (data["temperature"] ?? 0).toDouble();
        final h = (data["humidity"] ?? 0).toDouble();

        final now = DateTime.now().millisecondsSinceEpoch.toDouble();
        setState(() {
          tempData.add(FlSpot(now, t));
          humData.add(FlSpot(now, h));
          if (tempData.length > 20) tempData.removeAt(0);
          if (humData.length > 20) humData.removeAt(0);
        });
      }
    });
  }

  Widget _buildChart(List<FlSpot> data, String title, Color color, String unit) {
    if (data.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${data.last.y.toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString() + unit,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.map((e) => FlSpot(
                      (e.x - data.first.x) / 1000,
                      e.y,
                    )).toList(),
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.shade900,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)}$unit',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildChart(tempData, '🌡️ Temperature', Colors.redAccent, '°C'),
        const SizedBox(height: 16),
        _buildChart(humData, '💧 Humidity', Colors.blueAccent, '%'),
      ],
    );
  }
} 