import 'package:flutter/material.dart';

class StockLogo extends StatelessWidget {
  final String symbol;
  final double size;

  const StockLogo({
    super.key,
    required this.symbol,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getGradientColors(symbol),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: _getGradientColors(symbol).first.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          symbol.substring(0, symbol.length > 2 ? 2 : symbol.length),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors(String symbol) {
    final hash = symbol.hashCode;
    final colors = [
      [Colors.blue[700]!, Colors.blue[500]!],
      [Colors.purple[700]!, Colors.purple[500]!],
      [Colors.indigo[700]!, Colors.indigo[500]!],
      [Colors.teal[700]!, Colors.teal[500]!],
      [Colors.cyan[700]!, Colors.cyan[500]!],
      [Colors.orange[700]!, Colors.orange[500]!],
      [Colors.pink[700]!, Colors.pink[500]!],
      [Colors.deepOrange[700]!, Colors.deepOrange[500]!],
    ];
    return colors[hash.abs() % colors.length];
  }
}
