import 'package:flutter/material.dart';

import 'main.dart';
import 'providers/user_change_notifier.dart';

void main() {
  runApp(const ProviderExerciseWrapper(child: PreferencesApp()));
}
