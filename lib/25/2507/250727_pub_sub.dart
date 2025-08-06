import 'package:flutter/material.dart';

void main() {
  runApp(const StatePubSubApp());
}

final inverter = InverterController();
final eventBus = EventBus();

/// ---------------------------
/// EVENT SYSTEM
/// ---------------------------
enum InverterEvent {
  toggle,
  switchOn,
  switchOff,
}

class EventBus {
  final _listeners = <InverterEvent, List<VoidCallback>>{};

  void subscribe(InverterEvent event, VoidCallback callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  void publish(InverterEvent event) {
    final callbacks = _listeners[event];
    if (callbacks != null) {
      for (final cb in List.from(callbacks)) {
        cb();
      }
    }
  }

  void unsubscribe(InverterEvent event, VoidCallback callback) {
    _listeners[event]?.remove(callback);
  }
}

/// ---------------------------
/// INVERTER + CONTROLLER
/// ---------------------------
abstract class InverterState {
  void init();
  void dispose();

  IconData get icon;
  String get label;
}

class InverterController {
  final notifier = ValueNotifier<InverterState>(SwitchedOffState());
  final List<String> history = [];

  InverterController() {
    notifier.value.init();
    _log(notifier.value);
  }

  void setState(InverterState state) {
    notifier.value.dispose();
    notifier.value = state;
    state.init();
    _log(state);
  }

  void _log(InverterState state) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    history.add('[$timestamp] ${state.label}');
    if (history.length > 10) history.removeAt(0);
  }
}

/// ---------------------------
/// STATES
/// ---------------------------
class SwitchedOffState extends InverterState {
  @override
  void init() {
    eventBus.subscribe(InverterEvent.switchOn, _switchOn);
  }

  @override
  void dispose() {
    eventBus.unsubscribe(InverterEvent.switchOn, _switchOn);
  }

  void _switchOn() {
    inverter.setState(BatteryModeState());
  }

  @override
  IconData get icon => Icons.power_off;
  @override
  String get label => 'Switched Off';
}

class BatteryModeState extends InverterState {
  @override
  void init() {
    eventBus.subscribe(InverterEvent.toggle, _toggle);
    eventBus.subscribe(InverterEvent.switchOff, _switchOff);
  }

  @override
  void dispose() {
    eventBus.unsubscribe(InverterEvent.toggle, _toggle);
    eventBus.unsubscribe(InverterEvent.switchOff, _switchOff);
  }

  void _toggle() => inverter.setState(SolarPanelsModeState());
  void _switchOff() => inverter.setState(SwitchedOffState());

  @override
  IconData get icon => Icons.battery_full;
  @override
  String get label => 'Battery Mode';
}

class SolarPanelsModeState extends InverterState {
  @override
  void init() {
    eventBus.subscribe(InverterEvent.toggle, _toggle);
    eventBus.subscribe(InverterEvent.switchOff, _switchOff);
  }

  @override
  void dispose() {
    eventBus.unsubscribe(InverterEvent.toggle, _toggle);
    eventBus.unsubscribe(InverterEvent.switchOff, _switchOff);
  }

  void _toggle() => inverter.setState(UtilityModeState());
  void _switchOff() => inverter.setState(SwitchedOffState());

  @override
  IconData get icon => Icons.solar_power;
  @override
  String get label => 'Solar Panels Mode';
}

class UtilityModeState extends InverterState {
  @override
  void init() {
    eventBus.subscribe(InverterEvent.toggle, _toggle);
    eventBus.subscribe(InverterEvent.switchOff, _switchOff);
  }

  @override
  void dispose() {
    eventBus.unsubscribe(InverterEvent.toggle, _toggle);
    eventBus.unsubscribe(InverterEvent.switchOff, _switchOff);
  }

  void _toggle() => inverter.setState(BatteryModeState());
  void _switchOff() => inverter.setState(SwitchedOffState());

  @override
  IconData get icon => Icons.electrical_services;
  @override
  String get label => 'Utility Mode';
}

/// ---------------------------
/// MAIN APP
/// ---------------------------
class StatePubSubApp extends StatelessWidget {
  const StatePubSubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inverter PubSub',
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const InverterScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InverterScreen extends StatelessWidget {
  const InverterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<InverterState>(
      valueListenable: inverter.notifier,
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Inverter State (PubSub)"),
            actions: [
              IconButton(
                icon: const Icon(Icons.transform),
                onPressed: () => eventBus.publish(InverterEvent.toggle),
              ),
              IconButton(
                icon: const Icon(Icons.power),
                onPressed: () => eventBus.publish(InverterEvent.switchOn),
              ),
              IconButton(
                icon: const Icon(Icons.power_off),
                onPressed: () => eventBus.publish(InverterEvent.switchOff),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: Column(
                  key: ValueKey(state.label),
                  children: [
                    Icon(state.icon, size: 80, color: Colors.deepPurple),
                    const SizedBox(height: 12),
                    Text(
                      state.label,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'History Log',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView(
                  children: inverter.history.reversed.map(
                    (e) {
                      return ListTile(title: Text(e));
                    },
                  ).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
