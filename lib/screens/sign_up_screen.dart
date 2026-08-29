import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_form_components.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  String? _serverError;

  // Field errors
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
      _serverError = null;
    });

    final name = _nameController.text.trim();
    if (name.isEmpty || name.length < 2) {
      _nameError = 'Name must be at least 2 characters.';
      valid = false;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _emailError = 'Please enter a valid email address.';
      valid = false;
    }

    final password = _passwordController.text;
    if (password.length < 8) {
      _passwordError = 'Password must be at least 8 characters.';
      valid = false;
    }

    final confirm = _confirmController.text;
    if (confirm != password) {
      _confirmError = 'Passwords do not match.';
      valid = false;
    }

    return valid;
  }

  Future<void> _onSignUp() async {
    if (!_validate()) return;

    setState(() {
      _isLoading = true;
      _serverError = null;
    });

    try {
      await AuthService.register(
        email: _emailController.text.trim(),
        fullName: _nameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // On success, navigate to Log In with a success message.
      // TODO: if /register returns tokens, adapt to auto-login instead.
      Navigator.of(context).pop('account_created');
    } on ApiException catch (e) {
      setState(() {
        if (e.statusCode == 409) {
          _serverError =
              'An account with this email already exists.';
        } else if (e.statusCode >= 500) {
          _serverError = 'Something went wrong. Please try again.';
        } else {
          _serverError = e.message;
        }
      });
    } catch (_) {
      setState(() {
        _serverError =
            "Couldn't reach PlantPal. Check your connection and try again.";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _serverError = null;
    });

    try {
      // TODO: replace with real Google Sign-In SDK integration
      const idToken = 'PLACEHOLDER_GOOGLE_ID_TOKEN';
      final body = await AuthService.loginWithGoogle(idToken);

      if (!mounted) return;

      final token = AuthService.extractToken(body);
      if (token != null) {
        // TODO: persist token securely (secure storage / keychain)
        // TODO: persist user object from body['user']
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        setState(() {
          _serverError = 'Google sign-in failed. Please try again.';
        });
      }
    } on ApiException catch (e) {
      setState(() {
        if (e.statusCode == 409) {
          _serverError =
              'This email is already registered with a password. Try logging in with email instead.';
        } else {
          _serverError = 'Google sign-in failed. Please try again.';
        }
      });
    } catch (_) {
      setState(() {
        _serverError =
            "Couldn't reach PlantPal. Check your connection and try again.";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.sageTop, AppColors.sageBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                _BackButton(
                  onTap: () => Navigator.of(context).pop(),
                ),

                const SizedBox(height: 24),

                // Headline
                const Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cream,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start growing smarter with PlantPal.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.cream.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 32),

                // Form card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Server error banner
                      if (_serverError != null) ...[
                        ErrorBanner(
                          message: _serverError!,
                          onDismiss: () => setState(() => _serverError = null),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Full Name
                      AuthTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Jane Doe',
                        enabled: !_isLoading,
                        errorText: _nameError,
                      ),

                      const SizedBox(height: 16),

                      // Email
                      AuthTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                        errorText: _emailError,
                      ),

                      const SizedBox(height: 16),

                      // Password
                      AuthPasswordField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'At least 8 characters',
                        enabled: !_isLoading,
                        errorText: _passwordError,
                      ),

                      const SizedBox(height: 16),

                      // Confirm Password
                      AuthPasswordField(
                        controller: _confirmController,
                        label: 'Confirm Password',
                        hint: 'Re-enter password',
                        enabled: !_isLoading,
                        errorText: _confirmError,
                      ),

                      const SizedBox(height: 24),

                      // Create Account button
                      PrimaryButton(
                        label: 'Create Account',
                        isLoading: _isLoading,
                        enabled: !_isLoading,
                        onPressed: _onSignUp,
                      ),

                      const SizedBox(height: 20),

                      const OrDivider(),

                      const SizedBox(height: 20),

                      // Google button
                      GoogleButton(
                        onPressed: _onGoogleSignIn,
                        enabled: !_isLoading,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Already have account link
                Center(
                  child: TextLink(
                    text: 'Already have an account? Log in',
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Back Button
// ---------------------------------------------------------------------------

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.cream.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          LucideIcons.chevronLeft,
          color: AppColors.cream,
          size: 26,
        ),
      ),
    );
  }
}
