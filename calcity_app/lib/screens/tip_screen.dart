import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TipScreen extends StatefulWidget {
  const TipScreen({super.key});

  @override
  State<TipScreen> createState() => _TipScreenState();
}

class _TipScreenState extends State<TipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedCategory;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  final List<String> _categories = [
    'General',
    'News Tip',
    'Event Suggestion',
    'Business Recommendation',
    'Community Issue',
    'Other',
  ];

  /// Map the dropdown's display label to the backend category slug.
  String _categorySlug(String? label) {
    switch (label) {
      case 'News Tip':
        return 'news';
      case 'Event Suggestion':
        return 'event';
      case 'Business Recommendation':
        return 'business';
      default:
        return 'general';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await ApiService().submitTip(
      name: _nameController.text,
      email: _emailController.text,
      content: _contentController.text,
      category: _categorySlug(_selectedCategory),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      setState(() {
        _isSubmitted = true;
        _nameController.clear();
        _emailController.clear();
        _contentController.clear();
        _selectedCategory = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you! Your tip has been submitted.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Submit a Tip')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _isSubmitted ? _buildThankYou(theme) : _buildForm(theme),
      ),
    );
  }

  Widget _buildThankYou(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 60),
        Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Colors.green.shade400,
        ),
        const SizedBox(height: 24),
        Text(
          'Thank You!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your tip has been submitted successfully.\n'
          'Our team will review it shortly.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () {
            setState(() => _isSubmitted = false);
          },
          icon: const Icon(Icons.add),
          label: const Text('Submit Another Tip'),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Share something with the community',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Your Name (optional)',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email (optional)',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(),
            ),
            items: _categories
                .map(
                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Your Tip *',
              hintText: 'Tell us what you know...',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(Icons.lightbulb_outline),
              ),
              border: OutlineInputBorder(),
            ),
            maxLines: 6,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your tip content';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_isSubmitting ? 'Submitting...' : 'Submit Tip'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
