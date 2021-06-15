// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';

class Category {
  const Category({
    @required this.name,
  }) : assert(name != null);

  static Category byName(String name) {
    switch (name) {
      case 'ACCESSORIES':
        return categoryAccessories;
      case 'CLOTHING':
        return categoryClothing;
      case 'HOME':
        return categoryHome;
      default:
        return categoryAccessories;
    }
  }

  static String toName(Category category) {
    if (category == categoryAccessories) {
      return 'ACCESSORIES';
    }

    if (category == categoryClothing) {
      return 'CLOTHING';
    }

    if (category == categoryHome) {
      return 'HOME';
    }

    return 'ALL';
  }

  // A function taking a BuildContext as input and
  // returns the internationalized name of the category.
  final String Function(BuildContext) name;
}

Category categoryAll = Category(
  name: (context) => GalleryLocalizations.of(context).shrineCategoryNameAll,
);

Category categoryAccessories = Category(
  name: (context) =>
      GalleryLocalizations.of(context).shrineCategoryNameAccessories,
);

Category categoryClothing = Category(
  name: (context) =>
      GalleryLocalizations.of(context).shrineCategoryNameClothing,
);

Category categoryHome = Category(
  name: (context) => GalleryLocalizations.of(context).shrineCategoryNameHome,
);

List<Category> categories = [
  categoryAll,
  categoryAccessories,
  categoryClothing,
  categoryHome,
];

class Product {
  const Product({
    @required this.category,
    @required this.id,
    @required this.isFeatured,
    @required this.name,
    @required this.price,
    this.assetAspectRatio = 1,
  })  : assert(category != null),
        assert(id != null),
        assert(isFeatured != null),
        assert(name != null),
        assert(price != null),
        assert(assetAspectRatio != null);

  final Category category;
  final int id;
  final bool isFeatured;
  final double assetAspectRatio;

  // A function taking a BuildContext as input and
  // returns the internationalized name of the product.
  final String Function(BuildContext) name;

  final int price;

  String get assetName => '$id-0.jpg';
  String get assetPackage => 'shrine_images';

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
        id: map['id'] as int,
        category: Category.byName(map['category'] as String),
        isFeatured: false,
        name: (context) => map['name'] as String,
        price: map['price'] as int,
        assetAspectRatio: map['assetAspectRatio'] as double);
  }

  Map<String, dynamic> toMap(BuildContext context) {
    return <String, dynamic>{
      'category': category.name(context).toString(),
      'id': id,
      'isFeatured': isFeatured,
      'name': name(context),
      'price': price,
      'assetAspectRatio': assetAspectRatio,
    };
  }
}
