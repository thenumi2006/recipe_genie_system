import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class PostRecipeScreen extends StatefulWidget {
  const PostRecipeScreen({super.key});

  @override
  State<PostRecipeScreen> createState() => _PostRecipeScreenState();
}

class _PostRecipeScreenState extends State<PostRecipeScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  List<TextEditingController> _ingredientControllers = [TextEditingController()];

  // --- Form Values ---
  int _cookTime = 30;
  String _difficulty = "Easy";
  bool _isUploading = false;

  void _addIngredient() {
    setState(() => _ingredientControllers.add(TextEditingController()));
  }

  Future<void> _uploadRecipe() async {
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

      await FirebaseFirestore.instance.collection('recipes').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange,
          title: const Text("RecipeCraft", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),

          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.edit_note), text: "Write Recipe"),
              Tab(icon: Icon(Icons.auto_awesome), text: "AI Suggest"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildManualEntryForm(),
            const AIRecipeGenerator(),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel("Recipe Title"),
          _buildTextField(_titleController, "e.g. Spicy Ramen"),
          const SizedBox(height: 20),
          _buildLabel("Description"),
          _buildTextField(_descriptionController, "Tell us about this dish and with steps...", maxLines: 3),
          const SizedBox(height: 20),
          _buildLabel("Image URL"),
          _buildTextField(_imageUrlController, "Paste a .jpg link here"),
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

class AIRecipeGenerator extends StatefulWidget {
  const AIRecipeGenerator({super.key});

  @override
  State<AIRecipeGenerator> createState() => _AIRecipeGeneratorState();
}

class _AIRecipeGeneratorState extends State<AIRecipeGenerator> {
  final _ingredientsController = TextEditingController();
  bool _isLoading = false;
  String _generatedResult = "";

  final String _openRouterKey = "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";

  Future<void> _generateRecipe() async {
    if (_ingredientsController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _generatedResult = "";
    });

    try {
      const String modelId = "openai/gpt-3.5-turbo";

      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $_openRouterKey",
          "Content-Type": "application/json",
          "HTTP-Referer": "http://localhost:3000",
          "X-Title": "Recipe System",
        },
        body: jsonEncode({
          "model": modelId,
          "messages": [
            {
              "role": "user",
              "content": "I have these ingredients: ${_ingredientsController.text}. Suggest a recipe title, all ingredients  and brief instructions."
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _generatedResult = data['choices'][0]['message']['content'];
        });
      } else {
        setState(() {
          _generatedResult = "Auth/Server Error: ${response.statusCode}\n${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _generatedResult = "Connection Error: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Enter your ingredients?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 10),
          TextField(
            controller: _ingredientsController,
            decoration: InputDecoration(
              hintText: "e.g., Chicken, Onion, Rice",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _isLoading ? null : _generateRecipe,
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: const Text("Generate Recipe with AI",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 30),
          if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.orange)),
          if (_generatedResult.isNotEmpty) ...[
            const Text("AI Suggestion:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: SelectableText(_generatedResult),
            ),
          ]
        ],
      ),
    );
  }
}