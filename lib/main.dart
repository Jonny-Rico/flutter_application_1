import 'package:family_tasks/app.dart';
import 'package:family_tasks/core/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  await bootstrap();
  runApp(const ProviderScope(child: FamilyTasksApp()));
}