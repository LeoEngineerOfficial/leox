import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leox/providers/employee_providers/employee_auth_provider.dart';
import 'package:leox/views/employee/employee_register_view.dart';
import 'package:leox/views/general/role_option_view.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:leox/widgets/custom_popup.dart';
import 'package:leox/services/session_service.dart';

class EmployeeLoginView extends StatefulWidget {
  const EmployeeLoginView({super.key});

  @override
  State<EmployeeLoginView> createState() => _EmployeeLoginViewState();
}

class _EmployeeLoginViewState extends State<EmployeeLoginView> {
  bool isEmailSelected = true;
  bool isOtpSent = false;
  bool _obscurePassword = true;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  String selectedCountryCode = "+91";

  late EmployeeAuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    // Initialize provider access safely
    _authProvider = context.read<EmployeeAuthProvider>();
  }



  void _clearError() {
    _authProvider.clearError();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 42.w,
        leading: TextButton.icon(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RoleOptionView()),
            );
          },
          icon: Icon(Icons.home, color: theme.iconTheme.color),
          label: Text(
            "Change Role",
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.scaffoldBackgroundColor,
              isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(6.w),
            child: Card(
              color: theme.cardTheme.color ?? (isDark ? Colors.black87 : Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
              ),
              elevation: 8,
              child: Padding(
                padding: EdgeInsets.all(6.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                          child: Icon(
                            Icons.business_center_outlined,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Employee Login",
                          style: TextStyle(
                            fontSize: 23.sp,// Updated from 20.0 to 21.sp
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Sign in to apply for jobs.",
                      style: TextStyle(
                        fontSize: 17.sp,  // Updated from 14.0 to 15.sp
                        color: isDark ? Colors.grey[400] : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _tabButton(
                              context,
                              "Email",
                              selected: isEmailSelected,
                              onTap: () => setState(() {
                                isEmailSelected = true;
                                isOtpSent = false;
                              }),
                            ),
                          ),
                          Expanded(
                            child: _tabButton(
                              context,
                              "Phone",
                              selected: !isEmailSelected,
                              onTap: () => setState(() {
                                isEmailSelected = false;
                                isOtpSent = false;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (isEmailSelected) ...[
                      _label(context, "Email"),
                      const SizedBox(height: 8),
                      _inputField(
                          controller: emailController,
                          hintText: "Enter your email",
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 20),
                      _label(context, "Password"),
                      const SizedBox(height: 8),
                      _inputField(
                          controller: passwordController,
                          hintText: "Enter your password",
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () {
                            setState(() { _obscurePassword = !_obscurePassword; });
                          }),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPasswordDialog(context),
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      if (!isOtpSent) ...[
                        _label(context, "Phone Number"),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.dividerColor),
                                borderRadius: BorderRadius.circular(12),
                                color: theme.inputDecorationTheme.fillColor,
                              ),
                              child: DropdownButton<String>(
                                value: selectedCountryCode,
                                dropdownColor: theme.cardTheme.color,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(value: "+91", child: Text("+91")),
                                  DropdownMenuItem(value: "+1", child: Text("+1")),
                                  DropdownMenuItem(value: "+44", child: Text("+44")),
                                  DropdownMenuItem(value: "+61", child: Text("+61")),
                                ],
                                onChanged: (v) => setState(() => selectedCountryCode = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _inputField(
                                controller: phoneController,
                                hintText: "Enter phone number",
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        _label(context, "Verification Code"),
                        const SizedBox(height: 8),
                        _inputField(
                          controller: otpController,
                          hintText: "Enter 6-digit OTP",
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => isOtpSent = false),
                            child: const Text("Back"),
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 32),

                    Consumer<EmployeeAuthProvider>(
                      builder: (context, auth, _) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: auth.isLoading
                                ? null
                                : () async {
                                    final provider = context.read<EmployeeAuthProvider>();
                                    await SessionService.saveTargetRole('employee');
                                    if (!context.mounted) return;

                                    if (isEmailSelected) {
                                      await provider.loginWithEmail(
                                        emailController.text.trim(),
                                        passwordController.text,
                                      );
                                    } else {
                                      // Phone Login Logic
                                      if (!isOtpSent) {
                                        if (phoneController.text.trim().isEmpty) {
                                          CustomPopup.show(
                                            context,
                                            type: CustomPopupType.warning,
                                            title: 'Required Field',
                                            message: 'Please enter your phone number.',
                                          );
                                          return;
                                        }
                                        final phone = "$selectedCountryCode${phoneController.text.trim()}";
                                        await provider.sendOtp(phone); 
                                        if (provider.errorMessage == null) {
                                          setState(() => isOtpSent = true);
                                          if (context.mounted) {
                                            CustomPopup.show(
                                              context,
                                              type: CustomPopupType.info,
                                              title: 'OTP Sent',
                                              message: 'Verification code has been sent to your phone number.',
                                            );
                                          }
                                        }
                                      } else {
                                        await provider.verifyOtp(otpController.text);
                                      }
                                    }
 
                                    if (provider.errorMessage != null && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(provider.errorMessage!),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      CustomPopup.show(
                                        context,
                                        type: CustomPopupType.error,
                                        title: 'Login Failed',
                                        message: provider.errorMessage!,
                                      );
                                    } else if (provider.isLoggedIn && context.mounted) {
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
                                        message: 'You have logged in successfully.',
                                        buttonLabel: 'Go to Dashboard',
                                      );
                                      if (context.mounted) {
                                        Navigator.of(context).popUntil((route) => route.isFirst);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isEmailSelected
                                        ? "Sign In with Email"
                                        : isOtpSent
                                            ? "Verify & Sign In"
                                            : "Send Verification Code",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16, // Updated from 16 to 16.sp
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    Consumer<EmployeeAuthProvider>(
                      builder: (context, auth, _) {
                        return SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: auth.isLoading ? null : () async {
                              final provider = context.read<EmployeeAuthProvider>();
                              await SessionService.saveTargetRole('employee');
                              await provider.signInWithGoogle();
                              
                              if (provider.errorMessage != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(provider.errorMessage!),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                CustomPopup.show(
                                  context,
                                  type: CustomPopupType.error,
                                  title: 'Google Sign-In Failed',
                                  message: provider.errorMessage!,
                                );
                              } else if (provider.isLoggedIn && context.mounted) {
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
                                  message: 'You have logged in successfully with Google.',
                                  buttonLabel: 'Go to Dashboard',
                                );
                                if (context.mounted) {
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                }
                              }
                            },
                            icon: auth.isLoading 
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Image.asset(
                                  'assets/icons/google_logo.png',
                                  height: 24,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.g_mobiledata, size: 24),
                                ),
                            label: Text(
                              auth.isLoading ? "Signing in..." : "Sign In with Google",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: theme.dividerColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        );
                      }
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: Column(
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              fontSize: 17.sp, // Updated from 14.0 to 15.sp
                              color: isDark ? Colors.grey[400] : Colors.black54,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EmployeeRegisterView(),
                                ),
                              );
                            },
                            child: const Text(
                              "Register as Employee",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(
    BuildContext context,
    String text, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: selected
              ? theme.cardTheme.color
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(
                        alpha: 0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 17.sp, 
              fontWeight: selected
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailResetController = TextEditingController(text: emailController.text);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        title: Text(
          "Reset Password",
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter your registered email and we will send you a link to reset your password.",
              style: TextStyle(fontSize: 11.sp, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailResetController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: "Enter your email address",
                hintStyle: TextStyle(color: theme.hintColor),
                prefixIcon: const Icon(Icons.email_outlined),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: theme.colorScheme.primary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailResetController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter your email")),
                );
                return;
              }
              Navigator.pop(context); // Close dialog first

              try {
                final provider = context.read<EmployeeAuthProvider>();
                await provider.sendPasswordResetEmail(email);
                if (context.mounted) {
                  CustomPopup.show(
                    context,
                    type: CustomPopupType.success,
                    title: "Reset Link Sent",
                    message: "A password reset link has been sent to $email. Please check your inbox and spam folder.",
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  CustomPopup.show(
                    context,
                    type: CustomPopupType.error,
                    title: "Error Sending Link",
                    message: e.toString().replaceAll("Exception: ", ""),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Send Link", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 17.sp,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    String? hintText,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onChanged,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(fontSize: 16.sp),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 16.sp,
          color: Theme.of(context).hintColor.withValues(alpha: 0.6),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Colors.grey[100],
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
                ),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
      onChanged: (value) {
        _clearError();
        onChanged?.call();
      },
    );
  }
}
