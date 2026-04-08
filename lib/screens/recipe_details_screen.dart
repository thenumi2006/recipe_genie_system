import 'package:flutter/material.dart';

class RecipeDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> recipeData;

  const RecipeDetailsScreen({super.key, required this.recipeData});

  @override
  Widget build(BuildContext context) {
    // values from the database
    final String title = recipeData['title'] ?? 'Untitled Recipe';
    final String author = recipeData['authorName'] ?? 'Anonymous Chef';
    final String description = recipeData['description'] ?? 'No description provided.';
    final String imageUrl = recipeData['imageUrl'] ?? 'https://via.placeholder.com/400';
    final String cookTime = recipeData['cookTime']?.toString() ?? '30';
    final String difficulty = recipeData['difficulty'] ?? 'Easy';

    final List ingredients = recipeData['ingredients'] is List
        ? recipeData['ingredients']
        : [recipeData['ingredients'] ?? 'No ingredients listed'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Image.network(
              imageUrl,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "by $author",
                    style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    description,
                    style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 25),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(Icons.timer_outlined, "Cook", "$cookTime min"),
                        const VerticalDivider(width: 20),
                        _buildStatItem(Icons.bar_chart_outlined, "Difficulty", difficulty),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 5. Ingredients Section
                  const Row(
                    children: [
                      Icon(Icons.restaurant, color: Colors.orange, size: 20),
                      SizedBox(width: 10),
                      Text("Ingredients", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 15),

                  ...ingredients.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.orange),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            item.toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 24),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}