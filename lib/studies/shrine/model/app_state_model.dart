// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  void addProductToCart(int productId, Map<String, dynamic> productData) {
    addMultipleProductsToCart(productId, productData, 1);
  }

  DocumentReference getCartItemRef(int productId) {
    final uid = FirebaseAuth.instance.currentUser.uid;
    final cartRef = FirebaseFirestore.instance.collection('carts').doc(uid);
    return cartRef.collection('items').doc('$productId');
  }

  // Adds products to the cart by a certain amount.
  // quantity must be non-null positive value.
  void addMultipleProductsToCart(
      int productId, Map<String, dynamic> productData, int quantity) {
    assert(quantity > 0);
    assert(quantity != null);

    // /carts/$uid/items/$productId
    final itemRef = getCartItemRef(productId);

    if (!_productsInCart.containsKey(productId)) {
      itemRef.set(<String, dynamic>{'product': productData, 'quantity': 1});

      _productsInCart[productId] = quantity;
    } else {
      itemRef.update(
          <String, dynamic>{'quantity': FieldValue.increment(quantity)});

      _productsInCart[productId] += quantity;
    }

    notifyListeners();
  }

  // Removes an item from the cart.
  void removeItemFromCart(int productId) {
    final itemRef = getCartItemRef(productId);

    _productsInCart.remove(productId);
    itemRef.delete();

    notifyListeners();
  }

  // Returns the Product instance matching the provided id.
  Product getProductById(int id) {
    return _availableProducts.firstWhere((p) => p.id == id);
  }

  // Removes everything from the cart.
  void clearCart() {
    final productIdsInCart = List<int>.from(_productsInCart.keys);
    for (final productId in productIdsInCart) {
      final itemRef = getCartItemRef(productId);
      _productsInCart.remove(productId);
      itemRef.delete();
    }
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

        final itemsSnapshot = await cartItemsStream().first;
        for (final item in itemsSnapshot.docs) {
          _productsInCart[item['product']['id'] as int] =
              item['quantity'] as int;
        }
      } else {
        print('no user found so not getting products');
        _availableProducts = [];
      }
      notifyListeners();
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> cartStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }

    // Listen for cart and cart items
    final uid = user.uid;
    return FirebaseFirestore.instance.collection('carts').doc(uid).snapshots();
  }

  Stream<QuerySnapshot> cartItemsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<QuerySnapshot>.empty();
    }

    // Listen for cart and cart items
    final uid = user.uid;
    final cartRef = FirebaseFirestore.instance.collection('carts').doc(uid);
    return cartRef.collection('items').snapshots();
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
