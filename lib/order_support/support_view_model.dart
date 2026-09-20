import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

import 'support_errors.dart';
import 'jev_genui_provider.dart';
import 'jev_ui_selector.dart';
import 'orders.dart';
import 'support_catalog.dart';

class SupportEntry {
  const SupportEntry(this.text, {this.user = false, this.surfaceId});
  final String text;
  final bool user;
  final String? surfaceId;
}

class SupportViewModel extends ChangeNotifier {
  SupportViewModel({JevUiSelector? selector}) {
    controller = SurfaceController(catalogs: [supportCatalog(orders)]);
    provider = JevGenUiProvider(
      orders: orders,
      apiKey: () => apiKey,
      selector: selector,
      onRequest: (text) {
        error = null;
        entries.add(SupportEntry(text, user: true));
        notifyListeners();
      },
      onSelection: (id, title) {
        entries.add(SupportEntry(title, surfaceId: id));
        notifyListeners();
      },
    );
    conversation = Conversation(
      controller: controller,
      transport: provider.transport,
    );
    conversation.state.addListener(_changed);
    _events = conversation.events.listen((event) {
      if (event is ConversationError) {
        error = apiKey.trim().isEmpty
            ? 'Add your Jev API key to continue.'
            : friendlyError(event.error);
        notifyListeners();
      }
    });
  }
  final orders = OrderRepository();
  final entries = <SupportEntry>[];
  late final SurfaceController controller;
  late final JevGenUiProvider provider;
  late final Conversation conversation;
  late final StreamSubscription<ConversationEvent> _events;
  String apiKey = '';
  String? error;
  bool get busy => conversation.state.value.isWaiting;
  void _changed() => notifyListeners();

  Future<void> send(String text) async {
    if (busy || text.trim().isEmpty) return;
    if (apiKey.trim().isEmpty) {
      error = 'Add your Jev API key to continue.';
      notifyListeners();
      return;
    }
    error = null;
    await conversation.sendRequest(ChatMessage.user(text.trim()));
  }

  @override
  void dispose() {
    _events.cancel();
    conversation.state.removeListener(_changed);
    conversation.dispose();
    provider.dispose();
    controller.dispose();
    orders.dispose();
    apiKey = '';
    super.dispose();
  }
}
