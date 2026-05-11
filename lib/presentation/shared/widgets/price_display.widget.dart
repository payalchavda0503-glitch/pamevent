import 'package:flutter/material.dart';
import '../../../helpers/public_url.dart';
import '../../../helpers/app_colors.dart';

class PriceDisplay extends StatelessWidget {
  final dynamic price;
  final dynamic originalPrice;
  final bool? isDiscounted;
  final TextStyle? priceStyle;
  final TextStyle? originalPriceStyle;
  final WrapCrossAlignment crossAxisAlignment;

  const PriceDisplay({
    super.key,
    required this.price,
    this.originalPrice,
    this.isDiscounted,
    this.priceStyle,
    this.originalPriceStyle,
    this.crossAxisAlignment = WrapCrossAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final formattedPrice = formatPrice(price);
    final formattedOriginalPrice = originalPrice != null 
        ? formatPrice(originalPrice, extractOriginal: true) 
        : null;

    // Show discount if isDiscounted is true, or if prices are different
    bool showDiscount = false;
    if (formattedOriginalPrice != null && formattedOriginalPrice != 'Free') {
      // If isDiscounted is explicitly true, always show it if we have an original price
      if (isDiscounted == true) {
        showDiscount = true;
      } else {
        // Otherwise, show only if the prices are actually different
        showDiscount = formattedPrice != formattedOriginalPrice;
      }
    }

    return Wrap(
      crossAxisAlignment: crossAxisAlignment,
      spacing: 8,
      children: [
        Text(
          formattedPrice,
          style: priceStyle ?? const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.black,
          ),
        ),
        if (showDiscount)
          Text(
            formattedOriginalPrice!,
            style: originalPriceStyle ?? const TextStyle(
              fontSize: 12,
              color: AppColors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }
}
