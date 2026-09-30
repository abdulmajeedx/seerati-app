import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';

/// A newer release than the one running.
class AvailableUpdate {
  const AvailableUpdate({required this.version, required this.downloadUrl});

  /// Without the leading "v", e.g. "2.6.0".
  final String version;

  /// The release's APK when it has one, otherwise its page.
  final Uri downloadUrl;
}

/// Asks GitHub for the latest release. The app is sideloaded, so this is the
/// only way users hear about new versions. One anonymous GET per launch; any
/// failure (offline, rate limit, odd payload) means "no update".
abstract final class UpdateChecker {
  static Future<AvailableUpdate?> check({
    http.Client? client,
    String current = AppConstants.appVersion,
  }) async {
    final c = client ?? http.Client();
    try {
      final res = await c
          .get(
            Uri.parse(AppConstants.releasesApi),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body);
      if (json is! Map<String, dynamic>) return null;
      if (json['draft'] == true || json['prerelease'] == true) return null;
      final tag = json['tag_name'];
      if (tag is! String) return null;
      final version = tag.startsWith('v') ? tag.substring(1) : tag;
      if (compareVersions(version, current) <= 0) return null;

      final apk = (json['assets'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((a) => a['browser_download_url'])
          .whereType<String>()
          .where((u) => u.endsWith('.apk'))
          .firstOrNull;
      final page = json['html_url'];
      final url = apk ?? (page is String ? page : null);
      if (url == null) return null;
      return AvailableUpdate(version: version, downloadUrl: Uri.parse(url));
    } catch (_) {
      return null;
    } finally {
      if (client == null) c.close();
    }
  }

  /// Compares dotted numeric versions: 2.10.0 > 2.9.1. Missing or
  /// non-numeric parts count as 0.
  static int compareVersions(String a, String b) {
    List<int> parts(String v) =>
        v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final pa = parts(a), pb = parts(b);
    for (var i = 0; i < pa.length || i < pb.length; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }
}

/// Only Android builds are sideloaded APKs; elsewhere there's nothing to offer.
final updateProvider = FutureProvider<AvailableUpdate?>((ref) async {
  if (!Platform.isAndroid) return null;
  return UpdateChecker.check();
});
