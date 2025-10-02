import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/app_config.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:async';

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
  List<FlSpot> soilMoistureData = [];
  StreamSubscription<DatabaseEvent>? _sub;
  Timer? _fallbackTimer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    // After a longer timeout, if no points, show empty state instead of spinners
    _fallbackTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (tempData.isEmpty && humData.isEmpty && soilMoistureData.isEmpty) {
        setState(() => _timedOut = true);
      }
    });
    listenSensorUpdates();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _asMap(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  void listenSensorUpdates() {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConfig.realtimeDbUrl,
    );
    final ref = db.ref('Users/${widget.uid}/Devices/${widget.deviceId}');
    _sub = ref.onValue.listen((event) {
      if (!mounted) return;
      final root = _asMap(event.snapshot.value);
      // Try both Sensor_Data and sensorData keys for compatibility
      final sensorData = _asMap(root['Sensor_Data'] ?? root['sensorData']);
      
      if (sensorData.isNotEmpty) {
        // Handle both soilMoisture and 'Soil Moisture' (with space)
        final soilMoistureValue = sensorData['soilMoisture'] ?? sensorData['Soil Moisture'] ?? 0;
        
        final t = _parseToDouble(sensorData['temperature'] ?? 0);
        final h = _parseToDouble(sensorData['humidity'] ?? 0);
        final sm = _parseToDouble(soilMoistureValue);
        
        final now = DateTime.now().millisecondsSinceEpoch.toDouble();
        setState(() {
          tempData.add(FlSpot(now, t));
          humData.add(FlSpot(now, h));
          soilMoistureData.add(FlSpot(now, sm));
          if (tempData.length > 20) tempData.removeAt(0);
          if (humData.length > 20) humData.removeAt(0);
          if (soilMoistureData.length > 20) soilMoistureData.removeAt(0);
          _timedOut = false;
        });
        _fallbackTimer?.cancel();
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _timedOut = true;
        });
      }
    });
  }

  double _parseToDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Widget _buildEmpty(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 56,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No data yet'),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _timedOut = false;
                    });
                    _fallbackTimer?.cancel();
                    _fallbackTimer = Timer(const Duration(seconds: 10), () {
                      if (!mounted) return;
                      if (tempData.isEmpty && humData.isEmpty && soilMoistureData.isEmpty) {
                        setState(() => _timedOut = true);
                      }
                    });
                    // Re-establish the listener
                    _sub?.cancel();
                    listenSensorUpdates();
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<FlSpot> data, String title, Color color, String unit) {
    if (data.isEmpty) {
      if (_timedOut) {
        return _buildEmpty(title);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 56, child: Center(child: CircularProgressIndicator())),
        ],
      );
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
                      color: Colors.grey.withValues(alpha: 0.2),
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
                      color: color.withValues(alpha: 0.1),
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
        const SizedBox(height: 16),
        _buildChart(soilMoistureData, '🌱 Soil Moisture', Colors.greenAccent, '%'),
      ],
    );
  }
} 