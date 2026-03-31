class PhysicalScans {
  PhysicalScans({
    required this.totalScan,
    required this.totalTicket,
    required this.scanPercentage,
    required this.scanTicketLabel,
  });

   int totalScan;
   int totalTicket;
   num scanPercentage;
   String scanTicketLabel;

  factory PhysicalScans.fromJson(Map<String, dynamic> json) {
    return PhysicalScans(
      totalScan: int.tryParse(json['total_scan'].toString()) ?? 0,
      totalTicket: int.tryParse(json['total_ticket'].toString()) ?? 0,
      scanPercentage: num.tryParse(json['scan_percentage'].toString()) ?? 0,
      scanTicketLabel: json['scan_ticket_label']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_scan': totalScan,
      'total_ticket': totalTicket,
      'scan_percentage': scanPercentage,
      'scan_ticket_label': scanTicketLabel,
    };
  }
}
