import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:http/http.dart' as http;
import '../models/category.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _NewItemState();
  }
}

class _NewItemState extends State<NewItem> {
  final _formKey = GlobalKey<FormState>();
  var _itemName = "";
  var _itemCount = 1;
  var _itemCategory = categories[Categories.vegetables]!;
  var _isSending = false;


  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isSending = true;
      });
      Uri url = Uri.https("shoppinglist-96626-default-rtdb.firebaseio.com",
          "shopping-list.json");

      final response = await http.post(
        url,
        headers: {'Content-Type': "application/json"},
        body: json.encode(
          {
            "name": _itemName,
            "quantity": _itemCount,
            "category": _itemCategory.title
          },
        ),
      );

      if (!context.mounted) {
        return;
      }

      final Map<String, dynamic> resData = json.decode(response.body);

      Navigator.of(context).pop(
        GroceryItem(
            id: resData["name"],
            name: _itemName,
            quantity: _itemCount,
            category: _itemCategory),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add a new item"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text("Name"),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length >= 50) {
                    return "Length must be between 1 and 50";
                  }
                  return null;
                },
                onSaved: (val) {
                  _itemName = val!;
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        label: Text("Quantity"),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return "Must be a valid, positive integer";
                        }
                        return null;
                      },
                      initialValue: _itemCount.toString(),
                      onSaved: (val) {
                        _itemCount = int.tryParse(val!)!;
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: DropdownButtonFormField(
                        value: _itemCategory,
                        items: [
                          for (final category in categories.entries)
                            DropdownMenuItem(
                              value: category.value,
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    color: category.value.color,
                                  ),
                                  const SizedBox(
                                    width: 6,
                                  ),
                                  Text(category.value.title),
                                ],
                              ),
                            )
                        ],
                        onChanged: (value) {
                          setState(
                            () {
                              _itemCategory = value!;
                            },
                          );
                        }),
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _formKey.currentState!.reset();
                    },
                    child: const Text("Reset"),
                  ),
                  ElevatedButton(
                    onPressed: _isSending ? null : _saveItem,
                    child: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : const Text("Add Item"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
