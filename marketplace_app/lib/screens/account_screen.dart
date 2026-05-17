import 'package:flutter/material.dart';
import 'package:marketplace_app/screens/home_screen.dart';
import 'package:marketplace_app/widgets/screen_status_bar.dart';
import '../services/api_service.dart';
import '../models/client_profile.dart';
import '../models/client_update_dto.dart';
import '../theme/app_theme.dart';
import '../services/google_places_service.dart';
import '../services/storage_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;
  ClientProfile? _profile;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyContactController;
  late FocusNode _addressFocusNode;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _emergencyContactController = TextEditingController();
    _addressFocusNode = FocusNode();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService().getClientProfile();
      setState(() {
        _profile = profile;
        _firstNameController.text = profile.firstName;
        _lastNameController.text = profile.lastName;
        _phoneController.text = profile.phoneNumber ?? '';
        _dateOfBirth = profile.dateOfBirth;
        _addressController.text = profile.address ?? '';
        _emergencyContactController.text = profile.emergencyContact ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd ładowania profilu: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dto = ClientUpdateDto(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        dateOfBirth: _dateOfBirth,
        address: _addressController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim(),
      );

      final updatedProfile = await ApiService().updateClientProfile(dto);

      setState(() {
        _profile = updatedProfile;
        _isSaving = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil zaktualizowany pomyślnie')),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Błąd zapisu: ${e.toString().replaceAll('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await ApiService().logout();
    if (!mounted) return;

    // Navigate deeply to remove all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    setState(() => _isUploading = true);
    try {
      final file = await StorageService().pickAvatarFile();
      if (file == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie wybrano pliku')),
        );
        return;
      }

      final avatarUrl = await ApiService().uploadAvatar(file);
      if (avatarUrl.isNotEmpty) {
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Awatar zaktualizowany')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie udało się zaktualizować awatara')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd przesyłania awatara: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ScreenStatusBar(
        child: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return ScreenStatusBar(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Wyloguj',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar section
                Center(
                  child: GestureDetector(
                    onTap: _isUploading ? null : _pickAndUploadAvatar,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: ApiService().currentUser?.avatarUrl != null ? 72 : 50,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: ApiService().currentUser?.avatarUrl !=
                                  null
                              ? NetworkImage(
                                  ApiService().currentUser!.avatarUrl!)
                              as ImageProvider
                              : null,
                          child: ApiService().currentUser?.avatarUrl == null
                              ? Text(
                                  _profile?.firstName.isNotEmpty == true
                                      ? _profile!.firstName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 40,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            child: _isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _profile?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Dane osobowe',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _firstNameController,
                        label: 'Imię',
                        validator: (v) => v!.isEmpty ? 'Wymagane' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _lastNameController,
                        label: 'Nazwisko',
                        validator: (v) => v!.isEmpty ? 'Wymagane' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _phoneController,
                  label: 'Telefon',
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v != null && v.isNotEmpty && v.length > 20) {
                      return 'Zbyt długi numer';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data urodzenia',
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _dateOfBirth != null
                          ? "${_dateOfBirth!.day.toString().padLeft(2, '0')}.${_dateOfBirth!.month.toString().padLeft(2, '0')}.${_dateOfBirth!.year}"
                          : 'Wybierz datę',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Adres i Kontakt',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                RawAutocomplete<String>(
                  textEditingController: _addressController,
                  focusNode: _addressFocusNode,
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.length < 4) {
                      return const Iterable<String>.empty();
                    }
                    return await GooglePlacesService()
                        .getAutocompleteSuggestions(textEditingValue.text);
                  },
                  onSelected: (String selection) {
                    _addressController.text = selection;
                  },
                  fieldViewBuilder:
                      (
                        BuildContext context,
                        TextEditingController fieldTextEditingController,
                        FocusNode fieldFocusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        return TextFormField(
                          controller: fieldTextEditingController,
                          focusNode: fieldFocusNode,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Adres zamieszkania',
                            alignLabelWithHint: true,
                          ),
                        );
                      },
                  optionsViewBuilder:
                      (
                        BuildContext context,
                        AutocompleteOnSelected<String> onSelected,
                        Iterable<String> options,
                      ) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 200,
                                maxWidth:
                                    MediaQuery.of(context).size.width - 32,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(
                                    index,
                                  );
                                  return InkWell(
                                    onTap: () => onSelected(option),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(option),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _emergencyContactController,
                  label: 'Kontakt awaryjny (Imie, Telefon)',
                  maxLines: 2,
                ),

                const SizedBox(height: 32),

                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Zapisz zmiany'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}
