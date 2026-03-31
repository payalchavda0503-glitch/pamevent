import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import 'barcode_product.dart';

part 'barcode.g.dart';

@JsonSerializable()
class BarcodeModel {
  @JsonKey(name: 'booking_id')
  final String bookingId;

  @JsonKey(name: 'addon_scan_status')
   int addonScanStatus;

  @JsonKey(name: 'addon_barcode')
  final String addonBarcode;

  @JsonKey(name: 'addon_barcode_file')
  final String addonBarcodeFile;

  @JsonKey(name: 'addon_price')
  final double addonPrice;

  @JsonKey(name: 'addon_fees')
  final double addonFees;

  final double total;

  final List<BarcodeProduct> products;

  BarcodeModel({
    required this.bookingId,
    required this.addonScanStatus,
    required this.addonBarcode,
    required this.addonBarcodeFile,
    required this.addonPrice,
    required this.addonFees,
    required this.total,
    required this.products,
  });

  factory BarcodeModel.fromJson(Map<String, dynamic> json) =>
      _$BarcodeModelFromJson(json);

  factory BarcodeModel.fromJsonString(String json) =>
      _$BarcodeModelFromJson(jsonDecode(json));
  BarcodeModel get alredycheacked {
    return BarcodeModel(bookingId: bookingId, addonScanStatus: addonScanStatus, addonBarcode: addonBarcode, addonBarcodeFile: addonBarcodeFile, addonPrice: addonPrice, addonFees: addonFees, total: total, products: products

    );
  }
  Map<String, dynamic> toJson() => _$BarcodeModelToJson(this);
}
