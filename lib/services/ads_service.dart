import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob wrapper. Uses Google TEST ad unit IDs until real units are created
/// in the AdMob console after the app is on Play (see memory admob-android-units).
class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  // Google official TEST IDs — replace with real units once the app is live.
  static const String _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  bool _ready = false;
  InterstitialAd? _interstitial;
  int _matchesOpened = 0;

  String get bannerUnitId => _testBanner; // TODO real unit
  String get interstitialUnitId => _testInterstitial; // TODO real unit

  Future<void> init() async {
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    await MobileAds.instance.initialize();
    _ready = true;
    _loadInterstitial();
  }

  void _loadInterstitial() {
    if (!_ready) return;
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Show an interstitial occasionally (every 3rd match detail open).
  void maybeShowInterstitial() {
    _matchesOpened++;
    if (_matchesOpened % 3 != 0) return;
    final ad = _interstitial;
    if (ad == null) return;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
    );
    ad.show();
  }

  BannerAd createBanner() {
    final banner = BannerAd(
      adUnitId: bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    );
    banner.load();
    return banner;
  }
}
