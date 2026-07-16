/// LillithApp - the relief shopping list.
///
/// Items the user added from the Relief screen live here, saved encrypted on
/// the POD. Each can be checked off, searched for nearby (via the maps app, so
/// no location permission is needed) or bought online, or removed. The user can
/// also add their own items.

library;

import 'package:flutter/material.dart';

import 'package:lillith_app/models/shopping_list.dart';
import 'package:lillith_app/services/health_repository.dart';
import 'package:lillith_app/utils/links.dart';

class Shopping extends StatefulWidget {
  const Shopping({super.key});

  @override
  State<Shopping> createState() => _ShoppingState();
}

class _ShoppingState extends State<Shopping> {
  final _repo = HealthRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.load();
  }

  Future<void> _addOwn() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add an item'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Heat pad'),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await _repo.addShoppingItem(ShoppingItem(name: name));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addOwn,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add item'),
      ),
      body: AnimatedBuilder(
        animation: _repo,
        builder: (context, _) {
          final items = _repo.shoppingList;
          if (items.isEmpty) return const _EmptyShopping();
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
            children: [
              Text(
                'Shopping list',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Saved privately on your POD. Tick things off as you get them.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              for (final item in items) _ShoppingTile(item: item, repo: _repo),
            ],
          );
        },
      ),
    );
  }
}

class _ShoppingTile extends StatelessWidget {
  const _ShoppingTile({required this.item, required this.repo});

  final ShoppingItem item;
  final HealthRepository repo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            CheckboxListTile(
              value: item.bought,
              onChanged: (_) => repo.toggleBought(item.name),
              title: Text(
                item.name,
                style: TextStyle(
                  decoration: item.bought
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              subtitle: item.note == null ? null : Text(item.note!),
              secondary: IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Remove',
                onPressed: () => repo.removeShoppingItem(item.name),
              ),
            ),
            if (!item.bought)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8, right: 8),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => openMapsNearMe(item.name),
                      icon: const Icon(Icons.place_rounded, size: 18),
                      label: const Text('Find nearby'),
                    ),
                    TextButton.icon(
                      onPressed: () => openRetailerSearch(item.name),
                      icon: const Icon(Icons.shopping_bag_rounded, size: 18),
                      label: const Text('Buy online'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyShopping extends StatelessWidget {
  const _EmptyShopping();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_basket_rounded,
              size: 64,
              color: scheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Your list is empty',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add relief items from the Relief page, or tap “Add item” to '
              'start your own list.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
