import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      await StorageService().setLoggedIn(true);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }

  Future<void> _handleQuickLogin() async {
    await StorageService().setLoggedIn(true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  void _toggleAuthMode(bool signUp) {
    setState(() {
      _isSignUp = signUp;
      _formKey.currentState?.reset();
    });
  }

  @override
  void dispose() {
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
                      // Top decorative organic leaves / waves
                      Positioned(
                        top: -10,
                        left: -10,
                        child: IgnorePointer(
                          child: CustomPaint(
                            size: const Size(150, 150),
                            painter: _TopLeftDecorPainter(),
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

                          // Bottom Rounded Form Sheet
                          Expanded(
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
                                    Text(
                                      _isSignUp ? 'Sign Up' : 'Login',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.pharmaNavy,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),

                                    // Username / Email input
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
                                    const SizedBox(height: AppSpacing.md),

                                    // Password input
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

                                    if (_isSignUp) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      _buildCleanInputField(
                                        controller: _confirmPasswordController,
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
                                      const SizedBox(height: AppSpacing.md),
                                      _buildCleanInputField(
                                        controller: _phoneController,
                                        hintText: 'Phone',
                                        icon: Icons.phone_outlined,
                                        keyboardType: TextInputType.phone,
                                      ),
                                      const SizedBox(height: AppSpacing.lg + 4),
                                    ] else ...[
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
                                            padding: const EdgeInsets.symmetric(
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
                                      const SizedBox(height: AppSpacing.md),
                                    ],

                                    // Primary Submit Button
                                    SizedBox(
                                      height: 52,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.pharmaNavy,
                                          foregroundColor: Colors.white,
                                          elevation: 2,
                                          shadowColor: AppColors.pharmaNavy
                                              .withAlpha(60),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusMd,
                                            ),
                                          ),
                                        ),
                                        onPressed: _handleSubmit,
                                        child: Text(
                                          _isSignUp ? 'Sign Up' : 'Login',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ),

                                    if (!_isSignUp) ...[
                                      const SizedBox(height: AppSpacing.lg + 2),
                                      Row(
                                        children: [
                                          const Expanded(
                                            child: Divider(
                                              color: AppColors.containerHigh,
                                              thickness: 1,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              'Or login with',
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    fontSize: 12,
                                                    color: AppColors.textMuted,
                                                  ),
                                            ),
                                          ),
                                          const Expanded(
                                            child: Divider(
                                              color: AppColors.containerHigh,
                                              thickness: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.md + 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _buildSocialButton(
                                            onTap: _handleQuickLogin,
                                            child: const Icon(
                                              Icons.facebook_rounded,
                                              color: Color(0xFF1877F2),
                                              size: 26,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          _buildSocialButton(
                                            onTap: _handleQuickLogin,
                                            child: CustomPaint(
                                              size: const Size(22, 22),
                                              painter: _GoogleLogoPainter(),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          _buildSocialButton(
                                            onTap: _handleQuickLogin,
                                            child: const Icon(
                                              Icons.apple_rounded,
                                              color: Colors.black87,
                                              size: 26,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      const SizedBox(height: AppSpacing.lg),
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
                                            onTap: () => _toggleAuthMode(true),
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
                                    ] else ...[
                                      const Spacer(),
                                      const SizedBox(height: AppSpacing.md),
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
                                            onTap: () => _toggleAuthMode(false),
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
                                    ],
                                    const SizedBox(height: AppSpacing.sm),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Overlapping botanical/pharma illustration on the right boundary
                      if (!_isSignUp)
                        Positioned(
                          top: headerHeight - 108,
                          right: 24,
                          child: IgnorePointer(
                            child: CustomPaint(
                              size: const Size(115, 140),
                              painter: _PharmaPlantPainter(),
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
  @override
  void paint(Canvas canvas, Size size) {
    final fill1 = Paint()
      ..color = Colors.white.withAlpha(24)
      ..style = PaintingStyle.fill;

    final fill2 = Paint()
      ..color = const Color(0xFFE07A68).withAlpha(90)
      ..style = PaintingStyle.fill;

    // Upper organic leaf lobe
    final path1 = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
        size.width * 0.75,
        4,
        size.width * 0.62,
        size.height * 0.42,
      )
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.68,
        0,
        size.height * 0.55,
      )
      ..close();
    canvas.drawPath(path1, fill2);

    // Lower organic leaf lobe
    final path2 = Path()
      ..moveTo(0, size.height * 0.25)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.35,
        size.width * 0.38,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.95,
        0,
        size.height * 0.88,
      )
      ..close();
    canvas.drawPath(path2, fill1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PharmaPlantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground shadow ellipse
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(18)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.91),
        width: w * 0.56,
        height: 11,
      ),
      shadowPaint,
    );

    // Back leaf (left)
    final backLeafPaint = Paint()
      ..color = const Color(0xFF56796C)
      ..style = PaintingStyle.fill;
    final leftLeaf = Path()
      ..moveTo(w * 0.46, h * 0.58)
      ..quadraticBezierTo(w * 0.14, h * 0.44, w * 0.20, h * 0.16)
      ..quadraticBezierTo(w * 0.44, h * 0.24, w * 0.50, h * 0.55)
      ..close();
    canvas.drawPath(leftLeaf, backLeafPaint);

    // Center tall leaf
    final centerLeafPaint = Paint()
      ..color = const Color(0xFF3D8063)
      ..style = PaintingStyle.fill;
    final centerLeaf = Path()
      ..moveTo(w * 0.52, h * 0.58)
      ..quadraticBezierTo(w * 0.36, h * 0.26, w * 0.55, h * 0.04)
      ..quadraticBezierTo(w * 0.74, h * 0.28, w * 0.58, h * 0.58)
      ..close();
    canvas.drawPath(centerLeaf, centerLeafPaint);

    // Right leaf
    final rightLeafPaint = Paint()
      ..color = const Color(0xFF6A9986)
      ..style = PaintingStyle.fill;
    final rightLeaf = Path()
      ..moveTo(w * 0.56, h * 0.58)
      ..quadraticBezierTo(w * 0.88, h * 0.46, w * 0.86, h * 0.20)
      ..quadraticBezierTo(w * 0.62, h * 0.26, w * 0.54, h * 0.56)
      ..close();
    canvas.drawPath(rightLeaf, rightLeafPaint);

    // Center leaf vein
    final veinPaint = Paint()
      ..color = Colors.white.withAlpha(90)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.54, h * 0.14),
      Offset(w * 0.54, h * 0.54),
      veinPaint,
    );

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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
