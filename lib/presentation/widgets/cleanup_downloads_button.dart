import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/download_service.dart';

class CleanupDownloadsButton extends ConsumerStatefulWidget {
  const CleanupDownloadsButton({super.key});

  @override
  ConsumerState<CleanupDownloadsButton> createState() => _CleanupDownloadsButtonState();
}

class _CleanupDownloadsButtonState extends ConsumerState<CleanupDownloadsButton> {
  bool _isLoading = false;

  Future<void> _handleCleanup() async {
    setState(() => _isLoading = true);

    try {
      final downloadService = ref.read(downloadServiceProvider);
      final result = await downloadService.cleanupAllPartialDownloads();

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.deletedCount > 0
                        ? 'Deleted ${result.deletedCount} file(s), freed ${result.freedBytesFormatted}'
                        : 'No partial downloads to clean',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Cleanup failed: ${result.errorMessage}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleCleanup,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.cleaning_services),
      label: Text(_isLoading ? 'Cleaning...' : 'Clear Partial Downloads'),
    );
  }
}