import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../api_error_message.dart';

/// Runs an AI call with a busy state and localized error handling.
/// Hidden entirely in builds without a configured backend.
class AiButton extends ConsumerStatefulWidget {
  const AiButton({
    super.key,
    required this.label,
    required this.request,
    required this.onResult,
    this.validate,
    this.icon = Icons.auto_awesome_outlined,
  });

  final String label;
  final Future<String> Function(ApiClient client) request;
  final ValueChanged<String> onResult;

  /// Runs before the request; a false result cancels it.
  final bool Function()? validate;
  final IconData icon;

  @override
  ConsumerState<AiButton> createState() => _AiButtonState();
}

class _AiButtonState extends ConsumerState<AiButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (widget.validate != null && !widget.validate!()) return;
    setState(() => _busy = true);
    try {
      final text = await widget.request(ref.read(apiClientProvider));
      if (!mounted) return;
      widget.onResult(text);
    } on ApiException catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ApiClient.isConfigured) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return OutlinedButton.icon(
      onPressed: _busy ? null : _run,
      icon: _busy
          ? const SizedBox(
              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(widget.icon, size: 18),
      label: Text(_busy ? l10n.aiWorking : widget.label),
    );
  }
}
