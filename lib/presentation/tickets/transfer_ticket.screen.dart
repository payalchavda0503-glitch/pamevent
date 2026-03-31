import 'package:flutter/material.dart';
import '../../helpers/app_colors.dart';
import '../shared/widgets/custom_button.widget.dart';

class TransferTicketScreen extends StatefulWidget {
  const TransferTicketScreen({super.key});

  @override
  State<TransferTicketScreen> createState() => _TransferTicketScreenState();
}

class _TransferTicketScreenState extends State<TransferTicketScreen> {
  String? selectedTicket;

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Transfer my ticket',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lightGrey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedTicket,
                      hint: const Text(
                        'Select your ticket',
                        style: TextStyle(fontSize: 14, color: AppColors.grey),
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.black),
                      items: <String>['Ticket 1', 'Ticket 2'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTicket = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select the type of ticket you want to transfer',
                  style: TextStyle(fontSize: 12, color: AppColors.lightGrey),
                ),
                const SizedBox(height: 20),

                // Form Fields
                _buildLabel('Recipient First Name'),
                _buildTextField('Enter first name'),
                const SizedBox(height: 16),

                _buildLabel('Recipient Last Name'),
                _buildTextField('Enter last name'),
                const SizedBox(height: 16),

                _buildLabel('Recipient email address'),
                _buildTextField('Enter email address'),
                const SizedBox(height: 16),

                _buildLabel('Confirm email address'),
                _buildTextField('Confirm email address'),
                
                const SizedBox(height: 40),

                // Transfer Button
                Center(
                  child: SizedBox(
                    width: 180,
                    child: CustomButton(
                      title: 'Transfer',
                      onTap: () {
                        // Handle transfer logic
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.darkGrey,
        ),
      ),
    );
  }

  Widget _buildTextField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.lightGrey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}
