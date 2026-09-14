import 'package:in_app_purchase/in_app_purchase.dart';

/// Kết luận của server về một giao dịch.
enum VerifyResult {
  /// Server đã nhận và cấp quyền → đóng giao dịch, phát `purchased`.
  granted,

  /// Server **khẳng định** giao dịch không hợp lệ (chữ ký sai, product lạ, đã
  /// hoàn tiền) → đóng giao dịch và báo lỗi. Thử lại cũng không khác.
  rejected,

  /// **Chưa biết** — mất mạng, 5xx, timeout. KHÔNG đóng giao dịch: để store giữ
  /// nó lại và phát lại ở lần mở app sau, lúc đó verify lại.
  unavailable,
}

/// Đường để app **xác minh giao dịch với server của mình** trước khi
/// [BillingRepository] công nhận quyền và đóng giao dịch.
///
/// ## Vì sao phải là một hook, không phải việc app tự làm sau
/// Giao dịch chỉ được `completePurchase` khi nội dung đã được giao. Đóng trước
/// rồi mới gọi server là tự bỏ mất cơ hội thử lại: giao dịch biến mất khỏi hàng
/// đợi của store, và người vừa trả tiền phải tự bấm "Khôi phục" mới lấy lại
/// được quyền. Ngược lại, KHÔNG đóng thì StoreKit phát lại nó mỗi lần mở app —
/// đúng thứ ta muốn khi server tạm thời không với tới được.
///
/// ## Không đăng ký thì sao
/// [BillingRepository] bỏ qua bước này và công nhận quyền theo lời của store
/// (hành vi của 0.1.0). Chỉ dùng được cho app không có server.
///
/// Đăng ký vào GetIt trước khi `setupDI` của package chạy.
abstract interface class PurchaseVerifier {
  /// Gửi [PurchaseDetails.verificationData] lên server và trả kết luận.
  ///
  /// **Không được ném.** Lỗi mạng phải trả [VerifyResult.unavailable] — ném ra
  /// sẽ rơi vào listener của `purchaseStream`, chỗ không ai bắt.
  Future<VerifyResult> verify(PurchaseDetails purchase);
}
