import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProtectedAppsScreen extends StatefulWidget {
  const ProtectedAppsScreen({super.key});

  @override
  State<ProtectedAppsScreen> createState() => _ProtectedAppsScreenState();
}

class _ProtectedAppsScreenState extends State<ProtectedAppsScreen> {
  static const MethodChannel _channel = MethodChannel('privacy_protection');
  final TextEditingController _searchCtrl = TextEditingController();
  List<AppInfo> _apps = [];
  Set<String> _protected = {};
  bool _loading = true;
  String _message = '';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _query = _searchCtrl.text;
      });
    });
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AppInfo> get _filtered {
    if (_query.trim().isEmpty) return _apps;
    final q = _query.toLowerCase().trim();
    return _apps.where((a) {
      return a.appName.toLowerCase().contains(q) ||
          a.packageName.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = '';
    });
    try {
      final List<dynamic> protected =
          await _channel.invokeMethod<List<dynamic>>('getProtectedApps') ?? [];
      _protected = protected.map((e) => e.toString()).toSet();

      final List<dynamic> appsRaw =
          await _channel.invokeMethod<List<dynamic>>(
            'getInstalledLaunchableApps',
          ) ??
          [];
      _apps =
          appsRaw
              .map((e) => AppInfo.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList()
            ..sort(
              (a, b) =>
                  a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
            );
    } catch (e) {
      _message = 'Load error: $e';
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _toggle(String pkg, bool value) async {
    setState(() {
      if (value) {
        _protected.add(pkg);
      } else {
        _protected.remove(pkg);
      }
    });
    try {
      await _channel.invokeMethod('saveProtectedApps', _protected.toList());
    } catch (e) {
      setState(() {
        _message = 'Save error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('Protected Apps')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: (_loading ? 1 : items.length + 1),
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search apps',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_message.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _message,
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (_loading) const LinearProgressIndicator(),
                ],
              );
            }
            final app = items[index - 1];
            final checked = _protected.contains(app.packageName);
            return ListTile(
              leading: app.icon != null
                  ? CircleAvatar(backgroundImage: MemoryImage(app.icon!))
                  : const CircleAvatar(child: Icon(Icons.apps)),
              title: Text(app.appName),
              subtitle: Text(app.packageName),
              trailing: Checkbox(
                value: checked,
                onChanged: (v) => _toggle(app.packageName, v ?? false),
              ),
              onTap: () => _toggle(app.packageName, !checked),
            );
          },
        ),
      ),
    );
  }
}

class AppInfo {
  final String packageName;
  final String appName;
  final Uint8List? icon;

  AppInfo({required this.packageName, required this.appName, this.icon});

  factory AppInfo.fromMap(Map<String, dynamic> map) {
    Uint8List? icon;
    final raw = map['iconBase64'];
    if (raw is String && raw.isNotEmpty) {
      try {
        icon = base64Decode(raw);
      } catch (_) {}
    }
    return AppInfo(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      icon: icon,
    );
  }
}
