import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditRecipeScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> currentData;

  const EditRecipeScreen({super.key, required this.docId, required this.currentData});

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _imgController;
  late TextEditingController _ingredientsController;
  String _difficulty = "Easy";

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentData['title']);
    _descController = TextEditingController(text: widget.currentData['description']);
    _imgController = TextEditingController(text: widget.currentData['imageUrl']);
    _difficulty = widget.currentData['difficulty'] ?? "Easy";

    var rawIngredients = widget.currentData['ingredients'];
    if (rawIngredients is List) {
      _ingredientsController = TextEditingController(text: rawIngredients.join("\n"));
    } else {
      _ingredientsController = TextEditingController(text: rawIngredients?.toString() ?? "");
    }
  }

  Future<void> _updateRecipe() async {

    List<String> ingredientsList = _ingredientsController.text
        .split("\n")
        .where((item) => item.trim().isNotEmpty)
        .toList();

    await FirebaseFirestore.instance.collection('recipes').doc(widget.docId).update({
      'title': _titleController.text,
      'description': _descController.text,
      'imageUrl': _imgController.text,
      'ingredients': ingredientsList,
      'difficulty': _difficulty,
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Recipe Updated!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Recipe"), backgroundColor: Colors.orange),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Recipe Title")),
            const SizedBox(height: 15),
            TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(labelText: "Description")),
            const SizedBox(height: 15),
            TextField(controller: _imgController, decoration: const InputDecoration(labelText: "Image URL")),
            const SizedBox(height: 15),

            TextField(
                controller: _ingredientsController,
                maxLines: 6,
                decoration: const InputDecoration(
                    labelText: "Ingredients (One per line)",
                    hintText: "e.g.\n2 cups flour\n1 tsp salt"
                )
            ),
            const SizedBox(height: 15),
            DropdownButton<String>(
              value: _difficulty,
              items: ["Easy", "Medium", "Hard"].map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (val) => setState(() => _difficulty = val!),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(double.infinity, 50)),
              onPressed: _updateRecipe,
              child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}