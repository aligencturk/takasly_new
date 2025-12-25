import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/account/update_user_model.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ProfileEditView extends StatefulWidget {
  const ProfileEditView({super.key});

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<ProfileEditView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  String? _birthday; // format: dd.MM.yyyy
  int _gender = 3; // 1- Erkek, 2- Kadın, 3- Belirtilmemiş (Default)
  bool _showContact = true;

  File? _pickedImage;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().userProfile;
    _nameController = TextEditingController(text: user?.userFirstname ?? '');
    _surnameController = TextEditingController(text: user?.userLastname ?? '');
    _emailController = TextEditingController(text: user?.userEmail ?? '');
    _phoneController = TextEditingController(text: user?.userPhone ?? '');

    // Initialize new fields
    _birthday = user?.userBirthday;

    // Parse gender string to int
    if (user?.userGender == "Erkek") {
      _gender = 1;
    } else if (user?.userGender == "Kadın") {
      _gender = 2;
    } else {
      _gender = 3;
    }

    _showContact = (user?.isShowContact == true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    ); // Quality 70 to reduce size
    if (image != null) {
      // Read bytes and convert to base64
      final bytes = await File(image.path).readAsBytes();
      final base64String = base64Encode(bytes);

      // Determine mime type (simple check, or default to jpeg/png)
      // Usually image_picker returns jpg or png.
      // User example: "data:image/png;base64,..."
      // We'll construct the data URI.
      final String extension = image.path.split('.').last.toLowerCase();
      String mimeType = "image/jpeg";
      if (extension == 'png') {
        mimeType = "image/png";
      }

      setState(() {
        _pickedImage = File(image.path);
        _base64Image = "data:$mimeType;base64,$base64String";
      });
    }
  }

  void _onSave() async {
    if (_formKey.currentState!.validate()) {
      final authViewModel = context.read<AuthViewModel>();

      final request = UpdateUserRequestModel(
        userFirstname: _nameController.text,
        userLastname: _surnameController.text,
        userEmail: _emailController.text,
        userPhone: _phoneController.text,
        userGender: _gender,
        userBirthday: _birthday,
        showContact: _showContact ? 1 : 0,
        profilePhoto: _base64Image, // Send base64 image if selected
      );

      await authViewModel.updateAccount(request);

      if (authViewModel.state == AuthState.success ||
          authViewModel.errorMessage == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil başarıyla güncellendi.')),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authViewModel.errorMessage ?? 'Hata oluştu'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.userProfile;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Profili Düzenle"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: authViewModel.state == AuthState.busy
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Photo Edit Section
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                              image: _pickedImage != null
                                  ? DecorationImage(
                                      image: FileImage(_pickedImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : (user?.profilePhoto != null &&
                                        user!.profilePhoto!.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(user.profilePhoto!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child:
                                (_pickedImage == null &&
                                    (user?.profilePhoto == null ||
                                        user!.profilePhoto!.isEmpty))
                                ? const Center(
                                    child: Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildTextField("Ad", _nameController),
                    const SizedBox(height: 16),
                    _buildTextField("Soyad", _surnameController),
                    const SizedBox(height: 16),
                    _buildTextField(
                      "E-posta",
                      _emailController,
                      TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      "Telefon",
                      _phoneController,
                      TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    // Birthday Picker
                    GestureDetector(
                      onTap: () async {
                        DateTime initialDate = DateTime.now();
                        if (_birthday != null && _birthday!.isNotEmpty) {
                          try {
                            initialDate = DateFormat(
                              "dd.MM.yyyy",
                            ).parse(_birthday!);
                          } catch (_) {}
                        }

                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: initialDate,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          locale: const Locale(
                            'tr',
                            'TR',
                          ), // Ensure Turkish locale if available or default
                        );

                        if (picked != null) {
                          setState(() {
                            _birthday = DateFormat("dd.MM.yyyy").format(picked);
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: TextEditingController(text: _birthday),
                          decoration: InputDecoration(
                            labelText: "Doğum Tarihi",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: const Icon(
                              Icons.calendar_today_rounded,
                            ),
                          ),
                          validator: (value) => null, // Optional
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Gender Dropdown
                    DropdownButtonFormField<int>(
                      value: _gender,
                      decoration: InputDecoration(
                        labelText: "Cinsiyet",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text("Erkek")),
                        DropdownMenuItem(value: 2, child: Text("Kadın")),
                        DropdownMenuItem(
                          value: 3,
                          child: Text("Belirtilmemiş"),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _gender = val ?? 3;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Show Contact Switch
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: SwitchListTile(
                        title: const Text("İletişim Bilgisi Görünsün"),
                        value: _showContact,
                        onChanged: (bool value) {
                          setState(() {
                            _showContact = value;
                          });
                        },
                        activeColor: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Kaydet",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, [
    TextInputType? type,
  ]) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label boş olamaz';
        }
        return null;
      },
    );
  }
}
