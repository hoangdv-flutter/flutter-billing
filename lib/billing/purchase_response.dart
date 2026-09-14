import 'package:in_app_purchase/in_app_purchase.dart';

/// Kết quả một lượt mua, phát ra trên [BillingRepository.purchaseResponseStream].
class PurchaseResponse {
  final PurState purchaseStatus;

  final String productID;

  /// Giao dịch thô của store — `null` với những response do lớp trên tự dựng.
  ///
  /// Có mặt từ 0.2.0 để app **xác minh ở server** được: [serverVerificationData]
  /// là thứ BE cần, và không có đường nào khác lấy nó ra mà không mở thêm một
  /// listener thứ hai trên `InAppPurchase.instance.purchaseStream` (hai listener
  /// sẽ tranh nhau gọi `completePurchase`).
  final PurchaseDetails? details;

  /// Mã lỗi của store (chỉ có khi [purchaseStatus] là [PurState.error]).
  ///
  /// Dùng để phân biệt "hết hạn thẻ" với "server từ chối giao dịch" — hai thứ
  /// cần hai câu báo lỗi khác nhau.
  final String? errorCode;

  /// Câu lỗi store trả về, đã có sẵn ngôn ngữ của máy.
  final String? errorMessage;

  PurchaseResponse.error(
    this.productID, {
    this.details,
    this.errorCode,
    this.errorMessage,
  }) : purchaseStatus = PurState.error;

  PurchaseResponse.purchased(this.productID, {this.details})
      : purchaseStatus = PurState.purchased,
        errorCode = null,
        errorMessage = null;

  PurchaseResponse.pending(this.productID, {this.details})
      : purchaseStatus = PurState.pending,
        errorCode = null,
        errorMessage = null;

  /// Người dùng tự đóng luồng thanh toán — **không phải lỗi**, đừng hiện dialog.
  PurchaseResponse.cancelled(this.productID, {this.details})
      : purchaseStatus = PurState.cancelled,
        errorCode = null,
        errorMessage = null;

  PurchaseResponse({
    required this.purchaseStatus,
    required this.productID,
    this.details,
    this.errorCode,
    this.errorMessage,
  });

  bool get isSuccess => purchaseStatus == PurState.purchased;

  /// Bằng chứng để **server** xác minh giao dịch.
  ///
  /// - iOS / StoreKit 2: chuỗi **JWS** Apple ký (`jwsRepresentation`).
  /// - Android: `purchaseToken` của Play.
  ///
  /// Gửi nguyên văn lên BE. **Đừng** tự parse rồi tin nội dung ở client — giá
  /// trị của nó nằm đúng ở chỗ chỉ server mới kiểm được chữ ký.
  String? get serverVerificationData =>
      details?.verificationData.serverVerificationData;

  /// Id giao dịch của store — dùng để log/đối soát, KHÔNG dùng thay xác minh.
  String? get transactionId => details?.purchaseID;

  /// Giao dịch này là **khôi phục** lại quyền đã mua trước đó.
  bool get isRestored => details?.status == PurchaseStatus.restored;
}

enum PurState { pending, purchased, cancelled, error }
