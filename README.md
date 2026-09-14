# flutter_billing

Lớp mua hàng trong app (IAP) dùng chung cho các app Flutter của team. Bọc
[`in_app_purchase`](https://pub.dev/packages/in_app_purchase) lại thành một
repository + cubit, và nối quyền Premium vào `PremiumHolder` của `flutter_core`.

Không phải plugin native — mọi phần native do `in_app_purchase` lo.

## Cài

```yaml
dependencies:
  flutter_billing:
    path: packages/core/flutter_billing
```

## Nối vào app

1. **Khai danh sách gói** rồi đăng ký `BillingRequestProvider` **trước** khi gọi
   `setupDI` của package (nó là tham số của `BillingRepository_Impl`):

   ```dart
   getIt.registerSingleton(BillingRequestProvider([
     // id ở store, nhãn hiển thị, số ngày Premium (-1 = trọn đời)
     BillingRequest('app.premium.monthly', 'Hàng tháng', 30),
     BillingRequest('app.premium.annual', 'Hàng năm', 365, saleOff: 40),
   ]));
   await setupDI(getIt); // package_di.dart của flutter_billing
   ```

2. **(Tuỳ chọn, chỉ Android)** chống repack: kế thừa `SignatureChecker`, khai
   `acceptSignature`, đăng ký vào GetIt. Không đăng ký thì bước này được bỏ qua.

3. **Xác minh ở server** (bỏ qua nếu app không có BE): implement
   `PurchaseVerifier` và đăng ký vào GetIt. `BillingRepository` chờ nó trả lời
   trước khi công nhận quyền:

   ```dart
   class MyVerifier implements PurchaseVerifier {
     @override
     Future<VerifyResult> verify(PurchaseDetails p) async {
       try {
         await api.post('/billing/verify', data: {
           'platform': 'ios',
           'jws': p.verificationData.serverVerificationData,
         });
         return VerifyResult.granted;
       } on ServerSaysNo {
         return VerifyResult.rejected;    // chữ ký sai / product lạ — thử lại vô ích
       } catch (_) {
         return VerifyResult.unavailable; // mất mạng — giữ giao dịch, thử lại sau
       }
     }
   }
   ```

4. Dùng `BillingCubit` (hoặc `appInject<BillingRepository>()` trực tiếp):

   ```dart
   final products = await cubit.loadProducts();   // chờ được, ném BillingUnavailable
   cubit.buyProduct(products.first);
   cubit.purchaseResponse.listen(...);            // pending / purchased / cancelled / error
   await cubit.restorePurchases();                // nút bắt buộc theo luật App Store
   ```

## Hai kiểu đọc gói

| API | Dùng khi |
|---|---|
| `queryAllProducts()` + `productsStream` | Màn chỉ cần hiện gói, lỗi thì để trống |
| `loadProducts()` | Màn có trạng thái lỗi + nút "Thử lại" — hàm này **ném** `BillingUnavailable` |

`queryAllProducts()` chạy qua `executeSingleTask` của `flutter_core`, mà hàm đó
nuốt mọi exception; bên gọi không phân biệt được "store trả 0 gói" với "gọi store
hỏng". Cần phân biệt thì dùng `loadProducts()`.

## Cần biết trước khi lên iOS

- **Deployment target ≥ 15.0.** Từ `in_app_purchase_storekit` 0.4.0, StoreKit 2
  là mặc định ở mọi máy hỗ trợ. Muốn quay về StoreKit 1 thì gọi `enableStoreKit1`.
- **`SignatureChecker` không chạy trên iOS** — `PackageInfo.buildSignature` là
  thuộc tính riêng của Android, trên iOS luôn rỗng. Xem doc của lớp đó.
- **Phải `completePurchase`** mọi giao dịch (kể cả lỗi/huỷ), nếu không StoreKit
  phát lại nó mỗi lần mở app và Apple từ chối bản build. Repository đã làm sẵn.
- **Xác minh ở server**: `PurchaseResponse.serverVerificationData` là chuỗi JWS
  Apple ký, gửi nguyên văn lên BE mà verify. Đừng tin mỗi việc store báo
  "purchased", và đừng parse JWS ở client rồi tin nội dung — giá trị của nó nằm
  đúng ở chỗ chỉ server mới kiểm được chữ ký.

## Lịch sử

- **0.2.0** — `PurchaseResponse` lộ `serverVerificationData` (JWS) + hook
  `PurchaseVerifier` để xác minh với server **trước khi** đóng giao dịch.
- **0.1.0** — bỏ vỏ plugin native (ghim AGP 7.3 / compileSdk 31, làm vỡ build
  AGP 9); `in_app_purchase` 3.1.11 → 3.3.0; khai báo các dependency đang dùng
  chui; sửa loạt lỗi làm hỏng luồng mua trên iOS (xem `CHANGELOG.md`).
- **0.0.1** — bản đầu.
