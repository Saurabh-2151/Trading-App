import 'package:flutter/material.dart';

class SectorBadge extends StatelessWidget {
  final String sector;
  final double fontSize;

  const SectorBadge({
    super.key,
    required this.sector,
    this.fontSize = 10,
  });

  Color _getSectorColor() {
    switch (sector) {
      case 'IT':
        return Colors.blue[700]!;
      case 'Banking':
        return Colors.green[700]!;
      case 'Energy':
        return Colors.orange[700]!;
      case 'FMCG':
        return Colors.purple[700]!;
      case 'Telecom':
        return Colors.cyan[700]!;
      case 'Infra':
        return Colors.brown[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getSectorColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getSectorColor().withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        sector,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: _getSectorColor(),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
