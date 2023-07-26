import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_billing_method_channel.dart';

abstract class FlutterBillingPlatform extends PlatformInterface {
  /// Constructs a FlutterBillingPlatform.
  FlutterBillingPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterBillingPlatform _instance = MethodChannelFlutterBilling();

  /// The default instance of [FlutterBillingPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterBilling].
  static FlutterBillingPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterBillingPlatform] when
  /// they register themselves.
  static set instance(FlutterBillingPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
