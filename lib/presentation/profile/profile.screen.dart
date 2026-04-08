import 'package:flutter/material.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/app_state.dart';
import '../../helpers/public_url.dart';
import '../../helpers/extensions/context.extension.dart';
import '../auth/login.screen.dart';
import '../shared/widgets/custom_button.widget.dart';
import '../shared/widgets/custom_image.dart';
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
  Map<String, dynamic>? _profileData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (AppState.loggedIn) {
      _fetchProfile();
    }
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final data = await ApiClient.fetchProfile();
    if (mounted) {
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    }
  }

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
          ),
          body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: RefreshIndicator(
                  onRefresh: _fetchProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          
                          // Profile Info Section
                          Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.lightGrey),
                                ),
                                child: ClipOval(
                                  child: CustomImage(
                                    resolvePublicUrl(_profileData?['photo']),
                                    fit: BoxFit.cover,
                                    whenEmpty: const Icon(Icons.person, size: 40, color: AppColors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _profileData?['name'] ?? _profileData?['username'] ?? 'User',
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
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );
                if (result == true) {
                  _fetchProfile();
                }
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
        _buildInfoRow('Email :', _profileData?['email'] ?? '-'),
        _buildInfoRow('Username :', _profileData?['username'] ?? '-'),
        _buildInfoRow('Phone :', _profileData?['phone'] ?? '-'),
        _buildInfoRow('Address :', _profileData?['address'] ?? '-'),
        _buildInfoRow('Country :', _profileData?['country'] ?? '-'),
        _buildInfoRow('City :', _profileData?['city'] ?? '-'),
        _buildInfoRow('State :', _profileData?['state'] ?? '-'),
        _buildInfoRow('Zip-code :', _profileData?['zip_code'] ?? '-'),
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
