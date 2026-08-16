import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MonetizationController extends ChangeNotifier {
  MonetizationController._();

  static final instance = MonetizationController._();

  static const removeAdsProductId = 'com.ryushin.studycollection.remove_ads';
  static const _premiumStorageKey = 'premium_remove_ads_v1';

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? _removeAdsProduct;

  bool initialized = false;
  bool premium = false;
  bool canShowAds = false;
  bool storeAvailable = false;
  bool purchasePending = false;
  bool privacyOptionsRequired = false;
  String? errorMessage;

  String? get premiumPrice => _removeAdsProduct?.price;

  Future<void> initialize() async {
    if (initialized) return;
    final preferences = await SharedPreferences.getInstance();
    premium = preferences.getBool(_premiumStorageKey) ?? false;

    _purchaseSubscription = InAppPurchase.instance.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        errorMessage = '購入情報を確認できませんでした。';
        purchasePending = false;
        notifyListeners();
      },
    );
    await _initializeStore();
    if (!premium) await _initializeAds();
    initialized = true;
    notifyListeners();
  }

  Future<void> _initializeStore() async {
    storeAvailable = await InAppPurchase.instance.isAvailable();
    if (!storeAvailable) return;
    final response = await InAppPurchase.instance.queryProductDetails({
      removeAdsProductId,
    });
    if (response.productDetails.isNotEmpty) {
      _removeAdsProduct = response.productDetails.first;
    }
    if (response.error != null) {
      errorMessage = 'プレミアム情報を取得できませんでした。';
    }
  }

  Future<void> _initializeAds() async {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.t,
        ageRestrictedTreatment: AgeRestrictedTreatment.teen,
      ),
    );
    await MobileAds.instance.initialize();

    final consentCompleter = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        if (!consentCompleter.isCompleted) consentCompleter.complete();
      },
      (_) {
        if (!consentCompleter.isCompleted) consentCompleter.complete();
      },
    );
    await consentCompleter.future;
    canShowAds = await ConsentInformation.instance.canRequestAds();
    privacyOptionsRequired =
        await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
  }

  Future<void> buyRemoveAds() async {
    errorMessage = null;
    final product = _removeAdsProduct;
    if (!storeAvailable || product == null) {
      errorMessage = '現在プレミアムを購入できません。';
      notifyListeners();
      return;
    }
    purchasePending = true;
    notifyListeners();
    await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restorePurchases() async {
    errorMessage = null;
    if (!storeAvailable) {
      errorMessage = 'App Storeに接続できません。';
      notifyListeners();
      return;
    }
    purchasePending = true;
    notifyListeners();
    await InAppPurchase.instance.restorePurchases();
    purchasePending = false;
    notifyListeners();
  }

  Future<void> showPrivacyOptions() async {
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) errorMessage = 'プライバシー設定を開けませんでした。';
      notifyListeners();
    });
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != removeAdsProductId) continue;
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // StoreKit has validated the transaction before it reaches this
        // stream. Add server-side validation if accounts/cloud sync are added.
        premium = true;
        canShowAds = false;
        final preferences = await SharedPreferences.getInstance();
        await preferences.setBool(_premiumStorageKey, true);
      } else if (purchase.status == PurchaseStatus.error) {
        errorMessage = '購入を完了できませんでした。';
      }
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
    purchasePending = purchases.any(
      (purchase) => purchase.status == PurchaseStatus.pending,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
