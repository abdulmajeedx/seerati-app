import 'dart:io';

import 'package:seerati_backend/src/claude.dart';
import 'package:seerati_backend/src/db.dart';
import 'package:seerati_backend/src/handlers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final env = Platform.environment;
  final appKey = env['SEERATI_APP_KEY'] ?? '';
  if (appKey.isEmpty) {
    stderr.writeln('SEERATI_APP_KEY is required');
    exit(1);
  }
  final apiKey = env['ANTHROPIC_API_KEY'] ?? '';
  final mock = env['SEERATI_MOCK'] == '1';
  if (apiKey.isEmpty && !mock) {
    stderr.writeln('WARNING: ANTHROPIC_API_KEY unset — AI endpoints will '
        'return 503 until it is set (SEERATI_MOCK=1 for fake responses)');
  }
  final dbPath = env['SEERATI_DB'] ?? 'data/seerati.db';
  Directory(File(dbPath).parent.path).createSync(recursive: true);

  final api = Api(
    db: Db(dbPath),
    claude: ClaudeClient(apiKey: apiKey, mock: mock),
    config: ApiConfig(
      appKey: appKey,
      jobsModel: env['SEERATI_JOBS_MODEL'],
      jobsEnabled: env['SEERATI_JOBS_ENABLED'] != '0',
    ),
  );
  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(api.handler);
  final port = int.parse(env['PORT'] ?? '8787');
  // Loopback only: nginx terminates TLS and is the sole client, so the
  // X-Forwarded-For the rate limiter trusts cannot be spoofed from outside.
  final address = env['SEERATI_BIND'] == 'any'
      ? InternetAddress.anyIPv4
      : InternetAddress.loopbackIPv4;
  final server = await shelf_io.serve(handler, address, port);
  stdout.writeln('seerati-backend listening on :${server.port}'
      '${mock ? ' (MOCK mode)' : (apiKey.isEmpty ? ' (AI disabled)' : '')}');
}
