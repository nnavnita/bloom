import 'package:bloom/app.dart';
import 'package:bloom/services/notification_service.dart';
import 'package:bloom/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await NotificationService.init();
  runApp(const ProviderScope(child: BloomApp()));
}
