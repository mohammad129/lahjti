import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/avatar_state.dart';

/// Immersive high-performance procedural animated visual avatar in a rich classroom/studio environment.
class TutorAvatarView extends StatefulWidget {
  final AvatarState state;
  final String personaId; // 'abbas' or 'dunya'
  final double soundLevel; // 0.0 to 1.0
  final double size;
  final bool showEnvironment;

  const TutorAvatarView({
    super.key,
    required this.state,
    required this.personaId,
    this.soundLevel = 0.0,
    this.size = 180.0,
    this.showEnvironment = true,
  });

  @override
  State<TutorAvatarView> createState() => _TutorAvatarViewState();
}

class _TutorAvatarViewState extends State<TutorAvatarView>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _speakingController;
  late AnimationController _thinkingController;
  late AnimationController _blinkController;
  late AnimationController _environmentPulseController;

  @override
  void initState() {
    super.initState();

    // 1. Idle breathing and subtle head movement (3000ms loop)
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    // 2. Speaking mouth oscillation controller (180ms fast loop)
    _speakingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..repeat(reverse: true);

    // 3. Thinking orbit controller (2000ms continuous loop)
    _thinkingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // 4. Periodic natural eye blink controller (3500ms loop)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    // 5. Ambient studio background pulse
    _environmentPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _idleController.dispose();
    _speakingController.dispose();
    _thinkingController.dispose();
    _blinkController.dispose();
    _environmentPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAbbas = widget.personaId == 'abbas';

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _idleController,
          _speakingController,
          _thinkingController,
          _blinkController,
          _environmentPulseController,
        ]),
        builder: (context, _) {
          // Calculate dynamic animation values
          final idleProgress = _idleController.value;
          final speakingProgress =
              widget.state == AvatarState.speaking
                  ? (_speakingController.value * 0.7 + widget.soundLevel * 0.3)
                  : 0.0;
          final thinkingAngle = _thinkingController.value * 2 * math.pi;

          // Blink calculation: blink for 150ms every 3.5 seconds
          final blinkProgress = _blinkController.value;
          final isBlinking = blinkProgress > 0.95;
          final envPulse = _environmentPulseController.value;

          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _AvatarPainter(
              state: widget.state,
              isAbbas: isAbbas,
              idleProgress: idleProgress,
              speakingProgress: speakingProgress,
              thinkingAngle: thinkingAngle,
              isBlinking: isBlinking,
              soundLevel: widget.soundLevel,
              showEnvironment: widget.showEnvironment,
              envPulse: envPulse,
            ),
          );
        },
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final AvatarState state;
  final bool isAbbas;
  final double idleProgress;
  final double speakingProgress;
  final double thinkingAngle;
  final bool isBlinking;
  final double soundLevel;
  final bool showEnvironment;
  final double envPulse;

  _AvatarPainter({
    required this.state,
    required this.isAbbas,
    required this.idleProgress,
    required this.speakingProgress,
    required this.thinkingAngle,
    required this.isBlinking,
    required this.soundLevel,
    required this.showEnvironment,
    required this.envPulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Believable Studio/Classroom Background Environment (Depth + Ambient Lighting)
    if (showEnvironment) {
      _drawClassroomEnvironment(canvas, center, radius);
    }

    // 2. Dynamic Glow Aura based on state & persona
    _drawAura(canvas, center, radius);

    // 3. Head & Torso Frame
    _drawAvatarBody(canvas, center, radius);

    // 4. State-specific overlays (Thinking orbit, Listening wave rings)
    if (state == AvatarState.thinking) {
      _drawThinkingHalo(canvas, center, radius);
    } else if (state == AvatarState.listening) {
      _drawListeningRipples(canvas, center, radius);
    }
  }

  void _drawClassroomEnvironment(Canvas canvas, Offset center, double radius) {
    final envRect = Rect.fromCircle(center: center, radius: radius);

    // Deep modern learning studio gradient background
    final envGradient = RadialGradient(
      center: Alignment.topCenter,
      radius: 1.1,
      colors:
          isAbbas
              ? [
                const Color(0xFF1E293B),
                const Color(0xFF0F172A),
                const Color(0xFF020617),
              ]
              : [
                const Color(0xFF2E1065),
                const Color(0xFF1F0838),
                const Color(0xFF0F041C),
              ],
    );

    final bgPaint = Paint()..shader = envGradient.createShader(envRect);
    canvas.drawCircle(center, radius, bgPaint);

    // Ambient studio spotlights / warm study room glow
    final spotGlow =
        Paint()
          ..color = (isAbbas
                  ? const Color(0xFF0284C7)
                  : const Color(0xFFD946EF))
              .withValues(alpha: 0.15 + (envPulse * 0.08))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.4, center.dy - radius * 0.4),
      radius * 0.45,
      spotGlow,
    );

    final warmGlow =
        Paint()
          ..color = (isAbbas
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFFB923C))
              .withValues(alpha: 0.12 + (envPulse * 0.05))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(
      Offset(center.dx + radius * 0.45, center.dy - radius * 0.35),
      radius * 0.4,
      warmGlow,
    );

    // Classroom digital whiteboard / study room elements in subtle background lines
    final linePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;

    // Study shelf / Board outline
    final boardTop = center.dy - radius * 0.65;
    final boardBottom = center.dy + radius * 0.3;
    final boardLeft = center.dx - radius * 0.85;
    final boardRight = center.dx + radius * 0.85;

    final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(boardLeft, boardTop, boardRight, boardBottom),
      const Radius.circular(16),
    );
    canvas.drawRRect(boardRect, linePaint);

    // Subtle language symbols / decorative education glyphs in studio backdrop
    final glyphPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    // A simple book / education icon sketch on the left
    canvas.drawLine(
      Offset(center.dx - radius * 0.65, center.dy - radius * 0.45),
      Offset(center.dx - radius * 0.45, center.dy - radius * 0.4),
      glyphPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.45, center.dy - radius * 0.4),
      Offset(center.dx - radius * 0.25, center.dy - radius * 0.45),
      glyphPaint,
    );
  }

  void _drawAura(Canvas canvas, Offset center, double radius) {
    Color auraColor;
    double auraSpread;

    switch (state) {
      case AvatarState.listening:
        auraColor = isAbbas ? const Color(0xFF0284C7) : const Color(0xFFEA580C);
        auraSpread = 14 + (soundLevel * 16);
        break;
      case AvatarState.speaking:
        auraColor = isAbbas ? const Color(0xFF0D9488) : const Color(0xFFF97316);
        auraSpread = 12 + (speakingProgress * 14);
        break;
      case AvatarState.thinking:
        auraColor = const Color(0xFF8B5CF6);
        auraSpread = 10 + (math.sin(idleProgress * math.pi) * 6);
        break;
      case AvatarState.error:
        auraColor = AppColors.error;
        auraSpread = 10;
        break;
      case AvatarState.idle:
        auraColor = isAbbas ? const Color(0xFF0284C7) : const Color(0xFFF59E0B);
        auraSpread = 8 + (idleProgress * 5);
        break;
    }

    final auraPaint =
        Paint()
          ..color = auraColor.withValues(alpha: 0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, auraSpread);

    canvas.drawCircle(center, radius - 6, auraPaint);
  }

  void _drawAvatarBody(Canvas canvas, Offset center, double radius) {
    // Border Rim of Avatar Stage
    final borderPaint =
        Paint()
          ..color = (isAbbas
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFFB923C))
              .withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;

    canvas.drawCircle(center, radius - 4, borderPaint);

    // Clip inner character content to circle
    canvas.save();
    final clipPath =
        Path()..addOval(Rect.fromCircle(center: center, radius: radius - 5));
    canvas.clipPath(clipPath);

    // Gentle breathing offset (subtle natural breathing movement)
    final breathOffset = Offset(0, math.sin(idleProgress * math.pi) * 2.5);

    // Draw Torso / Clothes
    _drawTorso(canvas, center + breathOffset, radius);

    // Draw Neck & Face
    _drawFace(canvas, center + breathOffset, radius);

    // Draw Hair
    _drawHair(canvas, center + breathOffset, radius);

    // Draw Eyes
    _drawEyes(canvas, center + breathOffset, radius);

    // Draw Mouth
    _drawMouth(canvas, center + breathOffset, radius);

    canvas.restore();
  }

  void _drawTorso(Canvas canvas, Offset center, double radius) {
    final torsoPaint =
        Paint()
          ..color =
              isAbbas
                  ? const Color(0xFF0F766E) // Abbas: Professional Teal Blazer
                  : const Color(
                    0xFF9A3412,
                  ); // Dunya: Elegant Terracotta Cardigan

    final path = Path();
    final topY = center.dy + radius * 0.42;
    path.moveTo(center.dx - radius * 0.75, center.dy + radius);
    path.quadraticBezierTo(
      center.dx,
      topY,
      center.dx + radius * 0.75,
      center.dy + radius,
    );
    path.close();

    canvas.drawPath(path, torsoPaint);

    // Inner Shirt / Collar detail
    final collarPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round;

    final collarPath = Path();
    collarPath.moveTo(center.dx - radius * 0.22, topY + 4);
    collarPath.lineTo(center.dx, topY + radius * 0.24);
    collarPath.lineTo(center.dx + radius * 0.22, topY + 4);
    canvas.drawPath(collarPath, collarPaint);
  }

  void _drawFace(Canvas canvas, Offset center, double radius) {
    // Skin Tone
    final skinPaint =
        Paint()
          ..color =
              isAbbas
                  ? const Color(0xFFE5C298) // Warm olive/beige
                  : const Color(0xFFEDCCA4); // Warm radiant beige

    final faceCenter = Offset(center.dx, center.dy - radius * 0.05);
    final faceWidth = radius * 0.52;
    final faceHeight = radius * 0.62;

    final faceRect = Rect.fromCenter(
      center: faceCenter,
      width: faceWidth * 2,
      height: faceHeight * 2,
    );

    canvas.drawOval(faceRect, skinPaint);

    // Abbas: neat styled beard & stubble
    if (isAbbas) {
      final beardPaint =
          Paint()
            ..color = const Color(0xFF261C14)
            ..style = PaintingStyle.fill;

      final beardPath = Path();
      beardPath.moveTo(faceCenter.dx - faceWidth * 0.85, faceCenter.dy + 4);
      beardPath.quadraticBezierTo(
        faceCenter.dx,
        faceCenter.dy + faceHeight * 1.15,
        faceCenter.dx + faceWidth * 0.85,
        faceCenter.dy + 4,
      );
      beardPath.quadraticBezierTo(
        faceCenter.dx + faceWidth * 0.7,
        faceCenter.dy + faceHeight * 0.7,
        faceCenter.dx,
        faceCenter.dy + faceHeight * 0.85,
      );
      beardPath.quadraticBezierTo(
        faceCenter.dx - faceWidth * 0.7,
        faceCenter.dy + faceHeight * 0.7,
        faceCenter.dx - faceWidth * 0.85,
        faceCenter.dy + 4,
      );
      beardPath.close();

      canvas.drawPath(beardPath, beardPaint);
    }
  }

  void _drawHair(Canvas canvas, Offset center, double radius) {
    final hairPaint =
        Paint()
          ..color =
              isAbbas
                  ? const Color(0xFF1E1B18)
                  : const Color(0xFF362016); // Dark espresso vs Warm chestnut

    final hairPath = Path();
    final headTop = center.dy - radius * 0.65;

    if (isAbbas) {
      // Abbas: Modern styled cropped hair
      hairPath.moveTo(center.dx - radius * 0.55, center.dy - radius * 0.05);
      hairPath.quadraticBezierTo(
        center.dx - radius * 0.6,
        headTop - 4,
        center.dx,
        headTop - 6,
      );
      hairPath.quadraticBezierTo(
        center.dx + radius * 0.6,
        headTop - 4,
        center.dx + radius * 0.55,
        center.dy - radius * 0.05,
      );
      hairPath.quadraticBezierTo(
        center.dx + radius * 0.35,
        headTop + 8,
        center.dx,
        headTop + 14,
      );
      hairPath.quadraticBezierTo(
        center.dx - radius * 0.35,
        headTop + 8,
        center.dx - radius * 0.55,
        center.dy - radius * 0.05,
      );
      hairPath.close();
    } else {
      // Dunya: Elegant wavy styled hair framing face
      hairPath.moveTo(center.dx - radius * 0.62, center.dy + radius * 0.35);
      hairPath.quadraticBezierTo(
        center.dx - radius * 0.7,
        headTop - 8,
        center.dx,
        headTop - 10,
      );
      hairPath.quadraticBezierTo(
        center.dx + radius * 0.7,
        headTop - 8,
        center.dx + radius * 0.62,
        center.dy + radius * 0.35,
      );
      hairPath.quadraticBezierTo(
        center.dx + radius * 0.45,
        center.dy,
        center.dx + radius * 0.38,
        headTop + 12,
      );
      hairPath.quadraticBezierTo(
        center.dx,
        headTop + 16,
        center.dx - radius * 0.38,
        headTop + 12,
      );
      hairPath.quadraticBezierTo(
        center.dx - radius * 0.45,
        center.dy,
        center.dx - radius * 0.62,
        center.dy + radius * 0.35,
      );
      hairPath.close();
    }

    canvas.drawPath(hairPath, hairPaint);
  }

  void _drawEyes(Canvas canvas, Offset center, double radius) {
    final eyeY = center.dy - radius * 0.12;
    final leftEyeX = center.dx - radius * 0.22;
    final rightEyeX = center.dx + radius * 0.22;

    final eyePaint =
        Paint()
          ..color = const Color(0xFF1E1B18)
          ..style = PaintingStyle.fill;

    // Eyebrows
    final browPaint =
        Paint()
          ..color = const Color(0xFF1E1B18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isAbbas ? 2.8 : 2.0
          ..strokeCap = StrokeCap.round;

    final browOffset =
        state == AvatarState.thinking
            ? -3.0
            : (state == AvatarState.error ? 2.0 : 0.0);

    canvas.drawLine(
      Offset(leftEyeX - 9, eyeY - 11 + browOffset),
      Offset(leftEyeX + 9, eyeY - 9 + (browOffset * 0.5)),
      browPaint,
    );
    canvas.drawLine(
      Offset(rightEyeX - 9, eyeY - 9 + (browOffset * 0.5)),
      Offset(rightEyeX + 9, eyeY - 11 + browOffset),
      browPaint,
    );

    if (isBlinking) {
      // Closed eye line during natural blink
      final blinkPaint =
          Paint()
            ..color = const Color(0xFF1E1B18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(leftEyeX - 7, eyeY),
        Offset(leftEyeX + 7, eyeY),
        blinkPaint,
      );
      canvas.drawLine(
        Offset(rightEyeX - 7, eyeY),
        Offset(rightEyeX + 7, eyeY),
        blinkPaint,
      );
    } else {
      // Open animated eye with sparkle
      final eyeRadius = radius * 0.07;
      canvas.drawCircle(Offset(leftEyeX, eyeY), eyeRadius, eyePaint);
      canvas.drawCircle(Offset(rightEyeX, eyeY), eyeRadius, eyePaint);

      final sparklePaint = Paint()..color = Colors.white;
      canvas.drawCircle(
        Offset(leftEyeX + 1.5, eyeY - 1.5),
        eyeRadius * 0.35,
        sparklePaint,
      );
      canvas.drawCircle(
        Offset(rightEyeX + 1.5, eyeY - 1.5),
        eyeRadius * 0.35,
        sparklePaint,
      );
    }
  }

  void _drawMouth(Canvas canvas, Offset center, double radius) {
    final mouthY = center.dy + radius * 0.18;
    final mouthCenterX = center.dx;

    if (state == AvatarState.speaking && speakingProgress > 0.05) {
      // Open speaking mouth modulated by audio waveform & sound level
      final mouthHeight = 3.5 + (speakingProgress * 14.0);
      final mouthWidth = 14.0 + (speakingProgress * 6.0);

      final mouthPaint =
          Paint()
            ..color = const Color(0xFF5E1717)
            ..style = PaintingStyle.fill;

      final mouthRect = Rect.fromCenter(
        center: Offset(mouthCenterX, mouthY),
        width: mouthWidth,
        height: mouthHeight,
      );

      canvas.drawOval(mouthRect, mouthPaint);

      // Teeth highlight
      if (mouthHeight > 6) {
        final teethPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(mouthCenterX, mouthY - mouthHeight * 0.25),
              width: mouthWidth * 0.7,
              height: 2.5,
            ),
            const Radius.circular(1),
          ),
          teethPaint,
        );
      }
    } else {
      // Natural friendly smile curve
      final smilePaint =
          Paint()
            ..color =
                isAbbas ? const Color(0xFF451A03) : const Color(0xFF9F1239)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round;

      final smilePath = Path();
      smilePath.moveTo(mouthCenterX - 9, mouthY);
      smilePath.quadraticBezierTo(
        mouthCenterX,
        mouthY + 5.5,
        mouthCenterX + 9,
        mouthY,
      );
      canvas.drawPath(smilePath, smilePaint);
    }
  }

  void _drawThinkingHalo(Canvas canvas, Offset center, double radius) {
    final orbitRadius = radius - 1;
    const particleCount = 4;

    final haloPaint =
        Paint()
          ..color = const Color(0xFFA78BFA)
          ..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final angle = thinkingAngle + (i * (2 * math.pi / particleCount));
      final px = center.dx + math.cos(angle) * orbitRadius;
      final py = center.dy + math.sin(angle) * orbitRadius;

      canvas.drawCircle(Offset(px, py), 3.5, haloPaint);
    }
  }

  void _drawListeningRipples(Canvas canvas, Offset center, double radius) {
    final ripplePaint =
        Paint()
          ..color = (isAbbas
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFFB923C))
              .withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final pulseRadius = radius + (soundLevel * 12) + (idleProgress * 5);
    canvas.drawCircle(center, pulseRadius, ripplePaint);
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.isAbbas != isAbbas ||
        oldDelegate.idleProgress != idleProgress ||
        oldDelegate.speakingProgress != speakingProgress ||
        oldDelegate.thinkingAngle != thinkingAngle ||
        oldDelegate.isBlinking != isBlinking ||
        oldDelegate.soundLevel != soundLevel ||
        oldDelegate.showEnvironment != showEnvironment ||
        oldDelegate.envPulse != envPulse;
  }
}
