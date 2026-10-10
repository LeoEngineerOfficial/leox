import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription_plan_model.dart';
import '../widgets/custom_popup.dart';

class PremiumPaywall extends StatefulWidget {
  final String featureKey;
  final VoidCallback onAuthorized;
  final bool isFullScreen;
  final bool isEmbedded;

  const PremiumPaywall({
    super.key,
    required this.featureKey,
    required this.onAuthorized,
    this.isFullScreen = false,
    this.isEmbedded = false,
  });

  /// Static helper to check features anywhere in the app
  static void check(BuildContext context, String featureKey, VoidCallback onAuthorized) {
    final subProvider = context.read<SubscriptionProvider>();
    if (subProvider.hasFeature(featureKey)) {
      onAuthorized();
    } else {
      showPaywall(context, featureKey);
    }
  }

  /// Static helper to directly show the paywall bottom sheet
  static void showPaywall(BuildContext context, String featureKey) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PremiumPaywall(
        featureKey: featureKey,
        onAuthorized: () {},
      ),
    );
  }

  @override
  State<PremiumPaywall> createState() => _PremiumPaywallState();
}

class _PremiumPaywallState extends State<PremiumPaywall> {
  late Razorpay _razorpay;
  String _billingCycle = 'monthly'; // monthly or yearly
  
  SubscriptionPlanModel? _selectedPlan;
  bool _isVerifying = false;

  // Coupon controllers and variables
  final _couponController = TextEditingController();
  Map<String, dynamic>? _appliedCoupon;
  bool _isValidatingCoupon = false;
  String? _couponError;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _couponController.dispose();
    super.dispose();
  }

  // ================= RAZORPAY HANDLERS =================

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_selectedPlan == null) return;
    
    setState(() {
      _isVerifying = true;
    });

    try {
      final subProvider = context.read<SubscriptionProvider>();
      
      final verified = await subProvider.verifyPaymentSignature(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
        planId: _selectedPlan!.id,
        billingCycle: _billingCycle,
        couponCode: _appliedCoupon?['code'],
        gstNumber: null,
      );

      if (verified && mounted) {
        if (!widget.isEmbedded) {
          Navigator.pop(context); // Close paywall sheet
        }
        CustomPopup.show(
          context,
          type: CustomPopupType.success,
          title: "Premium Active!",
          message: "Thank you for subscribing! Your premium benefits are now active.",
        );
        widget.onAuthorized();
      } else {
        if (mounted) {
          CustomPopup.show(
            context,
            type: CustomPopupType.error,
            title: "Verification Failed",
            message: subProvider.errorMessage ?? "We could not verify your signature. Please contact support.",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomPopup.show(
          context,
          type: CustomPopupType.error,
          title: "Error",
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('[Paywall] Razorpay Checkout Error: code=${response.code}, message=${response.message}');
    CustomPopup.show(
      context,
      type: CustomPopupType.error,
      title: "Payment Cancelled",
      message: response.message ?? "The transaction was cancelled or declined.",
    );
  }

  // ================= BUSINESS LOGIC =================

  void _validateCoupon(SubscriptionProvider provider) async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingCoupon = true;
      _couponError = null;
      _appliedCoupon = null;
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('coupons').doc(code).get();
      if (!doc.exists) {
        setState(() {
          _couponError = "Invalid coupon code.";
          _isValidatingCoupon = false;
        });
        return;
      }

      final data = Map<String, dynamic>.from(doc.data()!);
      data['code'] = doc.id;
      data['discountType'] = data['discountType'] ?? data['type'] ?? 'percentage';
      
      final rawVal = data['discountValue'] ?? data['value'] ?? data['discount'] ?? 0;
      double parsedVal = 0.0;
      if (rawVal is num) {
        parsedVal = rawVal.toDouble();
      } else if (rawVal is String) {
        parsedVal = double.tryParse(rawVal) ?? 0.0;
      }
      data['discountValue'] = parsedVal;

      final now = DateTime.now();
      DateTime expiry;
      if (data['expiryDate'] is Timestamp) {
        expiry = (data['expiryDate'] as Timestamp).toDate();
      } else if (data['expiryDate'] is String) {
        expiry = DateTime.tryParse(data['expiryDate']) ?? DateTime.now().add(const Duration(days: 365));
      } else {
        expiry = DateTime.now().add(const Duration(days: 365));
      }

      final isActive = data['isActive'] ?? true;
      final useCount = (data['useCount'] as num?)?.toInt() ?? 0;
      final maxUses = (data['maxUses'] as num?)?.toInt() ?? 10000;
      final applicableRoles = List<String>.from(data['applicableRoles'] ?? []);
      final role = provider.currentSubscription?.role ?? 'employee';

      if (!isActive) {
        _couponError = "This coupon is inactive.";
      } else if (now.isAfter(expiry)) {
        _couponError = "This coupon has expired.";
      } else if (useCount >= maxUses) {
        _couponError = "This coupon has reached usage limit.";
      } else if (applicableRoles.isNotEmpty && !applicableRoles.contains(role)) {
        _couponError = "Not applicable for your account role.";
      }

      if (_couponError != null) {
        setState(() {
          _isValidatingCoupon = false;
        });
        return;
      }

      setState(() {
        _appliedCoupon = data;
        _isValidatingCoupon = false;
      });
    } catch (e) {
      setState(() {
        _couponError = "Error validating: $e";
        _isValidatingCoupon = false;
      });
    }
  }

  Future<void> _startCheckout(SubscriptionProvider provider) async {
    if (_selectedPlan == null) return;

    // Prevent checkout ONLY if they have an active, non-cancelled, non-trial paid subscription
    final sub = provider.currentSubscription;
    if (sub != null && sub.status == 'active' && sub.isActive) {
      if (mounted) {
        CustomPopup.show(
          context,
          type: CustomPopupType.warning,
          title: "Already Subscribed",
          message: "You already have an active premium subscription. There is no need to subscribe again!",
        );
      }
      return;
    }

    // 1. Call Backend to create Order
    final orderDetails = await provider.createCheckoutOrder(
      planId: _selectedPlan!.id,
      billingCycle: _billingCycle,
      couponCode: _appliedCoupon?['code'],
      gstNumber: null,
    );

    if (orderDetails == null) {
      debugPrint('[Paywall] Order details was null.');
      if (mounted) {
        CustomPopup.show(
          context,
          type: CustomPopupType.error,
          title: "Order Failed",
          message: provider.errorMessage ?? "Could not create payment order. Try again later.",
        );
      }
      return;
    }

    debugPrint('[Paywall] Order Details: $orderDetails');

    // Check if the order is simulated or free (bypassing payment gateway)
    final isBypass = orderDetails['isSimulated'] == true ||
        orderDetails['orderId'] == 'free_plan_bypass' ||
        (orderDetails['amount'] ?? 1) == 0;

    if (isBypass) {
      debugPrint('[Paywall] Bypassing payment gateway. Activating subscription.');
      setState(() {
        _isVerifying = true;
      });
      try {
        final verified = await provider.verifyPaymentSignature(
          razorpayOrderId: orderDetails['orderId'] ?? 'free_plan_bypass',
          razorpayPaymentId: 'pay_free_bypass_${DateTime.now().millisecondsSinceEpoch}',
          razorpaySignature: 'sig_free_bypass_mock_string',
          planId: _selectedPlan!.id,
          billingCycle: _billingCycle,
          couponCode: _appliedCoupon?['code'],
          gstNumber: null,
        );

        if (verified && mounted) {
          if (!widget.isEmbedded) {
            Navigator.pop(context); // Close paywall view/page
          }
          CustomPopup.show(
            context,
            type: CustomPopupType.success,
            title: "Premium Active!",
            message: "Thank you for subscribing! Your premium benefits are now active (Simulation Mode).",
          );
          widget.onAuthorized();
        } else {
          if (mounted) {
            CustomPopup.show(
              context,
              type: CustomPopupType.error,
              title: "Verification Failed",
              message: provider.errorMessage ?? "We could not verify your signature. Please contact support.",
            );
          }
        }
      } catch (e) {
        if (mounted) {
          CustomPopup.show(
            context,
            type: CustomPopupType.error,
            title: "Error",
            message: e.toString(),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isVerifying = false;
          });
        }
      }
      return;
    }

    // 2. Open Razorpay Checkouts
    final options = {
      'key': orderDetails['key'] ?? 'rzp_live_Tm71qz950LG3k7', // Razorpay public live key ID
      'amount': orderDetails['amount'], // Amount in paise
      'name': 'LEO OPUS Premium',
      'order_id': orderDetails['orderId'],
      'description': 'Subscription to ${_selectedPlan!.name}',
      'timeout': 300, // 5 minutes timeout
      'prefill': {
        'contact': '',
        'email': '',
      },
      'theme': {
        'color': '#3B82F6', // LEO OPUS blue theme accent
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('[Paywall] Checkout launch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final provider = context.watch<SubscriptionProvider>();

    // Filter plans applicable to user's role and exclude free trial/free plans (price = 0)
    final rolePlans = provider.plans
        .where((p) => p.role == (provider.currentSubscription?.role ?? 'employee') && p.monthlyPrice > 0)
        .toList();

    // Default to the first plan in list
    if (_selectedPlan == null && rolePlans.isNotEmpty) {
      _selectedPlan = rolePlans.firstWhere((p) => p.isRecommended, orElse: () => rolePlans.first);
    }

    final bodyContent = _isVerifying
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  "Verifying payment transaction...",
                  style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Upgrade to Premium",
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  "All accounts receive a 1-Month Free Trial by default with all features unlocked. Plans purchased now will only start billing after your 1st month trial expires.",
                  style: TextStyle(fontSize: 15.sp, color: Colors.grey, height: 1.3),
                ),
                SizedBox(height: 3.h),

                // Billing Cycle Selector
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ChoiceChip(
                      label: Text("Monthly", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
                      selected: _billingCycle == 'monthly',
                      onSelected: (val) => setState(() => _billingCycle = 'monthly'),
                    ),
                    ChoiceChip(
                      label: Text("Yearly (-15%)", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
                      selected: _billingCycle == 'yearly',
                      onSelected: (val) => setState(() => _billingCycle = 'yearly'),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),

                // Plans cards list
                if (rolePlans.isEmpty)
                  SizedBox(
                    height: 15.h,
                    child: Center(child: Text("No subscription plans available for your role.", style: TextStyle(fontSize: 15.sp))),
                  )
                else
                  ...rolePlans.map((plan) {
                    final isSelected = _selectedPlan?.id == plan.id;
                    final price = _billingCycle == 'yearly' ? plan.yearlyPrice : plan.monthlyPrice;
                    
                    double finalPrice = price;
                    if (isSelected && _appliedCoupon != null) {
                      final discountType = _appliedCoupon!['discountType'] ?? 'percentage';
                      final discountValue = (_appliedCoupon!['discountValue'] as num?)?.toDouble() ?? 0.0;
                      if (discountType == 'percentage') {
                        finalPrice = price - (price * (discountValue / 100));
                      } else {
                        finalPrice = (price - discountValue).clamp(0.0, double.infinity);
                      }
                    }

                    return GestureDetector(
                      onTap: () => setState(() => _selectedPlan = plan),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 2.h),
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? colorScheme.primary : (isDark ? Colors.white10 : Colors.black12),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          color: isSelected
                              ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
                              : Colors.transparent,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  plan.name,
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? colorScheme.primary : null,
                                  ),
                                ),
                                if (plan.isRecommended)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "RECOMMENDED",
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (finalPrice < price) ...[
                                  Text(
                                    "₹${price.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  "₹${finalPrice.toStringAsFixed(0)}",
                                  style: TextStyle(
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.w900,
                                    color: finalPrice < price ? Colors.green : colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  _billingCycle == 'yearly' ? "/year" : "/month",
                                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(plan.description, style: TextStyle(fontSize: 15.sp, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    );
                  }),

                SizedBox(height: 2.h),

                // Coupon / Promo Code Input
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                              decoration: InputDecoration(
                                labelText: "Promo / Coupon Code",
                                labelStyle: TextStyle(fontSize: 17.sp),
                                errorStyle: TextStyle(fontSize: 14.sp),
                                errorText: _couponError,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 58,
                            child: ElevatedButton(
                              onPressed: _isValidatingCoupon ? null : () => _validateCoupon(provider),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isValidatingCoupon
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text(
                                      "Apply",
                                      style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      if (_appliedCoupon != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 6),
                            Builder(
                              builder: (context) {
                                final valNum = (_appliedCoupon!['discountValue'] as num).toDouble();
                                final displayVal = valNum % 1 == 0 ? valNum.toInt().toString() : valNum.toString();
                                final displayUnit = _appliedCoupon!['discountType'] == 'percentage' ? '%' : ' INR';
                                return Text(
                                  "Coupon Applied: ${_appliedCoupon!['code']} ($displayVal$displayUnit Off)",
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 17.sp),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 3.h),

                Builder(
                  builder: (context) {
                    double finalPrice = 0.0;
                    if (_selectedPlan != null) {
                      finalPrice = _billingCycle == 'yearly' ? _selectedPlan!.yearlyPrice : _selectedPlan!.monthlyPrice;
                      if (_appliedCoupon != null) {
                        final valNum = (_appliedCoupon!['discountValue'] as num).toDouble();
                        if (_appliedCoupon!['discountType'] == 'percentage') {
                          finalPrice = finalPrice * (1 - (valNum / 100));
                        } else {
                          finalPrice -= valNum;
                        }
                        if (finalPrice < 0) finalPrice = 0.0;
                      }
                    }

                    return SizedBox(
                      width: double.infinity,
                      height: 6.h,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : () => _startCheckout(provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: provider.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _appliedCoupon != null
                                    ? "Pay ₹${finalPrice.toStringAsFixed(finalPrice % 1 == 0 ? 0 : 2)}"
                                    : "Proceed to Checkout",
                                style: TextStyle(fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                    );
                  }
                ),
              ],
            ),
          );

    if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "LEO OPUS Premium",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            child: bodyContent,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        top: 2.h,
        left: 5.w,
        right: 5.w,
        bottom: 2.h, // Just standard padding when inline. No viewInsets here to prevent keyboard overflow.
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: bodyContent,
    );
  }
}
