import 'package:flutter/material.dart';

import '../../../helpers/app_colors.dart';
import '../../../helpers/app_state.dart';
import '../../../helpers/public_url.dart';
import '../../../services/toast.service.dart';
import '../../auth/login.screen.dart';
import '../../artist/artists.screen.dart';
import '../app_web_view.screen.dart';

/// Drawer menus (same base for guest & logged-in; auth adds the last two).
///
/// **Before login & after login (always):**
/// Home, My Tickets, Artists, Contact Us (WebView → pamevent.com/contact form),
/// Terms & Conditions (URL from splash/settings API), Privacy Policy (API).
///
/// **Only when not logged in (appended):**
/// Login.
///
/// **Only after login (appended):**
/// My Profile, Logout.
class AppDrawer extends StatelessWidget {
  static const _contactUrl = 'https://pamevent.com/contact';

  final Function(int)? onTabSelected;

  const AppDrawer({super.key, this.onTabSelected});

  void _openWebView(BuildContext context, {required String title, required String url}) {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      ToastService.show('This page is not available right now.');
      return;
    }
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(
      MaterialPageRoute<void>(
        builder: (context) => AppWebViewScreen(title: title, url: url),
      ),
    );
  }

  void _openSettingsLink(BuildContext context, String? raw, String title) {
    final url = resolvePublicUrl(raw);
    if (url == null) {
      ToastService.show('This page is not available right now.');
      return;
    }
    _openWebView(context, title: title, url: url);
  }

  /// Items shown for everyone (guest + logged-in).
  List<Widget> _baseMenuTiles(BuildContext context) {
    return [
      ListTile(
        leading: const Icon(Icons.home_outlined),
        title: const Text('Home'),
        onTap: () {
          Navigator.pop(context);
          onTabSelected?.call(0);
        },
      ),
      ListTile(
        leading: const Icon(Icons.confirmation_number_outlined),
        title: const Text('My Tickets'),
        onTap: () {
          Navigator.pop(context);
          onTabSelected?.call(2);
        },
      ),
      ListTile(
        leading: const Icon(Icons.groups_outlined),
        title: const Text('Artists'),
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ArtistsScreen()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.mail_outline),
        title: const Text('Contact Us'),
        onTap: () => _openWebView(context, title: 'Contact Us', url: _contactUrl),
      ),
      ListTile(
        leading: const Icon(Icons.gavel_outlined),
        title: const Text('Terms & Conditions'),
        onTap: () => _openSettingsLink(
          context,
          AppState.termsConditionLink,
          'Terms & Conditions',
        ),
      ),
      ListTile(
        leading: const Icon(Icons.privacy_tip_outlined),
        title: const Text('Privacy Policy'),
        onTap: () => _openSettingsLink(
          context,
          AppState.privacyPolicyLink,
          'Privacy Policy',
        ),
      ),
    ];
  }

  /// Shown only when the user is **not** logged in.
  List<Widget> _guestMenuTiles(BuildContext context) {
    return [
      const Divider(),
      ListTile(
        leading: const Icon(Icons.login, color: AppColors.primary),
        title: const Text('Login'),
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          );
        },
      ),
    ];
  }

  /// Shown only when [AppState.loggedIn].
  List<Widget> _loggedInMenuTiles(BuildContext context) {
    return [
      const Divider(),
      ListTile(
        leading: const Icon(Icons.person_outline),
        title: const Text('My Profile'),
        onTap: () {
          Navigator.pop(context);
          onTabSelected?.call(3);
        },
      ),
      ListTile(
        leading: const Icon(Icons.logout, color: AppColors.red),
        title: const Text('Logout', style: TextStyle(color: AppColors.red)),
        onTap: () => AppState.logOut(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.authRevision,
      builder: (context, _) {
        final loggedIn = AppState.loggedIn;
        final profile = AppState.profile;

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: AppColors.primary),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.white,
                      child: Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loggedIn ? (profile?.username ?? profile?.email ?? 'Account') : 'Pamevent',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (loggedIn && (profile?.email?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile!.email!,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              ..._baseMenuTiles(context),
              if (!loggedIn) ..._guestMenuTiles(context),
              if (loggedIn) ..._loggedInMenuTiles(context),
            ],
          ),
        );
      },
    );
  }
}
