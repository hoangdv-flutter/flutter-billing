import 'package:package_info_plus/package_info_plus.dart';

abstract class SignatureChecker {
  final PackageInfo packageInfo;

  List<String> get acceptSignature;

  SignatureChecker(this.packageInfo);

  bool validSignature() =>
      acceptSignature.contains(packageInfo.buildSignature);
}
