import 'package:chat_bubbles/chat_bubbles.dart';
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
  final ProgressBarCountdownController _progressBarController =
      ProgressBarCountdownController();
  final ScrollController _scrollController = ScrollController();
  bool _isWaiting = true;

  @override
  Widget build(BuildContext context) {
    Color progressBarLightColor = Theme.of(
      context,
    ).colorScheme.secondaryContainer;

    final hslColor = HSLColor.fromColor(progressBarLightColor);
    Color progressBarDarkColor = hslColor
        .withLightness((hslColor.lightness - .45).clamp(0.0, 1.0))
        .toColor();

    Color startButtonColor = hslColor
        .withLightness((hslColor.lightness - .5).clamp(0.0, 1.0))
        .toColor();

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
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
            Text(
              _isWaiting ? ' Get ready to speak ...' : '  Speak now!',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 9,
                bottom: 12.0,
                left: 12.0,
                right: 12.0,
              ),
              child: ProgressBarCountdown(
                autoStart: true,
                controller: _progressBarController,
                countdownDirection: _isWaiting
                    ? ProgressBarCountdownAlignment.left
                    : ProgressBarCountdownAlignment.right,
                height: 8.0,
                hideText: true,
                initialDuration: Duration(seconds: _isWaiting ? 3 : 10),
                onComplete: () {
                  _toggleWaitSpeakMode(_isWaiting);
                },
                progressBackgroundColor: _isWaiting
                    ? progressBarLightColor
                    : progressBarDarkColor,
                progressColor: _isWaiting
                    ? progressBarDarkColor
                    : progressBarLightColor,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _toggleWaitSpeakMode(_isWaiting);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isWaiting
                    ? startButtonColor
                    : Colors.red.shade800,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: const Size(48, 48),
                shape: const CircleBorder(),
              ),
              child: _isWaiting
                  ? const Icon(Icons.arrow_right, size: 40.0)
                  : const Icon(Icons.stop, size: 28.0),
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

  @override
  void dispose() {
    _progressBarController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
}

class _Message {
  final String text;
  final bool isUser;

  const _Message({required this.text, this.isUser = true});
}
