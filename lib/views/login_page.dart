import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _ambientController;
  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _sheetSlide;
  late final Animation<double> _plantScale;

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      await Future.delayed(const Duration(milliseconds: 450));
      final rawInput = _usernameController.text.trim();
      final isEmail = rawInput.contains('@');
      final displayName = isEmail
          ? rawInput.split('@').first.replaceAll('.', ' ')
          : rawInput;
      final email = isEmail ? rawInput : '$rawInput@smartpharma.id';

      await StorageService().saveUserProfile(
        name: displayName.isNotEmpty ? displayName : 'Admin Farmasi',
        email: email,
        provider: 'Smart Pharma',
      );
      await StorageService().setLoggedIn(true);
      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }

  Future<void> _completeSsoLogin({
    required String name,
    required String email,
    required String provider,
  }) async {
    await StorageService().saveUserProfile(
      name: name,
      email: email,
      provider: provider,
    );
    await StorageService().setLoggedIn(true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Berhasil masuk via $provider sebagai $name'),
        backgroundColor: AppColors.pharmaNavy,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pushReplacementNamed(context, '/main');
  }

  void _showSsoAccountPicker(String provider) {
    final bool isGoogle = provider == 'Google';
    final bool isFacebook = provider == 'Facebook';

    final String domain = isGoogle
        ? 'gmail.com'
        : (isFacebook ? 'facebook.com' : 'icloud.com');
    final Color brandColor = isGoogle
        ? const Color(0xFF4285F4)
        : (isFacebook ? const Color(0xFF1877F2) : Colors.black87);

    final List<Map<String, String>> presetAccounts = [
      {
        'name': 'Fabian (Admin Farmasi)',
        'email': 'fabian.pharma@$domain',
        'role': 'Kepala Gudang Vaksin',
      },
      {
        'name': 'Operator Cold Storage',
        'email': 'coldstorage.unit1@$domain',
        'role': 'Petugas Shift Aktif',
      },
    ];

    final customNameCtrl = TextEditingController();
    final customEmailCtrl = TextEditingController();
    bool useCustomAccount = false;
    bool isAuthenticating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusMd),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> selectAccount(String name, String email) async {
              setSheetState(() => isAuthenticating = true);
              await Future.delayed(const Duration(milliseconds: 500));
              if (sheetContext.mounted) {
                Navigator.pop(sheetContext);
              }
              await _completeSsoLogin(
                name: name,
                email: email,
                provider: provider,
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md + 4,
                bottom:
                    MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.containerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.inputBg,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: isGoogle
                            ? CustomPaint(
                                size: const Size(22, 22),
                                painter: _GoogleLogoPainter(),
                              )
                            : Icon(
                                isFacebook
                                    ? Icons.facebook_rounded
                                    : Icons.apple_rounded,
                                color: brandColor,
                                size: 26,
                              ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Masuk dengan $provider',
                              style: AppTypography.subtitle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Pilih akun $provider untuk lanjut ke Smart Pharma',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(color: AppColors.containerLow, height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  if (isAuthenticating)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: brandColor,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Menghubungkan akun $provider...',
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!useCustomAccount) ...[
                    ...presetAccounts.map((acc) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: InkWell(
                          onTap: () =>
                              selectAccount(acc['name']!, acc['email']!),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.inputBg,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                              border: Border.all(
                                color: AppColors.containerHigh,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: brandColor.withAlpha(28),
                                  child: Text(
                                    acc['name']!.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color: brandColor,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        acc['name']!,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      Text(
                                        acc['email']!,
                                        style: AppTypography.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () {
                        setSheetState(() => useCustomAccount = true);
                      },
                      icon: Icon(
                        Icons.person_add_alt_1_outlined,
                        size: 18,
                        color: brandColor,
                      ),
                      label: Text(
                        'Gunakan akun $provider lain',
                        style: TextStyle(
                          color: brandColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Nama Akun',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: customNameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Fabian',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        filled: true,
                        fillColor: AppColors.inputBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.containerHigh,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Email $provider',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: customEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'nama@$domain',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        filled: true,
                        fillColor: AppColors.inputBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          borderSide: const BorderSide(
                            color: AppColors.containerHigh,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setSheetState(() => useCustomAccount = false);
                          },
                          child: const Text('Kembali'),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: brandColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                          ),
                          onPressed: () {
                            final emailInput = customEmailCtrl.text.trim();
                            final nameInput = customNameCtrl.text.trim();
                            final finalEmail = emailInput.isNotEmpty
                                ? (emailInput.contains('@')
                                      ? emailInput
                                      : '$emailInput@$domain')
                                : 'user@$domain';
                            final finalName = nameInput.isNotEmpty
                                ? nameInput
                                : finalEmail.split('@').first;
                            selectAccount(finalName, finalEmail);
                          },
                          child: Text('Lanjutkan dengan $provider'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
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
                                      'Hello!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 42,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.8,
                                        height: 1.05,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Welcome to Smart Pharma',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(220),
                                        fontSize: 16,
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

                                    // Username / Email input
                                    _buildStaggered(
                                      1,
                                      _buildCleanInputField(
                                        controller: _usernameController,
                                        hintText: 'Email or Username',
                                        icon: Icons.mail_outline_rounded,
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Username / Email tidak boleh kosong';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),

                                    // Password input
                                    _buildStaggered(
                                      2,
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
                                        3,
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
                                      const SizedBox(height: AppSpacing.md),
                                      _buildStaggered(
                                        4,
                                        _buildCleanInputField(
                                          controller: _phoneController,
                                          hintText: 'Phone',
                                          icon: Icons.phone_outlined,
                                          keyboardType: TextInputType.phone,
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
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Hubungi admin gudang untuk reset kredensial.',
                                                  ),
                                                  backgroundColor:
                                                      AppColors.pharmaNavy,
                                                ),
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
                                      SizedBox(
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

                                    if (!_isSignUp) ...[
                                      const SizedBox(height: AppSpacing.lg + 2),
                                      _buildStaggered(
                                        5,
                                        Column(
                                          children: [
                                            Row(
                                              children: [
                                                const Expanded(
                                                  child: Divider(
                                                    color:
                                                        AppColors.containerHigh,
                                                    thickness: 1,
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                      ),
                                                  child: Text(
                                                    'Or login with',
                                                    style: AppTypography.caption
                                                        .copyWith(
                                                          fontSize: 12,
                                                          color: AppColors
                                                              .textMuted,
                                                        ),
                                                  ),
                                                ),
                                                const Expanded(
                                                  child: Divider(
                                                    color:
                                                        AppColors.containerHigh,
                                                    thickness: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.md + 4,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                _buildSocialButton(
                                                  onTap: () =>
                                                      _showSsoAccountPicker(
                                                        'Facebook',
                                                      ),
                                                  child: const Icon(
                                                    Icons.facebook_rounded,
                                                    color: Color(0xFF1877F2),
                                                    size: 26,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: AppSpacing.md,
                                                ),
                                                _buildSocialButton(
                                                  onTap: () =>
                                                      _showSsoAccountPicker(
                                                        'Google',
                                                      ),
                                                  child: CustomPaint(
                                                    size: const Size(22, 22),
                                                    painter:
                                                        _GoogleLogoPainter(),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: AppSpacing.md,
                                                ),
                                                _buildSocialButton(
                                                  onTap: () =>
                                                      _showSsoAccountPicker(
                                                        'Apple',
                                                      ),
                                                  child: const Icon(
                                                    Icons.apple_rounded,
                                                    color: Colors.black87,
                                                    size: 26,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
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
                      top: headerHeight - (_isSignUp ? 92 : 108),
                      right: _isSignUp ? 18 : 24,
                      child: IgnorePointer(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.easeOutBack,
                          scale: _isSignUp ? 0.82 : 1.0,
                          alignment: Alignment.bottomCenter,
                          child: ScaleTransition(
                            scale: _plantScale,
                            alignment: Alignment.bottomCenter,
                            child: RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: _ambientController,
                                builder: (context, _) {
                                  return CustomPaint(
                                    size: const Size(115, 140),
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

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        width: 68,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
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

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w * 0.42;

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Red top arc
    stroke.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.35, 1.65, false, stroke);

    // Yellow left arc
    stroke.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.25, 1.35, false, stroke);

    // Green bottom arc
    stroke.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.85, 1.45, false, stroke);

    // Blue right arc + bar
    stroke.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.15, 1.05, false, stroke);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - 1.8, radius + 1.5, 3.6),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
