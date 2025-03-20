import 'dart:io';
import 'package:armstrong/models/article/article.dart';
import 'package:armstrong/services/supabase.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:armstrong/universal/blocs/articles/article_bloc.dart';

class EditArticleForm extends StatefulWidget {
  final Article article;

  const EditArticleForm({Key? key, required this.article}) : super(key: key);

  @override
  _EditArticleFormState createState() => _EditArticleFormState();
}

class _EditArticleFormState extends State<EditArticleForm> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  List<String> _categories = [
    'Health',
    'Social',
    'Relationships',
    'Growth',
    'Coping Strategies',
    'Mental Wellness',
    'Self-Care'
  ];
  List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  // ✅ Load existing data into form
  void _initializeFormData() {
    _titleController.text = widget.article.title;
    _contentController.text = widget.article.content;
    _selectedCategories = widget.article.categories
        .map((category) =>
            category[0].toUpperCase() + category.substring(1).toLowerCase())
        .toList();
  }

  // ✅ Pick a new image or retain the old one
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // ✅ Upload new image to Supabase
  Future<String?> _uploadImageToSupabase(File image) async {
    return await SupabaseService.uploadArticleImage(image);
  }

  // ✅ Handle Edit Submission
  Future<void> _submitEditedArticle() async {
    if (_titleController.text.isEmpty ||
        _contentController.text.isEmpty ||
        _selectedCategories.isEmpty) {
      _showSnackbar('Please fill all fields and choose categories',
          isError: true);
      return;
    }

    if (_selectedCategories.length > 2) {
      _showSnackbar('You can only select up to 2 categories', isError: true);
      return;
    }

    // ✅ Upload image if changed, otherwise use the existing one
    String? heroImageUrl = widget.article.heroImage;
    if (_image != null) {
      heroImageUrl = await _uploadImageToSupabase(_image!);
      if (heroImageUrl == null) {
        _showSnackbar('Failed to upload image', isError: true);
        return;
      }
    }

    // ✅ Dispatch UpdateArticle event with modified data
    context.read<ArticleBloc>().add(
          UpdateArticle(
            articleId: widget.article.id,
            title: _titleController.text,
            content: _contentController.text,
            heroImage: heroImageUrl ?? widget.article.heroImage,
            categories: _selectedCategories.map((c) => c.toLowerCase()).toList(),
          ),
        );

    _showSnackbar('Article updated successfully!');
    Navigator.pop(context); 
  }

  // ✅ Show success or error snackbar
  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Article'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Edit Article',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // ✅ Image Picker with Existing Image
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.surfaceVariant,
                          image: _image != null
                              ? DecorationImage(
                                  image: FileImage(_image!), fit: BoxFit.cover)
                              : DecorationImage(
                                  image: NetworkImage(widget.article.heroImage),
                                  fit: BoxFit.cover,
                                ),
                        ),
                        child: _image == null
                            ? null
                            : Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _image = null;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.background
                                          .withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.close,
                                        color: theme.colorScheme.onBackground,
                                        size: 20),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Title TextField
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    prefixIcon: const Icon(Icons.title),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ✅ Content TextField
                TextFormField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    prefixIcon: const Icon(Icons.description),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Category Selector
                const Text(
                  'Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ..._categories.map((category) {
                  return CheckboxListTile(
                    title: Text(category),
                    value: _selectedCategories.contains(category),
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected == true &&
                            _selectedCategories.length < 2) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),

                const SizedBox(height: 16),

                // ✅ Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitEditedArticle,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
