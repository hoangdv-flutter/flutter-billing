// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: unnecessary_lambdas
// ignore_for_file: lines_longer_than_80_chars
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_billing/billing/billing_helper.dart' as _i5;
import 'package:flutter_billing/billing/billing_repository.dart' as _i3;
import 'package:flutter_billing/billing/signature_checker.dart' as _i6;
import 'package:flutter_core/data/shared/premium_holder.dart' as _i4;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;
import 'package:package_info_plus/package_info_plus.dart' as _i7;

extension GetItInjectableX on _i1.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i1.GetIt init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.singleton<_i3.BillingRepository>(
      _i3.BillingRepository_Impl(
        gh<_i4.PremiumHolder>(),
        gh<_i5.BillingRequestProvider>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.singleton<_i6.SignatureChecker>(
        _i6.SignatureChecker(gh<_i7.PackageInfo>()));
    return this;
  }
}
