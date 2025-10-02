import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/app_config.dart';
import 'package:fl_chart/fl_chart.dart';

class SensorHistoryScreen extends StatefulWidget {
  final String uid;
  final String deviceId;
  final String deviceName;

  const SensorHistoryScreen({
    super.key,
    required this.uid,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<SensorHistoryScreen> createState() => _SensorHistoryScreenState();
}

class _SensorHistoryScreenState extends State<SensorHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _timeRange = '24h';
  bool _isLoading = false;
  List<Map<String, dynamic>>? _historyData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _historyData = null;
    });
    try {
      final hours = switch (_timeRange) {
        '6h' => 6,
        '12h' => 12,
        '24h' => 24,
        '48h' => 48,
        '7d' => 168,
        _ => 24,
      };
      final startTime = DateTime.now().subtract(Duration(hours: hours));
      
      // Try RTDB first: Users/{uid}/{deviceId}/History (list or map)
      List<Map<String, dynamic>> data = [];
      try {
        final db = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: AppConfig.realtimeDbUrl,
        );
        final ref = db.ref('Users/${widget.uid}/Devices/${widget.deviceId}/History');
        final snap = await ref.get();
        if (snap.exists) {
          if (snap.value is List) {
            final list = (snap.value as List)
                .where((e) => e != null)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            data.addAll(list);
          } else if (snap.value is Map) {
            final map = Map<String, dynamic>.from(snap.value as Map);
            for (final entry in map.values) {
              if (entry is Map) {
                data.add(Map<String, dynamic>.from(entry));
              }
            }
          }
          // Filter by timestamp if present
          data = data.where((m) {
            final ts = m['timestamp'];
            if (ts == null) return false;
            if (ts is int) {
              return DateTime.fromMillisecondsSinceEpoch(ts).isAfter(startTime);
            }
            if (ts is double) {
              return DateTime.fromMillisecondsSinceEpoch(ts.toInt()).isAfter(startTime);
            }
            if (ts is String) {
              final parsed = DateTime.tryParse(ts);
              return parsed != null && parsed.isAfter(startTime);
            }
            return false;
          }).toList()
            ..sort((a, b) {
              final at = (a['timestamp'] is int)
                  ? a['timestamp'] as int
                  : (a['timestamp'] is double)
                      ? (a['timestamp'] as double).toInt()
                      : (a['timestamp'] is String)
                          ? (DateTime.tryParse(a['timestamp'])?.millisecondsSinceEpoch ?? 0)
                          : 0;
              final bt = (b['timestamp'] is int)
                  ? b['timestamp'] as int
                  : (b['timestamp'] is double)
                      ? (b['timestamp'] as double).toInt()
                      : (b['timestamp'] is String)
                          ? (DateTime.tryParse(b['timestamp'])?.millisecondsSinceEpoch ?? 0)
                          : 0;
              return at.compareTo(bt);
            });
        }
      } catch (_) {
        // Ignore RTDB errors; we'll fallback to Firestore
      }

      // Fallback to Firestore if RTDB had no usable data
      if (data.isEmpty) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .collection('devices')
            .doc(widget.deviceId)
            .collection('history')
            .where('timestamp', isGreaterThanOrEqualTo: startTime)
            .orderBy('timestamp', descending: false)
            .get();

        for (final doc in querySnapshot.docs) {
          final raw = doc.data();
          // Defensive parsing
          final temp = (raw['temperature'] as num?)?.toDouble();
          final hum = (raw['humidity'] as num?)?.toDouble();
          final soilMoisture = (raw['soilMoisture'] as num?)?.toDouble();
          final ts = raw['timestamp'];
          DateTime? dt;
          if (ts is Timestamp) dt = ts.toDate();
          if (ts is int) dt = DateTime.fromMillisecondsSinceEpoch(ts);
          if (ts is double) dt = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
          if (ts is String) dt = DateTime.tryParse(ts);
          if (temp != null && hum != null && dt != null) {
            data.add({
              'temperature': temp,
              'humidity': hum,
              'soilMoisture': soilMoisture ?? 0.0,
              'timestamp': Timestamp.fromDate(dt),
            });
          }
        }
      }

      setState(() {
        _historyData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTimeRangeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            _buildTimeRangeChip('6h', '6 Hours'),
            const SizedBox(width: 8),
            _buildTimeRangeChip('12h', '12 Hours'),
            const SizedBox(width: 8),
            _buildTimeRangeChip('24h', '24 Hours'),
            const SizedBox(width: 8),
            _buildTimeRangeChip('48h', '2 Days'),
            const SizedBox(width: 8),
            _buildTimeRangeChip('7d', '7 Days'),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeChip(String value, String label) {
    final isSelected = _timeRange == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _timeRange = value);
          _loadData();
        }
      },
      backgroundColor: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
      showCheckmark: false,
    );
  }

  Widget _buildStatsCard(String title, String value, String unit, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$value$unit',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(List<Map<String, dynamic>> data, String valueType, String unit) {
    final values = data.map((d) => (d[valueType] as num?)?.toDouble() ?? 0.0).toList();
    if (values.isEmpty) return const SizedBox.shrink();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(child: _buildStatsCard('Average', avg.toStringAsFixed(1), unit, Icons.analytics_outlined, Colors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatsCard('Minimum', min.toStringAsFixed(1), unit, Icons.arrow_downward, Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatsCard('Maximum', max.toStringAsFixed(1), unit, Icons.arrow_upward, Colors.red)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.deviceName),
            Text('Sensor History', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Temperature'), 
            Tab(text: 'Humidity'),
            Tab(text: 'Soil Moisture')
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildTimeRangeSelector(),
          const SizedBox(height: 16),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_historyData == null || _historyData!.isEmpty)
            const Expanded(child: Center(child: Text('No data available')))
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ListView(
                    children: [
                      _buildStats(_historyData!, 'temperature', '°C'),
                      _SensorHistoryChart(
                        historyData: _historyData!,
                        title: 'Temperature History',
                        lineColor: Colors.orange,
                        valueType: 'temperature',
                        unit: '°C',
                      ),
                    ],
                  ),
                  ListView(
                    children: [
                      _buildStats(_historyData!, 'humidity', '%'),
                      _SensorHistoryChart(
                        historyData: _historyData!,
                        title: 'Humidity History',
                        lineColor: Colors.blue,
                        valueType: 'humidity',
                        unit: '%',
                      ),
                    ],
                  ),
                  ListView(
                    children: [
                      _buildStats(_historyData!, 'soilMoisture', '%'),
                      _SensorHistoryChart(
                        historyData: _historyData!,
                        title: 'Soil Moisture History',
                        lineColor: Colors.green,
                        valueType: 'soilMoisture',
                        unit: '%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SensorHistoryChart extends StatelessWidget {
  final List<Map<String, dynamic>> historyData;
  final String title;
  final Color lineColor;
  final String valueType;
  final String unit;
  
  const _SensorHistoryChart({
    required this.historyData, 
    required this.title, 
    required this.lineColor, 
    required this.valueType, 
    required this.unit
  });
  
  @override
  Widget build(BuildContext context) {
    if (historyData.isEmpty) {
      return const Center(child: Text('No historical data available'));
    }
    
    final spots = historyData.map((data) {
      final timestamp = data['timestamp'] as Timestamp?;
      final value = (data[valueType] as num?)?.toDouble() ?? 0.0;
      final x = timestamp?.millisecondsSinceEpoch.toDouble() ?? 0.0;
      return FlSpot(x, value);
    }).where((spot) => spot.x > 0).toList();
    
    if (spots.isEmpty) {
      return const Center(child: Text('No valid data points'));
    }
    
    spots.sort((a, b) => a.x.compareTo(b.x));
    double minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;
    minY -= padding;
    maxY += padding;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 300,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(
                  show: true, 
                  drawVerticalLine: true, 
                  horizontalInterval: 1, 
                  verticalInterval: 3600000
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 7200000,
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (maxY - minY) / 5,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(1)}$unit',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true, 
                  border: Border.all(color: Colors.grey.shade300)
                ),
                minX: spots.first.x,
                maxX: spots.last.x,
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true, 
                      color: lineColor.withValues(alpha: 0.1)
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.shade900,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                        return LineTooltipItem(
                          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
                          '\n${spot.y.toStringAsFixed(1)}$unit',
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
} 