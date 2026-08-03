import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../providers/watchlist_provider.dart';

class StockPickerDialog extends ConsumerWidget {
  final String watchlistId;

  const StockPickerDialog({
    super.key,
    required this.watchlistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlists = ref.watch(watchlistsProvider);
    final watchlist = watchlists.where((w) => w.id == watchlistId).firstOrNull;
    final existingSymbols = watchlist?.symbols ?? [];
    final availableSymbols = AppConstants.availableStocks
        .where((s) => !existingSymbols.contains(s))
        .toList();

    return AlertDialog(
      title: const Text('Add Stock'),
      content: SizedBox(
        width: double.maxFinite,
        child: availableSymbols.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('All stocks are already in this watchlist'),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: availableSymbols.length,
                itemBuilder: (context, index) {
                  final symbol = availableSymbols[index];
                  return ListTile(
                    title: Text(symbol),
                    onTap: () => Navigator.of(context).pop(symbol),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
