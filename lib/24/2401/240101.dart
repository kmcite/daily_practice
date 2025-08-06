import 'package:daily_practice/25/2508/250805_reactive_architecture.dart';
import 'package:flutter/material.dart';

void main() {
  /// BLOCS
  put(AppBloc());

  /// REPOS
  put(Dark());

  runApp(App());
}

class AppBloc extends Bloc {
  late final Dark dark = watch();
}

class App extends UI<AppBloc> {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: !controller.dark(),
      theme: controller.dark() ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        body: Center(
          child: Switch(
            value: controller.dark(),
            onChanged: controller.dark.emit,
          ),
        ),
      ),
    );
  }
}

class Dark extends Repository<bool> {
  Dark() : super(true);
}
