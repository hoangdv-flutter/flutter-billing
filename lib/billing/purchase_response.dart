class PurchaseResponse {
  final PurState purchaseStatus;

  final String productID;

  PurchaseResponse.error(this.productID) : purchaseStatus = PurState.error;

  PurchaseResponse.purchased(this.productID)
      : purchaseStatus = PurState.purchased;

  PurchaseResponse.pending(this.productID) : purchaseStatus = PurState.pending;

  PurchaseResponse({required this.purchaseStatus, required this.productID});
}

enum PurState { pending, purchased, error }
