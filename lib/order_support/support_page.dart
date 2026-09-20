import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import '../local_config.dart';

import 'support_view_model.dart';
import 'support_catalog.dart';

class OrderSupportPage extends StatefulWidget {
  const OrderSupportPage({super.key, this.viewModel});
  final SupportViewModel? viewModel;
  @override
  State<OrderSupportPage> createState() => _OrderSupportPageState();
}

class _OrderSupportPageState extends State<OrderSupportPage> {
  late SupportViewModel vm;
  final input = TextEditingController();
  final keyInput = TextEditingController(text: localJevApiKey);
  final scroll = ScrollController();
  bool showKey = false;
  @override
  void initState() {
    super.initState();
    vm = widget.viewModel ?? SupportViewModel();
    if (widget.viewModel == null) vm.apiKey = localJevApiKey;
    vm.addListener(_updated);
  }

  void _updated() {
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    vm.removeListener(_updated);
    if (widget.viewModel == null) vm.dispose();
    input.dispose();
    keyInput.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send([String? suggestion]) async {
    final text = suggestion ?? input.text;
    if (vm.apiKey.trim().isEmpty) setState(() => showKey = true);
    await vm.send(text);
    if (vm.error == null) input.clear();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff5f4ef),
    appBar: AppBar(
      backgroundColor: const Color(0xfff5f4ef),
      title: const Text(
        'KIN / care',
        style: TextStyle(
          color: ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Jev API key',
          onPressed: vm.busy ? null : () => setState(() => showKey = !showKey),
          icon: const Icon(Icons.key_outlined),
        ),
        IconButton(
          tooltip: 'New conversation',
          onPressed: vm.busy || widget.viewModel != null
              ? null
              : () {
                  vm.removeListener(_updated);
                  vm.dispose();
                  vm = SupportViewModel()..apiKey = keyInput.text;
                  vm.addListener(_updated);
                  setState(() {});
                },
          icon: const Icon(Icons.add_comment_outlined),
        ),
        const SizedBox(width: 12),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              if (showKey)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
                  child: TextField(
                    controller: keyInput,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    enabled: !vm.busy,
                    onChanged: (value) => vm.apiKey = value,
                    decoration: const InputDecoration(
                      labelText: 'Jev API key',
                      helperText: 'Kept in memory for this session.',
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: ink,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ORDER SUPPORT',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Chip(
                      label: Text(
                        'Sample orders',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (vm.entries.isEmpty) _welcome(),
                    for (final entry in vm.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: entry.user
                            ? Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 580,
                                  ),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: ink,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    entry.text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      entry.text,
                                      style: const TextStyle(
                                        color: ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  AbsorbPointer(
                                    absorbing: vm.busy,
                                    child: Surface(
                                      key: ValueKey(entry.surfaceId),
                                      surfaceContext: vm.controller.contextFor(
                                        entry.surfaceId!,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    if (vm.busy)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Finding the right next step…'),
                        ],
                      ),
                  ],
                ),
              ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    vm.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: input,
                      enabled: !vm.busy,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => send(),
                      decoration: InputDecoration(
                        hintText: 'Ask about an order, delivery, or return…',
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(5),
                          child: IconButton.filled(
                            tooltip: 'Send message',
                            style: IconButton.styleFrom(backgroundColor: ink),
                            onPressed: vm.busy ? null : () => send(),
                            icon: const Icon(Icons.arrow_upward),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Powered by Jev + GenUI · Demo actions only',
                      style: TextStyle(fontSize: 11, color: Color(0xff65746a)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _welcome() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 25),
      const Icon(Icons.spa_outlined, color: ink, size: 42),
      const SizedBox(height: 24),
      const Text(
        'Good things.\nGreat support.',
        style: TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w600,
          color: ink,
          height: 1.12,
          letterSpacing: -1.5,
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'From your doorstep to a fresh start.\nTell me what you need and I’ll bring the right tools to you.',
        style: TextStyle(fontSize: 17, height: 1.6, color: Color(0xff65746a)),
      ),
      const SizedBox(height: 28),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final prompt in [
            'Show my orders',
            'Return my backpack',
            'Where are my headphones?',
            'What is the return policy?',
          ])
            ActionChip(label: Text(prompt), onPressed: () => send(prompt)),
        ],
      ),
      const SizedBox(height: 28),
      const Text(
        'TRY AN ORDER',
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 2,
          color: Color(0xff65746a),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        '#1042  Everyday backpack · Delivered\n#1043  Studio headphones · Delivered\n#1031  Weekend tote · Delivered',
        style: TextStyle(height: 1.9, color: ink),
      ),
    ],
  );
}
