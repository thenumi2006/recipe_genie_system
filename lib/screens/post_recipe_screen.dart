import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostRecipeScreen extends StatefulWidget {
  const PostRecipeScreen({super.key});

  @override
  State<PostRecipeScreen> createState() => _PostRecipeScreenState();
}

class _PostRecipeScreenState extends State<PostRecipeScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController(); // NEW: URL Controller

  List<TextEditingController> _ingredientControllers = [TextEditingController()];

  int _prepTime = 15;
  int _cookTime = 30;
  String _difficulty = "Easy";
  bool _isUploading = false;

  void _addIngredient() {
    setState(() => _ingredientControllers.add(TextEditingController()));
  }

  Future<void> _uploadRecipe() async {
    // 1. Validation
    if (_titleController.text.isEmpty || _imageUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a title and an Image URL")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      List<String> ingredients = _ingredientControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      // 2. Save directly to Firestore (No Storage needed!)
      await FirebaseFirestore.instance.collection('recipes').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(), // Save the text URL
        'prepTime': _prepTime,
        'cookTime': _cookTime,
        'difficulty': _difficulty,
        'ingredients': ingredients,
        'authorId': user?.uid,
        'authorName': user?.displayName ?? "Chef",
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recipe Shared Successfully!")));

        // Reset the form
        _titleController.clear();
        _descriptionController.clear();
        _imageUrlController.clear();
        setState(() => _ingredientControllers = [TextEditingController()]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text("Post New Recipe", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Recipe Title"),
            _buildTextField(_titleController, "e.g. Spicy Ramen"),
            const SizedBox(height: 20),

            _buildLabel("Description"),
            _buildTextField(_descriptionController, "Tell us about this dish...", maxLines: 3),
            const SizedBox(height: 20),

            _buildLabel("Image URL"),
            _buildTextField(_imageUrlController, "Paste a .jpg or .png link here"),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _buildNumberCounter("Cook Time", _cookTime, (val) => setState(() => _cookTime = val))),
                const SizedBox(width: 15),
                Expanded(child: _buildDifficultyDropdown()),
              ],
            ),
            const SizedBox(height: 20),

            _buildLabel("Ingredients"),
            ..._ingredientControllers.map((controller) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildTextField(controller, "e.g. 2 cups of flour"),
            )),

            TextButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add, color: Colors.orange),
              label: const Text("Add Ingredient", style: TextStyle(color: Colors.orange)),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _isUploading ? null : _uploadRecipe,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Share Recipe", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  Widget _buildNumberCounter(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        Row(
          children: [
            IconButton(onPressed: () => onChanged(value > 0 ? value - 1 : 0), icon: const Icon(Icons.remove_circle_outline)),
            Text("$value", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add_circle_outline)),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Difficulty"),
        DropdownButton<String>(
          value: _difficulty,
          items: ["Easy", "Medium", "Hard"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (val) => setState(() => _difficulty = val!),
        ),
      ],
    );
  }
}