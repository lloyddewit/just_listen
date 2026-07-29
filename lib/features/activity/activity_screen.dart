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
  String _audioFilePath = "";

  final List<_Message> _messages = [
    _Message(text: 'Question1?', isUser: false),
  ];
  final ProgressBarCountdownController _progressBarController =
      ProgressBarCountdownController();
  final ScrollController _scrollController = ScrollController();
  bool _isWaiting = true;
  bool _isToggling = false;

  final _recorder = AudioRecorder();

  // Recording config optimized for speech recognition
  final _recordConfig = RecordConfig(
    encoder: AudioEncoder.wav, // WAV or FLAC preferred by APIs
    sampleRate: 16000, // 16kHz is standard for speech APIs
    numChannels: 1, // Mono
    autoGain: true,
    echoCancel: true,
    noiseSuppress: true,
  );

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
              onPressed: () async {
                await _toggleWaitSpeakMode(_isWaiting);
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
  Future<void> dispose() async {
    unawaited(_deleteFile(_audioFilePath));

    // Commented out because ProgressBarCountdownController does not implement dispose()
    //_progressBarController.dispose();

    _scrollController.dispose();
    unawaited(_recorder.dispose());
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
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  Future<void> _deleteFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return;

    const maxDuration = Duration(seconds: 10);
    const checkInterval = Duration(milliseconds: 500);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxDuration) {
      try {
        unawaited(file.delete());
        return; // Success
      } on PathAccessException catch (_) {
        // File still locked, wait and retry
        await Future.delayed(checkInterval);
      }
    }

    // Timeout reached — log and continue
    await _showErrorAndReturnToStartScreen(
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

  void _restartTimer() {
    if (!mounted) return;
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

  Future<String?> _readTranscription(String storagePath) async {
    final transcriptionPath = '$storagePath.wav_transcription.txt';
    final transcriptionRef = FirebaseStorage.instance.ref(transcriptionPath);

    const maxDuration = Duration(seconds: 20);
    const checkInterval = Duration(milliseconds: 500);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxDuration) {
      try {
        final bytes = await transcriptionRef.getData();
        if (bytes != null) {
          final jsonString = utf8.decode(bytes);

          // Parse JSON and extract transcript - fail fast on parse/shape errors
          try {
            final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
            final transcript =
                jsonMap['results'][0]['alternatives'][0]['transcript']
                    as String;
            //todo: just for temp debugging, print the transcript to console
            debugPrint('Transcription result: $transcript');
            return transcript;
          } catch (parseError) {
            await _showErrorAndReturnToStartScreen(
              'Could not transcribe any text from recording: $parseError',
            );
            return null;
          }
        }
      } catch (e) {
        // File not available yet (e.g., not found), wait and retry
        await Future.delayed(checkInterval);
      }
    }

    await _showErrorAndReturnToStartScreen(
      'Transcription not available after ${maxDuration.inSeconds} seconds',
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
            onPressed: () {
              Navigator.of(dialogContext).pop(); // close dialog
              Navigator.of(dialogContext).popUntil(
                // return to start
                ModalRoute.withName('/'),
              );
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
    final recordedPath = await _recorder.stop();
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
      await _showErrorAndReturnToStartScreen(
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
    _isToggling = true;

    if (isWaiting) {
      await _startRecording();
      _isToggling = false;
      _restartTimer();
    } else {
      _addMessage('Question?', false);
      final String? normalizedRecordedPath = await _stopRecording();
      _isToggling = false;
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
