/// Kết quả một lượt mua, phát ra trên [BillingRepository.purchaseResponseStream].
class PurchaseResponse {
  final PurState purchaseStatus;

  final String productID;

  /// Mã lỗi của store (chỉ có khi [purchaseStatus] là [PurState.error]).
  ///
  /// Dùng để phân biệt "hết hạn thẻ" với "sai chữ ký app" — hai thứ cần hai câu
  /// báo lỗi khác nhau.
  final String? errorCode;

  /// Câu lỗi store trả về, đã có sẵn ngôn ngữ của máy.
  final String? errorMessage;

  PurchaseResponse.error(this.productID, {this.errorCode, this.errorMessage})
      : purchaseStatus = PurState.error;

  PurchaseResponse.purchased(this.productID)
      : purchaseStatus = PurState.purchased,
        errorCode = null,
        errorMessage = null;

  PurchaseResponse.pending(this.productID)
      : purchaseStatus = PurState.pending,
        errorCode = null,
        errorMessage = null;

  /// Người dùng tự đóng luồng thanh toán — **không phải lỗi**, đừng hiện dialog.
  PurchaseResponse.cancelled(this.productID)
      : purchaseStatus = PurState.cancelled,
        errorCode = null,
        errorMessage = null;

  PurchaseResponse({
    required this.purchaseStatus,
    required this.productID,
    this.errorCode,
    this.errorMessage,
  });

  bool get isSuccess => purchaseStatus == PurState.purchased;
}

enum PurState { pending, purchased, cancelled, error }
