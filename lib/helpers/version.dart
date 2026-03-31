import 'package:package_info_plus/package_info_plus.dart';

import '../api/json_convertors/serializer.dart';

class AppVersion {
  static String _name = '';
  static String get name => 'v$_name';
  static int buildNumber = -1;

  static Future<void> setVersion() async {
    final packInfo = await PackageInfo.fromPlatform();
    buildNumber = const IntNullParser().fromJson(packInfo.buildNumber) ?? -1;
    _name = '${packInfo.version}${buildNumber > 0 ? '+$buildNumber' : ''}';
  }
}
