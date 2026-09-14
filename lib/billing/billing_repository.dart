import 'dart:async';
import 'dart:io';

import 'package:flutter_billing/billing/billing_helper.dart';
import 'package:flutter_billing/billing/product_item.dart';
import 'package:flutter_billing/billing/purchase_response.dart';
import 'package:flutter_billing/billing/purchase_verifier.dart';
import 'package:flutter_billing/billing/signature_checker.dart';
// flutter_core gom mọi thứ vào một thư viện `core.dart` (các file con là
// `part of`), nên import lẻ từng file sẽ không biên dịch được.
import 'package:flutter_core/core.dart';
import 'package:get_it/get_it.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

/// Store không dùng được (máy tắt mua hàng, chưa đăng nhập store, sandbox lỗi).
class BillingUnavailable implements Exception {
  const BillingUnavailable([this.reason]);

  final String? reason;

  @override
  String toString() => 'BillingUnavailable(${reason ?? 'store not available'})';
}

abstract class BillingRepository extends Executable {
  ValueStream<List<ProductItem>> get productsStream;

  Stream<PurchaseResponse> get purchaseResponseStream;

  void queryAllProducts();

  /// Bản **chờ được** của [queryAllProducts] — trả về danh sách sau khi hỏi
  /// store xong, ném [BillingUnavailable] nếu store không dùng được.
  ///
  /// Có mặt từ 0.1.0: [queryAllProducts] chạy qua `executeSingleTask`, mà hàm đó
  /// **nuốt mọi exception**, nên bên gọi không có cách nào phân biệt "store trả
  /// về 0 gói" với "gọi store thất bại". Màn paywall cần phân biệt để chọn giữa
  /// trạng thái rỗng và trạng thái lỗi-có-nút-thử-lại.
  Future<List<ProductItem>> loadProducts({bool force = false});

  void buyProduct(ProductItem productItem);

  /// Khôi phục giao dịch cũ (bắt buộc phải có nút này theo luật App Store).
  Future<void> restorePurchases();
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

  /// Chỉ xoá quyền Premium khi danh sách rỗng đến **sau một lượt khôi phục**.
  ///
  /// `purchaseStream` phát `[]` để báo "khôi phục xong, không có giao dịch nào".
  /// Bản 0.0.1 coi mọi lượt `[]` là mất quyền — nghĩa là một lượt phát rỗng lạc
  /// nhịp cũng đủ thổi bay Premium của người đã trả tiền.
  bool _restoreInFlight = false;

  @override
  @disposeMethod
  Future<void> dispose() async {
    _purchaseStreamSubscription?.cancel();
    _productItemsBS.close();
    _purchaseResponseSC.close();
  }

  void updateProductItem(List<ProductItem> productItems) {
    _productsItem
      ..clear()
      ..addAll(productItems);
    _productItemsBS.addSafety(productItems);
  }

  /// Chữ ký chỉ kiểm tra khi app **có đăng ký** [SignatureChecker].
  ///
  /// Bản 0.0.1 gọi thẳng `appInject<SignatureChecker>()`: app nào quên đăng ký
  /// là `GetIt` ném ngay trong listener của `purchaseStream` — lỗi rơi vào chỗ
  /// không ai bắt, và người dùng thấy màn thanh toán treo im.
  bool _validSignature() {
    final checker = GetIt.I.isRegistered<SignatureChecker>()
        ? GetIt.I<SignatureChecker>()
        : null;
    return checker?.validSignature() ?? true;
  }

  void _listenPurchaseUpdate() {
    _purchaseStreamSubscription = InAppPurchase.instance.purchaseStream.listen((
      purchaseDetails,
    ) async {
      if (purchaseDetails.isEmpty) {
        if (_restoreInFlight) {
          _restoreInFlight = false;
          _activePremium(null);
        }
        return;
      }
      _restoreInFlight = false;
      for (final purchase in purchaseDetails) {
        await _handleOne(purchase);
      }
    });
  }

  Future<void> _handleOne(PurchaseDetails purchase) async {
    switch (purchase.status) {
      // Chờ duyệt (Ask to Buy của trẻ em, thẻ cần xác thực thêm). KHÔNG phải
      // lỗi — bản 0.0.1 báo `error` nên UI đóng màn và người dùng tưởng hỏng,
      // rồi vài phút sau giao dịch về thì không còn chỗ nào hiện ra.
      //
      // Đang chờ thì `pendingCompletePurchase` là `false`; không đóng gì cả.
      case PurchaseStatus.pending:
        _emit(PurchaseResponse.pending(purchase.productID, details: purchase));
        return;

      // Người dùng bấm huỷ. Bản 0.0.1 không có nhánh này nên rơi tọt xuống đáy
      // vòng lặp: UI kẹt ở spinner vĩnh viễn.
      case PurchaseStatus.canceled:
        _emit(PurchaseResponse.cancelled(purchase.productID, details: purchase));
      case PurchaseStatus.error:
        _emit(
          PurchaseResponse.error(
            purchase.productID,
            details: purchase,
            errorCode: purchase.error?.code,
            errorMessage: purchase.error?.message,
          ),
        );
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        if (!_validSignature()) {
          _emit(
            PurchaseResponse.error(
              purchase.productID,
              details: purchase,
              errorCode: 'invalid_signature',
            ),
          );
          break;
        }
        switch (await _verifyWithServer(purchase)) {
          case VerifyResult.granted:
            _emit(
              PurchaseResponse.purchased(purchase.productID, details: purchase),
            );
            _activePremium(purchase);
          case VerifyResult.rejected:
            // Server nói KHÔNG và sẽ mãi nói không ⇒ đóng giao dịch (rơi xuống
            // dưới). Giữ lại chỉ để store phát lại một giao dịch vô dụng mỗi lần
            // mở app.
            _emit(
              PurchaseResponse.error(
                purchase.productID,
                details: purchase,
                errorCode: 'server_rejected',
              ),
            );
          case VerifyResult.unavailable:
            // **Chưa biết** ⇒ KHÔNG đóng: store giữ giao dịch lại và phát lại ở
            // lần mở app sau, lúc đó verify lại. Đóng bây giờ là vứt mất cơ hội
            // đó và người vừa trả tiền phải tự bấm "Khôi phục".
            _emit(
              PurchaseResponse.error(
                purchase.productID,
                details: purchase,
                errorCode: 'verify_unavailable',
              ),
            );
            return;
        }
    }

    // Giao dịch chưa "finish" thì StoreKit phát lại nó mỗi lần mở app, và Apple
    // từ chối bản build để nguyên như vậy — nên vẫn phải đóng cả với trường hợp
    // lỗi/huỷ/bị server từ chối.
    if (purchase.pendingCompletePurchase) {
      await InAppPurchase.instance.completePurchase(purchase);
    }
  }

  void _emit(PurchaseResponse response) =>
      _purchaseResponseSC.addSafety(response);

  /// Hỏi server của app xem giao dịch này có thật không.
  ///
  /// Không đăng ký [PurchaseVerifier] ⇒ tin store luôn (app không có server).
  /// Verifier ném thì coi như **chưa biết**: nó vi phạm hợp đồng của mình, và
  /// đoán "hợp lệ" ở đây là phát Premium theo lời của thiết bị.
  Future<VerifyResult> _verifyWithServer(PurchaseDetails purchase) async {
    if (!GetIt.I.isRegistered<PurchaseVerifier>()) return VerifyResult.granted;
    try {
      return await GetIt.I<PurchaseVerifier>().verify(purchase);
    } catch (_) {
      return VerifyResult.unavailable;
    }
  }

  @override
  void queryAllProducts() {
    executeSingleTask(() => loadProducts());
  }

  @override
  Future<List<ProductItem>> loadProducts({bool force = false}) async {
    if (!force && _productsItem.isNotEmpty) return List.of(_productsItem);

    if (!await InAppPurchase.instance.isAvailable()) {
      updateProductItem([]);
      throw const BillingUnavailable('in-app purchase disabled on this device');
    }

    final response = await InAppPurchase.instance.queryProductDetails(
      billingRequestProvider.allProducts,
    );
    if (response.error != null) {
      updateProductItem([]);
      throw BillingUnavailable(response.error!.message);
    }

    // Chỉ **một** id chưa duyệt xong ở App Store Connect là bản 0.0.1 ném đi
    // sạch catalog và màn paywall trắng trơn. Giữ những gói store trả về được;
    // `notFoundIDs` là chuyện cấu hình, không phải lỗi phiên mua.
    final items = _mapProductDetail(response.productDetails);
    updateProductItem(items);

    // Đọc lại quyền từ giao dịch cũ. Không `await` để trả gói về cho UI ngay —
    // kết quả khôi phục đi đường `purchaseStream`.
    unawaited(restorePurchases());
    return items;
  }

  List<ProductItem> _mapProductDetail(List<ProductDetails> productDetails) {
    final productItems = <ProductItem>[];
    for (final product in productDetails) {
      final billingRequest =
          billingRequestProvider.productRequestMap[product.id];
      if (billingRequest == null) continue;
      productItems.add(
        ProductItem(label: billingRequest.label, productDetail: product)
          ..saleOff = billingRequest.saleOff,
      );
    }
    productItems.sort(
      (a, b) => a.productDetail.rawPrice.compareTo(b.productDetail.rawPrice),
    );
    return productItems;
  }

  @override
  Future<void> buyProduct(ProductItem productItem) async {
    final purchaseParams = PurchaseParam(
      productDetails: productItem.productDetail,
    );
    await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParams);
  }

  @override
  Future<void> restorePurchases() async {
    _restoreInFlight = true;
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {
      _restoreInFlight = false;
      rethrow;
    }
  }

  /// Chỉ Android mới cần: gói mua-một-lần đăng ký kiểu `consumable` phải được
  /// "tiêu thụ" thì Play mới cho mua lại. Giữ lại cho app nào dùng tới.
  Future<void> consumePurchase(PurchaseDetails purchaseDetails) async {
    if (!Platform.isAndroid) return;
    final androidAddition = InAppPurchase.instance
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    await androidAddition.consumePurchase(purchaseDetails);
  }

  void _activePremium(PurchaseDetails? purchase) {
    if (purchase == null) {
      premiumHolder.isLifetime = false;
      premiumHolder.premiumDay = 0;
      return;
    }
    final startDay = int.tryParse(purchase.transactionDate ?? '') ??
        DateTime.now().millisecondsSinceEpoch;
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
