import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_routes.dart';
import '../constants/app_theme.dart';
import '../providers/auth_provider.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  String _selectedGender = 'Male';
  bool _isConsentChecked = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_isConsentChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please confirm you are above 15 years of age'),
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _mobileController.text.trim(),
        aadhaarNumber: _aadhaarController.text.trim(),
        gender: _selectedGender,
      );

      if (success && mounted) {
        _showVerificationCard();
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  void _showVerificationCard() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /*const Text(
                    'Welcome 👋',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),*/
                  const SizedBox(height: 30),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Verified!',
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'You have successfully verified your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushReplacementNamed(context, AppRoutes.home);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        "Browse Home",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          SizedBox(
            width: size.width,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Image.asset('assets/images/get-started.png', fit: BoxFit.cover),
          ),

          // Content overlay
          SingleChildScrollView(
            child: Column(
              children: [
                // Status bar space
                SizedBox(height: MediaQuery.of(context).padding.top + 20),

                // Logo in top left
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Row(
                    children: [
                      // Use only text, no logo image
                      const Text(
                        "Ryde",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.22),

                // White card content
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Create Your Account",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Name field
                        CustomTextField(
                          label: 'Name',
                          hint: 'Enter name',
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          validator: Validators.validateName,
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        const SizedBox(height: 16),

                        // Email field
                        CustomTextField(
                          label: 'Email',
                          hint: 'Enter email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        const SizedBox(height: 16),

                        // Mobile Number field
                        CustomTextField(
                          label: 'Mobile Number',
                          hint: 'Enter mobile number',
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your mobile number';
                            }
                            if (value.length != 10) {
                              return 'Mobile number must be 10 digits';
                            }
                            return null;
                          },
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        const SizedBox(height: 16),

                        // Aadhaar Number field
                        CustomTextField(
                          label: 'Aadhaar Number',
                          hint: 'Enter Aadhaar number',
                          controller: _aadhaarController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your Aadhaar number';
                            }
                            if (value.length != 12) {
                              return 'Aadhaar number must be 12 digits';
                            }
                            return null;
                          },
                          prefixIcon: Icon(Icons.credit_card_outlined),
                        ),
                        const SizedBox(height: 16),

                        // Gender dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gender',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedGender,
                                  items:
                                      ['Male', 'Female', 'Other']
                                          .map(
                                            (gender) => DropdownMenuItem(
                                              value: gender,
                                              child: Text(gender),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedGender = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        CustomTextField(
                          label: 'Password',
                          hint: 'Enter password',
                          controller: _passwordController,
                          isPassword: true,
                          validator: Validators.validatePassword,
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        const SizedBox(height: 16),

                        // Consent checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _isConsentChecked,
                              onChanged: (value) {
                                setState(() {
                                  _isConsentChecked = value ?? false;
                                });
                              },
                              activeColor: AppTheme.primaryColor,
                            ),
                            Expanded(
                              child: Text(
                                'I confirm that I am above 15 years of age and agree to the terms and conditions',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Sign Up button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Or divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade300,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                "Or",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade300,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Google Sign Up button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Google login implementation
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            icon: Image.asset(
                              'assets/icons/google.png',
                              width: 24,
                              height: 24,
                            ),
                            label: const Text(
                              "Log In with Google",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        // Already have an account
                        Padding(
                          padding: const EdgeInsets.only(top: 30, bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: _navigateToLogin,
                                child: Text(
                                  "Log in",
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
