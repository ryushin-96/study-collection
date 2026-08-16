import 'dart:async';

import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/common_widgets.dart';
import '../../app/ad_banner_slot.dart';
import '../../app/formatters.dart';
import '../../app/theme.dart';
import '../../data/repositories/app_state.dart';
import '../../data/storage/image_storage.dart';

class StudyTimerPage extends StatefulWidget {
  const StudyTimerPage({
    super.key,
    required this.state,
    required this.subject,
    required this.countdownSeconds,
  });

  final AppState state;
  final String subject;
  final int? countdownSeconds;

  @override
  State<StudyTimerPage> createState() => _StudyTimerPageState();
}

class _StudyTimerPageState extends State<StudyTimerPage>
    with WidgetsBindingObserver {
  Timer? timer;
  DateTime? runningSince;
  int accumulated = 0;
  bool running = true;
  bool leaving = false;

  int get elapsed =>
      accumulated +
      (runningSince == null
          ? 0
          : DateTime.now().difference(runningSince!).inSeconds);

  int get shownSeconds => widget.countdownSeconds == null
      ? elapsed
      : (widget.countdownSeconds! - elapsed).clamp(0, widget.countdownSeconds!);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    runningSince = DateTime.now();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (widget.countdownSeconds != null &&
          elapsed >= widget.countdownSeconds! &&
          running) {
        // stop timer and finish automatically when countdown reaches zero
        timer?.cancel();
        finish();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  void pause() {
    if (!running) return;
    accumulated = elapsed;
    runningSince = null;
    setState(() => running = false);
  }

  void resume() {
    if (running) return;
    runningSince = DateTime.now();
    setState(() => running = true);
  }

  Future<void> finish() async {
    pause();
    if (accumulated < 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('1秒以上勉強してから記録してください')));
      return;
    }
    await widget.state.addSession(
      subject: widget.subject,
      seconds: accumulated,
    );
    leaving = true;
    if (mounted) {
      // return to app root so user seesホーム（手帳）画面に戻る
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> cancel() async {
    pause();
    final shouldDiscard =
        elapsed == 0 ||
        await confirm(
          context,
          title: '計測を取り消しますか？',
          message: '今回の${formatDuration(elapsed)}は記録されません。',
          actionLabel: '記録せず戻る',
        );
    if (!shouldDiscard || !mounted) return;
    leaving = true;
    Navigator.pop(context);
  }

  Future<bool> confirmBack() async {
    if (leaving) return true;
    await cancel();
    return false;
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalProgress =
        ((widget.state.notebookSeconds + elapsed) /
                widget.state.currentTheme.goalSeconds)
            .clamp(0.0, 1.0);
    return PopScope(
      canPop: leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) confirmBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: const AdBannerSlot(),
        body: Stack(
          children: [
            if (widget.state.activeImagePath != null)
              Positioned.fill(
                child: ImageFiltered(
                  // reduced blur to lower CPU/GPU cost
                  imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: ResizeImage(
                          FileImage(
                            File(
                              ImageStorage.resolve(
                                widget.state.activeImagePath!,
                              ),
                            ),
                          ),
                          width: 1200,
                        ),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.25),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Positioned.fill(child: Container(color: const Color(0xFF40364A))),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 650;
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: cancel,
                              tooltip: '取り消して戻る',
                              icon: const Icon(
                                CupertinoIcons.xmark,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              '集中タイム',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SoftPill(label: widget.subject),
                          ],
                        ),
                        const Spacer(),
                        SizedBox(
                          width: compact ? 120 : 210,
                          child: DevelopingPhoto(
                            imagePath: widget.state.activeImagePath,
                            progress: totalProgress,
                          ),
                        ),
                        SizedBox(height: compact ? 12 : 30),
                        Text(
                          formatClock(shownSeconds),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 48 : 64,
                            fontWeight: FontWeight.w900,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          totalProgress >= 1
                              ? 'フォトが完成しました！'
                              : '完成まであと ${formatDuration(((1 - totalProgress) * widget.state.currentTheme.goalSeconds).round())}',
                          style: const TextStyle(color: Color(0xFFD6C9D9)),
                        ),
                        SizedBox(height: compact ? 12 : 22),
                        LinearProgressIndicator(
                          value: totalProgress,
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(20),
                          backgroundColor: Colors.white12,
                          color: pink,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: '終了して記録',
                                onPressed: finish,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: running ? pause : resume,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white24),
                                  minimumSize: const Size.fromHeight(54),
                                ),
                                child: Text(running ? '一時停止' : '再開'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: cancel,
                          icon: const Icon(CupertinoIcons.clear, size: 16),
                          label: const Text('記録せず取り消す'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white60,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
