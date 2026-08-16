import 'dart:io';

import 'package:flutter/material.dart';

import '../data/models/study_session.dart';
import 'formatters.dart';
import 'theme.dart';

class Brand extends StatelessWidget {
  const Brand({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        text: '推しと',
        children: [
          TextSpan(
            text: 'Study',
            style: TextStyle(color: pink),
          ),
        ],
      ),
      style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w900),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: pink,
          disabledBackgroundColor: const Color(0xFFF1CBD7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D493849),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SoftPill extends StatelessWidget {
  const SoftPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEEE8FF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF715AB0),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class DevelopingPhoto extends StatelessWidget {
  const DevelopingPhoto({
    super.key,
    required this.imagePath,
    required this.progress,
  });

  final String? imagePath;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0);
    final veilOpacity = safeProgress == 1
        ? 0.0
        : (1 - safeProgress).clamp(0.0, 1.0) * .92 + .08;
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imagePath != null)
              Image(
                image: ResizeImage(FileImage(File(imagePath!)), width: 800),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.white),
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9D86E8), Color(0xFFFF83A9)],
                  ),
                ),
                child: const Center(
                  child: Text(
                    '推',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: veilOpacity,
                duration: const Duration(milliseconds: 700),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-.5, -.55),
                      radius: 1.3,
                      colors: [
                        Colors.white,
                        Color(0xFFFFFAFC),
                        Color(0xFFF5EFFF),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFFC8B8C4)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ink, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

Widget pageHeader(String title, String subtitle) => Padding(
  padding: const EdgeInsets.only(bottom: 18),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: ink,
          fontSize: 25,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
    ],
  ),
);

Widget sectionTitle(String title) => Text(
  title,
  style: const TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w900),
);

Widget sessionTile(StudySession session) => Container(
  margin: const EdgeInsets.only(top: 8),
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    border: Border.all(color: line),
  ),
  child: Row(
    children: [
      Container(
        width: 7,
        height: 38,
        decoration: BoxDecoration(
          color: subjectColor(session.subject),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${session.subject}・${formatDuration(session.seconds)}',
              style: const TextStyle(color: ink, fontWeight: FontWeight.w900),
            ),
            Text(
              formatDate(session.at),
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
      ),
      const Text(
        '記録',
        style: TextStyle(
          color: pink,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  ),
);

Color subjectColor(String subject) {
  const fixed = {
    '英語': Color(0xFFFF7FA5),
    '数学': Color(0xFF9C86E8),
    '国語': Color(0xFFFFAD69),
    '理科': Color(0xFF5AC3A1),
    '社会': Color(0xFF70A9DF),
  };
  return fixed[subject] ??
      const [
        Color(0xFFEF78A4),
        Color(0xFF887EE3),
        Color(0xFFE39A62),
        Color(0xFF4FBA9A),
      ][subject.codeUnits.fold(0, (a, b) => a + b) % 4];
}

BoxDecoration themeDecoration(String theme) {
  final colors = switch (theme) {
    'debug' => const [Color(0xFFF2F2F2), Color(0xFFE2E2E2)],
    'ribbon' => const [Color(0xFFFFFBFD), Color(0xFFF9E4EF)],
    'lace' => const [Color(0xFFFFFBFF), Color(0xFFEDE6FF)],
    'jewel' => const [Color(0xFFFFF5FA), Color(0xFFECE4FF)],
    _ => const [Colors.white, Color(0xFFFFE8EF)],
  };
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    ),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: line),
    boxShadow: const [
      BoxShadow(
        color: Color(0x15523D4B),
        blurRadius: 28,
        offset: Offset(0, 12),
      ),
    ],
  );
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String actionLabel = '実行',
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(actionLabel),
            ),
          ],
        ),
      ) ??
      false;
}
