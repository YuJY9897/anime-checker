import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_controller.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  static const categories = ['기능 제안', '오류 신고', '불편한 점', '기타'];

  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final emailController = TextEditingController();
  String category = categories.first;
  bool sending = false;

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('피드백 보내기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            '추가됐으면 하는 기능이나 불편한 점을 앱 안에서 바로 보낼 수 있어요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(
              labelText: '문의 종류',
              border: OutlineInputBorder(),
            ),
            items: categories
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: sending
                ? null
                : (value) => setState(() => category = value ?? category),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: titleController,
            enabled: !sending,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '제목',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bodyController,
            enabled: !sending,
            minLines: 7,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: '내용',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            enabled: !sending,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: '답장 받을 이메일 선택사항',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(sending ? '보내는 중' : '보내기'),
            onPressed: sending ? null : _sendFeedback,
          ),
        ],
      ),
    );
  }

  Future<void> _sendFeedback() async {
    final title = titleController.text.trim();
    final body = bodyController.text.trim();
    final email = emailController.text.trim();
    if (body.length < 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('내용을 조금 더 적어 주세요.')));
      return;
    }
    setState(() => sending = true);
    try {
      await ref
          .read(apiClientProvider)
          .submitFeedback(
            category: category,
            title: title,
            body: body,
            email: email,
          );
      if (!mounted) return;
      titleController.clear();
      bodyController.clear();
      emailController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('피드백을 보냈어요. 고마워요.')));
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전송에 실패했어요. 잠시 후 다시 시도해 주세요.')),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }
}
