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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.background, colorScheme.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Protected Apps',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: colorScheme.primary,
                  backgroundColor: colorScheme.surface,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: (_loading ? 1 : items.length + 1),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _searchCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Search apps...',
                                prefixIcon: Icon(Icons.search_rounded),
                              ),
                            ),
                            if (_message.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                _message,
                                style: TextStyle(color: colorScheme.error),
                              ),
                            ],
                            const SizedBox(height: 20),
                            if (_loading)
                              LinearProgressIndicator(
                                backgroundColor: Colors.transparent,
                                color: colorScheme.primary,
                              ),
                          ],
                        );
                      }
                      final app = items[index - 1];
                      final checked = _protected.contains(app.packageName);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: checked
                              ? colorScheme.primary.withOpacity(0.1)
                              : colorScheme.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: checked
                                ? colorScheme.primary.withOpacity(0.5)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: app.icon != null
                                ? Image.memory(app.icon!, fit: BoxFit.contain)
                                : Icon(
                                    Icons.android_rounded,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                          ),
                          title: Text(
                            app.appName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            app.packageName,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Transform.scale(
                            scale: 1.1,
                            child: Checkbox(
                              value: checked,
                              onChanged: (v) =>
                                  _toggle(app.packageName, v ?? false),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              activeColor: colorScheme.primary,
                              checkColor: Colors.black,
                            ),
                          ),
                          onTap: () => _toggle(app.packageName, !checked),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
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
