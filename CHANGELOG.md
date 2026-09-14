## 0.1.0

**Nâng cấp & sửa lỗi chặn đường iOS.**

### Bỏ vỏ plugin native
Bản 0.0.1 sinh ra từ `flutter create --template=plugin` nên mang theo `android/`
và `ios/` chỉ để trả về `getPlatformVersion` — không ai gọi. Đống đó ghim
AGP 7.3.0 / compileSdk 31 / minSdk 16 / Kotlin 1.7.10, đủ làm vỡ build của app
chạy AGP 9. Đã xoá `android/`, `ios/`, `FlutterBillingPlatform`,
`MethodChannelFlutterBilling` và mục `flutter: plugin:`.
`lib/flutter_billing.dart` giờ là barrel export toàn bộ API công khai.

### Dependency
- `in_app_purchase` ^3.1.11 → **^3.3.0** (iOS mặc định StoreKit 2).
- Khai báo `in_app_purchase_android` và `package_info_plus` — code vẫn `import`
  hai package này từ 0.0.1 mà **không** khai báo trong `pubspec.yaml`.
- `get_it` ^7.6.0 → **^8.0.0**, `injectable` ^2.1.2 → **^2.7.0**,
  `encrypt` ^5.0.1 → **^5.0.3**, `flutter_lints` ^2 → **^6**.
- Bỏ `plugin_platform_interface` (không còn là plugin).
- Import `package:flutter_core/core.dart` thay cho các đường dẫn file lẻ —
  flutter_core đã gom thành một thư viện với `part of`, import lẻ không còn biên
  dịch được.

### Sửa lỗi
- **`SignatureChecker` làm trượt mọi giao dịch iOS.** `PackageInfo.buildSignature`
  chỉ có trên Android; trên iOS nó rỗng nên `validSignature()` luôn `false`, và
  `BillingRepository` coi đó là lỗi. Giờ nền tảng không có chữ ký gói cài thì bỏ
  qua bước kiểm tra.
- **Không đăng ký `SignatureChecker` là app nổ.** Bản cũ gọi thẳng
  `appInject<SignatureChecker>()` trong listener của `purchaseStream`; GetIt ném
  lỗi ở chỗ không ai bắt và màn thanh toán treo im. Giờ không đăng ký = bỏ qua.
- **`PurchaseStatus.pending` bị báo là lỗi.** Ask-to-Buy / thẻ cần xác thực thêm
  không phải hỏng. Giờ phát `PurchaseResponse.pending`.
- **`PurchaseStatus.canceled` không có nhánh nào xử lý** → UI kẹt spinner vĩnh
  viễn khi người dùng bấm huỷ. Thêm `PurState.cancelled`.
- **Một product id chưa duyệt xong là mất sạch catalog.** `notFoundIDs.isNotEmpty`
  từng ném đi toàn bộ gói; giờ giữ những gói store trả về được.
- **Lượt `purchaseStream` phát `[]` xoá quyền Premium vô điều kiện.** Giờ chỉ xoá
  khi nó đến ngay sau một lượt `restorePurchases()`.
- **Lỗi gọi store bị nuốt.** Thêm `loadProducts()` chờ được, ném
  `BillingUnavailable` để màn paywall chọn được giữa trạng thái rỗng và lỗi.
- `PurchaseResponse.error` mang thêm `errorCode` / `errorMessage` của store.
- Thêm `restorePurchases()` vào API công khai (App Store bắt buộc có nút này).
- `int.parse(transactionDate)` → `int.tryParse` có giá trị dự phòng; sort giá
  dùng `compareTo` thay vì so sánh `>` (giá bằng nhau trả về thứ tự không ổn định).
- `_consumePurchase` (private, chưa dùng bao giờ) → `consumePurchase` công khai.

## 0.0.1

* Bản đầu.
