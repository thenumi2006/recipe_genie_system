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
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Recipe Craft",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange,
        centerTitle: true,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search for recipes...",
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          if (searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("Popular Recipes",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: StreamBuilder<QuerySnapshot>(

                      stream: FirebaseFirestore.instance.collection('recipes').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();


                        var popularList = snapshot.data!.docs;
                        popularList.sort((a, b) {
                          List aLikes = (a.data() as Map)['likedBy'] ?? [];
                          List bLikes = (b.data() as Map)['likedBy'] ?? [];
                          return bLikes.length.compareTo(aLikes.length);
                        });
                        var top6 = popularList.take(6).toList();

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: top6.length,
                          itemBuilder: (context, index) {
                            var data = top6[index].data() as Map<String, dynamic>;
                            return _buildPopularCard(top6[index].id, data);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("Latest Posts",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),


          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('recipes')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const SliverFillRemaining(child: Center(child: Text("Error")));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }

              final recipes = snapshot.data!.docs.where((doc) {
                String title = (doc.data() as Map<String, dynamic>)['title']?.toString().toLowerCase() ?? "";
                return title.contains(searchQuery);
              }).toList();

              if (recipes.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text("No recipes found.")));
              }

              return SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      var data = recipes[index].data() as Map<String, dynamic>;
                      String docId = recipes[index].id;
                      List likedBy = data['likedBy'] ?? [];
                      return _buildRecipeCard(docId, data, likedBy);
                    },
                    childCount: recipes.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCard(String docId, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecipeDetailsScreen(recipeData: data))),
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(data['imageUrl'] ?? 'https://via.placeholder.com/400', height: 100, width: 160, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(data['title'] ?? 'Recipe', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
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