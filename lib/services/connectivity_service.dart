import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static Future<bool> isOnline() async {
    var result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
} 