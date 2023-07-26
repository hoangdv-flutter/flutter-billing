
import 'flutter_billing_platform_interface.dart';

class FlutterBilling {
  Future<String?> getPlatformVersion() {
    return FlutterBillingPlatform.instance.getPlatformVersion();
  }
}
