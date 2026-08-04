import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../data/services/ad_service.dart';

class AdBannerSlot extends StatefulWidget {
  const AdBannerSlot({super.key, this.enabled = true});

  final bool enabled;

  @override
  State<AdBannerSlot> createState() => _AdBannerSlotState();
}

class _AdBannerSlotState extends State<AdBannerSlot> {
  BannerAd? _ad;
  int? _loadedWidth;
  bool _loading = false;

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  Future<void> _load(int width) async {
    if (!widget.enabled || width <= 0 || _loading || _loadedWidth == width) {
      return;
    }
    _loading = true;
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) {
      _loading = false;
      return;
    }
    await _ad?.dispose();
    final ad = BannerAd(
      size: size,
      adUnitId: AdService.instance.bannerId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          if (!mounted) {
            loaded.dispose();
            return;
          }
          setState(() {
            _ad = loaded as BannerAd;
            _loadedWidth = width;
            _loading = false;
          });
        },
        onAdFailedToLoad: (failed, error) {
          failed.dispose();
          if (mounted) setState(() => _loading = false);
        },
      ),
    );
    ad.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.floor();
          WidgetsBinding.instance.addPostFrameCallback((_) => _load(width));
          final ad = _ad;
          if (ad == null) return const SizedBox(height: 0);
          return SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: AdWidget(ad: ad),
          );
        },
      ),
    );
  }
}
