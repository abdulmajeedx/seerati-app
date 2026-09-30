import 'package:flutter/material.dart';

/// The theme makes filled buttons full-width, which suits screens but stacks
/// a dialog's actions. Dialog confirm buttons use this compact size instead.
final dialogActionStyle = FilledButton.styleFrom(
  minimumSize: const Size(64, 40),
);
