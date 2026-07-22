class ScanService {
  int? extractObjectId(String rawValue) {
    final urls = [
      RegExp(r'/objects/(\d+)'),
      RegExp(r'/object/(\d+)'),
      RegExp(r'/scan_result/(\d+)'),
    ];
    for (final reg in urls) {
      final m = reg.firstMatch(rawValue);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    return int.tryParse(rawValue);
  }
}
