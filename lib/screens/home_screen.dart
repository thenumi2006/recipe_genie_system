import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'recipe_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _toggleLike(String docId, List likedBy) async {
    if (user == null) return;
    final docRef = FirebaseFirestore.instance.collection('recipes').doc(docId);

    if (likedBy.contains(user!.uid)) {
      await docRef.update({
        'likedBy': FieldValue.arrayRemove([user!.uid])
      });
    } else {
      await docRef.update({
        'likedBy': FieldValue.arrayUnion([user!.uid])
      });
    }
  }

  Future<void> _toggleSave(String docId) async {
    if (user == null) return;
    final saveRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('saves')
        .doc(docId);

    final doc = await saveRef.get();
    if (doc.exists) {
      await saveRef.delete();
    } else {
      await saveRef.set({'savedAt': FieldValue.serverTimestamp()});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recipe Finder",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recipes')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading recipes"));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          final recipes = snapshot.data!.docs;

          if (recipes.isEmpty) {
            return const Center(child: Text("No recipes found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              var data = recipes[index].data() as Map<String, dynamic>;
              String docId = recipes[index].id;
              List likedBy = data['likedBy'] ?? [];

              return _buildRecipeCard(docId, data, likedBy);
            },
          );
        },
      ),
    );
  }

  Widget _buildRecipeCard(String docId, Map<String, dynamic> data, List likedBy) {
    bool isLiked = likedBy.contains(user?.uid);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailsScreen(recipeData: data),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                data['imageUrl'] ?? 'https://via.placeholder.com/400',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? 'Untitled Recipe',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "by ${data['authorName'] ?? 'Chef'}",
                    style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w500),
                  ),
                  const Divider(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Like Section
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _toggleLike(docId, likedBy),
                            icon: Icon(
                              isLiked ? Icons.thumb_up : Icons.thumb_up_off_alt,
                              color: isLiked ? Colors.blue : Colors.grey,
                            ),
                          ),
                          Text("${likedBy.length} likes"),
                        ],
                      ),

                      // Save Section
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user!.uid)
                            .collection('saves')
                            .doc(docId)
                            .snapshots(),
                        builder: (context, saveSnapshot) {
                          bool isSaved = saveSnapshot.hasData && saveSnapshot.data!.exists;
                          return TextButton.icon(
                            onPressed: () => _toggleSave(docId),
                            icon: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: Colors.orange,
                            ),
                            label: Text(
                              isSaved ? "Saved" : "Save",
                              style: const TextStyle(color: Colors.orange),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}