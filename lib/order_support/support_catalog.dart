import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'orders.dart';

const ink = Color(0xff173d35);

Catalog supportCatalog(OrderRepository orders) => Catalog([
  for (final name in [
    ...SupportUi.values.map((e) => e.component),
    'ReturnConfirmation',
  ])
    CatalogItem(
      name: name,
      dataSchema: S.object(
        properties: {'orderId': S.string(), 'reference': S.string()},
        required: ['orderId'],
      ),
      widgetBuilder: (context) =>
          SupportCard(type: name, itemContext: context, orders: orders),
    ),
], catalogId: orderCatalogId);

class SupportCard extends StatefulWidget {
  const SupportCard({
    super.key,
    required this.type,
    required this.itemContext,
    required this.orders,
  });
  final String type;
  final CatalogItemContext itemContext;
  final OrderRepository orders;
  @override
  State<SupportCard> createState() => _SupportCardState();
}

class _SupportCardState extends State<SupportCard> {
  String? _reason;
  bool _confirmed = false;
  void _action(
    String name,
    DemoOrder order, [
    Map<String, Object?> extra = const {},
  ]) {
    widget.itemContext.dispatchEvent(
      UserActionEvent(
        name: name,
        sourceComponentId: widget.itemContext.id,
        context: {'orderId': order.id, ...extra},
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.orders,
    builder: (context, _) {
      final data = widget.itemContext.data as Map;
      final order = widget.orders.find(data['orderId'] as String?);
      final type = widget.type;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffdde5df)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type == 'ReturnConfirmation') ...[
              const Icon(Icons.check_circle, color: ink, size: 38),
              const SizedBox(height: 12),
              _title('Demo return saved'),
              Text('Reference ${data['reference']}'),
              const SizedBox(height: 12),
              const Text(
                'Your sample return is recorded for this session. No real refund, shipping label, or return has been created.',
              ),
            ] else if (type == 'ReturnPolicy') ...[
              _title('A little more peace of mind.'),
              const Text(
                'DEMO RETURN POLICY',
                style: TextStyle(fontSize: 11, letterSpacing: 1.5),
              ),
              const SizedBox(height: 16),
              _line(
                Icons.calendar_month_outlined,
                '30 days from delivery',
                'Items must be unused and in their original packaging.',
              ),
              _line(
                Icons.local_shipping_outlined,
                'Delivered items only',
                'Orders still in transit cannot be returned yet.',
              ),
              _line(
                Icons.credit_card_outlined,
                'Original payment method',
                'Sample policy: allow 5–7 business days after inspection.',
              ),
            ] else if (type == 'SupportHelp') ...[
              _title('Let’s find the right next step.'),
              const Text(
                'I can help with your orders, deliveries, and returns. Mention an order number or choose an order below.',
              ),
              ...widget.orders.orders.map((o) => _orderTile(o, 'view_order')),
            ] else if (type == 'OrderList' || order == null) ...[
              _title(
                type == 'OrderList'
                    ? 'Your recent orders'
                    : 'Which order is this about?',
              ),
              const Text('Choose a sample order to continue.'),
              ...widget.orders.orders.map(
                (o) => _orderTile(
                  o,
                  type == 'ReturnForm'
                      ? 'return_order'
                      : type == 'TrackingCard'
                      ? 'track_order'
                      : 'view_order',
                ),
              ),
            ] else ...[
              _product(order),
              const Divider(height: 32),
              if (type == 'ReturnForm') ...[
                _title('Let’s make this right.'),
                if (widget.orders.returnReference(order.id) != null)
                  Text(
                    'Demo return already saved: ${widget.orders.returnReference(order.id)}',
                  )
                else if (!order.returnable)
                  Text(
                    order.delivered
                        ? 'This sample order is outside the 30-day return window.'
                        : 'This order is still in transit. A return can start after delivery.',
                  )
                else ...[
                  Text(
                    'Eligible for a return · Delivered ${order.daysSinceDelivery} days ago',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _reason,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Reason for return',
                    ),
                    items: returnReasons
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (value) => setState(() => _reason = value),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _confirmed,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'I understand this saves a demo return only.',
                      ),
                      onChanged: (value) =>
                          setState(() => _confirmed = value ?? false),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _reason != null && _confirmed
                          ? () => _action('submit_return', order, {
                              'reason': _reason,
                            })
                          : null,
                      icon: const Icon(Icons.keyboard_return),
                      label: const Text('Submit demo return'),
                    ),
                  ),
                ],
              ] else if (type == 'TrackingCard') ...[
                _title(
                  order.delivered
                      ? 'Your order has arrived.'
                      : 'Your order is on its way.',
                ),
                _line(
                  Icons.check_circle_outline,
                  'Order confirmed',
                  'We received your sample order.',
                ),
                _line(
                  Icons.inventory_2_outlined,
                  'Packed and shipped',
                  'Your items have left the warehouse.',
                ),
                _line(
                  order.delivered
                      ? Icons.home_outlined
                      : Icons.local_shipping_outlined,
                  order.delivered ? 'Delivered' : 'In transit',
                  order.delivered
                      ? 'Delivered ${order.daysSinceDelivery} days ago.'
                      : 'Demo estimate: arrives in 2 days.',
                ),
              ] else ...[
                _title('Everything in one place.'),
                Text(
                  'Order #${order.id} · ${order.delivered ? 'Delivered' : 'In transit'}',
                ),
                const SizedBox(height: 10),
                Text('Total paid: \$${order.price}.00'),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _action('track_order', order),
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Track order'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _action('return_order', order),
                      icon: const Icon(Icons.keyboard_return),
                      label: const Text('Start a return'),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      );
    },
  );

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
  );

  Widget _product(DemoOrder order) => Row(
    children: [
      Container(
        width: 64,
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xffeef1e9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          order.id == '1043' ? Icons.headphones : Icons.shopping_bag_outlined,
          size: 32,
          color: ink,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.item,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            Text(order.variant),
            Text('Order #${order.id} · \$${order.price}.00'),
          ],
        ),
      ),
    ],
  );

  Widget _orderTile(DemoOrder order, String action) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _action(action, order),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(child: _product(order)),
            const Icon(Icons.chevron_right, color: ink),
          ],
        ),
      ),
    ),
  );

  Widget _line(IconData icon, String title, String subtitle) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ink),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(subtitle),
            ],
          ),
        ),
      ],
    ),
  );
}
