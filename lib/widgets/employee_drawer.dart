import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leox/providers/employee_providers/employee_auth_provider.dart';
import 'package:leox/providers/employee_providers/employee_profile_provider.dart';
import 'package:leox/views/employee/employee_ai_resume_matcher.dart';
import 'package:leox/views/employee/employee_dashboard_view.dart';
import 'package:leox/views/employee/employee_jobs_list_view.dart';
import 'package:leox/views/employee/employee_profile_view.dart';
import 'package:leox/views/common/notifications_view.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'premium_paywall.dart';

enum EmployeeDrawerItem { dashboard, jobs, notifications, aiMatcher, profile }

class EmployeeDrawer extends StatelessWidget {
  final EmployeeDrawerItem selectedItem;

  const EmployeeDrawer({super.key, required this.selectedItem});

  static const Color _drawerBg = Color(0xFF0B1220);
  static const Color _divider = Color(0xFF1C2536);

  @override
  Widget build(BuildContext context) {
    //final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      width: 70.w,
      backgroundColor: _drawerBg,
      surfaceTintColor: Colors.transparent,
      child: Column(
        children: [
          // ================= HEADER =================
          Container(
            padding: EdgeInsets.fromLTRB(6.w, 7.h, 4.w, 3.h),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _divider)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/icons/leo_Opus_logo.jpeg',
                    width: 12.w,
                    height: 12.w,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.syncopate(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.5,
                        ),
                        children: const [
                          TextSpan(
                            text: 'LEO',
                            style: TextStyle(color: Color.fromARGB(255, 34, 81, 222)),
                          ),
                          TextSpan(text: ' '),
                          TextSpan(
                            text: 'OPUS',
                            style: TextStyle(color: Color(0xFF3374D9)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // ================= MENU =================
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              children: [
                _drawerItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  title: "Dashboard",
                  isSelected: selectedItem == EmployeeDrawerItem.dashboard,
                  onTap:
                      () => _navigate(context, const EmployeeDashboardView()),
                ),

                _drawerItem(
                  context,
                  icon: Icons.work_outline,
                  activeIcon: Icons.work,
                  title: "Jobs",
                  isSelected: selectedItem == EmployeeDrawerItem.jobs,
                  onTap: () {
                    _navigate(context, const EmployeeJobsListView());
                  },
                ),

                _drawerItem(
                  context,
                  icon: Icons.notifications_none_outlined,
                  activeIcon: Icons.notifications,
                  title: "Notifications",
                  isSelected: selectedItem == EmployeeDrawerItem.notifications,
                  onTap: () {
                    _navigate(context, const NotificationsView());
                  },
                ),

                _drawerItem(
                  context,
                  icon: Icons.smart_toy_outlined,
                  activeIcon: Icons.smart_toy,
                  title: "Resume Matcher",
                  isSelected: selectedItem == EmployeeDrawerItem.aiMatcher,
                  onTap: () => _navigate(context, const EmployeeAiResumeMatcherView()),
                ),

                _drawerItem(
                  context,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  title: "My Profile",
                  isSelected: selectedItem == EmployeeDrawerItem.profile,
                  onTap: () => _navigate(context, const EmployeeProfileView()),
                ),

                if (!Platform.isIOS) _drawerItem(
                  context,
                  icon: Icons.credit_card_outlined,
                  activeIcon: Icons.credit_card,
                  title: "Subscription",
                  isSelected: false,
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PremiumPaywall(
                          featureKey: 'resume_matching',
                          onAuthorized: () {},
                          isFullScreen: true,
                        ),
                      ),
                    );
                  },
                ),

                Divider(height: 4.h, color: _divider),

                // ================= LOGOUT =================
                _logoutItem(context),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(4.w),
            child: Text(
              "v1.0.0",
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= DRAWER ITEM =================
  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.6.h),
      child: Material(
        elevation: isSelected ? 6 : 0,
        shadowColor: colorScheme.primary.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: colorScheme.primary.withValues(alpha: 0.15),
          highlightColor: colorScheme.primary.withValues(alpha: 0.08),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 23.sp,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: title == "AI Resume Matcher" ? 16.sp : (title.length > 15 ? 15.sp : 17.sp),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color:
                            isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= LOGOUT ITEM =================
  Widget _logoutItem(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.6.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _confirmLogout(context),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.6.h),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 21.sp, color: Colors.redAccent),
              SizedBox(width: 4.w),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Logout",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= LOGOUT DIALOG =================
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: _drawerBg,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: _divider),
            ),
            title: Row(
              children: [
                const Icon(Icons.logout_rounded, color: Colors.redAccent),
                SizedBox(width: 3.w),
                Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              "Are you sure you want to sign out of your employee account? You'll need to login again to see your applications and saved jobs.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16.sp,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 16.sp,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 2.w),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 1.2.h,
                    ),
                  ),
                  onPressed: () async {
                    // 1. Close dialog using its builder context
                    Navigator.of(dialogContext).pop();

                    // 2. Perform logout and reset profile
                    final auth = context.read<EmployeeAuthProvider>();
                    final profile = context.read<EmployeeProfileProvider>();

                    await auth.logout();
                    profile.reset();
                  },
                  child: Text(
                    "Yes, Logout",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.of(context).pop(); // Close drawer first
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
