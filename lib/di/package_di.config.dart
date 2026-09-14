// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:flutter_billing/billing/billing_helper.dart' as _i215;
import 'package:flutter_billing/billing/billing_repository.dart' as _i241;
import 'package:flutter_core/core.dart' as _i842;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.singleton<_i241.BillingRepository>(
      () => _i241.BillingRepository_Impl(
        gh<_i842.PremiumHolder>(),
        gh<_i215.BillingRequestProvider>(),
      ),
      dispose: (i) => i.dispose(),
    );
    return this;
  }
}
