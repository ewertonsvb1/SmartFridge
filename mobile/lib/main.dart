import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfridge_mobile/src/app.dart';
import 'package:smartfridge_mobile/src/core/notification/notification_background.dart';
import 'package:workmanager/workmanager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await Workmanager().initialize(notificationSyncCallbackDispatcher);
  }

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
