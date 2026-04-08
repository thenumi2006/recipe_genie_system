import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_details_screen.dart';
import 'edit_recipe_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _deletePost(String docId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Recipe?"),
        content: const Text("This will permanently remove your recipe."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('recipes').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ],
        ),
        body: Column(
          children: [

            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  const CircleAvatar(radius: 35, backgroundColor: Colors.orange, child: Icon(Icons.person, size: 40, color: Colors.white)),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.displayName ?? "User Name", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(user?.email ?? "email@example.com", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),

            // TAB BAR
            const TabBar(
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange,
              tabs: [
                Tab(text: "My Posts"),
                Tab(text: "Saved Posts"),
              ],
            ),


            Expanded(
              child: TabBarView(
                children: [
                  _buildMyPostsTab(),
                  _buildSavedPostsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyPostsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('recipes').where('authorId', isEqualTo: user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("You haven't shared any recipes yet."));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String docId = docs[index].id;
            return _buildRecipeListTile(docId, data, true);
          },
        );
      },
    );
  }

  Widget _buildSavedPostsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('saves').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final savedDocs = snapshot.data!.docs;
        if (savedDocs.isEmpty) return const Center(child: Text("No saved recipes."));

        return ListView.builder(
          itemCount: savedDocs.length,
          itemBuilder: (context, index) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('recipes').doc(savedDocs[index].id).get(),
              builder: (context, recipeSnap) {
                if (!recipeSnap.hasData || !recipeSnap.data!.exists) return const SizedBox();
                var data = recipeSnap.data!.data() as Map<String, dynamic>;
                return _buildRecipeListTile(savedDocs[index].id, data, false);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecipeListTile(String docId, Map<String, dynamic> data, bool isOwn) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(data['imageUrl'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image)),
      ),
      title: Text(data['title'] ?? 'Untitled'),
      trailing: isOwn
          ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // EDIT
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditRecipeScreen(docId: docId, currentData: data))),
          ),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deletePost(docId)),
        ],
      )
          : const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailsScreen(recipeData: data))),
    );
  }
}