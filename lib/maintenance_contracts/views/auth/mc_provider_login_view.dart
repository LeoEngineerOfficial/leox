import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../controllers/mc_provider_auth_controller.dart';
import 'mc_provider_register_view.dart';
import 'package:leox/widgets/custom_popup.dart';
import 'package:leox/services/session_service.dart';

class McProviderLoginView extends StatefulWidget {
  const McProviderLoginView({super.key});

  @override
  State<McProviderLoginView> createState() => _McProviderLoginViewState();
}

class _McProviderLoginViewState extends State<McProviderLoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final authController = context.read<McProviderAuthController>();
      await SessionService.saveTargetRole('mc_provider');
      final error = await authController.loginWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged in successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await CustomPopup.show(
          context,
          type: CustomPopupType.success,
          title: 'Welcome Back!',
          message: 'You have logged in successfully as a Service Provider.',
          buttonLabel: 'Go to Dashboard',
        );
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
        CustomPopup.show(
          context,
          type: CustomPopupType.error,
          title: 'Login Failed',
          message: error,
        );
      }
    }
  }

  void _loginWithGoogle() async {
    final authController = context.read<McProviderAuthController>();
    await SessionService.saveTargetRole('mc_provider');
    final error = await authController.signInWithGoogle();

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged in successfully with Google!'),
          backgroundColor: Colors.green,
        ),
      );
      await CustomPopup.show(
        context,
        type: CustomPopupType.success,
        title: 'Welcome Back!',
        message: 'You have logged in successfully as a Service Provider.',
        buttonLabel: 'Go to Dashboard',
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else if (error != "Sign-In cancelled by user") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
      CustomPopup.show(
        context,
        type: CustomPopupType.error,
        title: 'Google Sign-In Failed',
        message: error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authController = context.watch<McProviderAuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Provider Portal"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.scaffoldBackgroundColor, const Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(6.w),
            child: Card(
              color:
                  theme.cardTheme.color ??
                  (isDark ? Colors.black87 : Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                ),
              ),
              elevation: 8,
              child: Padding(
                padding: EdgeInsets.all(6.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.engineering_outlined,
                        size: 42.sp,
                        color: const Color(0xFF0EA5E9),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "Service Provider Login",
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        "Log in to manage your maintenance contracts.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                          fontSize: 17.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16.sp),
                        decoration: InputDecoration(
                          hintText: "Enter email address",
                          hintStyle: TextStyle(
                            fontSize: 16.sp,
                            color: theme.hintColor.withValues(alpha: 0.6),
                          ),
                          labelText: "Email",
                          labelStyle: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                            fontSize: 16.sp,
                          ),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Color(0xFF0EA5E9),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF0EA5E9),
                            ),
                          ),
                        ),
                        validator:
                            (value) =>
                                (value == null || value.isEmpty)
                                    ? "Please enter your email"
                                    : null,
                      ),
                      SizedBox(height: 2.h),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16.sp),
                        decoration: InputDecoration(
                          hintText: "Enter password",
                          hintStyle: TextStyle(
                            fontSize: 16.sp,
                            color: theme.hintColor.withValues(alpha: 0.6),
                          ),
                          labelText: "Password",
                          labelStyle: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                            fontSize: 16.sp,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Color(0xFF0EA5E9),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[700],
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  isDark
                                      ? Colors.grey[800]!
                                      : Colors.grey[300]!,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF0EA5E9),
                            ),
                          ),
                        ),
                        validator:
                            (value) =>
                                (value == null || value.isEmpty)
                                    ? "Please enter your password"
                                    : null,
                      ),
                      SizedBox(height: 4.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: authController.isLoading ? null : _login,
                          child:
                              authController.isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              authController.isLoading
                                  ? null
                                  : _loginWithGoogle,
                          icon:
                              authController.isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0EA5E9),
                                    ),
                                  )
                                  : Image.asset(
                                    'assets/icons/google_logo.png',
                                    height: 24,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.g_mobiledata,
                                              size: 24,
                                              color: Color(0xFF0EA5E9),
                                            ),
                                  ),
                          label: Text(
                            authController.isLoading
                                ? "Signing in..."
                                : "Sign In with Google",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            side: BorderSide(
                              color: const Color(
                                0xFF0EA5E9,
                              ).withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const McProviderRegisterView(),
                            ),
                          );
                        },
                        child: Text(
                          "Don't have an account? Register",
                          style: TextStyle(
                            color: const Color(0xFF0EA5E9),
                            fontSize: 18.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
