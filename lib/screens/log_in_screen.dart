import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_form_components.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _serverError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;
      _serverError = null;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _emailError = 'Please enter a valid email address.';
      valid = false;
    }

    if (_passwordController.text.isEmpty) {
      _passwordError = 'Password is required.';
      valid = false;
    }

    return valid;
  }

  Future<void> _onLogIn() async {
    if (!_validate()) return;

    setState(() {
      _isLoading = true;
      _serverError = null;
    });

    try {
      final body = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      final token = AuthService.extractToken(body);
      if (token != null) {
        // TODO: persist token securely (secure storage / keychain)
        // TODO: call GET /users/me to hydrate user profile
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        setState(() {
          _serverError = 'Login succeeded but no token was returned.';
        });
      }
    } on ApiException catch (e) {
      setState(() {
        if (e.statusCode == 401) {
          _serverError = 'Incorrect email or password.';
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
        // TODO: persist token securely
        // TODO: persist user from body['user']
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
                  'Welcome back',
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
                  'Log in to check on your plants.',
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
                        hint: 'Password',
                        enabled: !_isLoading,
                        errorText: _passwordError,
                      ),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/forgot-password');
                          },
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.accentDark,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Log In button
                      PrimaryButton(
                        label: 'Log In',
                        isLoading: _isLoading,
                        enabled: !_isLoading,
                        onPressed: _onLogIn,
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

                // Sign up link
                Center(
                  child: TextLink(
                    text: "Don't have an account? Sign up",
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/sign-up');
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
