import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:progress_bar_countdown/progress_bar_countdown.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

// Option: Lift state to ActivityScreen (StatefulWidget)
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  // Timing
  static const int _prepSeconds = 3;
  static const int _speakSeconds = 10;
  static const int _transcriptionTimeoutSeconds = 20;
  static const int _pollIntervalMs = 500;
  static const int _scrollAnimationMs = 250;

  // Layout
  static const double _progressBarHeight = 8.0;
  static const double _buttonSize = 48.0;
  static const double _iconSizeStart = 40.0;
  static const double _iconSizeStop = 28.0;

  String _audioFilePath = "";
  bool _isWaiting = true;
  bool _isToggling = false;

  final List<_Message> _messages = [
    _Message(text: 'Question1?', isUser: false),
  ];
  final ProgressBarCountdownController _progressBarController =
      ProgressBarCountdownController();
  final ScrollController _scrollController = ScrollController();

  // Recording config optimized for speech recognition
  final _recordConfig = RecordConfig(
    encoder: AudioEncoder.wav, // WAV or FLAC preferred by APIs
    sampleRate: 16000, // 16kHz is standard for speech APIs
    numChannels: 1, // Mono
    autoGain: true,
    echoCancel: true,
    noiseSuppress: true,
  );
  final AudioRecorder _recorder = AudioRecorder();

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
      appBar: AppBar(
        leading: BackButton(onPressed: () async => await _leaveScreen()),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) await _leaveScreen();
        },
        child: SafeArea(
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
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
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
                  height: _progressBarHeight,
                  hideText: true,
                  initialDuration: Duration(
                    seconds: _isWaiting ? _prepSeconds : _speakSeconds,
                  ),
                  onComplete: () async {
                    await _toggleWaitSpeakMode(_isWaiting);
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
                onPressed: _isToggling
                    ? null
                    : () async {
                        await _toggleWaitSpeakMode(_isWaiting);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isWaiting
                      ? startButtonColor
                      : Colors.red.shade800,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  minimumSize: const Size(_buttonSize, _buttonSize),
                  shape: const CircleBorder(),
                ),
                child: _isWaiting
                    ? const Icon(Icons.arrow_right, size: _iconSizeStart)
                    : const Icon(Icons.stop, size: _iconSizeStop),
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
      ),
    );
  }

  @override
  void dispose() {
    // Commented out because ProgressBarCountdownController does not implement dispose()
    //_progressBarController.dispose();

    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(String msg, bool isUser) {
    if (!mounted) return;
    setState(() {
      _messages.add(_Message(text: msg, isUser: isUser));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        unawaited(
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: _scrollAnimationMs),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  Future<void> _deleteFile(String path) async {
    if (path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) return;

    const maxDuration = Duration(seconds: _transcriptionTimeoutSeconds);
    const checkInterval = Duration(milliseconds: _pollIntervalMs);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxDuration) {
      try {
        await file.delete();
        return; // Success
      } on PathAccessException catch (_) {
        // File still locked, wait and retry
        await Future.delayed(checkInterval);
      }
    }

    // Timeout reached — log and continue
    debugPrint(
      'Failed to delete file after ${maxDuration.inSeconds} seconds: $path',
    );
  }

  Future<String> _getTempRecordingPath() async {
    if (kIsWeb) {
      // Web: return a placeholder or use memory-based approach
      throw UnsupportedError('File recording not supported on web');
    }

    final tempDir = await getTemporaryDirectory();
    return '${tempDir.path}/voice_recording_${Uuid().v4()}.wav';
  }

  Future<void> _leaveScreen() async {
    _progressBarController.pause();

    // Stop recording if still active
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    await _recorder.dispose();
    await _deleteFile(_audioFilePath);

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _restartTimer() {
    if (!mounted) return;
    setState(() {
      _isWaiting = !_isWaiting;
    });

    // Capture the duration at call time, not callback time (i.e. outside addPostFrameCallback)
    // See: https://github.com/lloyddewit/just_listen/pull/5 09/06/26 comment.
    final duration = _isWaiting ? _prepSeconds : _speakSeconds;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _progressBarController.reset(duration: Duration(seconds: duration));
      _progressBarController.start();
    });
  }

  Future<String?> _readTranscription(String storagePath) async {
    final transcriptionPath = '$storagePath.wav_transcription.txt';
    final transcriptionRef = FirebaseStorage.instance.ref(transcriptionPath);

    const maxDuration = Duration(seconds: _transcriptionTimeoutSeconds);
    const checkInterval = Duration(milliseconds: _pollIntervalMs);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxDuration) {
      try {
        final bytes = await transcriptionRef.getData();
        if (bytes != null) {
          final jsonString = utf8.decode(bytes);

          // Parse JSON and extract transcript - fail fast on parse/shape errors
          try {
            final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
            final results = jsonMap['results'] as List?;
            final first = results?.firstOrNull as Map<String, dynamic>?;
            final alternatives = first?['alternatives'] as List?;
            final String transcript =
                (alternatives?.firstOrNull?['transcript'] as String?) ??
                'No transcript found.';
            //todo: just for temp debugging, print the transcript to console
            debugPrint('Transcription result: $transcript');
            return transcript;
          } catch (parseError) {
            await _showErrorAndReturnToStartScreen(
              'Error transcribing text from recording: $parseError',
            );
            return null;
          }
        }
      } catch (e) {
        // File not available yet (e.g., not found), wait and retry
        await Future.delayed(checkInterval);
      }
    }

    debugPrint(
      'Warning: Transcription not available after ${maxDuration.inSeconds} seconds',
    );
    return null;
  }

  Future<void> _showErrorAndReturnToStartScreen(String message) async {
    if (!mounted) return;
    _progressBarController.pause();
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // force explicit confirmation
      builder: (dialogContext) => AlertDialog(
        title: const Text('Something went wrong'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _leaveScreen();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  //todo
  Future<void> _startRecording() async {
    if (!(await _recorder.hasPermission())) {
      await _showErrorAndReturnToStartScreen(
        'Microphone permission denied. Cannot start recording.',
      );
      return;
    }
    _audioFilePath = p.normalize(await _getTempRecordingPath());
    await _recorder.start(_recordConfig, path: _audioFilePath);
  }

  Future<String?> _stopRecording() async {
    final String? recordedPath = await _recorder.stop();
    if (recordedPath == null) {
      await _showErrorAndReturnToStartScreen(
        'Recording failed to stop properly. No file path returned.',
      );
      return null;
    }

    final normalizedRecordedPath = p.normalize(recordedPath);
    if (normalizedRecordedPath != _audioFilePath) {
      unawaited(_deleteFile(normalizedRecordedPath));
      unawaited(_deleteFile(_audioFilePath));
      debugPrint(
        'Warning: Recorded file path ($normalizedRecordedPath) does not match expected path ($_audioFilePath).',
      );
      return null;
    }
    if (!File(normalizedRecordedPath).existsSync()) {
      await _showErrorAndReturnToStartScreen(
        'Recorded file does not exist at expected path: $normalizedRecordedPath',
      );
      return null;
    }

    return normalizedRecordedPath;
  }

  Future<void> _toggleWaitSpeakMode(bool isWaiting) async {
    if (!mounted || _isToggling) {
      return;
    }
    setState(() => _isToggling = true);

    if (isWaiting) {
      await _startRecording();
      setState(() => _isToggling = false);
      _restartTimer();
    } else {
      _addMessage('Question?', false);
      final String? normalizedRecordedPath = await _stopRecording();
      setState(() => _isToggling = false);
      if (normalizedRecordedPath == null) {
        return;
      }
      _restartTimer(); // restart timer now, else user perceives delay
      final String? storagePath = await _uploadUserResponseAudio(
        normalizedRecordedPath,
      );
      //todo _readTranscription only called to create debug message and ensure transcription worked
      if (storagePath == null) {
        return;
      }
      unawaited(_readTranscription(storagePath));
    }
  }

  Future<String?> _uploadUserResponseAudio(String path) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.wav';
      final storagePath = 'transcriptions/es/$fileName';
      final storageRef = FirebaseStorage.instance.ref(storagePath);

      final file = File(path);
      await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'audio/wav'),
      );
      unawaited(_deleteFile(path));

      return storagePath;
    } catch (e) {
      await _showErrorAndReturnToStartScreen('Failed to upload audio: $e');
      return null;
    }
  }
}

class _Message {
  final String text;
  final bool isUser;

  const _Message({required this.text, this.isUser = true});
}
