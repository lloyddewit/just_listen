import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:timer_widget/timer_widget.dart';

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
  bool _showCircularTimer = true;

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
      _showCircularTimer = true;
    });
    try {
      _countDownController.restart();
    } catch (_) {
      // ignore: avoid_print
      print('CountDownController.restart() failed or not available');
    }
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
            if (_showCircularTimer)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircularCountDownTimer(
                      duration: 3,
                      initialDuration: 0,
                      controller: _countDownController,
                      width: MediaQuery.of(context).size.width / 14,
                      height: MediaQuery.of(context).size.height / 14,
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
                        fontSize: 18.0,
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
                        setState(() => _showCircularTimer = false);
                      },
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        _countDownController.pause();
                        setState(() => _showCircularTimer = false);
                      },
                      child: const Text('Start now'),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _UserResponse(
                onSubmit: _addMessage,
                restartTimer: restartTimer,
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
      try {
        widget.restartTimer();
      } catch (_) {
        // ignore: avoid_print
        print('restartTimer callback failed');
      }
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
