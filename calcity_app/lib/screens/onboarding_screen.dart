import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// First-launch onboarding — 3 showcases then a signup prompt.
/// Calls [onComplete] when the user skips or finishes signing up.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _pages = <_PageData>[
    _PageData(
      icon: Icons.storefront_rounded,
      color: Color(0xFFB8573E),
      title: 'Promote Your\nBusiness',
      subtitle: 'Get featured to every local resident. \nGrow your customer base — it\'s free.',
    ),
    _PageData(
      icon: Icons.work_outline,
      color: Color(0xFF1565C0),
      title: 'Work as a\nFreelancer',
      subtitle: 'Offer your skills and take jobs around town. \nGet paid directly — no middleman.',
    ),
    _PageData(
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFC62828),
      title: 'Stay Alert &\nSafe',
      subtitle: 'Real-time emergency updates — floods, fires, \nroad closures, and severe weather alerts.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skip() => widget.onComplete();

  Future<void> _goSignup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
    if (!mounted) return;
    if (context.read<AuthProvider>().isLoggedIn) {
      widget.onComplete();
    }
  }

  Future<void> _goLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (!mounted) return;
    if (context.read<AuthProvider>().isLoggedIn) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: Text('Skip',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _buildPage(0, cs),
                  _buildPage(1, cs),
                  _buildPage(2, cs),
                ],
              ),
            ),
            // Dot indicators
            _buildDots(cs),
            const SizedBox(height: 16),
            // Sign-up button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _goSignup,
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text('Sign Up — It\'s Free'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _goLogin,
              child: const Text('Already have an account? Log In'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int index, ColorScheme cs) {
    final p = _pages[index];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            p.color.withValues(alpha: 0.12),
            p.color.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: p.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(p.icon, size: 52, color: p.color),
          ),
          const SizedBox(height: 36),
          Text(
            p.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44),
            child: Text(
              p.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.55,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildDots(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = _page == i;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _PageData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _PageData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}
