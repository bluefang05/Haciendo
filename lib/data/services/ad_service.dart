import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const String releaseBannerId =
      'ca-app-pub-3322493998376707/2990833259';
  static const String androidTestBannerId =
      'ca-app-pub-3940256099942544/6300978111';

  String get bannerId => kReleaseMode ? releaseBannerId : androidTestBannerId;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }
}
