import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:genui/genui.dart';

import 'jev_ui_selector.dart';
import 'orders.dart';

/// Bridges Jev's constrained choices into GenUI A2UI surface messages.
class JevGenUiProvider {
  JevGenUiProvider({
    required this.orders,
    required this.apiKey,
    required this.onRequest,
    required this.onSelection,
    JevUiSelector? selector,
  }) : selector = selector ?? JevUiSelector() {
    transport = A2uiTransportAdapter(onSend: _send);
  }
  final OrderRepository orders;
  final String Function() apiKey;
  final void Function(String) onRequest;
  final void Function(String, String) onSelection;
  final JevUiSelector selector;
  late final A2uiTransportAdapter transport;
  final history = <Map<String, String>>[];
  String? selectedOrder;
  bool _busy = false, _disposed = false;
  int _sequence = 0;

  Future<void> _send(ChatMessage message) async {
    if (_busy || _disposed) return;
    _busy = true;
    try {
      var prompt = message.text;
      for (final part in message.parts.uiInteractionParts) {
        final payload = jsonDecode(part.interaction) as Map<String, dynamic>;
        final action = payload['action'];
        // Engine errors must not recursively trigger model requests.
        if (action is! Map) {
          throw const FormatException('GenUI could not render this screen');
        }
        final context = Map<String, dynamic>.from(
          action['context'] as Map? ?? {},
        );
        final id = context['orderId'] as String?;
        if (orders.find(id) == null) {
          throw const FormatException('Unknown order');
        }
        if (action['name'] == 'submit_return') {
          final reason = context['reason'] as String? ?? '';
          final reference = orders.submitReturn(id!, reason);
          onRequest('Submit demo return for #$id: $reason');
          _emit('ReturnConfirmation', id, 'Demo return saved', {
            'reference': reference,
          });
          return;
        }
        final intent = switch (action['name']) {
          'view_order' => 'Show details',
          'track_order' => 'Track delivery',
          'return_order' => 'Start a return',
          _ => throw const FormatException('Unknown action'),
        };
        selectedOrder = id;
        prompt = '$intent for order #$id';
      }
      if (apiKey().trim().isEmpty) throw StateError('missing-api-key');
      onRequest(prompt);
      final selection = await selector.select(
        apiKey: apiKey().trim(),
        prompt: prompt,
        history: List.of(history),
        orders: orders,
        selectedOrder: selectedOrder,
      );
      if (_disposed) return;
      selectedOrder = selection.orderId;
      history.addAll([
        {'role': 'user', 'content': prompt},
        {
          'role': 'assistant',
          'content': '${selection.ui.name}: ${selection.orderId ?? 'none'}',
        },
      ]);
      _emit(selection.ui.component, selection.orderId, selection.ui.title, {});
    } finally {
      _busy = false;
    }
  }

  void _emit(
    String component,
    String? orderId,
    String title,
    Map<String, dynamic> extra,
  ) {
    if (_disposed) return;
    final id = 'support-${++_sequence}';
    transport.addMessage(
      a2ui.CreateSurfaceMessage(surfaceId: id, catalogId: orderCatalogId),
    );
    transport.addMessage(
      a2ui.UpdateComponentsMessage(
        surfaceId: id,
        components: [
          {
            'id': 'root',
            'component': component,
            'orderId': orderId ?? '',
            ...extra,
          },
        ],
      ),
    );
    onSelection(id, title);
  }

  void dispose() {
    _disposed = true;
    transport.dispose();
  }
}
