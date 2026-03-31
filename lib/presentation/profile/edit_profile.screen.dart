import 'package:flutter/material.dart';
import '../../helpers/app_colors.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage('https://picsum.photos/200/200?random=10'),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: AppColors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(label: 'Name *', initialValue: 'John Brock'),
            const SizedBox(height: 12),
            _buildTextField(label: 'Email Address *', initialValue: 'rakeshsolanki60@gmail.com'),
            const SizedBox(height: 12),
            _buildTextField(label: 'Username *', initialValue: 'organizer'),
            const SizedBox(height: 12),
            _buildTextField(label: 'Phone', initialValue: '+91 1050608090', isPhone: true),
            const SizedBox(height: 12),
            _buildTextField(label: 'Country', initialValue: 'United States'),
            const SizedBox(height: 12),
            _buildTextField(label: 'City', initialValue: 'Readsboro'),
            const SizedBox(height: 12),
            _buildTextField(label: 'State', initialValue: 'North Carolina'),
            const SizedBox(height: 12),
            _buildTextField(label: 'Zip-code', initialValue: '05350'),
            const SizedBox(height: 12),
            _buildTextField(label: 'Address', initialValue: 'Readsboro, North Carolina, United States', maxLines: 3),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26C6DA),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Update',
                  style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    bool isPhone = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.darkGrey),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.lightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            prefixIcon: isPhone
                ? Padding(
                    padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('🇮🇳', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                      ],
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
