import 'package:flutter/material.dart';
import 'package:quickride/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _incomingOrderAlerts = true;
  late final ApiClient _api;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _initToken();
  }

  Future<void> _initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _api.setToken(prefs.getString('auth_token'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          SwitchListTile(
            value: _incomingOrderAlerts,
            onChanged: (v) async {
              setState(() => _incomingOrderAlerts = v);
              try {
                await _api.post('/api/vendors/settings/notifications', {
                  'incomingOrderAlerts': v,
                });
              } catch (_) {}
            },
            title: const Text('Incoming order alerts'),
            subtitle: const Text(
              'Toggle to receive notifications for new orders',
            ),
          ),
        ],
      ),
    );
  }
}
