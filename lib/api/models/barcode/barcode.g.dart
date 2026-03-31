// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'barcode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BarcodeModel _$BarcodeModelFromJson(Map<String, dynamic> json) => BarcodeModel(
  bookingId: json['booking_id'] as String,
  addonScanStatus: (json['addon_scan_status'] as num).toInt(),
  addonBarcode: json['addon_barcode'] as String,
  addonBarcodeFile: json['addon_barcode_file'] as String,
  addonPrice: (json['addon_price'] as num).toDouble(),
  addonFees: (json['addon_fees'] as num).toDouble(),
  total: (json['total'] as num).toDouble(),
  products: (json['products'] as List<dynamic>)
      .map((e) => BarcodeProduct.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BarcodeModelToJson(BarcodeModel instance) =>
    <String, dynamic>{
      'booking_id': instance.bookingId,
      'addon_scan_status': instance.addonScanStatus,
      'addon_barcode': instance.addonBarcode,
      'addon_barcode_file': instance.addonBarcodeFile,
      'addon_price': instance.addonPrice,
      'addon_fees': instance.addonFees,
      'total': instance.total,
      'products': instance.products,
    };
