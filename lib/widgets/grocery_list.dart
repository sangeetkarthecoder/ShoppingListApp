import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/data/dummy_items.dart';
import 'package:shopping_list_app/widgets/new_item.dart';
import 'package:http/http.dart' as http;
import '../models/grocery_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var remItem;
  String? error;
  var _isLoading = true;

  void _loadItem() async {
    Uri url = Uri.https(
        "shoppinglist-96626-default-rtdb.firebaseio.com", "shopping-list.json");
    final response = await http.get(url);

    if (response.statusCode >= 400) {
      setState(() {
        error = "Failed to fetch data, try again later.";
      });
    }

    if(response.body == "null") {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItem = [];

    for (final item in listData.entries) {
      final category = categories.entries.firstWhere(
        (element) => element.value.title == item.value["category"],
      );
      loadedItem.add(
        GroceryItem(
            id: item.key,
            name: item.value["name"],
            quantity: item.value['quantity'],
            category: category.value),
      );
      setState(() {
        _groceryItems = loadedItem;
        _isLoading = false;
      });
    }

    print(response.body);
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) return;

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _remItem(GroceryItem item) {
    Uri url = Uri.https("shoppinglist-96626-default-rtdb.firebaseio.com",
        "shopping-list/${item.id}.json");
    http.delete(url);
    setState(
      () {
        _groceryItems.remove(item);
      },
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadItem();
  }

  @override
  Widget build(BuildContext context) {
    Widget currScreen = const Center(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          "Nothing to show! , try adding an item",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );

    if (_isLoading) {
      currScreen = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      currScreen = Center(
        child: Text(error!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Groceries"),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: _groceryItems.isEmpty
          ? currScreen
          : currScreen = ListView.builder(
              itemCount: _groceryItems.length,
              itemBuilder: (ctx, ind) => Dismissible(
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  setState(() {
                    _remItem(_groceryItems.elementAt(ind));
                  });
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Item removed"),
                      // action: SnackBarAction(
                      //     label: "Undo",
                      //     onPressed: () {
                      //       setState(() {
                      //         _groceryItems.insert(ind, remItem);
                      //       });
                      //     }),
                    ),
                  );
                },
                key: Key(_groceryItems[ind].id),
                child: ListTile(
                  title: Text(_groceryItems[ind].name),
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: _groceryItems[ind].category.color,
                  ),
                  trailing: Text(_groceryItems[ind].quantity.toString()),
                ),
              ),
            ),
    );
  }
}
