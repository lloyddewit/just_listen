import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/material.dart';

// Option: Lift state to ActivityScreen (StatefulWidget)
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final List<_Message> _messages = [_Message('Question1?', isUser: false)];
  final _scrollController = ScrollController();

  void _addMessage(String msg) {
    setState(() => _messages.add(_Message(msg, isUser: true)));
    _messages.add(_Message('Echo: $msg', isUser: false));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) => BubbleSpecialOne(
                  tail: true,
                  text: _messages[index].text,
                  isSender: _messages[index].isUser,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _UserResponse(onSubmit: _addMessage),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;

  _Message(this.text, {this.isUser = true});
}

class _UserResponse extends StatefulWidget {
  const _UserResponse({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<_UserResponse> createState() => _UserResponseState();
}

class _UserResponseState extends State<_UserResponse> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSubmit(text);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: const InputDecoration(hintText: 'Type something...'),
            onSubmitted: (_) => _submit(),
          ),
        ),
        IconButton(icon: const Icon(Icons.send), onPressed: _submit),
      ],
    );
  }
}
