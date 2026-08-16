import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies bundled HTML help from Flutter assets into app storage so WebView
/// can open multi-page manuals with relative CSS/JS links.
class HelpManualExtractor {
  static const assetPrefix = 'assets/help/';

  /// Bump when help assets change so devices re-extract.
  static const version = '7';
  static const _versionFile = '.help_version';

  /// Returns absolute path to extracted `index.html`.
  Future<String> ensureExtracted() async {
    final base = await getApplicationSupportDirectory();
    final helpDir = Directory(p.join(base.path, 'help_manual'));
    final versionFile = File(p.join(helpDir.path, _versionFile));

    final needsExtract = !helpDir.existsSync() ||
        !versionFile.existsSync() ||
        (await versionFile.readAsString()).trim() != version;

    if (needsExtract) {
      if (helpDir.existsSync()) {
        await helpDir.delete(recursive: true);
      }
      await helpDir.create(recursive: true);
      await _copyAllHelpAssets(helpDir);
      await versionFile.writeAsString(version);
    }

    final index = File(p.join(helpDir.path, 'index.html'));
    if (!index.existsSync()) {
      throw StateError('Help index.html missing after extract');
    }
    return index.path;
  }

  Future<void> _copyAllHelpAssets(Directory helpDir) async {
    final keys = await _listHelpAssetKeys();
    if (keys.isEmpty) {
      await _copyKnownTree(helpDir);
      return;
    }

    for (final assetKey in keys) {
      final relative = assetKey.substring(assetPrefix.length);
      if (relative.isEmpty) continue;
      final out = File(p.join(helpDir.path, relative));
      await out.parent.create(recursive: true);
      final data = await rootBundle.load(assetKey);
      await out.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
  }

  Future<List<String>> _listHelpAssetKeys() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest
          .listAssets()
          .where((key) => key.startsWith(assetPrefix))
          .where((key) => !key.endsWith('/'))
          .toList()
        ..sort();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _copyKnownTree(Directory helpDir) async {
    const files = <String>[
      'index.html',
      'assets/tutorial.css',
      'assets/lang.js',
      'en/index.html',
      'en/01-getting-started.html',
      'en/02-tasks.html',
      'en/03-create-edit.html',
      'en/04-family.html',
      'en/05-dashboard.html',
      'en/06-settings.html',
      'en/07-whats-new.html',
      'ru/index.html',
      'ru/01-getting-started.html',
      'ru/02-tasks.html',
      'ru/03-create-edit.html',
      'ru/04-family.html',
      'ru/05-dashboard.html',
      'ru/06-settings.html',
      'ru/07-whats-new.html',
    ];

    for (final relative in files) {
      final assetKey = '$assetPrefix$relative';
      final out = File(p.join(helpDir.path, relative));
      await out.parent.create(recursive: true);
      final data = await rootBundle.load(assetKey);
      await out.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    }
  }
}
