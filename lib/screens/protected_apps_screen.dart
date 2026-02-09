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

  List<AppInfo> get _filteredApps {
    if (_query.trim().isEmpty) return _apps;
    final q = _query.toLowerCase().trim();
    return _apps.where((a) {
      return a.appName.toLowerCase().contains(q) ||
          a.packageName.toLowerCase().contains(q);
    }).toList();
  }

  List<AppInfo> get _protectedList {
    final list = _filteredApps
        .where((a) => _protected.contains(a.packageName))
        .toList();
    list.sort(
      (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
    );
    return list;
  }

  List<AppInfo> get _unprotectedList {
    final list = _filteredApps
        .where((a) => !_protected.contains(a.packageName))
        .toList();
    list.sort(
      (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
    );
    return list;
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
      _apps = appsRaw
          .map((e) => AppInfo.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final protectedApps = _protectedList;
    final unprotectedApps = _unprotectedList;
    final totalApps = _apps.length;
    final protectedCount = _protected.length;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: RefreshIndicator(
                color: colorScheme.primary,
                backgroundColor: Colors.white,
                onRefresh: _load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildSearchField(theme),
                          const SizedBox(height: 16),
                          _buildStatsRow(theme, totalApps, protectedCount),
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
                        ]),
                      ),
                    ),
                    if (!_loading) ...[
                      if (protectedApps.isNotEmpty)
                        _buildSectionHeader(context, 'Protected Apps'),
                      _buildAppList(protectedApps, true),
                      if (unprotectedApps.isNotEmpty)
                        _buildSectionHeader(context, 'Other Apps'),
                      _buildAppList(unprotectedApps, false),
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Text(
            'Protected Apps',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchCtrl,
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'Search apps...',
        hintStyle: TextStyle(color: theme.colorScheme.secondary),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: theme.colorScheme.secondary,
        ),
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, int total, int protected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total Apps: $total',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Protected: $protected',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildAppList(List<AppInfo> apps, bool isProtected) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final app = apps[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: AppListItem(
            app: app,
            isChecked: isProtected,
            query: _query,
            onToggle: (val) => _toggle(app.packageName, val),
          ),
        );
      }, childCount: apps.length),
    );
  }
}

class AppListItem extends StatelessWidget {
  final AppInfo app;
  final bool isChecked;
  final String query;
  final ValueChanged<bool> onToggle;

  const AppListItem({
    super.key,
    required this.app,
    required this.isChecked,
    required this.query,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isChecked
            ? Border.all(color: colorScheme.primary.withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.background,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8),
          child: app.icon != null
              ? Image.memory(app.icon!, fit: BoxFit.contain)
              : Icon(Icons.android_rounded, color: colorScheme.secondary),
        ),
        title: _buildHighlightText(
          app.appName,
          query.trim(),
          theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          colorScheme.primary,
        ),
        subtitle: Text(
          app.packageName,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.secondary,
          ),
        ),
        trailing: Checkbox(
          value: isChecked,
          onChanged: (v) => onToggle(v ?? false),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          activeColor: colorScheme.primary,
          checkColor: Colors.white,
          side: BorderSide(
            color: colorScheme.secondary.withOpacity(0.5),
            width: 2,
          ),
        ),
        onTap: () => onToggle(!isChecked),
      ),
    );
  }

  Widget _buildHighlightText(
    String text,
    String query,
    TextStyle baseStyle,
    Color highlightColor,
  ) {
    if (query.isEmpty) return Text(text, style: baseStyle);

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        matches.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        matches.add(TextSpan(text: text.substring(start, index)));
      }
      matches.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: baseStyle.copyWith(
            color: highlightColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      start = index + query.length;
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: matches),
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
