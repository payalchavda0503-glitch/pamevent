import 'package:json_annotation/json_annotation.dart';

part 'barcode_product.g.dart';

@JsonSerializable()
class BarcodeProduct {
  BarcodeProduct({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productQty,
    required this.isIncluded,
  });

  @JsonKey(name: 'product_id')
  final int productId;

  @JsonKey(name: 'product_name')
  final String productName;

  @JsonKey(name: 'product_price')
  final double productPrice;

  @JsonKey(name: 'product_qty')
  final int productQty;

  @JsonKey(name: 'is_included')
  final int isIncluded;

  factory BarcodeProduct.fromJson(Map<String, dynamic> json) =>
      _$BarcodeProductFromJson(json);

  Map<String, dynamic> toJson() => _$BarcodeProductToJson(this);
}
