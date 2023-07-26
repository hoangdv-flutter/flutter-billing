import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

@singleton
class SignatureChecker {
  SignatureChecker(this.packageInfo);

  final PackageInfo packageInfo;

  static const _acceptedSignature = [
    "9EE1999345B1040C879F0BDB22A7C356BBC5A973",
    "25E599C439685229E2E3220BE142991E1F02193A",
    "80C40A3042E4ED9F2A0DFCCD2CD79F688833E65D" /*Hoang's computer debug*/
  ];

  bool validSignature() =>
      _acceptedSignature.contains(packageInfo.buildSignature);
}
