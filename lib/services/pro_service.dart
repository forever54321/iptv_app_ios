import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProService {
  static const String productId = 'com.iptvapp.player.pro_unlock';
  static const String _isProKey = 'pro_unlocked';
  static const String _grandfatherKey = 'pro_grandfather_checked';

  /// SHA256 hash of the single valid promo code. Storing the hash (not plaintext)
  /// keeps the actual code out of the compiled binary.
  /// Codes are case-insensitive and trimmed before comparison.
  static const Set<String> _promoCodeHashes = {
    '505d2af5ef156d4ea44a2a5f0c91d87bfc55ef51ac40bf140a77adaa33d280b6',
  };

  /// Marketing version at which the app went from paid to free.
  /// Anyone whose StoreKit `originalAppVersion` is less than this paid for it.
  static const String _firstFreeVersion = '4.1.2';

  static const _channel = MethodChannel('iptv/store');

  static final ProService instance = ProService._();
  ProService._();

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  final ValueNotifier<bool> isPro = ValueNotifier(false);
  ProductDetails? _product;
  ProductDetails? get product => _product;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isPro.value = prefs.getBool(_isProKey) ?? false;

    if (!isPro.value) {
      await _checkLegacyPaidUser(prefs);
    }

    if (!await _iap.isAvailable()) return;

    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (_) {});

    try {
      final response = await _iap.queryProductDetails({productId});
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
      }
    } catch (_) {}
  }

  /// Detects users who paid for the app before it went free.
  /// Combines StoreKit 2 `originalAppVersion` (most reliable, survives
  /// reinstall/new device) with a local Hive heuristic (fallback for
  /// pre-iOS 16 / edge cases).
  /// Holds the last-seen original app version (or error string) for diagnostics.
  String? lastOriginalAppVersion;
  String? lastReceiptError;

  Future<void> _checkLegacyPaidUser(
    SharedPreferences prefs, {
    bool interactive = false,
  }) async {
    if (Platform.isIOS) {
      try {
        final method = interactive
            ? 'refreshOriginalAppVersion'
            : 'getOriginalAppVersion';
        final originalVersion = await _channel.invokeMethod<String?>(method);
        lastOriginalAppVersion = originalVersion;
        lastReceiptError = null;
        if (originalVersion != null && originalVersion.isNotEmpty) {
          if (_isOlderThanFreeEra(originalVersion)) {
            await _setPro(true);
            await prefs.setBool(_grandfatherKey, true);
            return;
          }
          await prefs.setBool(_grandfatherKey, true);
          return;
        }
      } on PlatformException catch (e) {
        lastReceiptError = e.message ?? e.code;
      } catch (e) {
        lastReceiptError = e.toString();
      }
    }

    if (!(prefs.getBool(_grandfatherKey) ?? false)) {
      try {
        if (Hive.isBoxOpen('playlists')) {
          final box = Hive.box('playlists');
          if (box.isNotEmpty) {
            await _setPro(true);
          }
        }
      } catch (_) {}
      await prefs.setBool(_grandfatherKey, true);
    }
  }

  static bool _isOlderThanFreeEra(String version) {
    final v = _parseVersion(version);
    final cutoff = _parseVersion(_firstFreeVersion);
    for (var i = 0; i < 3; i++) {
      final a = i < v.length ? v[i] : 0;
      final b = i < cutoff.length ? cutoff[i] : 0;
      if (a < b) return true;
      if (a > b) return false;
    }
    return false;
  }

  static List<int> _parseVersion(String s) =>
      s.split('.').map((p) => int.tryParse(p) ?? 0).toList();

  Future<void> buy() async {
    if (_product == null) return;
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: _product!),
    );
  }

  /// Restores a previous IAP purchase AND re-checks legacy paid status.
  /// Interactive: triggers `AppTransaction.refresh()` which prompts the user
  /// to authenticate with Apple ID if not already signed into App Store.
  Future<void> restore() async {
    await _iap.restorePurchases();

    if (!isPro.value) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_grandfatherKey);
      await _checkLegacyPaidUser(prefs, interactive: true);
    }
  }

  /// Validates a promo code and unlocks Pro on success.
  /// Returns true if the code matched, false otherwise.
  Future<bool> redeemPromoCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return false;
    final hash = sha256.convert(utf8.encode(normalized)).toString();
    if (_promoCodeHashes.contains(hash)) {
      await _setPro(true);
      return true;
    }
    return false;
  }

  /// Diagnostic snapshot for surfacing to the user when restore fails.
  String diagnosticMessage() {
    if (lastReceiptError != null) {
      return 'Receipt check failed: $lastReceiptError';
    }
    if (lastOriginalAppVersion != null && lastOriginalAppVersion!.isNotEmpty) {
      return 'Original purchase version: $lastOriginalAppVersion '
          '(this version of the app went free at $_firstFreeVersion). '
          'Make sure you are signed into the App Store with the Apple ID you '
          'originally used to buy IPTV Player.';
    }
    return 'No previous purchase found. Make sure you are signed into the '
        'App Store with the Apple ID you used to buy IPTV Player.';
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.productID != productId) continue;
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        await _setPro(true);
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  Future<void> _setPro(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isProKey, v);
    isPro.value = v;
  }

  void dispose() {
    _sub?.cancel();
  }
}
