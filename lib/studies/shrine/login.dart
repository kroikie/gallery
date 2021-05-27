// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:gallery/data/gallery_options.dart';
import 'package:gallery/layout/adaptive.dart';
import 'package:gallery/layout/image_placeholder.dart';
import 'package:gallery/layout/letter_spacing.dart';
import 'package:gallery/layout/text_scale.dart';
import 'package:gallery/studies/shrine/app.dart';
import 'package:gallery/studies/shrine/colors.dart';
import 'package:gallery/studies/shrine/theme.dart';

const _horizontalPadding = 24.0;

double desktopLoginScreenMainAreaWidth({BuildContext context}) {
  return min(
    360 * reducedTextScale(context),
    MediaQuery.of(context).size.width - 2 * _horizontalPadding,
  );
}

class LoginPage extends StatelessWidget {
  LoginPage({Key key}) : super(key: key);

  final usernameController = TextEditingController(text: 'me@you.com');
  final passwordController = TextEditingController(text: 'mypassword');
  @override
  Widget build(BuildContext context) {
    final isDesktop = isDisplayDesktop(context);

    return ApplyTextOptions(
      child: isDesktop
          ? LayoutBuilder(
              builder: (context, constraints) => Scaffold(
                body: SafeArea(
                  child: Center(
                    child: SizedBox(
                      width: desktopLoginScreenMainAreaWidth(context: context),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _ShrineLogo(),
                          const SizedBox(height: 40),
                          _UsernameTextField(usernameController),
                          const SizedBox(height: 16),
                          _PasswordTextField(passwordController),
                          const SizedBox(height: 24),
                          _CancelAndNextButtons(
                              usernameController, passwordController),
                          const SizedBox(height: 62),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : Scaffold(
              appBar:
                  AppBar(backgroundColor: Colors.white, leading: Container()),
              body: SafeArea(
                child: ListView(
                  restorationId: 'login_list_view',
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: _horizontalPadding,
                  ),
                  children: [
                    const SizedBox(height: 80),
                    const _ShrineLogo(),
                    const SizedBox(height: 120),
                    _UsernameTextField(usernameController),
                    const SizedBox(height: 12),
                    _PasswordTextField(passwordController),
                    _CancelAndNextButtons(
                        usernameController, passwordController),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ShrineLogo extends StatelessWidget {
  const _ShrineLogo();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        children: [
          const FadeInImagePlaceholder(
            image: AssetImage('packages/shrine_images/diamond.png'),
            placeholder: SizedBox(
              width: 34,
              height: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SHRINE',
            style: Theme.of(context).textTheme.headline5,
          ),
        ],
      ),
    );
  }
}

class _UsernameTextField extends StatelessWidget {
  _UsernameTextField(this._controller);

  final TextEditingController _controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PrimaryColorOverride(
      color: shrineBrown900,
      child: TextField(
        textInputAction: TextInputAction.next,
        restorationId: 'username_text_field',
        cursorColor: colorScheme.onSurface,
        decoration: InputDecoration(
          labelText: GalleryLocalizations.of(context).shrineLoginUsernameLabel,
          labelStyle: TextStyle(
              letterSpacing: letterSpacingOrNone(mediumLetterSpacing)),
        ),
        controller: _controller,
      ),
    );
  }
}

class _PasswordTextField extends StatelessWidget {
  _PasswordTextField(this._controller);

  final TextEditingController _controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PrimaryColorOverride(
      color: shrineBrown900,
      child: TextField(
        restorationId: 'password_text_field',
        cursorColor: colorScheme.onSurface,
        obscureText: true,
        decoration: InputDecoration(
          labelText: GalleryLocalizations.of(context).shrineLoginPasswordLabel,
          labelStyle: TextStyle(
              letterSpacing: letterSpacingOrNone(mediumLetterSpacing)),
        ),
        controller: _controller,
      ),
    );
  }
}

class _CancelAndNextButtons extends StatelessWidget {
  _CancelAndNextButtons(this._usernameController, this._passwordController);

  final TextEditingController _usernameController;
  final TextEditingController _passwordController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDesktop = isDisplayDesktop(context);

    final buttonTextPadding = isDesktop
        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
        : EdgeInsets.zero;

    return Wrap(
      children: [
        ButtonBar(
          buttonPadding: isDesktop ? EdgeInsets.zero : null,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                shape: const BeveledRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(7)),
                ),
              ),
              onPressed: () {
                // The login screen is immediately displayed on top of
                // the Shrine home screen using onGenerateRoute and so
                // rootNavigator must be set to true in order to get out
                // of Shrine completely.
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: Padding(
                padding: buttonTextPadding,
                child: Text(
                  GalleryLocalizations.of(context).shrineCancelButtonCaption,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 8,
                shape: const BeveledRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(7)),
                ),
              ),
              onPressed: () async {
                final user = await signIn(
                    _usernameController.text, _passwordController.text);
                if (user != null) {
                  Navigator.of(context)
                      .restorablePushNamed(ShrineApp.homeRoute);
                } else {
                  // show toast saying sign in failed
                }
              },
              child: Padding(
                padding: buttonTextPadding,
                child: Text(
                  GalleryLocalizations.of(context).shrineNextButtonCaption,
                  style: TextStyle(
                      letterSpacing: letterSpacingOrNone(largeLetterSpacing)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<User> signIn(String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (err) {
      print('failed to sign in');
      print(err);
      return null;
    }
  }
}

class PrimaryColorOverride extends StatelessWidget {
  const PrimaryColorOverride({Key key, this.color, this.child})
      : super(key: key);

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(primaryColor: color),
      child: child,
    );
  }
}
