import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_billing/flutter_billing.dart';
import 'package:flutter_billing/flutter_billing_platform_interface.dart';
import 'package:flutter_billing/flutter_billing_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterBillingPlatform
    with MockPlatformInterfaceMixin
    implements FlutterBillingPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterBillingPlatform initialPlatform = FlutterBillingPlatform.instance;

  test('$MethodChannelFlutterBilling is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterBilling>());
  });

  test('getPlatformVersion', () async {
    FlutterBilling flutterBillingPlugin = FlutterBilling();
    MockFlutterBillingPlatform fakePlatform = MockFlutterBillingPlatform();
    FlutterBillingPlatform.instance = fakePlatform;

    expect(await flutterBillingPlugin.getPlatformVersion(), '42');
  });
}
