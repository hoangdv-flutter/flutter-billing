import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_billing_platform_interface.dart';

/// An implementation of [FlutterBillingPlatform] that uses method channels.
class MethodChannelFlutterBilling extends FlutterBillingPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_billing');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
