import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickride/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  XFile? _picked;
  bool _saving = false;
  late final ApiClient _api;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _picked = img);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      _api.setToken(token);
      final fields = {
        'name': _nameCtrl.text.trim(),
        'price': _priceCtrl.text.trim(),
        'quantity': _qtyCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
      };
      await _api.postMultipart(
        '/vendors/products',
        fields,
        fileField: _picked != null ? 'image' : null,
        filePath: _picked?.path,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Product uploaded')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _picked == null
                        ? const Icon(Icons.add_a_photo, size: 40)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(_picked!.path),
                                fit: BoxFit.cover),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Product name'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (₦)'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter price' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter quantity' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cloud_upload),
                  label: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
