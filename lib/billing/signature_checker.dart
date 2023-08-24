import 'package:encrypt/encrypt.dart';
import 'package:package_info_plus/package_info_plus.dart';

abstract class SignatureChecker {
  final PackageInfo packageInfo;

  List<String> get acceptSignature;

  SignatureChecker(this.packageInfo) {
    for (var sign in acceptSignature) {
      final decrypted = decrypt(sign);
      final encrypted = encrypt(decrypted);
      print("encrypted: $encrypted");
      print("decrypted: $decrypted");
    }
  }

  bool validSignature() =>
      acceptSignature.contains(encrypt(packageInfo.buildSignature));

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
