import 'package:flutter/material.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/app_state.dart';
import '../../helpers/extensions/context.extension.dart';
import '../auth/login.screen.dart';
import '../shared/widgets/custom_button.widget.dart';
import 'account_information.screen.dart';
import 'edit_profile.screen.dart';
import 'change_password.screen.dart';
import 'delete_account.screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onMenuTap;
  const ProfileScreen({super.key, this.onBack, this.onMenuTap});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _activeTab = 'Details';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.authRevision,
      builder: (context, _) {
        if (!AppState.loggedIn) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: AppBar(
              backgroundColor: AppColors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: AppColors.black),
                onPressed: widget.onMenuTap,
              ),
              title: const Text(
                'My Profile',
                style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list, color: AppColors.black),
                  onPressed: () {
                    // Handle filter action
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_outline, size: 72, color: AppColors.grey.withValues(alpha: 0.85)),
                            const SizedBox(height: 20),
                            Text(
                              'Sign in to manage your account, tickets, and settings.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.darkGrey.withValues(alpha: 0.95),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 28),
                            CustomButton(
                              title: 'Sign in',
                              onTap: () => context.push(const LoginScreen()),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final profile = AppState.profile;

        return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.black),
          onPressed: widget.onMenuTap,
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.black),
            onPressed: () {
              // Handle filter action
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                
                // Profile Info Section
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage('https://picsum.photos/200/200?random=10'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        profile?.username ?? 'Rachelle Jean Marie',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Tabs/Buttons: Details and Security
                Row(
                  children: [
                    _buildOutlineButton(
                      'Details',
                      isActive: _activeTab == 'Details',
                      onTap: () {
                        setState(() {
                          _activeTab = 'Details';
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildOutlineButton(
                      'Security',
                      isActive: _activeTab == 'Security',
                      onTap: () {
                        setState(() {
                          _activeTab = 'Security';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Content based on active tab
                if (_activeTab == 'Details')
                  _buildAccountInformation()
                else
                  _buildSecurityContent(),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildAccountInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Account Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.edit, size: 16, color: AppColors.primary),
              label: const Text(
                'Edit',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.lightGrey),
        const SizedBox(height: 24),
        const Text(
          'User',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 24),
        _buildInfoRow('Email :', 'rakeshsolanki60@gmail.com'),
        _buildInfoRow('Username :', 'organizer'),
        _buildInfoRow('Phone :', '+91 1050608090'),
        _buildInfoRow('Address :', 'Readshoro, North Carolina, United States'),
        _buildInfoRow('Country :', 'United States'),
        _buildInfoRow('City :', 'Readshoro'),
        _buildInfoRow('State :', 'North Carolina'),
        _buildInfoRow('Zip-code :', '05350'),
      ],
    );
  }

  Widget _buildSecurityContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.lightGrey),
        const SizedBox(height: 24),
        const Text(
          'Password & Authentication',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 24),
        _buildSecurityItem(
          Icons.lock_outline,
          'Change Password',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChangePasswordScreen(),
              ),
            );
          },
        ),
        _buildSecurityItem(
          Icons.delete_outline,
          'Delete Account',
          color: AppColors.red,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DeleteAccountScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(IconData icon, String title, {Color? color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? AppColors.black),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color ?? AppColors.black,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: AppColors.lightGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineButton(String title, {required VoidCallback onTap, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.black : AppColors.lightGrey,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isActive ? AppColors.black : AppColors.grey,
          ),
        ),
      ),
    );
  }
}
