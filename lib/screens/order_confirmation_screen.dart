import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:decimal/decimal.dart';
import '../core/utils/price_formatter.dart';
import '../core/theme/app_theme.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String symbol;
  final String type;
  final int quantity;
  final String price;
  final String total;

  const OrderConfirmationScreen({
    super.key,
    required this.symbol,
    required this.type,
    required this.quantity,
    required this.price,
    required this.total,
  });

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController; // OPTIMIZATION: late final
  late final Animation<double> _scaleAnimation; // OPTIMIZATION: late final
  late final Animation<double> _fadeAnimation; // OPTIMIZATION: late final

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = widget.type == 'BUY';
    final color = isBuy ? AppTheme.successColor : AppTheme.errorColor;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Order Confirmation'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 60,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Order Executed Successfully',
                  style: AppTheme.heading2.copyWith(
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              RepaintBoundary( // OPTIMIZATION: Isolate card from animations
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                  children: [
                    _buildRow('Type', widget.type, color),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: AppTheme.dividerColor),
                    const SizedBox(height: 16),
                    _buildRow('Symbol', widget.symbol, null),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: AppTheme.dividerColor),
                    const SizedBox(height: 16),
                    _buildRow('Quantity', PriceFormatter.formatQuantity(widget.quantity), null),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: AppTheme.dividerColor),
                    const SizedBox(height: 16),
                    _buildRow('Price', '₹${PriceFormatter.formatPrice(Decimal.parse(widget.price))}', null),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: AppTheme.dividerColor),
                    const SizedBox(height: 16),
                    _buildRow(
                      'Total Value',
                      '₹${PriceFormatter.formatPrice(Decimal.parse(widget.total))}',
                      null,
                      isLarge: true,
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Go to Home',
                    style: AppTheme.subtitle1.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, Color? valueColor, {bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isLarge 
              ? AppTheme.subtitle1.copyWith(color: AppTheme.textSecondary)
              : AppTheme.body2.copyWith(color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: isLarge 
              ? AppTheme.heading3.copyWith(color: valueColor ?? AppTheme.textPrimary)
              : AppTheme.subtitle2.copyWith(color: valueColor ?? AppTheme.textPrimary),
        ),
      ],
    );
  }
}
