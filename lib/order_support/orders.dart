import 'package:flutter/foundation.dart';

class DemoOrder {
  const DemoOrder(
    this.id,
    this.item,
    this.variant,
    this.price,
    this.delivered,
    this.daysSinceDelivery,
  );
  final String id, item, variant;
  final int price;
  final bool delivered;
  final int daysSinceDelivery;
  bool get returnable => delivered && daysSinceDelivery <= 30;
  Map<String, Object> toJson() => {
    'id': id,
    'item': item,
    'price_usd': price,
    'status': delivered ? 'Delivered' : 'In transit',
    'return_eligible': returnable,
  };
}

class OrderRepository extends ChangeNotifier {
  final orders = const [
    DemoOrder('1042', 'Everyday backpack', 'Sand / 20L', 89, true, 8),
    DemoOrder('1043', 'Studio headphones', 'Forest / Wireless', 149, true, 3),
    DemoOrder('1031', 'Weekend tote', 'Ink / Large', 64, true, 12),
  ];
  final Map<String, String> _returns = {};
  DemoOrder? find(String? id) {
    for (final order in orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  String? returnReference(String id) => _returns[id];
  String submitReturn(String id, String reason) {
    final order = find(id);
    if (order == null || !order.returnable || !returnReasons.contains(reason)) {
      throw const FormatException('This demo return is not eligible.');
    }
    final reference = _returns.putIfAbsent(id, () => 'DEMO-RMA-$id');
    notifyListeners();
    return reference;
  }
}

const returnReasons = [
  'Wrong size or fit',
  'Item arrived damaged',
  'Not as expected',
  'Changed my mind',
];
const orderCatalogId = 'com.jev.order-support';

enum SupportUi {
  orderList('OrderList', 'Your orders'),
  orderDetails('OrderDetails', 'Order details'),
  tracking('TrackingCard', 'Delivery update'),
  returnForm('ReturnForm', 'Start a return'),
  returnPolicy('ReturnPolicy', 'Return policy'),
  supportHelp('SupportHelp', 'How can I help?');

  const SupportUi(this.component, this.title);
  final String component, title;
}

class UiSelection {
  const UiSelection(this.ui, this.orderId);
  final SupportUi ui;
  final String? orderId;
}
