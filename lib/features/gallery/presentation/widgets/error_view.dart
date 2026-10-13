import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final AppException error;
  final VoidCallback onRetry;

  IconData get _icon => switch (error.type) {
        AppErrorType.network => Icons.wifi_off_rounded,
        AppErrorType.timeout => Icons.timer_off_outlined,
        AppErrorType.rateLimited => Icons.speed_rounded,
        AppErrorType.invalidApiKey ||
        AppErrorType.missingApiKey =>
          Icons.vpn_key_off_outlined,
        _ => Icons.error_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canRetry = error.type != AppErrorType.missingApiKey;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, size: 72, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Something went wrong', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                error.message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(canRetry ? 'Try again' : 'Check again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
