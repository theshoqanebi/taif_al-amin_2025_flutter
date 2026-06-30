import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:taif_alamin/theme/app_colors.dart';

class StatusWidget extends StatelessWidget {
  final int count;
  final Currency currency;
  final StatusType type;
  const StatusWidget({
    super.key,
    required this.count,
    this.currency = Currency.iqd,
    this.type = StatusType.total,
  });

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat('#,##0', 'en_US');

    return Container(
      width: double.maxFinite,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: _gradient(type)),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment(1, 1.5),
            child: Image.asset(
              'icons/extra/cart.png',
              color: Color.fromARGB(32, 255, 255, 255),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Text(
                  _title(type),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 42,
                    color: _titleColor(type),
                  ),
                ),
                Text(
                  "${priceFormat.format(count)} ${_currency(currency)}",
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 24,
                    color: AppColors.neutral,
                  ),
                ),
                Container(
                  width: 300,
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      _icon(TrendingStatus.up),
                      Text(
                        '+12% عن الشهر الماضي',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          color: _infoColor(TrendingStatus.up),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _currency(Currency currency) {
    switch (currency) {
      case Currency.usd:
        return "\$";
      case Currency.iqd:
        return "د.ع";
    }
  }

  String _title(StatusType type) {
    switch (type) {
      case StatusType.total:
        return 'إجمالي المبالغ';
      case StatusType.paied:
        return 'إجمالي المسدد';
      case StatusType.remaining:
        return 'إجمالي المتبقي';
    }
  }

  List<Color> _gradient(StatusType type) {
    switch (type) {
      case StatusType.total:
        return [Color(0xFF0080AD), AppColors.primary];
      case StatusType.paied:
        return [Color(0xFF00391F), Color(0xFF006D40)];
      case StatusType.remaining:
        return [Color(0xFF0080AD), AppColors.primary];
    }
  }

  Color _titleColor(StatusType type) {
    switch (type) {
      case StatusType.total:
        return Color(0xFF7FAEE9);
      case StatusType.paied:
        return Color(0xFF74DB9D);
      case StatusType.remaining:
        return Color(0xFF5B8DC4);
    }
  }

  Color _infoColor(TrendingStatus status) {
    switch (status) {
      case TrendingStatus.up:
        return Colors.green;
      case TrendingStatus.down:
        return Colors.red;
    }
  }

  Widget _icon(TrendingStatus status) {
    switch (status) {
      case TrendingStatus.up:
        return SvgPicture.asset(
          width: 16,
          height: 16,
          'icons/extra/trending_up.svg',
          colorFilter: ColorFilter.mode(Colors.green, BlendMode.srcIn),
          //color: _infoColor(type),
        );
      case TrendingStatus.down:
        return SvgPicture.asset(
          width: 16,
          height: 16,
          'icons/extra/trending_down.svg',
          colorFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn),
        );
    }
  }
}

enum StatusType { total, paied, remaining }

enum TrendingStatus { up, down }

enum Currency { usd, iqd }
