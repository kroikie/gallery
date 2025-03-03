// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:gallery/layout/letter_spacing.dart';
import 'package:gallery/studies/shrine/colors.dart';
import 'package:gallery/studies/shrine/expanding_bottom_sheet.dart';
import 'package:gallery/studies/shrine/model/app_state_model.dart';
import 'package:gallery/studies/shrine/model/product.dart';
import 'package:gallery/studies/shrine/theme.dart';
import 'package:intl/intl.dart';
import 'package:scoped_model/scoped_model.dart';

const _startColumnWidth = 60.0;
const _ordinalSortKeyName = 'shopping_cart';

class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({Key key}) : super(key: key);

  @override
  _ShoppingCartPageState createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  ShoppingCartRow _cartRow(AppStateModel model, Product product, int quantity) {
    return ShoppingCartRow(
      product: product,
      quantity: quantity,
      onPressed: () {
        model.removeItemFromCart(product.id);
      },
    );
  }

  StreamBuilder<QuerySnapshot<Object>> _shoppingCartColumn(
      AppStateModel model) {
    return StreamBuilder<QuerySnapshot>(
      stream: model.cartItemsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading');
        }

        return Column(
          children: snapshot.data.docs.map((document) {
            final data = document.data() as Map<String, dynamic>;
            final quantity = data['quantity'] as int;
            final productData = data['product'] as Map<String, dynamic>;
            final product = Product.fromMap(productData);

            return _cartRow(model, product, quantity);
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localTheme = Theme.of(context);
    return Scaffold(
      backgroundColor: shrinePink50,
      body: SafeArea(
        child: ScopedModelDescendant<AppStateModel>(
          builder: (context, child, model) {
            return Stack(
              children: [
                ListView(
                  children: [
                    Semantics(
                      sortKey:
                          const OrdinalSortKey(0, name: _ordinalSortKeyName),
                      child: Row(
                        children: [
                          SizedBox(
                            width: _startColumnWidth,
                            child: IconButton(
                              icon: const Icon(Icons.keyboard_arrow_down),
                              onPressed: () =>
                                  ExpandingBottomSheet.of(context).close(),
                              tooltip: GalleryLocalizations.of(context)
                                  .shrineTooltipCloseCart,
                            ),
                          ),
                          Text(
                            GalleryLocalizations.of(context)
                                .shrineCartPageCaption,
                            style: localTheme.textTheme.subtitle1
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            GalleryLocalizations.of(context)
                                .shrineCartItemCount(
                              model.totalCartQuantity,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      sortKey:
                          const OrdinalSortKey(1, name: _ordinalSortKeyName),
                      child: _shoppingCartColumn(model),
                    ),
                    Semantics(
                      sortKey:
                          const OrdinalSortKey(2, name: _ordinalSortKeyName),
                      child: ShoppingCartSummary(model: model),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
                PositionedDirectional(
                  bottom: 16,
                  start: 16,
                  end: 16,
                  child: Semantics(
                    sortKey: const OrdinalSortKey(3, name: _ordinalSortKeyName),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(7)),
                        ),
                        primary: shrinePink100,
                      ),
                      onPressed: () {
                        model.clearCart();
                        ExpandingBottomSheet.of(context).close();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          GalleryLocalizations.of(context)
                              .shrineCartClearButtonCaption,
                          style: TextStyle(
                              letterSpacing:
                                  letterSpacingOrNone(largeLetterSpacing)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Widget _shoppingCartSummaryInternals(BuildContext context, double totalCost,
    double subtotalCost, double shippingCost, double tax) {
  final smallAmountStyle =
      Theme.of(context).textTheme.bodyText2.copyWith(color: shrineBrown600);
  final largeAmountStyle = Theme.of(context)
      .textTheme
      .headline4
      .copyWith(letterSpacing: letterSpacingOrNone(mediumLetterSpacing));
  final formatter = NumberFormat.simpleCurrency(
    decimalDigits: 2,
    locale: Localizations.localeOf(context).toString(),
  );

  return Row(
    children: [
      const SizedBox(width: _startColumnWidth),
      Expanded(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: 16),
          child: Column(
            children: [
              MergeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      GalleryLocalizations.of(context).shrineCartTotalCaption,
                    ),
                    Expanded(
                      child: Text(
                        formatter.format(totalCost),
                        style: largeAmountStyle,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              MergeSemantics(
                child: Row(
                  children: [
                    Text(
                      GalleryLocalizations.of(context)
                          .shrineCartSubtotalCaption,
                    ),
                    Expanded(
                      child: Text(
                        formatter.format(subtotalCost),
                        style: smallAmountStyle,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              MergeSemantics(
                child: Row(
                  children: [
                    Text(
                      GalleryLocalizations.of(context)
                          .shrineCartShippingCaption,
                    ),
                    Expanded(
                      child: Text(
                        formatter.format(shippingCost),
                        style: smallAmountStyle,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              MergeSemantics(
                child: Row(
                  children: [
                    Text(
                      GalleryLocalizations.of(context).shrineCartTaxCaption,
                    ),
                    Expanded(
                      child: Text(
                        formatter.format(tax),
                        style: smallAmountStyle,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class ShoppingCartSummary extends StatelessWidget {
  const ShoppingCartSummary({Key key, this.model}) : super(key: key);

  final AppStateModel model;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: model.cartStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading');
        }

        final data = snapshot.data;
        var subtotal = 0.0;
        var shipping = 0.0;
        var tax = 0.0;
        if (data.exists) {
          subtotal = data['subtotal'] + 0.0 as double;
          shipping = data['shipping'] + 0.0 as double;
          tax = data['tax'] + 0.0 as double;
        }
        final total = subtotal + shipping + tax;

        return _shoppingCartSummaryInternals(
            context, total, subtotal, shipping, tax);
      },
    );
  }
}

class ShoppingCartRow extends StatelessWidget {
  const ShoppingCartRow({
    Key key,
    @required this.product,
    @required this.quantity,
    this.onPressed,
  }) : super(key: key);

  final Product product;
  final int quantity;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.simpleCurrency(
      decimalDigits: 0,
      locale: Localizations.localeOf(context).toString(),
    );
    final localTheme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        key: ValueKey<int>(product.id),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            label: GalleryLocalizations.of(context)
                .shrineScreenReaderRemoveProductButton(product.name(context)),
            button: true,
            enabled: true,
            child: ExcludeSemantics(
              child: SizedBox(
                width: _startColumnWidth,
                child: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: onPressed,
                  tooltip:
                      GalleryLocalizations.of(context).shrineTooltipRemoveItem,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        product.assetName,
                        package: product.assetPackage,
                        fit: BoxFit.cover,
                        width: 75,
                        height: 75,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MergeSemantics(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MergeSemantics(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        GalleryLocalizations.of(context)
                                            .shrineProductQuantity(quantity),
                                      ),
                                    ),
                                    Text(
                                      GalleryLocalizations.of(context)
                                          .shrineProductPrice(
                                        formatter.format(product.price),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                product.name(context),
                                style: localTheme.textTheme.subtitle1
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(
                    color: shrineBrown900,
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
