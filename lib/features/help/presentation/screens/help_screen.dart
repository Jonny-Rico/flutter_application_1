import 'dart:io';

import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/help/data/help_manual_extractor.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app user manual (bundled HTML help).
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  WebViewController? _controller;
  var _loading = true;
  String? _error;
  var _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _openManual();
  }

  Future<void> _openManual() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final path = await HelpManualExtractor().ensureExtracted();
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(AppColors.surfaceDark)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) async {
              final canBack = await _controller?.canGoBack() ?? false;
              if (mounted) {
                setState(() {
                  _loading = false;
                  _canGoBack = canBack;
                });
              }
            },
            onWebResourceError: (error) {
              if (mounted) {
                setState(() {
                  _loading = false;
                  _error = error.description;
                });
              }
            },
          ),
        );

      await controller.loadFile(path);
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  Future<void> _goBackInWeb() async {
    final controller = _controller;
    if (controller == null) return;
    if (await controller.canGoBack()) {
      await controller.goBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
        actions: [
          if (_canGoBack)
            IconButton(
              tooltip: 'Back in help',
              onPressed: _goBackInWeb,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          IconButton(
            tooltip: 'Reload',
            onPressed: _openManual,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.menu_book_outlined, size: 40, color: AppColors.onSurfaceMuted),
              const SizedBox(height: 12),
              Text(
                'Could not open help',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _openManual,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null || _loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // WebView is Android-first in this project; guard for unsupported platforms.
    if (!Platform.isAndroid && !Platform.isIOS) {
      return const Center(
        child: Text('Help is available on mobile devices.'),
      );
    }

    return WebViewWidget(controller: _controller!);
  }
}
