
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ai_provider.dart';
import '../providers/study_session_provider.dart';
import '../providers/syllabus_provider.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController _controller =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _askAi(String message) async {
    final cleanMessage = message.trim();

    if (cleanMessage.isEmpty) return;

    _controller.clear();

    await context.read<AiProvider>().sendMessage(
          userMessage: cleanMessage,
          userProvider: context.read<UserProvider>(),
          taskProvider: context.read<TaskProvider>(),
          syllabusProvider:
              context.read<SyllabusProvider>(),
          studySessionProvider:
              context.read<StudySessionProvider>(),
        );

    if (!mounted) return;

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        if (!_scrollController.hasClients) return;

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded),
            SizedBox(width: 10),
            Text('StudyX AI'),
          ],
        ),
        actions: [
          if (ai.messages.isNotEmpty)
            IconButton(
              tooltip: 'Clear chat',
              onPressed: ai.isLoading
                  ? null
                  : () {
                      context
                          .read<AiProvider>()
                          .clearChat();
                    },
              icon: const Icon(
                Icons.delete_outline_rounded,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: ai.messages.isEmpty
                  ? _buildEmpty()
                  : _buildChat(ai),
            ),

            if (ai.isLoading) _buildTypingIndicator(),

            _buildInput(ai.isLoading),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.blue.withOpacity(0.25),
        ),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 24,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 26,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'StudyX AI Coach',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your personal study assistant',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY CHAT
  // ============================================================

  Widget _buildEmpty() {
    final suggestions = [
      'What should I study today?',
      'Show my progress',
      'Help me clear my backlog',
      'What should I revise?',
      'What task should I do first?',
      'Motivate me',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 10),

        const Center(
          child: Icon(
            Icons.smart_toy_outlined,
            size: 54,
          ),
        ),

        const SizedBox(height: 14),

        const Center(
          child: Text(
            'How can I help?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 6),

        const Center(
          child: Text(
            'Ask about your study plan, progress, tasks, backlog or revision.',
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 24),

        ...suggestions.map(
          (text) => Padding(
            padding: const EdgeInsets.only(
              bottom: 10,
            ),
            child: Card(
              child: ListTile(
                leading: const Icon(
                  Icons.auto_awesome_outlined,
                ),
                title: Text(text),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                ),
                onTap: () => _askAi(text),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CHAT MESSAGES
  // ============================================================

  Widget _buildChat(AiProvider ai) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(),
    );

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12,
      ),
      itemCount: ai.messages.length,
      itemBuilder: (context, index) {
        final message = ai.messages[index];

        return _buildMessageBubble(
          text: message.text,
          isUser: message.isUser,
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isUser,
  }) {
    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 520,
        ),
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.blue
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(
              isUser ? 18 : 4,
            ),
            bottomRight: Radius.circular(
              isUser ? 4 : 18,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            height: 1.45,
            color: isUser ? Colors.white : null,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AI TYPING INDICATOR
  // ============================================================

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      child: Row(
        children: [
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 10),
          Text('StudyX AI is thinking...'),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT
  // ============================================================

  Widget _buildInput(bool loading) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !loading,
                minLines: 1,
                maxLines: 4,
                textInputAction:
                    TextInputAction.send,
                onSubmitted: loading
                    ? null
                    : _askAi,
                decoration: InputDecoration(
                  hintText:
                      'Ask your AI study coach...',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              tooltip: 'Send',
              onPressed: loading
                  ? null
                  : () => _askAi(
                        _controller.text,
                      ),
              icon: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}