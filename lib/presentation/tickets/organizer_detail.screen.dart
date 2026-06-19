import 'package:flutter/material.dart';
import '../../helpers/app_colors.dart';
import '../shared/widgets/custom_image.dart';
import '../../helpers/public_url.dart';

class OrganizerDetailScreen extends StatefulWidget {
  final Map<String, dynamic> organizer;
  const OrganizerDetailScreen({super.key, required this.organizer});

  @override
  State<OrganizerDetailScreen> createState() => _OrganizerDetailScreenState();
}

class _OrganizerDetailScreenState extends State<OrganizerDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final organizer = widget.organizer;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppColors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Organizer Photo
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: CustomImage(
                      resolvePublicUrl(organizer['photo']?.toString()) ?? '',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Username
                Center(
                  child: Text(
                    organizer['username']?.toString() ?? 'Organizer',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Email
                if (organizer['email'] != null)
                  _buildInfoItem(Icons.email, organizer['email']?.toString() ?? ''),
                const SizedBox(height: 8),

                // Phone
                if (organizer['phone'] != null)
                  _buildInfoItem(Icons.phone, organizer['phone']?.toString() ?? ''),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGrey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
