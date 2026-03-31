// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_addon.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingAddon _$BookingAddonFromJson(Map<String, dynamic> json) => BookingAddon(
  total: (json['total'] as num).toDouble(),
  products: (json['products'] as List<dynamic>)
      .map((e) => AddonProduct.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BookingAddonToJson(BookingAddon instance) =>
    <String, dynamic>{'total': instance.total, 'products': instance.products};

AddonProduct _$AddonProductFromJson(Map<String, dynamic> json) => AddonProduct(
  productId: (json['product_id'] as num).toInt(),
  productName: json['product_name'] as String,
  productPrice: (json['product_price'] as num).toDouble(),
  productQty: (json['product_qty'] as num).toInt(),
  isIncluded: (json['is_included'] as num).toInt(),
  productTotal: (json['product_total'] as num).toDouble(),
);

Map<String, dynamic> _$AddonProductToJson(AddonProduct instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'product_name': instance.productName,
      'product_price': instance.productPrice,
      'product_qty': instance.productQty,
      'is_included': instance.isIncluded,
      'product_total': instance.productTotal,
    };
