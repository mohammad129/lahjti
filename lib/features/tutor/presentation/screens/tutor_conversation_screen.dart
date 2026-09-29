import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../domain/models/avatar_state.dart';
import '../../domain/models/voice_session_state.dart';
import '../providers/avatar_state_provider.dart';
import '../providers/voice_session_provider.dart';
import '../widgets/tutor_avatar_view.dart';

/// Immersive AI Language Tutor Screen featuring large animated studio/classroom avatar,
/// interactive voice conversation, instant typing console, and reliable navigation.
class TutorConversationScreen extends ConsumerStatefulWidget {
  const TutorConversationScreen({super.key});

  @override
  ConsumerState<TutorConversationScreen> createState() =>
      _TutorConversationScreenState();
}

class _TutorConversationScreenState
    extends ConsumerState<TutorConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  bool _hasInitialized = false;
  bool _isTextModeExpanded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      final l10n = context.l10n;
      final tutor = ref.read(voiceSessionNotifierProvider).tutor;
      final isAbbas = tutor.id == 'abbas';
      final fallbackGreeting =
          isAbbas ? l10n.tutorGreetingAbbas : l10n.tutorGreetingDunya;

      Future.microtask(() {
        ref
            .read(voiceSessionNotifierProvider.notifier)
            .initializeSession(defaultGreeting: fallbackGreeting);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleBackNavigation() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _submitText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _textController.clear();
    ref.read(voiceSessionNotifierProvider.notifier).sendTextMessage(trimmed);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final state = ref.watch(voiceSessionNotifierProvider);
    final avatarState = ref.watch(avatarStateProvider);
    final soundLevel = ref.watch(avatarSoundLevelProvider);
    final notifier = ref.read(voiceSessionNotifierProvider.notifier);
    final isAbbas = state.tutor.id == 'abbas';

    ref.listen<VoiceSessionState>(voiceSessionNotifierProvider, (_, next) {
      if (next.messages.length != state.messages.length) {
        _scrollToBottom();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Premium dark studio theme
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0.5,
          leading: IconButton(
            key: const Key('tutor_back_button'),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            tooltip: isArabic ? 'رجوع' : 'Back',
            onPressed: _handleBackNavigation,
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    isAbbas
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.secondary.withValues(alpha: 0.3),
                child: Text(
                  isAbbas ? '👨‍🏫' : '👩‍🏫',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.tutor.localizedName(l10n),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isArabic
                          ? 'معلم الذكاء الاصطناعي متعدد اللغات'
                          : 'Multilingual AI Language Tutor',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Home Direct Navigation Icon
            IconButton(
              key: const Key('tutor_home_appbar_btn'),
              icon: const Icon(Icons.home_rounded, color: Colors.white70),
              tooltip: isArabic ? 'الرئيسية' : 'Home',
              onPressed: () => context.go(AppRoutes.home),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = constraints.maxHeight;
              // AI Tutor stage occupies approximately 42–48% of the available height
              final stageHeight = (screenHeight * 0.44).clamp(240.0, 420.0);

              return Column(
                children: [
                  // 1. IMMERSIVE AI TUTOR STAGE (40–55% Screen Area)
                  SizedBox(
                    height: stageHeight,
                    width: double.infinity,
                    child: _buildImmersiveTutorStage(
                      state,
                      avatarState,
                      soundLevel,
                      isAbbas,
                      isArabic,
                      l10n,
                      stageHeight,
                    ),
                  ),

                  // 2. ERROR NOTICE BANNER (when error occurs)
                  if (state.errorMessage != null)
                    _buildErrorBanner(
                      state.errorMessage!,
                      notifier,
                      l10n,
                      isArabic,
                    ),

                  // 3. CONVERSATION CHAT STREAM (Scrollable History)
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF0B1120),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount:
                            state.messages.length +
                            (state.currentTranscript.isNotEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.messages.length) {
                            return _buildLiveTranscriptBubble(
                              state.currentTranscript,
                              isArabic,
                            );
                          }
                          final msg = state.messages[index];
                          return _buildMessageBubble(
                            msg,
                            isAbbas,
                            isArabic,
                            notifier,
                          );
                        },
                      ),
                    ),
                  ),

                  // 4. BOTTOM INTERACTIVE AUDIO & TEXT CONSOLE
                  _buildBottomConsole(state, notifier, l10n, isAbbas, isArabic),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Immersive large tutor area with animated environment & state indicator
  Widget _buildImmersiveTutorStage(
    VoiceSessionState state,
    AvatarState avatarState,
    double soundLevel,
    bool isAbbas,
    bool isArabic,
    dynamic l10n,
    double stageHeight,
  ) {
    // Dynamic avatar size scaled to stage height
    final avatarSize = (stageHeight * 0.72).clamp(160.0, 260.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              isAbbas
                  ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF0284C7).withValues(alpha: 0.15),
                  ]
                  : [
                    const Color(0xFF1E1035),
                    const Color(0xFFD946EF).withValues(alpha: 0.15),
                  ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ambient studio lighting particles
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: CustomPaint(
                painter: _StudioAtmospherePainter(isAbbas: isAbbas),
              ),
            ),
          ),

          // Main Animated Avatar View
          Center(
            child: TutorAvatarView(
              state: avatarState,
              personaId: state.tutor.id,
              soundLevel: soundLevel,
              size: avatarSize,
              showEnvironment: true,
            ),
          ),

          // Top Learning Studio Environment Badge
          Positioned(
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isAbbas ? '🎙️ Studio Classroom' : '📚 Modern Study Room',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Live Interactive Status Pill
          Positioned(
            bottom: 10,
            child: _buildStateBadgePill(avatarState, isArabic),
          ),
        ],
      ),
    );
  }

  /// Live dynamic state pill (Ready, Listening, Thinking, Speaking, Error)
  Widget _buildStateBadgePill(AvatarState avatarState, bool isArabic) {
    Color bg;
    Color fg;
    String text;
    IconData icon;

    switch (avatarState) {
      case AvatarState.listening:
        bg = const Color(0xFF0284C7);
        fg = Colors.white;
        text = isArabic ? 'أسمعك...' : 'Listening...';
        icon = Icons.mic;
        break;
      case AvatarState.thinking:
        bg = const Color(0xFF7C3AED);
        fg = Colors.white;
        text = isArabic ? 'أفكر...' : 'Thinking...';
        icon = Icons.psychology;
        break;
      case AvatarState.speaking:
        bg = const Color(0xFF059669);
        fg = Colors.white;
        text = isArabic ? 'يتحدث معك...' : 'Speaking...';
        icon = Icons.volume_up_rounded;
        break;
      case AvatarState.error:
        bg = AppColors.error;
        fg = Colors.white;
        text = isArabic ? 'تعذر الاتصال' : 'Connection Error';
        icon = Icons.error_outline;
        break;
      case AvatarState.idle:
        bg = const Color(0xFF334155);
        fg = const Color(0xFFE2E8F0);
        text = isArabic ? 'جاهز للمحادثة' : 'Ready to chat';
        icon = Icons.check_circle_outline_rounded;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(
    String error,
    VoiceSessionNotifier notifier,
    dynamic l10n,
    bool isArabic,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB91C1C)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => notifier.startListening(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF991B1B),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isArabic ? 'إعادة المحاولة' : 'Retry',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTranscriptBubble(String transcript, bool isArabic) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0284C7).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF0284C7).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                transcript,
                style: const TextStyle(
                  color: Color(0xFFBAE6FD),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    VoiceMessage msg,
    bool isAbbas,
    bool isArabic,
    VoiceSessionNotifier notifier,
  ) {
    final isUser = msg.isUser;

    return Align(
      alignment:
          isUser
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser ? const Color(0xFF3B82F6) : const Color(0xFF334155),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message Text
            Text(
              msg.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Tutor correction (if applicable)
            if (!isUser && msg.shouldCorrect && msg.correctedAnswer != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF312E81),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        msg.correctedAnswer!,
                        style: const TextStyle(
                          color: Color(0xFFC7D2FE),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Arabic feedback note & Audio replay action
            if (!isUser) ...[
              if (msg.explanationArabic != null &&
                  msg.explanationArabic!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    msg.explanationArabic!,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => notifier.speakTutorMessage(msg),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.volume_up_rounded,
                            size: 14,
                            color: Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isArabic ? 'استماع' : 'Listen',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Bottom Control Console with large Voice Mic and expandable Text Input
  Widget _buildBottomConsole(
    VoiceSessionState state,
    VoiceSessionNotifier notifier,
    dynamic l10n,
    bool isAbbas,
    bool isArabic,
  ) {
    final isListening = state.isListening;
    final isProcessing = state.isProcessing;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expandable text input row
          if (_isTextModeExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textInputAction: TextInputAction.send,
                      onSubmitted: _submitText,
                      decoration: InputDecoration(
                        hintText:
                            isArabic
                                ? 'اكتب رسالتك للمدرّب هنا...'
                                : 'Type your message to the tutor...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF334155),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF334155),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed:
                        isProcessing
                            ? null
                            : () => _submitText(_textController.text),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          isAbbas ? AppColors.primary : AppColors.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

          // Main Control Bar: Toggle Keyboard | Giant Microphone CTA | Speaker Stop
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Keyboard Input Toggle
              IconButton(
                key: const Key('tutor_keyboard_toggle_btn'),
                onPressed: () {
                  setState(() {
                    _isTextModeExpanded = !_isTextModeExpanded;
                  });
                },
                icon: Icon(
                  _isTextModeExpanded
                      ? Icons.keyboard_hide_rounded
                      : Icons.keyboard_rounded,
                  color:
                      _isTextModeExpanded
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF94A3B8),
                  size: 26,
                ),
                tooltip: isArabic ? 'الكتابة نصيًا' : 'Type instead',
              ),

              // 2. Central Giant Voice Microphone Button
              GestureDetector(
                key: const Key('tutor_mic_cta_btn'),
                onTap: () {
                  if (isProcessing) return;
                  if (isListening) {
                    notifier.stopListening();
                  } else {
                    notifier.startListening();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isListening
                            ? const Color(0xFFDC2626)
                            : (isAbbas
                                ? const Color(0xFF0284C7)
                                : const Color(0xFFEA580C)),
                    boxShadow: [
                      BoxShadow(
                        color: (isListening
                                ? const Color(0xFFDC2626)
                                : (isAbbas
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFFEA580C)))
                            .withValues(alpha: isListening ? 0.6 : 0.4),
                        blurRadius: isListening ? 18 : 10,
                        spreadRadius: isListening ? 4 : 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child:
                        isProcessing
                            ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                            : Icon(
                              isListening
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                  ),
                ),
              ),

              // 3. Audio Stop / Replay Control
              IconButton(
                key: const Key('tutor_audio_stop_btn'),
                onPressed:
                    state.isSpeaking ? () => notifier.stopSpeaking() : null,
                icon: Icon(
                  state.isSpeaking
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_outlined,
                  color:
                      state.isSpeaking
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF64748B),
                  size: 26,
                ),
                tooltip: isArabic ? 'إيقاف الصوت' : 'Stop Audio',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Subtle atmosphere painter for background studio particles
class _StudioAtmospherePainter extends CustomPainter {
  final bool isAbbas;

  _StudioAtmospherePainter({required this.isAbbas});

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint =
        Paint()
          ..color = (isAbbas
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFFB923C))
              .withValues(alpha: 0.15)
          ..style = PaintingStyle.fill;

    // Fixed decorative nodes
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.2),
      3,
      particlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.3),
      4,
      particlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.75),
      2.5,
      particlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.8),
      3.5,
      particlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
