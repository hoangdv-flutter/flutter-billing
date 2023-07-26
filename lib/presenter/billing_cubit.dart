import 'dart:async';

import 'package:flutter_billing/billing/billing_repository.dart';
import 'package:flutter_billing/billing/product_item.dart';
import 'package:flutter_billing/billing/purchase_response.dart';
import 'package:flutter_core/component/view/list/my_list_view.dart';
import 'package:flutter_core/ext/di.dart';
import 'package:flutter_core/ext/stream.dart';
import 'package:flutter_core/presenter/base_cubit.dart';
import 'package:rxdart/rxdart.dart';

class BillingCubit extends BaseCubit<void> {
  BillingCubit() : super(null) {
    _productSubs = billingRepository.productsStream.listen((products) {
      _productsBS.addSafety(
          ListItemUpdate(data: products, action: ItemUpdateAction.replace));
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

  void buyProduct(ProductItem productItem) {
    billingRepository.buyProduct(productItem);
  }

  late final billingRepository = appInject<BillingRepository>();

  @override
  Future<void> close() {
    _productsBS.close();
    _productSubs?.cancel();
    return super.close();
  }
}
