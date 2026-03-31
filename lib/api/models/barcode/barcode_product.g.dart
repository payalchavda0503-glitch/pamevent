// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'barcode_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BarcodeProduct _$BarcodeProductFromJson(Map<String, dynamic> json) =>
    BarcodeProduct(
      productId: (json['product_id'] as num).toInt(),
      productName: json['product_name'] as String,
      productPrice: (json['product_price'] as num).toDouble(),
      productQty: (json['product_qty'] as num).toInt(),
      isIncluded: (json['is_included'] as num).toInt(),
    );

Map<String, dynamic> _$BarcodeProductToJson(BarcodeProduct instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'product_name': instance.productName,
      'product_price': instance.productPrice,
      'product_qty': instance.productQty,
      'is_included': instance.isIncluded,
    };
