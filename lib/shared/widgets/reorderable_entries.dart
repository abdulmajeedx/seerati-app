import 'package:flutter/material.dart';

/// A short, non-scrolling list whose entries can be dragged by a handle to
/// reorder them, for use inside an already scrolling form. The list is
/// reordered in place; [onChanged] should rebuild the caller.
///
/// ReorderableListView also gives screen readers "move up/down" actions.
class ReorderableEntries<T extends Object> extends StatelessWidget {
  const ReorderableEntries({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onChanged,
  });

  final List<T> items;

  /// Builds one entry; place [handle] (null for a single entry) where the
  /// entry should be grabbed, usually at its end.
  final Widget Function(BuildContext context, T item, int index, Widget? handle)
  itemBuilder;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: items.length,
      // The target index already accounts for the item's removal.
      onReorderItem: (from, to) {
        items.insert(to, items.removeAt(from));
        onChanged();
      },
      itemBuilder: (context, i) => KeyedSubtree(
        key: ObjectKey(items[i]),
        child: itemBuilder(
          context,
          items[i],
          i,
          items.length < 2
              ? null
              : ReorderableDragStartListener(
                  index: i,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_indicator),
                  ),
                ),
        ),
      ),
    );
  }
}
