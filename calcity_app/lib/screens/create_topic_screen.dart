import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Form to start a new discussion topic. Returns the created topic
/// via Navigator.pop so the list can refresh.
class CreateTopicScreen extends StatefulWidget {
  const CreateTopicScreen({super.key});

  @override
  State<CreateTopicScreen> createState() => _CreateTopicScreenState();
}

class _CreateTopicScreenState extends State<CreateTopicScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _category = 'general';
  bool _saving = false;
  String? _error;

  static const _categories = <String, String>{
    'general': 'General',
    'news': 'News',
    'events': 'Events',
    'business': 'Business',
    'help': 'Help & Questions',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give your topic a title');
      return;
    }
    if (body.isEmpty) {
      setState(() => _error = 'Add a little detail so people know what to discuss');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final created = await ApiService().createTopic(
      title: title,
      body: body,
      category: _category,
    );
    if (!mounted) return;
    if (created != null) {
      Navigator.pop(context, created);
    } else {
      setState(() {
        _saving = false;
        _error = 'Could not post — check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Discussion'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What do you want to talk about?',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final e in _categories.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              minLines: 5,
              maxLines: 10,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Details',
                hintText: 'Share the background, links, or questions…',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: cs.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 18),
                label: Text(_saving ? 'Posting…' : 'Post Topic'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
