// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gallery/studies/shrine/model/product.dart';
import 'package:gallery/studies/shrine/model/products_repository.dart';
import 'package:scoped_model/scoped_model.dart';

double _salesTaxRate = 0.06;
double _shippingCostPerItem = 7;

class AppStateModel extends Model {
  // All the available products.
  List<Product> _availableProducts;

  // The currently selected category of products.
  Category _selectedCategory = categoryAll;

  // The IDs and quantities of products currently in the cart.
  final Map<int, int> _productsInCart = <int, int>{};

  Map<int, int> get productsInCart => Map<int, int>.from(_productsInCart);

  // Total number of items in the cart.
  int get totalCartQuantity => _productsInCart.values.fold(0, (v, e) => v + e);

  Category get selectedCategory => _selectedCategory;

  // Totaled prices of the items in the cart.
  double get subtotalCost {
    return _productsInCart.keys
        .map((id) => _availableProducts[id].price * _productsInCart[id])
        .fold(0.0, (sum, e) => sum + e);
  }

  // Total shipping cost for the items in the cart.
  double get shippingCost {
    return _shippingCostPerItem *
        _productsInCart.values.fold(0.0, (sum, e) => sum + e);
  }

  // Sales tax for the items in the cart
  double get tax => subtotalCost * _salesTaxRate;

  // Total cost to order everything in the cart.
  double get totalCost => subtotalCost + shippingCost + tax;

  // Returns a copy of the list of available products, filtered by category.
  List<Product> getProducts() {
    if (_availableProducts == null) {
      return [];
    }

    return _availableProducts;
  }

  // Adds a product to the cart.
  void addProductToCart(int productId) {
    if (!_productsInCart.containsKey(productId)) {
      _productsInCart[productId] = 1;
    } else {
      _productsInCart[productId]++;
    }

    notifyListeners();
  }

  // Adds products to the cart by a certain amount.
  // quantity must be non-null positive value.
  void addMultipleProductsToCart(int productId, int quantity) {
    assert(quantity > 0);
    assert(quantity != null);
    if (!_productsInCart.containsKey(productId)) {
      _productsInCart[productId] = quantity;
    } else {
      _productsInCart[productId] += quantity;
    }

    notifyListeners();
  }

  // Removes an item from the cart.
  void removeItemFromCart(int productId) {
    if (_productsInCart.containsKey(productId)) {
      if (_productsInCart[productId] == 1) {
        _productsInCart.remove(productId);
      } else {
        _productsInCart[productId]--;
      }
    }

    notifyListeners();
  }

  // Returns the Product instance matching the provided id.
  Product getProductById(int id) {
    return _availableProducts.firstWhere((p) => p.id == id);
  }

  // Removes everything from the cart.
  void clearCart() {
    _productsInCart.clear();
    notifyListeners();
  }

  static Future<void> backfillProducts(BuildContext context) async {
    final coll = FirebaseFirestore.instance.collection('products');
    final allProducts = ProductsRepository.loadProducts(categoryAll);

    allProducts.forEach((element) async {
      return await coll.doc(element.id.toString()).set(element.toMap(context));
    });
  }

  // Loads the list of available products from Firestore
  void loadProducts() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        _availableProducts = await queryForProducts();
      } else {
        print('no user found so not getting products');
        _availableProducts = [];
      }
      notifyListeners();
    });
  }

  Future<List<Product>> queryForProducts() async {
    // Query based on the selected category
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('products');
    if (_selectedCategory != categoryAll) {
      query = query.where('category',
          isEqualTo: Category.toName(_selectedCategory));
    }

    // Fetch the snapshot from Firestore
    final productSnapshot = await query.get();

    // Map products from Firestore docs to objects
    final productDocs = productSnapshot.docs;
    return productDocs.map((doc) {
      return Product.fromMap(doc.data());
    }).toList();
  }

  void setCategory(Category newCategory) {
    _selectedCategory = newCategory;
    queryForProducts().then((value) {
      _availableProducts = value;
      notifyListeners();
    });
  }

  @override
  String toString() {
    return 'AppStateModel(totalCost: $totalCost)';
  }
}
