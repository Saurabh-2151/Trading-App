import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/watchlist_provider.dart';

class RenameWatchlistDialog extends ConsumerStatefulWidget {
  final String watchlistId;
  final String currentName;

  const RenameWatchlistDialog({
    super.key,
    required this.watchlistId,
    required this.currentName,
  });

  @override
  ConsumerState<RenameWatchlistDialog> createState() => _RenameWatchlistDialogState();
}

class _RenameWatchlistDialogState extends ConsumerState<RenameWatchlistDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename Watchlist'),
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
            if (name.isNotEmpty && name != widget.currentName) {
              final watchlists = ref.read(watchlistsProvider);
              final watchlist = watchlists.where((w) => w.id == widget.watchlistId).firstOrNull;
              if (watchlist != null) {
                final updated = watchlist.copyWith(name: name);
                await ref.read(watchlistsProvider.notifier).updateWatchlist(updated);
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
