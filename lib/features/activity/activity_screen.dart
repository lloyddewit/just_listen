import 'package:flutter/material.dart';

final GlobalKey<_MessageListState> _messagesKey =
    GlobalKey<_MessageListState>();

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _MessageList(key: _messagesKey)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _UserResponse(
                onSubmit: (newMessage) {
                  _messagesKey.currentState?.addMessageToList(newMessage);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageList extends StatefulWidget {
  const _MessageList({super.key});

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  final List<String> messageList = [];
  final ScrollController _scrollController = ScrollController();

  void addMessageToList(String newMessage) {
    setState(() => messageList.add(newMessage));

    // Wait until the frame is rendered, then scroll to the bottom.
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
    return ListView.builder(
      controller: _scrollController,
      itemCount: messageList.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(messageList[index]));
      },
    );
  }
}

class _UserResponse extends StatefulWidget {
  const _UserResponse({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  State<_UserResponse> createState() => _UserResponseState();
}

class _UserResponseState extends State<_UserResponse> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSubmit(text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Type something...'),
            onSubmitted: (_) => _submit(),
          ),
        ),
        IconButton(icon: const Icon(Icons.send), onPressed: _submit),
      ],
    );
  }
}
