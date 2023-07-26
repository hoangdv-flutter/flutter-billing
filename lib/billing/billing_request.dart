class BillingRequest {
  final String id;
  final String label;
  final int premiumDay;

  final int saleOff;

  BillingRequest(this.id, this.label, this.premiumDay, {this.saleOff = 0});
}
