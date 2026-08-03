import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/watchlist_provider.dart';

class CreateWatchlistDialog extends ConsumerStatefulWidget {
  const CreateWatchlistDialog({super.key});

  @override
  ConsumerState<CreateWatchlistDialog> createState() => _CreateWatchlistDialogState();
}

class _CreateWatchlistDialogState extends ConsumerState<CreateWatchlistDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Watchlist'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Watchlist Name',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final name = _controller.text.trim();
            if (name.isNotEmpty) {
              await ref.read(watchlistsProvider.notifier).createWatchlist(name);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
