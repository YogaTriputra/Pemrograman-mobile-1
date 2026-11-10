import 'package:flutter/material.dart';

import '../utils/validators.dart';

class ValidationCard extends StatefulWidget {
  const ValidationCard({super.key});

  @override
  State<ValidationCard> createState() => _ValidationCardState();
}

class _ValidationCardState extends State<ValidationCard> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _urlController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;
  String? _preview;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _preview = Validators.sanitize(_nameController.text);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _urlController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Validasi & Sanitasi Input',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (value) => Validators.validateText(
                  value,
                  fieldName: 'Nama',
                  maxLength: 100,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telepon'),
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'URL'),
                keyboardType: TextInputType.url,
                validator: Validators.validateUrl,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _hidePassword,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    tooltip: _hidePassword
                        ? 'Tampilkan password'
                        : 'Sembunyikan password',
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(
                      _hidePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Validasi Input'),
              ),
              if (_preview != null) ...[
                const SizedBox(height: 12),
                Text('Hasil sanitasi: $_preview'),
              ],
              const SizedBox(height: 12),
              const Text(
                'HTML entities untuk demonstrasi; Text Flutter tidak mengeksekusi HTML.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
