import 'package:flutter/material.dart';
import 'package:leox/providers/employer_auth_provider.dart';
import 'package:leox/views/employer/employer_login_view.dart';
import 'package:leox/views/general/role_option_view.dart';
import 'package:leox/utils/email_validator_helper.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:leox/widgets/custom_popup.dart';

class EmployerRegisterView extends StatefulWidget {
  const EmployerRegisterView({super.key});

  @override
  State<EmployerRegisterView> createState() => _EmployerRegisterViewState();
}

class _EmployerRegisterViewState extends State<EmployerRegisterView> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  String _selectedCountryCode = "+91";

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final auth = context.read<EmployerAuthProvider>();
    
    if (_companyController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _contactNumberController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      CustomPopup.show(
        context,
        type: CustomPopupType.warning,
        title: 'Validation Action Required',
        message: 'Please fill in all the required fields.',
      );
      return;
    }

    final emailError = EmailValidatorHelper.validateEmployerEmail(_emailController.text.trim());
    if (emailError != null) {
      CustomPopup.show(
        context,
        type: CustomPopupType.warning,
        title: 'Validation Action Required',
        message: emailError,
      );
      return;
    }

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      CustomPopup.show(
        context,
        type: CustomPopupType.warning,
        title: 'Validation Action Required',
        message: 'Passwords do not match.',
      );
      return;
    }

    try {
      await auth.registerWithFirebaseEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        companyName: _companyController.text.trim(),
        contactNumber: "$_selectedCountryCode${_contactNumberController.text.trim()}",
        address: _addressController.text.trim(),
        linkedin: _linkedinController.text.trim(),
      );
      if (!mounted) return;
      
      if (auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        CustomPopup.show(
          context,
          type: CustomPopupType.error,
          title: 'Registration Failed',
          message: auth.errorMessage!,
        );
      } else if (auth.isLoggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registered successfully! Welcome to LeoOpus.'),
            backgroundColor: Colors.green,
          ),
        );
        await CustomPopup.show(
          context,
          type: CustomPopupType.success,
          title: 'Registration Successful!',
          message: 'Welcome to LeoOpus! Your employer account has been created successfully.',
          buttonLabel: 'Go to Dashboard',
        );
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
      CustomPopup.show(
        context,
        type: CustomPopupType.error,
        title: 'Registration Failed',
        message: e.toString(),
      );
    }
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
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          label: Text(
            "Back",
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
        ),
      ),
      body: SafeArea(
        child: SizedBox.expand(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: Icon(
                        Icons.business_center_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Employer Registration",
                      style: TextStyle(
                        fontSize: 21.sp, // Updated from 20.0 to 21.sp
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Create your employer account to manage jobs and review candidates.",
                  style: TextStyle(
                    fontSize: 15.sp, // Updated from 14.0 to 15.sp
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
                  child: Column(
                    children: [
                      _buildTextField("Company Name", _companyController, hintText: "Enter company name"),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Contact Number",
                            style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.dividerColor),
                                  borderRadius: BorderRadius.circular(10),
                                  color: theme.inputDecorationTheme.fillColor ?? Colors.grey[100],
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCountryCode,
                                    dropdownColor: theme.cardTheme.color ?? (isDark ? Colors.grey[900] : Colors.white),
                                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
                                    items: const [
                                      DropdownMenuItem(value: "+91", child: Text("+91")),
                                      DropdownMenuItem(value: "+1", child: Text("+1")),
                                      DropdownMenuItem(value: "+44", child: Text("+44")),
                                      DropdownMenuItem(value: "+61", child: Text("+61")),
                                    ],
                                    onChanged: (v) => setState(() => _selectedCountryCode = v!),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _contactNumberController,
                                  keyboardType: TextInputType.phone,
                                  style: TextStyle(fontSize: 16.sp),
                                  decoration: InputDecoration(
                                    hintText: "Enter contact number",
                                    hintStyle: TextStyle(
                                      fontSize: 16.sp,
                                      color: Theme.of(context).hintColor.withValues(alpha: 0.6),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: theme.dividerColor),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    filled: true,
                                    fillColor: theme.inputDecorationTheme.fillColor ?? Colors.grey[100],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField("Company Address", _addressController, hintText: "Enter company address"),
                      const SizedBox(height: 16),
                      _buildTextField("Email", _emailController, hintText: "Enter email address"),
                      const SizedBox(height: 16),
                      _buildTextField("Company LinkedIn (Optional)", _linkedinController, hintText: "Enter LinkedIn profile URL (optional)"),
                      const SizedBox(height: 16),
                      _buildTextField("Password", _passwordController, 
                          hintText: "Enter password",
                          isPassword: true, 
                          obscureText: _obscurePassword, 
                          onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          }),
                      const SizedBox(height: 16),
                      _buildTextField("Confirm Password", _confirmPasswordController, 
                          hintText: "Confirm password",
                          isPassword: true, 
                          obscureText: _obscureConfirmPassword, 
                          onToggleVisibility: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          }),
                      const SizedBox(height: 32),
                      Consumer<EmployerAuthProvider>(
                        builder: (context, auth, child) {
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _register,
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
                                  : const Text(
                                      "Register",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0, // Fixed from 16.sp to 16.0
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Consumer<EmployerAuthProvider>(
                  builder: (context, auth, _) {
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: auth.isLoading ? null : () async {
                          final provider = context.read<EmployerAuthProvider>();
                          await provider.signUpWithGoogle();
                          
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
                              title: 'Google Sign-Up Failed',
                              message: provider.errorMessage!,
                            );
                          } else if (provider.isLoggedIn && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Registered successfully with Google!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            await CustomPopup.show(
                              context,
                              type: CustomPopupType.success,
                              title: 'Registration Successful!',
                              message: 'Your account was registered successfully with Google.',
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
                        label: Text(auth.isLoading ? "Signing up..." : "Sign Up with Google"),
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
                        "Already have an account?",
                        style: TextStyle(
                          fontSize: 15.sp, // Updated from 14.0 to 15.sp
                          color: isDark ? Colors.grey[400] : Colors.black54,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EmployerLoginView(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign In",
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
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hintText,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15.0, // Fixed from 15.sp to 15.0
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? obscureText : false,
          style: TextStyle(fontSize: 16.sp),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 16.sp,
              color: Theme.of(context).hintColor.withValues(alpha: 0.6),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor:
                Theme.of(context).inputDecorationTheme.fillColor ??
                Colors.grey[100],
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
        ),
      ],
    );
  }
}
