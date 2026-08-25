import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:m_extension_server/m_extension_server.dart';
import 'package:mangayomi/main.dart';
import 'package:mangayomi/models/settings.dart';
import 'package:mangayomi/modules/more/settings/browse/providers/browse_state_provider.dart';
import 'package:mangayomi/utils/platform_utils.dart';

class MExtensionServerPlatform {
  static Future<void>? _iosStartOperation;
  static String? _iosActiveBaseUrl;

  WidgetRef ref;
  MExtensionServerPlatform(this.ref);

  Future<bool> check() => _check(_baseUrl);

  Future<bool> _check(String baseUrl) async {
    if (baseUrl == "http://127.0.0.1:0") return false;
    try {
      final res = await http.get(Uri.parse("$baseUrl/"));
      if (res.statusCode == 200) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> startServer({bool forceLocal = false}) {
    if (!Platform.isIOS) return _startServer();

    return _iosStartOperation ??=
        _startServer(
          baseUrl: forceLocal
              ? _iosActiveBaseUrl ?? 'http://127.0.0.1:0'
              : null,
        ).whenComplete(() {
          _iosStartOperation = null;
        });
  }

  Future<void> _startServer({String? baseUrl}) async {
    try {
      final isRunning = baseUrl == null ? await check() : await _check(baseUrl);
      if (!isRunning) {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final port = server.port;
        await server.close();
        if (isDesktop) {
          final settings = isar.settings.getSync(227);
            final configuredJrePath = settings?.jrePath;
            final jrePath = Platform.isLinux &&
                (configuredJrePath?.isEmpty ?? true)
              ? 'java'
              : configuredJrePath;
          final serverJarPath = settings?.extensionServerPath;
          if ((jrePath?.isEmpty ?? true) || (serverJarPath?.isEmpty ?? true)) {
            _markServerUnavailable();
            return;
          }
            final javaAvailable = Platform.isLinux && jrePath == 'java'
              ? (await Process.run('java', ['-version'])).exitCode == 0
              : await File(jrePath!).exists();
            if (!javaAvailable ||
              !await File(serverJarPath!).exists()) {
            _markServerUnavailable();
            return;
          }
          await MExtensionServer().startServer(
            port,
            jvmPath: jrePath,
            serverJarPath: serverJarPath,
          );
        } else {
          await MExtensionServer().startServer(port);
        }
        final localBaseUrl = "http://127.0.0.1:$port";
        var ready = false;
        for (var attempt = 0; attempt < 20; attempt++) {
          if (await _check(localBaseUrl)) {
            ready = true;
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
        if (!ready) {
          _markServerUnavailable();
          return;
        }
        if (Platform.isIOS) _iosActiveBaseUrl = localBaseUrl;
        ref.read(androidProxyServerStateProvider.notifier).set(localBaseUrl);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  void _markServerUnavailable() {
    ref
        .read(androidProxyServerStateProvider.notifier)
        .set('http://127.0.0.1:0');
  }

  Future<void> stopServer() async {
    try {
      if (Platform.isIOS) await _iosStartOperation;
      await MExtensionServer().stopServer();
      if (Platform.isIOS) _iosActiveBaseUrl = null;
    } catch (_) {}
  }

  Future<bool> checkLocalServer() async =>
      _iosActiveBaseUrl != null && await _check(_iosActiveBaseUrl!);

  String get _baseUrl => ref.watch(androidProxyServerStateProvider);
}
