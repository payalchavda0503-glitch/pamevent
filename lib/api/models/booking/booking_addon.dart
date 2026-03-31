import 'package:json_annotation/json_annotation.dart';

part 'booking_addon.g.dart';

@JsonSerializable()
class BookingAddon {
  BookingAddon({
    required this.total,
    required this.products,
  });

  final double total;
  final List<AddonProduct> products;

  factory BookingAddon.fromJson(Map<String, dynamic> json) =>
      _$BookingAddonFromJson(json);

  Map<String, dynamic> toJson() => _$BookingAddonToJson(this);
}

@JsonSerializable()
class AddonProduct {
  AddonProduct({
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productQty,
    required this.isIncluded,
    required this.productTotal,
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

  @JsonKey(name: 'product_total')
  final double productTotal;

  factory AddonProduct.fromJson(Map<String, dynamic> json) =>
      _$AddonProductFromJson(json);

  Map<String, dynamic> toJson() => _$AddonProductToJson(this);
}
