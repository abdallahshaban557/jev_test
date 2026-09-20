import 'package:flutter/material.dart';

import 'choice_service.dart';

void main() => runApp(const JevApp());

class JevApp extends StatelessWidget {
  const JevApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Jev Choices',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff6554c0)),
      scaffoldBackgroundColor: const Color(0xfff7f7fb),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
    home: const ChatPage(),
  );
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.service});
  final ChoiceService? service;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _key = TextEditingController();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <({bool user, String text, ServiceOption? option})>[];
  late final _service = widget.service ?? ChoiceService();
  bool _busy = false;
  String? _error;
  String? _retryPrompt;

  @override
  void dispose() {
    _key.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  });

  Future<void> _send([String? retry]) async {
    final prompt = (retry ?? _input.text).trim();
    if (_busy || prompt.isEmpty) return;
    if (_key.text.trim().isEmpty) {
      setState(() => _error = 'Add your Jev API key to start chatting.');
      return;
    }
    final history = _messages
        .map((m) => {'role': m.user ? 'user' : 'assistant', 'content': m.text})
        .toList();
    setState(() {
      _busy = true;
      _error = null;
      _retryPrompt = null;
      if (retry == null) {
        _messages.add((user: true, text: prompt, option: null));
        _input.clear();
      }
    });
    _scrollDown();
    try {
      final option = await _service.select(
        apiKey: _key.text.trim(),
        prompt: prompt,
        history: history,
      );
      if (!mounted) return;
      setState(
        () => _messages.add((
          user: false,
          text: 'Select ${option.label}.',
          option: option,
        )),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(error);
        _retryPrompt = prompt;
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _scrollDown();
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'jev / choices',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      actions: [
        TextButton.icon(
          onPressed: _busy
              ? null
              : () => setState(() {
                  _messages.clear();
                  _error = null;
                  _retryPrompt = null;
                }),
          icon: const Icon(Icons.add),
          label: const Text('New chat'),
        ),
        const SizedBox(width: 12),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _key,
                      obscureText: true,
                      enabled: !_busy,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'Jev API key',
                        prefixIcon: Icon(Icons.key_outlined),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Local prototype · Key stays in memory. The local server forwards it to Jev.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _messages.isEmpty
                    ? _welcome()
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(20),
                        itemCount: _messages.length + (_busy ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Jev is choosing…'),
                                ],
                              ),
                            );
                          }
                          final m = _messages[index];
                          return Align(
                            alignment: m.user
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 560),
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: m.user
                                    ? const Color(0xffeae5fc)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xffe8e5ef),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.user ? 'YOU' : 'JEV',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    m.text,
                                    style: TextStyle(
                                      fontSize: m.user ? 16 : 22,
                                      fontWeight: m.user
                                          ? FontWeight.normal
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  if (m.option != null) ...[
                                    const SizedBox(height: 12),
                                    Chip(label: Text(m.option!.category)),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Returned choice: ${m.option!.name}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      if (_retryPrompt != null)
                        TextButton(
                          onPressed: _busy ? null : () => _send(_retryPrompt),
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _input,
                      enabled: !_busy,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'What are you trying to do?',
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(6),
                          child: IconButton.filled(
                            tooltip: 'Ask Jev',
                            onPressed: _busy ? null : () => _send(),
                            icon: const Icon(Icons.arrow_upward),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Jev picks the closest of three options. No service actions are performed.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
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

  Widget _welcome() => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const SizedBox(height: 30),
        const Icon(Icons.auto_awesome, size: 42, color: Color(0xff6554c0)),
        const SizedBox(height: 18),
        const Text(
          'One question. The right choice.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        const Text(
          'Describe what you need. Jev will select the best matching service.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: ServiceOption.values
              .map((s) => Chip(label: Text('${s.label} · ${s.category}')))
              .toList(),
        ),
        const SizedBox(height: 28),
        for (final example in [
          'How can I accept a subscription payment?',
          'Where can I see which features people use?',
          'I need to add sign-in to my app.',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              onPressed: () {
                _input.text = example;
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(example),
              ),
            ),
          ),
      ],
    ),
  );
}
