import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
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
            '추가됐으면 하는 기능이나 불편한 점을 적어 주세요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: '제목',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bodyController,
            minLines: 7,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: '내용',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.mail_outline),
            label: const Text('메일로 보내기'),
            onPressed: _sendFeedback,
          ),
        ],
      ),
    );
  }

  Future<void> _sendFeedback() async {
    final subject = titleController.text.trim().isEmpty
        ? '애니 체크 피드백'
        : '애니 체크 피드백: ${titleController.text.trim()}';
    final body = bodyController.text.trim();
    final uri = Uri(
      scheme: 'mailto',
      path: 'yujy9897@gmail.com',
      queryParameters: {'subject': subject, 'body': body},
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('메일 앱을 열 수 없습니다.')));
    }
  }
}
