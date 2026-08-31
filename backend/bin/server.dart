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
  if (apiKey.isEmpty) {
    stderr.writeln('WARNING: ANTHROPIC_API_KEY unset — running in MOCK mode');
  }
  final dbPath = env['SEERATI_DB'] ?? 'data/seerati.db';
  Directory(File(dbPath).parent.path).createSync(recursive: true);

  final api = Api(
    db: Db(dbPath),
    claude: ClaudeClient(apiKey: apiKey),
    config: ApiConfig(appKey: appKey),
  );
  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(api.handler);
  final port = int.parse(env['PORT'] ?? '8787');
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('seerati-backend listening on :${server.port}'
      '${apiKey.isEmpty ? ' (MOCK mode)' : ''}');
}
