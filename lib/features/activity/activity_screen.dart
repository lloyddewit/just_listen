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

  void _addMessage(String msg, bool isUser) {
    setState(() {
      _messages.add(_Message(text: msg, isUser: isUser));
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

    // Capture the duration at call time, not callback time (i.e. outside addPostFrameCallback)
    // See: https://github.com/lloyddewit/just_listen/pull/5 09/06/26 comment.
    final duration = _isWaiting ? 3 : 10;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _countDownController.restart(duration: duration);
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
                  padding: const EdgeInsets.symmetric(vertical: 2),
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
              height: 96,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        _isWaiting ? 'Get ready to speak ...' : 'Speak now!',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    CircularCountDownTimer(
                      duration: _isWaiting ? 3 : 10,
                      controller: _countDownController,
                      width: 48,
                      height: 48,
                      ringColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.onSecondaryContainer,
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
                        if (!_isWaiting) {
                          _addMessage('User response.', true);
                          _addMessage('Question?', false);
                        }
                        restartTimer();
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 90,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isWaiting
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        minimumSize: const Size(62, 62),
                        shape: const CircleBorder(),
                      ),
                      onPressed: () {
                        if (!_isWaiting) {
                          _addMessage('User response.', true);
                          _addMessage('Question?', false);
                        }
                        restartTimer();
                      },
                      child: _isWaiting
                          ? const Icon(Icons.arrow_right, size: 40.0)
                          : const Icon(Icons.stop, size: 32.0),
                    ),
                    Text(
                      _isWaiting ? 'Start now' : 'Stop now',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
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
