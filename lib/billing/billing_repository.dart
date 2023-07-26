import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_billing/billing/billing_helper.dart';
import 'package:flutter_billing/billing/product_item.dart';
import 'package:flutter_billing/billing/purchase_response.dart';
import 'package:flutter_billing/billing/signature_checker.dart';
import 'package:flutter_core/data/executable.dart';
import 'package:flutter_core/data/shared/premium_holder.dart';
import 'package:flutter_core/ext/di.dart';
import 'package:flutter_core/ext/list.dart';
import 'package:flutter_core/ext/stream.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

abstract class BillingRepository extends Executable {
  ValueStream<List<ProductItem>> get productsStream;

  Stream<PurchaseResponse> get purchaseResponseStream;

  void queryAllProducts();

  void buyProduct(ProductItem productItem);
}

@Singleton(as: BillingRepository)
// ignore: camel_case_types
class BillingRepository_Impl extends BillingRepository {
  BillingRepository_Impl(this.premiumHolder, this.billingRequestProvider) {
    _listenPurchaseUpdate();
    queryAllProducts();
  }

  final BillingRequestProvider billingRequestProvider;

  final PremiumHolder premiumHolder;

  late final StreamController<PurchaseResponse> _purchaseResponseSC =
      StreamController.broadcast();

  @override
  Stream<PurchaseResponse> get purchaseResponseStream =>
      _purchaseResponseSC.stream;

  late final _productsItem = <ProductItem>[];

  @override
  ValueStream<List<ProductItem>> get productsStream => _productItemsBS.stream;

  late final BehaviorSubject<List<ProductItem>> _productItemsBS =
      BehaviorSubject();

  StreamSubscription? _purchaseStreamSubscription;

  @override
  @disposeMethod
  Future<void> dispose() async {
    _purchaseStreamSubscription?.cancel();
    _productItemsBS.close();
    _purchaseResponseSC.close();
  }

  void updateProductItem(List<ProductItem> productItems) {
    _productsItem.clear();
    _productsItem.addAll(productItems);
    _productItemsBS.addSafety(productItems);
  }

  void _listenPurchaseUpdate() {
    _purchaseStreamSubscription =
        InAppPurchase.instance.purchaseStream.listen((purchaseDetails) async {
      if (purchaseDetails.isEmpty) {
        _activePremium(null);
        return;
      }
      for (var purchase in purchaseDetails) {
        if (purchase.status == PurchaseStatus.pending) {
          _purchaseResponseSC
              .addSafety(PurchaseResponse.error(purchase.productID));
        } else if (purchase.status == PurchaseStatus.error ||
            !appInject<SignatureChecker>().validSignature()) {
          _purchaseResponseSC
              .addSafety(PurchaseResponse.error(purchase.productID));
        } else if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          _purchaseResponseSC
              .addSafety(PurchaseResponse.purchased(purchase.productID));
          _activePremium(purchase);
        }

        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
        // _consumePurchase(purchase);
      }
    });
  }

  @override
  void queryAllProducts() {
    executeSingleTask(() async {
      if (_productsItem.isNotEmpty) return;
      final available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        updateProductItem([]);
        return;
      }
      final ProductDetailsResponse productDetailsResponse = await InAppPurchase
          .instance
          .queryProductDetails(billingRequestProvider.allProducts);
      if (productDetailsResponse.notFoundIDs.isNotEmpty) {
        updateProductItem([]);
        return;
      }
      _mappingProductDetail(productDetailsResponse.productDetails);
      await InAppPurchase.instance.restorePurchases();
    });
  }

  void _mappingProductDetail(List<ProductDetails> productDetails) {
    final productItems = <ProductItem>[];
    for (var product in productDetails) {
      final billingRequest =
          billingRequestProvider.productRequestMap[product.id];
      if (billingRequest == null) continue;
      final item =
          ProductItem(label: billingRequest.label, productDetail: product);
      item.saleOff = billingRequest.saleOff;
      productItems.add(item);
    }
    productItems.sort(
      (a, b) => a.productDetail.rawPrice > b.productDetail.rawPrice ? 1 : -1,
    );
    updateProductItem(productItems);
  }

  @override
  Future<void> buyProduct(ProductItem productItem) async {
    final purchaseParams =
        PurchaseParam(productDetails: productItem.productDetail);
    await InAppPurchase.instance
        .buyNonConsumable(purchaseParam: purchaseParams);
    // if (productItem.productDetail.id == BillingHelper.productLifetime) {
    //   await InAppPurchase.instance
    //       .buyConsumable(purchaseParam: purchaseParams, autoConsume: false);
    // } else {
    //   await InAppPurchase.instance
    //       .buyNonConsumable(purchaseParam: purchaseParams);
    // }
  }

  Future<void> _consumePurchase(PurchaseDetails purchaseDetails) async {
    if (Platform.isAndroid) {
      final InAppPurchaseAndroidPlatformAddition androidAddition = InAppPurchase
          .instance
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      await androidAddition.consumePurchase(purchaseDetails);
    }
  }

  void _activePremium(PurchaseDetails? purchase) {
    if (purchase == null) {
      premiumHolder.isLifetime = false;
      premiumHolder.premiumDay = 0;
      return;
    }
    final startDay = int.parse(purchase.transactionDate ?? '0');
    final billingRequest =
        billingRequestProvider.productRequestMap[purchase.productID];
    if (billingRequest == null) return;
    if (billingRequest.premiumDay > -1) {
      premiumHolder.premiumDay =
          startDay + 86400000 * billingRequest.premiumDay;
    } else {
      premiumHolder.isLifetime = true;
    }
  }
}
