import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Chặn app bị mod/repack: so chữ ký APK đang chạy với danh sách chữ ký hợp lệ.
///
/// ## Chỉ có tác dụng trên Android
/// `PackageInfo.buildSignature` là **thuộc tính riêng của Android**; trên iOS nó
/// luôn là chuỗi rỗng. Bản 0.0.1 vẫn đem chuỗi rỗng đi so → trên iOS
/// [validSignature] **luôn trả `false`**, và vì [BillingRepository] coi chữ ký
/// sai là lỗi nên **mọi giao dịch iOS đều bị đánh trượt**. Từ 0.1.0, nền tảng
/// nào không có khái niệm chữ ký APK thì bỏ qua bước này.
///
/// iOS không cần: app chỉ cài được qua App Store và đã được Apple ký; việc xác
/// minh giao dịch là chuyện của receipt/JWS, không phải chữ ký gói cài.
///
/// ## Cách dùng
/// Lớp này **không tự đăng ký DI**. App tự kế thừa, khai `acceptSignature`, rồi
/// đăng ký vào GetIt. Không đăng ký cũng được — [BillingRepository] bỏ qua kiểm
/// tra thay vì ném lỗi.
abstract class SignatureChecker {
  final PackageInfo packageInfo;

  List<String> get acceptSignature;

  SignatureChecker(this.packageInfo);

  /// Nền tảng không có chữ ký gói cài (iOS/macOS/web/desktop) → luôn hợp lệ.
  static bool get _platformHasSignature => Platform.isAndroid;

  bool validSignature() {
    if (!_platformHasSignature) return true;
    return acceptSignature.contains(encrypt(packageInfo.buildSignature));
  }

  late final iv = IV.fromLength(8);

  late final encrypter = createEncrypter();

  String encrypt(String data) {
    return encrypter.encrypt(data, iv: iv).base64;
  }

  String decrypt(String data) {
    return encrypter.decrypt64(data, iv: iv);
  }

  Encrypter createEncrypter() {
    final key = Key.fromLength(32);
    final encrypter = Encrypter(Salsa20(key));
    return encrypter;
  }
}
