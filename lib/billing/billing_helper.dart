import 'package:flutter_billing/billing/billing_request.dart';

class BillingRequestProvider {
  final List<BillingRequest> billingRequest;

  late final allProducts = billingRequest.map((e) => e.id).toSet();

  late final productRequestMap = {for (var e in billingRequest) e.id: e};

  BillingRequestProvider(this.billingRequest);
}
