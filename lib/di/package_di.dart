import 'package:flutter_billing/di/package_di.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

@InjectableInit()
Future<void> setupDI(GetIt instance) async => instance.init();
