import 'dart:math';

import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:progress_bar_countdown/progress_bar_countdown.dart';

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
  final ProgressBarCountdownController _progressBarController =
      ProgressBarCountdownController();
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

  void _restartTimer() {
    setState(() {
      _isWaiting = !_isWaiting;
    });

    // Capture the duration at call time, not callback time (i.e. outside addPostFrameCallback)
    // See: https://github.com/lloyddewit/just_listen/pull/5 09/06/26 comment.
    final duration = _isWaiting ? 3 : 10;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _countDownController.restart(duration: duration);
      _progressBarController.reset(duration: Duration(seconds: duration));
      _progressBarController.start();
    });
  }

  void _toggleWaitSpeakMode(bool isWaiting) {
    if (!isWaiting) {
      _addMessage('User response.', true);
      _addMessage('Question?', false);
    }
    _restartTimer();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color progressBarLightColor = Theme.of(
      context,
    ).colorScheme.secondaryContainer;

    final hslColor = HSLColor.fromColor(progressBarLightColor);
    Color progressBarDarkColor = hslColor
        .withLightness((hslColor.lightness - .45).clamp(0.0, 1.0))
        .toColor();

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isWaiting
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..scaleByDouble(-1.0, 1.0, 1.0, 1.0),
                        child: const Icon(
                          Icons.psychology_outlined,
                          size: 24.0,
                        ),
                      )
                    : Icon(
                        Icons.record_voice_over,
                        size: 24.0,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                Text(
                  _isWaiting ? ' Get ready to speak ...' : '  Speak now!',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 9,
                bottom: 12.0,
                left: 12.0,
                right: 12.0,
              ),
              child: ProgressBarCountdown(
                hideText: true,
                initialDuration: Duration(seconds: _isWaiting ? 3 : 10),
                progressColor: _isWaiting
                    ? progressBarDarkColor
                    : progressBarLightColor,
                progressBackgroundColor: _isWaiting
                    ? progressBarLightColor
                    : progressBarDarkColor,
                initialTextColor: _isWaiting
                    ? progressBarLightColor
                    : progressBarDarkColor,
                revealedTextColor: _isWaiting
                    ? progressBarDarkColor
                    : progressBarLightColor,
                height: 8.0,
                countdownDirection: _isWaiting
                    ? ProgressBarCountdownAlignment.left
                    : ProgressBarCountdownAlignment.right,
                controller: _progressBarController,
                autoStart: true,
                onComplete: () {
                  _toggleWaitSpeakMode(_isWaiting);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 9, bottom: 12.0),
              child: CircularCountDownTimer(
                duration: _isWaiting ? 3 : 10,
                controller: _countDownController,
                width: 48,
                height: 48,
                ringColor: Theme.of(context).colorScheme.secondaryContainer,
                fillColor: Theme.of(context).colorScheme.onSecondaryContainer,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
                  // _toggleWaitSpeakMode(_isWaiting);
                },
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isWaiting
                    ? Colors.green.shade800
                    : Colors.red.shade800,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: const Size(62, 62),
                shape: const CircleBorder(),
              ),
              onPressed: () {
                _toggleWaitSpeakMode(_isWaiting);
              },
              child: _isWaiting
                  ? const Icon(Icons.arrow_right, size: 40.0)
                  : const Icon(Icons.stop, size: 32.0),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                _isWaiting ? 'Start now' : 'Stop now',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
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
