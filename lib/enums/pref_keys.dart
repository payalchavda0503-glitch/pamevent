enum PrefKeys {
  profile('pe_profile'),
  tickets('tickets', keepAlive: true),
  queue('queue', keepAlive: true),
  barcodes('barcodes', keepAlive: true),
  barcodeQueue('barcode_queue', keepAlive: true);

  const PrefKeys(this.key, {this.keepAlive = false});

  final String key;
  final bool keepAlive;
}
