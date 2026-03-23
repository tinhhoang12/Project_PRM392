import 'package:flutter/material.dart';
import '../../entity/category.dart';
import '../../service/category_service.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends State<CategoryManagementScreen> {

  List<Category> categories = [];
  final service = CategoryService();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    categories = await service.getAll();
    setState(() {});
  }

  // =========================
  // ADD / EDIT DIALOG
  // =========================
  void showForm({Category? category}) {
    final controller = TextEditingController(
      text: category?.name ?? "",
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(category == null ? "Add Category" : "Edit Category"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Category Name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;

              if (category == null) {
                await service.insert(
                  Category(name: controller.text),
                );
              } else {
                await service.update(
                  Category(
                    id: category.id,
                    name: controller.text,
                  ),
                );
              }

              Navigator.pop(context);
              loadData();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // =========================
  // DELETE
  // =========================
  void deleteCategory(int id) async {
    await service.delete(id);
    loadData();
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Category Management"),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final c = categories[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(c.name),

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // EDIT
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => showForm(category: c),
                  ),

                  // DELETE
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteCategory(c.id!),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // ADD BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () => showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}