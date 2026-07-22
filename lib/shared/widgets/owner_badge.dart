import 'package:flutter/material.dart';

class OwnerBadge extends StatelessWidget {
  final String? name;
  const OwnerBadge({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final label = (name ?? '').trim().isEmpty ? 'Unknown' : name!;
    return Chip(label: Text(label));
  }
}
