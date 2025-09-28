import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/stream_manager.dart';
import 'loading_widget.dart';

class DashboardOverview extends StatefulWidget {
  final String uid;

  const DashboardOverview({super.key, required this.uid});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  int _refreshKey = 0;

  Future<void> _refreshData() async {
    // Force stream refresh by changing the key
    setState(() {
      _refreshKey++;
    });
    
    // Small delay to show refresh indicator
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return StreamBuilder<DatabaseEvent>(
      key: ValueKey('dashboard_${widget.uid}_$_refreshKey'),
      stream: StreamManager.getUserDevicesStream(widget.uid).timeout(
        const Duration(seconds: 10),
        onTimeout: (eventSink) {
          eventSink.addError('Connection timeout. Please check your internet connection.');
        },
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: 'Loading your farm data...');
        }

        if (snapshot.hasError) {
          return CustomErrorWidget(
            message: 'Error loading dashboard',
            error: 'Unable to load your farm data. Please check your connection.\n\nError: ${snapshot.error}',
            onRetry: () {
              // Trigger rebuild to retry
              setState(() {});
            },
          );
        }

        // Check if we have data but it's null or empty
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return CustomErrorWidget(
            message: 'No data available',
            error: 'No farm data found. This could mean:\n• No devices have been added yet\n• Database connection issue\n• User not properly authenticated',
            onRetry: () {
              setState(() {});
            },
          );
        }

        final root = snapshot.hasData && snapshot.data!.snapshot.value is Map
            ? Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map)
            : <String, dynamic>{};
        final deviceEntries = root.entries
            .where((e) => e.value is Map)
            .map((e) => MapEntry(e.key, Map<String, dynamic>.from(e.value as Map)))
            .toList();

        if (deviceEntries.isEmpty) {
          return _buildEmptyState(context, themeService);
        }

        final onlineDevices = deviceEntries.where((e) {
          final meta = e.value['Meta'] is Map ? Map<String, dynamic>.from(e.value['Meta']) : <String, dynamic>{};
          final statusRoot = e.value['DeviceStatus'] is Map ? Map<String, dynamic>.from(e.value['DeviceStatus']) : <String, dynamic>{};
          final last = statusRoot['last_seen'] ?? meta['updatedAtMs'] ?? 0;
          int lastMs = 0;
          if (last is int) lastMs = last;
          if (last is double) lastMs = last.toInt();
          if (last is String) {
            final d = DateTime.tryParse(last);
            if (d != null) lastMs = d.millisecondsSinceEpoch;
          }
          return lastMs > 0 && (DateTime.now().millisecondsSinceEpoch - lastMs) <= 30000;
        }).length;

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: BoxDecoration(
                  gradient: themeService.getPrimaryGradient(),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: themeService.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.spa_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Welcome to your farm',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Quickly view device status and recent activity',
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Add Device',
            onPressed: () => Navigator.pushNamed(
                context, '/add-device/intro',
                arguments: {'uid': widget.uid}),
                        icon: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildStatsCards(context, onlineDevices, deviceEntries.length, themeService),
              const SizedBox(height: 16),
              _buildRecentActivityRtdb(context, deviceEntries, themeService),
              const SizedBox(height: 16),
              _buildQuickActions(context, themeService),
              const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeService themeService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: themeService.getAccentGradient(),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.device_hub_outlined,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No devices found',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: themeService.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add your first device to get started',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
                context, '/add-device/intro',
                arguments: {'uid': widget.uid}),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Device'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, int onlineDevices, int totalDevices, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              'Online Devices',
              '$onlineDevices',
              Icons.check_circle,
              Colors.green,
              themeService,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              'Total Devices',
              '$totalDevices',
              Icons.device_hub,
              themeService.primaryColor,
              themeService,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, ThemeService themeService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityRtdb(BuildContext context, List<MapEntry<String, Map<String, dynamic>>> devices, ThemeService themeService) {
    final recent = devices.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'Recent Activity',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeService.primaryColor,
              ),
            ),
          ),
          ...recent.map((entry) {
            final data = entry.value;
            final meta = data['Meta'] is Map ? Map<String, dynamic>.from(data['Meta']) : <String, dynamic>{};
            final deviceName = (meta['name'] ?? data['name'] ?? entry.key).toString();
            final statusRoot = data['DeviceStatus'] is Map ? Map<String, dynamic>.from(data['DeviceStatus']) : <String, dynamic>{};
            final rawLast = statusRoot['last_seen'] ?? meta['updatedAtMs'] ?? 0;
            int lastMs = 0;
            if (rawLast is int) lastMs = rawLast;
            if (rawLast is double) lastMs = rawLast.toInt();
            if (rawLast is String) {
              final d = DateTime.tryParse(rawLast);
              if (d != null) lastMs = d.millisecondsSinceEpoch;
            }
            final isOnline = lastMs > 0 && (DateTime.now().millisecondsSinceEpoch - lastMs) <= 30000;
            final lastUpdated = lastMs > 0 ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isOnline 
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isOnline ? Icons.check_circle : Icons.error,
                        color: isOnline ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            deviceName,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lastUpdated != null 
                                ? 'Last updated: ${DateFormat('MMM dd, HH:mm').format(lastUpdated)}'
                                : 'No recent activity',
                            style: GoogleFonts.inter(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOnline ? 'ONLINE' : 'OFFLINE',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'Quick Actions',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeService.primaryColor,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  'Add Device',
                  Icons.add_circle,
                  themeService.getPrimaryGradient(),
                  () => Navigator.pushNamed(
                      context, '/add-device/intro',
                      arguments: {'uid': widget.uid}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  context,
                  'View All',
                  Icons.list,
                  themeService.getAccentGradient(),
                  () => Navigator.pushNamed(context, '/my-devices', arguments: {'uid': widget.uid}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, LinearGradient gradient, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomErrorWidget extends StatelessWidget {
  final String message;
  final String error;
  final VoidCallback onRetry;

  const CustomErrorWidget({
    super.key,
    required this.message,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
