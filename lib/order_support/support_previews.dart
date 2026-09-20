import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:genui/genui.dart';

import '../support_theme.dart';
import 'orders.dart';
import 'support_page.dart';
import 'support_view_model.dart';

// Every preview owns its repository and controller. No Jev requests or keys
// are needed. Button actions use the same local flow as the running app.
final class OrderCardPreview extends MultiPreview {
  const OrderCardPreview(this.label);
  final String label;

  @override
  List<Preview> get previews => [
    Preview(
      name: '$label / desktop',
      group: 'Order widgets',
      size: const Size(560, 760),
    ),
    Preview(
      name: '$label / phone',
      group: 'Order widgets',
      size: const Size(390, 760),
    ),
  ];
}

@OrderCardPreview('Order list')
Widget orderListPreview() => const _CardPreview('OrderList');

@OrderCardPreview('Order details')
Widget orderDetailsPreview() => const _CardPreview('OrderDetails');

@OrderCardPreview('Tracking')
Widget trackingPreview() => const _CardPreview('TrackingCard');

@OrderCardPreview('Return form')
Widget returnFormPreview() => const _CardPreview('ReturnForm');

@OrderCardPreview('Return / choose an order')
Widget returnChooserPreview() => const _CardPreview('ReturnForm', orderId: '');

@OrderCardPreview('Return / already saved')
Widget savedReturnPreview() =>
    const _CardPreview('ReturnForm', savedReturn: true);

@OrderCardPreview('Return policy')
Widget returnPolicyPreview() => const _CardPreview('ReturnPolicy');

@OrderCardPreview('Support help')
Widget supportHelpPreview() => const _CardPreview('SupportHelp');

@OrderCardPreview('Return confirmation')
Widget returnConfirmationPreview() =>
    const _CardPreview('ReturnConfirmation', savedReturn: true);

@Preview(name: 'Chat / desktop', group: 'Full page', size: Size(1100, 850))
@Preview(name: 'Chat / phone', group: 'Full page', size: Size(390, 844))
Widget supportPagePreview() => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: supportTheme(),
  home: const OrderSupportPage(),
);

class _CardPreview extends StatefulWidget {
  const _CardPreview(
    this.component, {
    this.orderId = '1042',
    this.savedReturn = false,
  });
  final String component;
  final String orderId;
  final bool savedReturn;

  @override
  State<_CardPreview> createState() => _CardPreviewState();
}

class _CardPreviewState extends State<_CardPreview> {
  late final SupportViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = SupportViewModel();
    final reference = widget.savedReturn
        ? vm.orders.submitReturn(widget.orderId, returnReasons.first)
        : '';
    vm.controller.handleMessage(
      a2ui.CreateSurfaceMessage(
        surfaceId: 'preview',
        catalogId: orderCatalogId,
      ),
    );
    vm.controller.handleMessage(
      a2ui.UpdateComponentsMessage(
        surfaceId: 'preview',
        components: [
          {
            'id': 'root',
            'component': widget.component,
            'orderId': widget.orderId,
            'reference': reference,
          },
        ],
      ),
    );
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: supportTheme(),
    home: Scaffold(
      backgroundColor: const Color(0xfff5f4ef),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ListenableBuilder(
          listenable: vm,
          builder: (context, _) {
            final id =
                vm.entries
                    .where((e) => e.surfaceId != null)
                    .lastOrNull
                    ?.surfaceId ??
                'preview';
            return Surface(
              key: ValueKey(id),
              surfaceContext: vm.controller.contextFor(id),
            );
          },
        ),
      ),
    ),
  );
}
