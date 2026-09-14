import 'dart:async';

import 'package:flutter_billing/billing/billing_repository.dart';
import 'package:flutter_billing/billing/product_item.dart';
import 'package:flutter_billing/billing/purchase_response.dart';
import 'package:flutter_core/core.dart';
import 'package:rxdart/rxdart.dart';

class BillingCubit extends BaseCubit<void> {
  BillingCubit() : super(null) {
    _productSubs = billingRepository.productsStream.listen((products) {
      _productsBS.addSafety(
        ListItemUpdate(data: products, action: ItemUpdateAction.replace),
      );
    });
  }

  ValueStream<ListItemUpdate<ProductItem>> get productsStream =>
      _productsBS.stream;

  StreamSubscription? _productSubs;

  final BehaviorSubject<ListItemUpdate<ProductItem>> _productsBS =
      BehaviorSubject();

  Stream<PurchaseResponse> get purchaseResponse =>
      billingRepository.purchaseResponseStream;

  void queryAllProducts() {
    billingRepository.queryAllProducts();
  }

  /// Hỏi store và **chờ** kết quả — dùng cho màn có trạng thái lỗi/thử lại.
  Future<List<ProductItem>> loadProducts({bool force = false}) =>
      billingRepository.loadProducts(force: force);

  void buyProduct(ProductItem productItem) {
    billingRepository.buyProduct(productItem);
  }

  /// Nút "Khôi phục giao dịch" — App Store bắt buộc app bán subscription phải có.
  Future<void> restorePurchases() => billingRepository.restorePurchases();

  late final billingRepository = appInject<BillingRepository>();

  @override
  Future<void> close() {
    _productsBS.close();
    _productSubs?.cancel();
    return super.close();
  }
}
