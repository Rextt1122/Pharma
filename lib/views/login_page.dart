import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/biometric_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _ambientController;
  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _sheetSlide;
  late final Animation<double> _plantScale;

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  final BiometricService _biometricService = BiometricService();
  bool _canUseBiometrics = false;
  bool _isAuthenticatingBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();

    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.05, 0.70, curve: Curves.easeOutCubic),
      ),
    );
    _plantScale = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.95, curve: Curves.easeOutBack),
    );
  }

  Widget _buildStaggered(int step, Widget child) {
    final double start = (0.12 + step * 0.08).clamp(0.0, 0.75);
    final double end = (start + 0.42).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _entranceController,
      child: child,
      builder: (context, ch) {
        final double raw =
            ((_entranceController.value - start) / (end - start)).clamp(
              0.0,
              1.0,
            );
        final double curved = Curves.easeOutCubic.transform(raw);
        final double scale = 0.94 + (0.06 * curved);
        return Opacity(
          opacity: curved,
          child: Transform.translate(
            offset: Offset(0, 26 * (1.0 - curved)),
            child: Transform.scale(scale: scale, child: ch),
          ),
        );
      },
    );
  }

  Future<void> _checkBiometrics() async {
    final supported = await _biometricService.isDeviceSupported();
    final enabled = await StorageService().isBiometricEnabled();
    final hasToken = await StorageService().hasBiometricToken();
    if (mounted) {
      setState(() => _canUseBiometrics = supported && enabled && hasToken);
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (_isAuthenticatingBiometric) return;
    setState(() => _isAuthenticatingBiometric = true);
    try {
      final authenticated = await _biometricService.authenticate(
        reason: 'Pindai sidik jari untuk masuk ke Smart Pharma',
      );
      if (!authenticated) return;

      // Biometrik hanya membuka token yang diterbitkan server, bukan login baru.
      final restored = await StorageService().restoreSessionFromBiometric();
      if (!mounted) return;
      if (restored) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        setState(() => _canUseBiometrics = false);
        AppToast.error(context, 'Sesi kedaluwarsa. Login dengan password.');
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticatingBiometric = false);
      }
    }
  }

  Future<void> _showServerConfigSheet() async {
    final currentIp = await StorageService().getServerIp();
    final ipCtrl = TextEditingController(text: currentIp);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Konfigurasi Server / VPS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Masukkan IP laptop pada hotspot (contoh: 192.168.253.238) atau domain server/VPS jika sudah live.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ipCtrl,
                    decoration: InputDecoration(
                      labelText: 'IP Server / Host',
                      hintText: '192.168.253.238',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      filled: true,
                      fillColor: AppColors.inputBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pharmaNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final newIp = ipCtrl.text.trim();
                              if (newIp.isEmpty) {
                                AppToast.error(context, 'IP Server tidak boleh kosong');
                                return;
                              }
                              setModalState(() => isSaving = true);
                              await StorageService().saveServerIp(newIp);
                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                              if (mounted) {
                                AppToast.success(context, 'Server disetel ke: $newIp');
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Simpan Konfigurasi',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      try {
        if (_isSignUp) {
          final email = _emailController.text.trim();
          final fullName = username;

          final res = await ApiService().register(
            username: username,
            password: password,
            fullName: fullName.isNotEmpty ? fullName : 'Petugas Farmasi',
            email: email,
          );
          final user = (res['user'] as Map<String, dynamic>?) ?? {};
          final role = user['role']?.toString() ?? 'user';

          await StorageService().saveUserProfile(
            name: user['name']?.toString() ?? fullName,
            email: user['email']?.toString() ?? email,
            provider: 'Database MySQL ($role)',
            role: role,
          );

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/main');
          }
        } else {
          final res = await ApiService().login(username, password);
          final user = (res['user'] as Map<String, dynamic>?) ?? {};
          final userName = user['name']?.toString() ?? user['full_name']?.toString() ?? username;
          final userEmail = user['email']?.toString() ?? (username.contains('@') ? username : '$username@smartpharma.id');
          final role = user['role']?.toString() ?? 'operator';

          await StorageService().saveUserProfile(
            name: userName,
            email: userEmail,
            provider: 'Database MySQL ($role)',
            role: role,
          );

          if (mounted) {
            Navigator.pushReplacementNamed(context, '/main');
          }
        }
      } catch (e) {
        if (mounted) {
          final cleanMsg = e.toString().replaceAll('Exception: ', '');
          AppToast.error(context, cleanMsg);
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  void _toggleAuthMode(bool signUp) {
    setState(() {
      _isSignUp = signUp;
      _formKey.currentState?.reset();
    });
    _entranceController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _entranceController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double headerHeight = _isSignUp ? 165.0 : 250.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.pharmaNavy,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      // Animated top decorative organic leaves / waves & floating orbs
                      Positioned(
                        top: -10,
                        left: -10,
                        right: 0,
                        height: 260,
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _ambientController,
                              builder: (context, _) {
                                return CustomPaint(
                                  painter: _TopLeftDecorPainter(
                                    progress: _ambientController.value,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // Server IP Config button in top right
                      Positioned(
                        top: 14,
                        right: 18,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _showServerConfigSheet,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.dns_rounded, size: 14, color: Colors.white),
                                  SizedBox(width: 5),
                                  Text(
                                    'Server IP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Main vertical structure
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Header Area
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            height: headerHeight,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg + 4,
                            ),
                            child: FadeTransition(
                              opacity: _headerFade,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isSignUp) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    InkWell(
                                      onTap: () => _toggleAuthMode(false),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm,
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 4,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.arrow_back_ios_new_rounded,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Back to login',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: AppSpacing.md),
                                    const Text(
                                      'Smart Pharma',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Monitoring & Akses Gudang',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(200),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Bottom Rounded Form Sheet
                          Expanded(
                            child: SlideTransition(
                              position: _sheetSlide,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg + 4,
                                  AppSpacing.xl + 4,
                                  AppSpacing.lg + 4,
                                  AppSpacing.lg,
                                ),
                              decoration: const BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(36),
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildStaggered(
                                      0,
                                      Text(
                                        _isSignUp ? 'Sign Up' : 'Login',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.pharmaNavy,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),

                                    // Username input (Login: Username/Email, SignUp: Username)
                                    _buildStaggered(
                                      1,
                                      _buildCleanInputField(
                                        controller: _usernameController,
                                        hintText: _isSignUp ? 'Username' : 'Username or Email',
                                        icon: Icons.person_outline_rounded,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Username tidak boleh kosong';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    if (_isSignUp) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      _buildStaggered(
                                        2,
                                        _buildCleanInputField(
                                          controller: _emailController,
                                          hintText: 'Email (contoh: nama@domain.com)',
                                          icon: Icons.mail_outline_rounded,
                                          keyboardType: TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Email wajib diisi';
                                            }
                                            if (!value.contains('@') ||
                                                !value.contains('.')) {
                                              return 'Format email tidak valid';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.md),

                                    // Password input
                                    _buildStaggered(
                                      _isSignUp ? 3 : 2,
                                      _buildCleanInputField(
                                        controller: _passwordController,
                                        hintText: 'Password',
                                        icon: Icons.lock_outline_rounded,
                                        obscureText: _obscurePassword,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 18,
                                            color: AppColors.textMuted,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Password tidak boleh kosong';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),

                                    if (_isSignUp) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      _buildStaggered(
                                        4,
                                        _buildCleanInputField(
                                          controller:
                                              _confirmPasswordController,
                                          hintText: 'Confirm password',
                                          icon: Icons.lock_reset_rounded,
                                          obscureText: _obscurePassword,
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Konfirmasi password wajib diisi';
                                            }
                                            if (value !=
                                                _passwordController.text) {
                                              return 'Password tidak sama';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg + 4),
                                    ] else ...[
                                      _buildStaggered(
                                        3,
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              AppToast.info(
                                                context,
                                                'Hubungi admin gudang untuk reset kredensial.',
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.pharmaNavy,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 8,
                                                  ),
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: const Text(
                                              'Forgot Password',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.pharmaNavy,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                    ],

                                    // Primary Submit Button
                                    _buildStaggered(
                                      _isSignUp ? 5 : 4,
                                      Row(
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              height: 52,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.pharmaNavy,
                                                  foregroundColor: Colors.white,
                                                  elevation: 2,
                                                  shadowColor: AppColors.pharmaNavy
                                                      .withAlpha(60),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppSpacing.radiusMd,
                                                        ),
                                                  ),
                                                ),
                                                onPressed: _isSubmitting
                                                    ? null
                                                    : _handleSubmit,
                                                child: _isSubmitting
                                                    ? const SizedBox(
                                                        width: 22,
                                                        height: 22,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2.4,
                                                              color: Colors.white,
                                                            ),
                                                      )
                                                    : Text(
                                                        _isSignUp
                                                            ? 'Sign Up'
                                                            : 'Login',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w800,
                                                          letterSpacing: 0.3,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                          if (!_isSignUp && _canUseBiometrics) ...[
                                            const SizedBox(width: AppSpacing.sm + 2),
                                            SizedBox(
                                              height: 52,
                                              width: 52,
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  side: const BorderSide(
                                                    color: AppColors.pharmaNavy,
                                                    width: 1.5,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          AppSpacing.radiusMd,
                                                        ),
                                                  ),
                                                  backgroundColor: AppColors.cardWhite,
                                                ),
                                                onPressed: _isAuthenticatingBiometric
                                                    ? null
                                                    : _handleBiometricLogin,
                                                child: _isAuthenticatingBiometric
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: AppColors.pharmaNavy,
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons.fingerprint_rounded,
                                                        color: AppColors.pharmaNavy,
                                                        size: 28,
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    if (!_isSignUp) ...[
                                      const Spacer(),
                                      const SizedBox(height: AppSpacing.lg),
                                      _buildStaggered(
                                        6,
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Don't have account? ",
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    fontSize: 13,
                                                    color: AppColors.textMuted,
                                                  ),
                                            ),
                                            GestureDetector(
                                              onTap: () =>
                                                  _toggleAuthMode(true),
                                              child: const Text(
                                                'Sign Up',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.pharmaNavy,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      const Spacer(),
                                      const SizedBox(height: AppSpacing.md),
                                      _buildStaggered(
                                        6,
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Already have an account? ',
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    fontSize: 13,
                                                    color: AppColors.textMuted,
                                                  ),
                                            ),
                                            GestureDetector(
                                              onTap: () =>
                                                  _toggleAuthMode(false),
                                              child: const Text(
                                                'Login',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.pharmaNavy,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.sm),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Overlapping botanical/pharma illustration on the right boundary (both Login & Sign Up)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOutBack,
                      top: headerHeight - (_isSignUp ? 72 : 88),
                      right: _isSignUp ? 18 : 22,
                      child: IgnorePointer(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.easeOutBack,
                          scale: _isSignUp ? 0.85 : 1.0,
                          alignment: Alignment.bottomCenter,
                          child: ScaleTransition(
                            scale: _plantScale,
                            alignment: Alignment.bottomCenter,
                            child: RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: _ambientController,
                                builder: (context, _) {
                                  return CustomPaint(
                                    size: const Size(88, 108),
                                    painter: _PharmaPlantPainter(
                                      progress: _ambientController.value,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCleanInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: AppTypography.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFFA0938E),
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          prefixIcon: Icon(icon, color: const Color(0xFFA0938E), size: 20),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(
              color: AppColors.pharmaNavy,
              width: 1.4,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.alertRed, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.alertRed, width: 1.5),
          ),
        ),
        validator: validator,
      ),
    );
  }

}

class _TopLeftDecorPainter extends CustomPainter {
  final double progress;

  _TopLeftDecorPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double angle = progress * 2 * math.pi;
    final double wave1 = math.sin(angle);
    final double wave2 = math.cos(angle);

    final fill1 = Paint()
      ..color = Colors.white.withAlpha(24)
      ..style = PaintingStyle.fill;

    final fill2 = Paint()
      ..color = AppColors.pharmaTeal.withAlpha(115)
      ..style = PaintingStyle.fill;

    final orbPaint = Paint()
      ..color = Colors.white.withAlpha(18)
      ..style = PaintingStyle.fill;

    // Upper organic leaf lobe (breathing & swaying)
    final path1 = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
        115 + wave1 * 12,
        4 + wave2 * 6,
        94 + wave2 * 10,
        64 + wave1 * 8,
      )
      ..quadraticBezierTo(
        68 + wave1 * 8,
        104 + wave2 * 10,
        0,
        84 + wave1 * 6,
      )
      ..close();
    canvas.drawPath(path1, fill2);

    // Lower organic leaf lobe (counter-swaying)
    final path2 = Path()
      ..moveTo(0, 36 + wave2 * 4)
      ..quadraticBezierTo(
        80 + wave2 * 10,
        52 + wave1 * 8,
        58 + wave1 * 9,
        118 + wave2 * 8,
      )
      ..quadraticBezierTo(
        34 + wave2 * 6,
        144 + wave1 * 6,
        0,
        134 + wave2 * 6,
      )
      ..close();
    canvas.drawPath(path2, fill1);

    // Floating ambient circles in header right/top
    canvas.drawCircle(
      Offset(size.width * 0.78 + wave1 * 8, 44 + wave2 * 7),
      26 + wave1 * 3,
      orbPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.62 - wave2 * 6, 86 + wave1 * 5),
      12 + wave2 * 2,
      fill2,
    );
  }

  @override
  bool shouldRepaint(covariant _TopLeftDecorPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _PharmaPlantPainter extends CustomPainter {
  final double progress;

  _PharmaPlantPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final double angle = progress * 2 * math.pi;
    final double sway = math.sin(angle);
    final double swaySecondary = math.cos(angle);
    final double bob = math.sin(angle * 2) * 1.8;

    // Ground shadow ellipse (scales slightly with plant motion)
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(18)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52 + sway * 1.5, h * 0.91),
        width: w * (0.56 + sway * 0.03),
        height: 11,
      ),
      shadowPaint,
    );

    canvas.save();
    canvas.translate(0, bob);

    // Back leaf (left) - sways gently
    final backLeafPaint = Paint()
      ..color = const Color(0xFF56796C)
      ..style = PaintingStyle.fill;
    final leftLeaf = Path()
      ..moveTo(w * 0.46, h * 0.58)
      ..quadraticBezierTo(
        w * 0.14 + sway * 5.0,
        h * 0.44 + swaySecondary * 2.5,
        w * 0.20 + sway * 7.5,
        h * 0.16 + swaySecondary * 3.0,
      )
      ..quadraticBezierTo(
        w * 0.44 + sway * 4.0,
        h * 0.24,
        w * 0.50,
        h * 0.55,
      )
      ..close();
    canvas.drawPath(leftLeaf, backLeafPaint);

    // Center tall leaf - sways with primary breeze
    final centerLeafPaint = Paint()
      ..color = const Color(0xFF3D8063)
      ..style = PaintingStyle.fill;
    final centerLeaf = Path()
      ..moveTo(w * 0.52, h * 0.58)
      ..quadraticBezierTo(
        w * 0.36 + swaySecondary * 4.5,
        h * 0.26,
        w * 0.55 + sway * 6.5,
        h * 0.04 + swaySecondary * 2.0,
      )
      ..quadraticBezierTo(
        w * 0.74 + sway * 4.5,
        h * 0.28,
        w * 0.58,
        h * 0.58,
      )
      ..close();
    canvas.drawPath(centerLeaf, centerLeafPaint);

    // Right leaf - sways with phase offset
    final rightLeafPaint = Paint()
      ..color = const Color(0xFF6A9986)
      ..style = PaintingStyle.fill;
    final rightLeaf = Path()
      ..moveTo(w * 0.56, h * 0.58)
      ..quadraticBezierTo(
        w * 0.88 + swaySecondary * 5.0,
        h * 0.46 - sway * 2.0,
        w * 0.86 + swaySecondary * 7.5,
        h * 0.20 + sway * 3.0,
      )
      ..quadraticBezierTo(
        w * 0.62 + swaySecondary * 4.0,
        h * 0.26,
        w * 0.54,
        h * 0.56,
      )
      ..close();
    canvas.drawPath(rightLeaf, rightLeafPaint);

    // Center leaf vein (follows center leaf sway)
    final veinPaint = Paint()
      ..color = Colors.white.withAlpha(95)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final veinPath = Path()
      ..moveTo(w * 0.54, h * 0.54)
      ..quadraticBezierTo(
        w * 0.53 + sway * 3.0,
        h * 0.32,
        w * 0.54 + sway * 5.2,
        h * 0.14 + swaySecondary * 1.5,
      );
    canvas.drawPath(veinPath, veinPaint);

    // White planter / pharma vessel
    final potPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final potPath = Path()
      ..moveTo(w * 0.30, h * 0.54)
      ..lineTo(w * 0.74, h * 0.54)
      ..lineTo(w * 0.67, h * 0.86)
      ..quadraticBezierTo(w * 0.52, h * 0.92, w * 0.37, h * 0.86)
      ..close();
    canvas.drawPath(potPath, potPaint);

    // Subtle pot rim
    final rimPaint = Paint()
      ..color = const Color(0xFFF0E9E4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.28, h * 0.51, w * 0.48, 7),
        const Radius.circular(4),
      ),
      rimPaint,
    );

    // Medical cross emblem on the white pot
    final crossPaint = Paint()
      ..color = AppColors.pharmaNavy.withAlpha(200)
      ..style = PaintingStyle.fill;
    final cx = w * 0.52;
    final cy = h * 0.70;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 4.5, height: 14),
        const Radius.circular(1.5),
      ),
      crossPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 14, height: 4.5),
        const Radius.circular(1.5),
      ),
      crossPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PharmaPlantPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
