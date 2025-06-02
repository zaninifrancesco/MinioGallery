import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/gallery_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  List<String> _tags = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );

    if (image != null) {
      // Verifica dimensione file (max 5MB) - usa XFile invece di File per web compatibility
      final fileSize = await image.length();
      if (fileSize > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image size must be less than 5MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (image != null) {
        // Verifica dimensione file
        final fileSize = await image.length();
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size must be less than 5MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take picture: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Image Source',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePicture();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _updateTags(String value) {
    final tags =
        value
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

    setState(() {
      _tags = tags;
    });
  }

  Future<void> _uploadImage() async {
    if (!_formKey.currentState!.validate() || _selectedImage == null) {
      return;
    }

    final galleryProvider = Provider.of<GalleryProvider>(
      context,
      listen: false,
    );

    final success = await galleryProvider.uploadImage(
      imageFile: _selectedImage!,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      tags: _tags,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(galleryProvider.errorMessage ?? 'Upload failed'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Photo'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<GalleryProvider>(
        builder: (context, galleryProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Preview/Selection
                  GestureDetector(
                    onTap:
                        galleryProvider.isUploading
                            ? null
                            : _showImageSourceDialog,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        color:
                            _selectedImage != null
                                ? null
                                : Theme.of(context).colorScheme.surfaceVariant,
                      ),
                      child:
                          _selectedImage != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child:
                                    kIsWeb
                                        ? Image.network(
                                          _selectedImage!.path,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        )
                                        : Image.file(
                                          File(_selectedImage!.path),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                              )
                              : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 48,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to select an image',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Max size: 5MB | JPEG, PNG',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title Field
                  CustomTextField(
                    labelText: 'Title *',
                    hintText: 'Enter image title',
                    controller: _titleController,
                    prefixIcon: Icons.title,
                    enabled: !galleryProvider.isUploading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Title must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  CustomTextField(
                    labelText: 'Description',
                    hintText: 'Enter image description (optional)',
                    controller: _descriptionController,
                    prefixIcon: Icons.description,
                    keyboardType: TextInputType.multiline,
                    enabled: !galleryProvider.isUploading,
                  ),
                  const SizedBox(height: 16),

                  // Tags Field
                  CustomTextField(
                    labelText: 'Tags',
                    hintText: 'Enter tags separated by commas',
                    controller: _tagsController,
                    prefixIcon: Icons.local_offer,
                    enabled: !galleryProvider.isUploading,
                    onChanged: _updateTags,
                  ),
                  const SizedBox(height: 8),

                  // Tags Preview
                  if (_tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _tags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor:
                                      Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                  labelStyle: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                  ),
                                  side: BorderSide.none,
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () {
                                    setState(() {
                                      _tags.remove(tag);
                                      _tagsController.text = _tags.join(', ');
                                    });
                                  },
                                ),
                              )
                              .toList(),
                    ),
                  const SizedBox(height: 32),

                  // Upload Button
                  CustomButton(
                    text: 'Upload Photo',
                    onPressed:
                        _selectedImage != null && !galleryProvider.isUploading
                            ? _uploadImage
                            : null,
                    isLoading: galleryProvider.isUploading,
                    icon: Icons.cloud_upload,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 16),

                  // Requirements Text
                  Card(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Requirements',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Supported formats: JPEG, PNG, GIF\n'
                            '• Maximum file size: 5MB\n'
                            '• Title is required\n'
                            '• Tags help organize your photos',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
