import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../api/api.client.dart';
import '../../helpers/app_colors.dart';
import '../../helpers/app_state.dart';
import '../../helpers/public_url.dart';
import '../shared/widgets/custom_image.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _addressController;

  File? _selectedImage;
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _usernameController = TextEditingController();
    _phoneController = TextEditingController();
    _countryController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _zipController = TextEditingController();
    _addressController = TextEditingController();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final data = await ApiClient.fetchProfile();
    if (data != null && mounted) {
      setState(() {
        _profileData = data;
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _usernameController.text = data['username'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _countryController.text = data['country'] ?? '';
        _cityController.text = data['city'] ?? '';
        _stateController.text = data['state'] ?? '';
        _zipController.text = data['zip_code'] ?? '';
        _addressController.text = data['address'] ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    print('Pick image called');
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        print('Image picked: ${pickedFile.path}');
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    AppState.showLoader();
    try {
      final success = await ApiClient.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        username: _usernameController.text,
        phone: _phoneController.text,
        photoPath: _selectedImage?.path,
        country: _countryController.text,
        city: _cityController.text,
        state: _stateController.text,
        zipCode: _zipController.text,
        address: _addressController.text,
      );

      if (success && mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      AppState.hideLoader();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _addressController.dispose();
    super.dispose();
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.lightGrey),
                            ),
                            child: ClipOval(
                              child: _selectedImage != null
                                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                  : CustomImage(
                                      resolvePublicUrl(_profileData?['photo']),
                                      fit: BoxFit.cover,
                                      whenEmpty: const Icon(Icons.person, size: 50, color: AppColors.grey),
                                    ),
                            ),
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
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(label: 'Name *', controller: _nameController),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Email Address *', controller: _emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Username *', controller: _usernameController),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Phone', controller: _phoneController, keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Country', controller: _countryController),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'City', controller: _cityController),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'State', controller: _stateController),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Zip-code', controller: _zipController),
                    const SizedBox(height: 12),
                    _buildTextField(label: 'Address', controller: _addressController, maxLines: 3),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
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
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
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
          ),
          validator: (value) {
            if (label.contains('*') && (value == null || value.isEmpty)) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}
