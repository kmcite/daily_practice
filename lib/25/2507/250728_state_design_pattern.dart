import 'package:flutter/material.dart';

/// GLOBAL INVERTER INSTANCE
final Inverter inverter = Inverter(SwitchedOffState());

/// MAIN APP
class StateDesignPattern extends StatelessWidget {
  const StateDesignPattern({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inverter State Pattern',
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const InverterScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// UI SCREEN
class InverterScreen extends StatefulWidget {
  const InverterScreen({super.key});

  @override
  State<InverterScreen> createState() => _InverterScreenState();
}

class _InverterScreenState extends State<InverterScreen> {
  final List<String> history = [];

  void log(String entry) {
    setState(() {
      history.insert(
          0, '${DateTime.now().toLocal().toIso8601String()} → $entry');
    });
  }

  @override
  void initState() {
    super.initState();
    inverter.notifier.addListener(() {
      log(inverter.state.modeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<InverterState>(
      valueListenable: inverter.notifier,
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: state.color,
            title: const Text('Inverter System'),
            actions: [
              IconButton(
                tooltip: 'Toggle Mode',
                onPressed:
                    state is! SwitchedOffState ? () => inverter.toggle() : null,
                icon: const Icon(Icons.compare_arrows_rounded),
              ),
              IconButton(
                tooltip: 'Switch Off',
                onPressed: state is SwitchedOnState
                    ? () => inverter.switchOff()
                    : null,
                icon: const Icon(Icons.power_settings_new),
              ),
              IconButton(
                tooltip: 'Switch On',
                onPressed: state is SwitchedOffState
                    ? () => inverter.switchOn()
                    : null,
                icon: const Icon(Icons.power),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Container(
                    key: ValueKey(state.modeName),
                    padding: const EdgeInsets.all(24),
                    width: double.infinity,
                    color: state.color.withValues(alpha: 0.1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(state.icon, size: 100, color: state.color),
                        const SizedBox(height: 20),
                        Text(
                          state.modeName,
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: state.color),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          state.description,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Container(
                color: Colors.grey.shade100,
                height: 180,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("History Log",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) => Text(
                          history[index],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ========================== STATE PATTERN ==========================

/// BASE STATE
abstract class InverterState {
  late Inverter inverter;

  void setContext(Inverter inverter) => this.inverter = inverter;

  String get modeName;
  String get description;
  IconData get icon;
  Color get color;

  void toggle() => throw UnimplementedError();
  void switchOn() => throw UnimplementedError();
  void switchOff() => throw UnimplementedError();
  void toBatteryMode() => throw UnimplementedError();
  void toSolarPanelsMode() => throw UnimplementedError();
  void toUtiltyMode() => throw UnimplementedError();
}

/// SWITCHED OFF STATE
class SwitchedOffState extends InverterState {
  @override
  String get modeName => "Switched Off";

  @override
  String get description =>
      "The inverter is currently powered off. Please switch it on.";

  @override
  IconData get icon => Icons.power_off;

  @override
  Color get color => Colors.grey;

  @override
  void switchOn() {
    inverter.state = BatteryModeState();
  }
}

/// SWITCHED ON BASE STATE
abstract class SwitchedOnState extends InverterState {
  @override
  void switchOff() {
    inverter.state = SwitchedOffState();
  }
}

/// BATTERY MODE
class BatteryModeState extends SwitchedOnState {
  @override
  String get modeName => "Battery Mode";

  @override
  String get description =>
      "Inverter is running on battery. Used during power failure.";

  @override
  IconData get icon => Icons.battery_charging_full;

  @override
  Color get color => Colors.green.shade700;

  @override
  void toggle() {
    inverter.state = SolarPanelsModeState();
  }
}

/// SOLAR MODE
class SolarPanelsModeState extends SwitchedOnState {
  @override
  String get modeName => "Solar Mode";

  @override
  String get description =>
      "Inverter is now using solar power. Eco-friendly and cost-effective.";

  @override
  IconData get icon => Icons.solar_power;

  @override
  Color get color => Colors.orange;

  @override
  void toggle() {
    inverter.state = UtilityModeState();
  }
}

/// UTILITY MODE
class UtilityModeState extends SwitchedOnState {
  @override
  String get modeName => "Utility Mode";

  @override
  String get description =>
      "Inverter is running on WAPDA/grid. Power is stable and reliable.";

  @override
  IconData get icon => Icons.electrical_services;

  @override
  Color get color => Colors.blueAccent;

  @override
  void toggle() {
    inverter.state = BatteryModeState();
  }
}

/// INVERTER CONTEXT
class Inverter {
  Inverter(InverterState initialState) {
    notifier = ValueNotifier(initialState..setContext(this));
  }

  late final ValueNotifier<InverterState> notifier;

  InverterState get state => notifier.value;

  set state(InverterState newState) {
    newState.setContext(this);
    notifier.value = newState;
  }

  void toggle() => state.toggle();
  void switchOn() => state.switchOn();
  void switchOff() => state.switchOff();
  void toBatteryMode() => state.toBatteryMode();
  void toSolarPanelsMode() => state.toSolarPanelsMode();
  void toUtiltyMode() => state.toUtiltyMode();
}
