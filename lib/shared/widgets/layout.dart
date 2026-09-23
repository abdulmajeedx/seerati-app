import 'package:flutter/material.dart';

/// Widest a column of cards or form fields should get; beyond this lines get
/// hard to scan, so tablets get side margins instead.
const kMaxContentWidth = 640.0;

/// Horizontal padding that keeps content [kMaxContentWidth] wide at most
/// and at least [min] from the edges.
EdgeInsets readableHorizontalPadding(BuildContext context, {double min = 16}) {
  final width = MediaQuery.sizeOf(context).width;
  final side = ((width - kMaxContentWidth) / 2).clamp(min, double.infinity);
  return EdgeInsets.symmetric(horizontal: side);
}

/// Centres [child] and caps it at [kMaxContentWidth].
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
      child: child,
    ),
  );
}

/// [IndexedStack] that fades the newly shown child in. Every child stays
/// mounted (and keeps its state) as with a plain IndexedStack; only the
/// opacity animates, so nothing is rebuilt from scratch.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _fade.forward(from: 0);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
    child: IndexedStack(index: widget.index, children: widget.children),
  );
}
