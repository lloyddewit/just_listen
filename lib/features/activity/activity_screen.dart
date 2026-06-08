import 'dart:math';

import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';

// Option: Lift state to ActivityScreen (StatefulWidget)
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final List<_Message> _messages = [
    _Message(text: 'Question1?', isUser: false),
  ];
  final ScrollController _scrollController = ScrollController();
  final CountDownController _countDownController = CountDownController();
  bool _isWaiting = true;

  void _addMessage(String msg) {
    setState(() {
      _messages.add(_Message(text: msg, isUser: true));
      _messages.add(_Message(text: 'Echo: $msg', isUser: false));
    });
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

  void restartTimer() {
    setState(() {
      _isWaiting = !_isWaiting;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _countDownController.restart(duration: _isWaiting ? 3 : 10);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double timerSize = max(48, MediaQuery.of(context).size.width / 14);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Activity'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 8,
                  ),
                  child: BubbleSpecialOne(
                    tail: true,
                    text: _messages[index].text,
                    isSender: _messages[index].isUser,
                    color: _messages[index].isUser
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: CircularCountDownTimer(
                  duration: _isWaiting ? 3 : 10,
                  controller: _countDownController,
                  width: timerSize,
                  height: timerSize,
                  ringColor: Theme.of(context).colorScheme.secondaryContainer,
                  fillColor: Theme.of(context).colorScheme.onSecondaryContainer,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  strokeWidth: 7.0,
                  strokeCap: StrokeCap.round,
                  textStyle: TextStyle(
                    fontSize: 32.0,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  textFormat: CountdownTextFormat.S,
                  isReverse: true,
                  isReverseAnimation: true,
                  isTimerTextShown: true,
                  autoStart: true,
                  onComplete: () {
                    restartTimer();
                  },
                ),
              ),
            ),
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),

                child: _isWaiting
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        onPressed: () {
                          restartTimer();
                        },
                        child: const Text('Start talking now'),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          shape: CircleBorder(),
                        ),
                        onPressed: () {
                          restartTimer();
                        },
                        child: const Icon(Icons.stop, size: 32.0),
                      ),
              ),
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

  const _Message({required this.text, this.isUser = true});
}

class _UserResponse extends StatefulWidget {
  const _UserResponse({required this.onSubmit, required this.restartTimer});

  final ValueChanged<String> onSubmit;
  final VoidCallback restartTimer;

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
      widget.restartTimer();
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
