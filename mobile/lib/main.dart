import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    log(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  runZonedGuarded(() {
    runApp(
      const ProviderScope(
        child: SmartHouseApp(),
      ),
    );
  }, (error, stackTrace) {
    log(
      'Unhandled error',
      error: error,
      stackTrace: stackTrace,
    );
  });
}