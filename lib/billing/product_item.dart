import 'package:in_app_purchase/in_app_purchase.dart';

class ProductItem {
  final String label;
  int? saleOff;
  final ProductDetails productDetail;

  ProductItem({
    required this.label,
    this.saleOff,
    required this.productDetail,
  });
}
