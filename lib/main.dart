// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:gallery/constants.dart';
import 'package:gallery/data/gallery_options.dart';
import 'package:gallery/pages/backdrop.dart';
import 'package:gallery/pages/splash.dart';
import 'package:gallery/routes.dart';
import 'package:gallery/themes/gallery_theme_data.dart';
import 'package:google_fonts/google_fonts.dart';

export 'package:gallery/data/demos.dart' show pumpDeferredLibraries;

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const GalleryApp());
}

// Change this to toggle emulators on/off
bool useFirebaseEmulators = true;
bool firebaseEmulatorsConfigured = false;

class GalleryApp extends StatefulWidget {
  const GalleryApp({Key key, this.initialRoute, this.isTestMode = false})
      : super(key: key);

  final bool isTestMode;
  final String initialRoute;

  @override
  _GalleryAppState createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  Completer<FirebaseApp> initializeFirebase() {
    final completer = Completer<FirebaseApp>();
    Firebase.initializeApp().then((value) {
      if (useFirebaseEmulators && !firebaseEmulatorsConfigured) {
        // Configure the app to use Firebase emulators
        final host = defaultTargetPlatform == TargetPlatform.android
            ? '10.0.2.2'
            : 'localhost';

        // Configure Firestore emulator
        FirebaseFirestore.instance.settings = Settings(
            host: '$host:8080', sslEnabled: false, persistenceEnabled: false);

        // Configure Firebase Auth emulator
        FirebaseAuth.instance.useEmulator('http://$host:9099');
      }

      firebaseEmulatorsConfigured = true;
      completer.complete(value);
    });

    return completer;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      // Initialize FlutterFire:
      future: initializeFirebase().future,
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          print('something went wrong');
          return Container();
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          return ModelBinding(
            initialModel: GalleryOptions(
              themeMode: ThemeMode.system,
              textScaleFactor: systemTextScaleFactorOption,
              customTextDirection: CustomTextDirection.localeBased,
              locale: null,
              timeDilation: timeDilation,
              platform: defaultTargetPlatform,
              isTestMode: widget.isTestMode,
            ),
            child: Builder(
              builder: (context) {
                return MaterialApp(
                  restorationScopeId: 'rootGallery',
                  title: 'Flutter Gallery',
                  debugShowCheckedModeBanner: false,
                  themeMode: GalleryOptions.of(context).themeMode,
                  theme: GalleryThemeData.lightThemeData.copyWith(
                    platform: GalleryOptions.of(context).platform,
                  ),
                  darkTheme: GalleryThemeData.darkThemeData.copyWith(
                    platform: GalleryOptions.of(context).platform,
                  ),
                  localizationsDelegates: const [
                    ...GalleryLocalizations.localizationsDelegates,
                    LocaleNamesLocalizationsDelegate()
                  ],
                  initialRoute: widget.initialRoute,
                  supportedLocales: GalleryLocalizations.supportedLocales,
                  locale: GalleryOptions.of(context).locale,
                  localeResolutionCallback: (locale, supportedLocales) {
                    deviceLocale = locale;
                    return locale;
                  },
                  onGenerateRoute: RouteConfiguration.onGenerateRoute,
                );
              },
            ),
          );
        }

        // Otherwise, show something whilst waiting for initialization to complete
        print('loading...');
        return Container(
          child: const Center(
              child: Text(
            'loading...',
            textDirection: TextDirection.ltr,
          )),
        );
      },
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ApplyTextOptions(
      child: SplashPage(
        child: Backdrop(),
      ),
    );
  }
}
