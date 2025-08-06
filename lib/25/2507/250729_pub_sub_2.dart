import 'package:flutter/material.dart';

/// Base class for all events
abstract class Event {}

/// Event Bus with support for multiple subscribers
class EventBus {
  final _subscribers = <Type, List<void Function(Event)>>{};

  void subscribe<T extends Event>(void Function(T) handler) {
    final type = T;
    _subscribers[type] ??= [];
    _subscribers[type]!.add((event) => handler(event as T));
  }

  void publish<T extends Event>(T event) {
    final type = event.runtimeType;
    final listeners = _subscribers[type];
    if (listeners != null) {
      for (final listener in listeners) {
        listener(event);
      }
    }
  }
}

/// Global event bus
final eventBus = EventBus();

/// Inverter State Logic
class InverterState {
  final isRunning = ValueNotifier(false);
  bool get state => isRunning.value;

  void toggle() => isRunning.value = !state;
  void switching(bool to) => isRunning.value = to;

  void register() {
    eventBus.subscribe<ToggleInverter>((event) => toggle());
    eventBus.subscribe<SwitchOff>((event) => switching(false));
    eventBus.subscribe<SwitchOn>((event) => switching(true));
  }
}

/// Event definitions
class ToggleInverter extends Event {}

class SwitchOff extends Event {}

class SwitchOn extends Event {}

/// Inverter instance
final inverterState = InverterState();

void main() {
  inverterState.register(); // subscribe to events
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: inverterState.isRunning,
      builder: (_, value, __) => MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          appBar: AppBar(
            title: const Text("Inverter Control (PubSub)"),
            actions: [
              IconButton(
                onPressed: () => eventBus.publish(ToggleInverter()),
                icon: const Icon(Icons.sync_alt),
              ),
              IconButton(
                onPressed: () => eventBus.publish(SwitchOff()),
                icon: const Icon(Icons.power_off),
              ),
              IconButton(
                onPressed: () => eventBus.publish(SwitchOn()),
                icon: const Icon(Icons.power),
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  value ? Icons.bolt : Icons.bolt_outlined,
                  size: 100,
                  color: value ? Colors.orange : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  value ? "Inverter is ON" : "Inverter is OFF",
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
