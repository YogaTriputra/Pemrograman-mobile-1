import 'package:flutter/material.dart';

import '../utils/form_validators.dart';
import '../widgets/custom_text_field.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _confirmKey = GlobalKey<FormFieldState<String>>();
  final _termsKey = GlobalKey<FormFieldState<bool>>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _birthDate;
  String? _gender;
  bool _agreed = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  int _strength = 0;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_revalidateConfirmation);
  }

  void _revalidateConfirmation() {
    if (_confirmPasswordController.text.isNotEmpty) {
      _confirmKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_revalidateConfirmation);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Pilih tanggal lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (!mounted || date == null) return;
    setState(() => _birthDate = date);
    _birthDateController.text =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _updateStrength(String value) {
    final strength = FormValidators.passwordStrength(value);
    if (strength != _strength) setState(() => _strength = strength);
  }

  Future<void> _submitForm() async {
    if (_isLoading) return;
    final valid = _formKey.currentState!.validate();
    if (!valid || !_agreed) return;
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registrasi Berhasil'),
        content: Text(
          'Selamat, $name!\nEmail: $email\n\n'
          'Ini adalah simulasi registrasi, data tidak dikirim ke server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    _resetForm();
  }

  void _resetForm() {
    FocusScope.of(context).unfocus();
    _confirmPasswordController.clear();
    _passwordController.clear();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _birthDateController.clear();
    _formKey.currentState!.reset();
    setState(() {
      _birthDate = null;
      _gender = null;
      _agreed = false;
      _strength = 0;
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
  }

  Widget _visibilityButton(bool obscure, VoidCallback onPressed) {
    return IconButton(
      tooltip: obscure ? 'Tampilkan password' : 'Sembunyikan password',
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
    );
  }

  @override
  Widget build(BuildContext context) {
    const strengthLabels = ['Belum diisi', 'Lemah', 'Sedang', 'Kuat'];
    const strengthColors = [
      Colors.grey,
      Colors.red,
      Colors.orange,
      Colors.green,
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Registrasi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.person_add,
                      size: 72,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Buat Akun Baru',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Isi form di bawah ini untuk mendaftar',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _nameController,
                      label: 'Nama Lengkap',
                      hint: 'Masukkan nama lengkap Anda',
                      prefixIcon: Icons.person,
                      validator: FormValidators.name,
                      enabled: !_isLoading,
                    ),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'nama@contoh.com',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: FormValidators.email,
                      enabled: !_isLoading,
                    ),
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Nomor Telepon',
                      hint: '10–13 digit angka',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: FormValidators.phone,
                      enabled: !_isLoading,
                    ),
                    CustomTextField(
                      controller: _birthDateController,
                      label: 'Tanggal Lahir',
                      hint: 'Pilih tanggal lahir',
                      prefixIcon: Icons.calendar_today,
                      readOnly: true,
                      onTap: _pickBirthDate,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Tanggal lahir wajib diisi'
                          : null,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Kelamin',
                        prefixIcon: Icon(Icons.people),
                      ),
                      items: const ['Laki-laki', 'Perempuan']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: _isLoading
                          ? null
                          : (value) => setState(() => _gender = value),
                      validator: (value) =>
                          value == null ? 'Jenis kelamin wajib dipilih' : null,
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Minimal 8 karakter, huruf kapital, angka',
                      prefixIcon: Icons.lock,
                      obscureText: _obscurePassword,
                      suffixIcon: _visibilityButton(_obscurePassword, () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      }),
                      validator: FormValidators.password,
                      onChanged: _updateStrength,
                      enabled: !_isLoading,
                    ),
                    LinearProgressIndicator(
                      value: _strength / 3,
                      color: strengthColors[_strength],
                      semanticsLabel:
                          'Kekuatan password: ${strengthLabels[_strength]}',
                      semanticsValue: '${(_strength / 3 * 100).round()}%',
                    ),
                    const SizedBox(height: 6),
                    Text('Kekuatan password: ${strengthLabels[_strength]}'),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: _confirmKey,
                      controller: _confirmPasswordController,
                      enabled: !_isLoading,
                      obscureText: _obscureConfirmPassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: _visibilityButton(
                          _obscureConfirmPassword,
                          () {
                            setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            );
                          },
                        ),
                      ),
                      validator: (value) => FormValidators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FormField<bool>(
                      key: _termsKey,
                      initialValue: false,
                      validator: (value) => value != true
                          ? 'Anda wajib menyetujui syarat dan ketentuan'
                          : null,
                      builder: (field) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: const Text(
                              'Setuju dengan Syarat & Ketentuan',
                            ),
                            value: _agreed,
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    setState(() => _agreed = value ?? false);
                                    field.didChange(_agreed);
                                    field.validate();
                                  },
                          ),
                          if (field.hasError)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                field.errorText!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isLoading ? null : _submitForm,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Daftar'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _isLoading ? null : _resetForm,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Reset'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
