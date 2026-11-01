import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/study_buddy_service.dart';
import 'study_buddy_mascot.dart';
import '../theme/app_colors.dart';

class StudyBuddyScreen extends StatefulWidget {
  const StudyBuddyScreen({super.key, this.initialMood = StudyBuddyMood.sad});

  final StudyBuddyMood initialMood;

  @override
  State<StudyBuddyScreen> createState() => _StudyBuddyScreenState();
}

class _StudyBuddyScreenState extends State<StudyBuddyScreen> {
  final StudyBuddyService _service = StudyBuddyService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_BuddyMessage> _messages = [
    _BuddyMessage(
      text:
          'Hey! I’m your Study Buddy. 💜\n\nI can help you stay consistent, make a study plan, and work through NEET Physics, Chemistry, and Biology questions. What are we studying today?',
      isUser: false,
    ),
  ];
  bool _isSending = false;
  late StudyBuddyMood _mood = widget.initialMood;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _inputController.text).trim();
    if (text.isEmpty || _isSending) return;

    _inputController.clear();
    final history = _messages
        .map((m) => <String, String>{
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList(growable: false);

    setState(() {
      _messages.add(_BuddyMessage(text: text, isUser: true));
      _isSending = true;
      _mood = StudyBuddyMood.focused;
    });
    _scrollToBottom();

    final reply = await _service.sendMessage(message: text, history: history);
    if (!mounted) return;

    setState(() {
      _messages.add(_BuddyMessage(text: reply, isUser: false));
      _isSending = false;
      _mood = StudyBuddyMood.happy;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            StudyBuddyMascot(
                mood: _isSending ? StudyBuddyMood.focused : _mood, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study Buddy',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _service.isAiConnected
                        ? 'AI tutor connected by endpoint'
                        : 'Motivation + offline study helper',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildIntroCard(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                itemCount: _messages.length + (_isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isSending && index == _messages.length) {
                    return _buildTypingBubble();
                  }
                  return _buildMessage(_messages[index]);
                },
              ),
            ),
            _buildQuickPrompts(),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    final mood = _isSending ? StudyBuddyMood.focused : _mood;
    final message = mood == StudyBuddyMood.sad
        ? 'I’m here with you. Let’s begin with just 10 minutes.'
        : mood == StudyBuddyMood.focused
            ? 'Focus mode! One question at a time—we’ve got this.'
            : 'You showed up. That’s a win. Let’s keep going!';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.cardBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          StudyBuddyMascot(mood: mood, size: 84),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood == StudyBuddyMood.sad
                      ? 'Let’s start small'
                      : mood == StudyBuddyMood.focused
                          ? 'We’re focusing!'
                          : 'Proud of you!',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'YOUR NEET STUDY PARTNER',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(_BuddyMessage message) {
    final color = message.isUser
        ? AppColors.primary.withValues(alpha: 0.18)
        : AppColors.cardBackground;
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isUser ? 18 : 5),
            bottomRight: Radius.circular(message.isUser ? 5 : 18),
          ),
          border: Border.all(
            color: message.isUser
                ? AppColors.primary.withValues(alpha: 0.24)
                : AppColors.glassBorder,
          ),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const SizedBox(
          width: 22,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildQuickPrompts() {
    final prompts = <String>[
      'Motivate me',
      'Quiz me on Biology',
      'Make a study plan',
      'Explain Newton’s laws',
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) => ActionChip(
          label: Text(prompts[index]),
          labelStyle: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: AppColors.cardBackground,
          side: BorderSide(color: AppColors.glassBorder),
          onPressed: _isSending ? null : () => _send(prompts[index]),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style:
                  GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ask a study question…',
                hintStyle:
                    GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppColors.cardBackground,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: AppColors.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 9),
          IconButton.filled(
            onPressed: _isSending ? null : _send,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              fixedSize: const Size(48, 48),
            ),
            icon: const Icon(Icons.arrow_upward_rounded),
            tooltip: 'Send message',
          ),
        ],
      ),
    );
  }
}

class _BuddyMessage {
  final String text;
  final bool isUser;
  const _BuddyMessage({required this.text, required this.isUser});
}
