import 'package:flutter/material.dart';

void main() => runApp(const MediatorPatternApp());

/// MAIN APP
class MediatorPatternApp extends StatelessWidget {
  const MediatorPatternApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inverter - Mediator Pattern',
      theme: ThemeData.light(useMaterial3: true),
      home: const InverterScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// GLOBAL MEDIATOR
final inverterMediator = InverterMediator();

/// UI SCREEN
class InverterScreen extends StatefulWidget {
  const InverterScreen({super.key});

  @override
  State<InverterScreen> createState() => _InverterScreenState();
}

class _InverterScreenState extends State<InverterScreen> {
  @override
  void initState() {
    super.initState();
    inverterMediator.init();
    inverterMediator.historyNotifier.addListener(() {
      setState(() {}); // Rebuild on history change
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<InverterState>(
      valueListenable: inverterMediator.stateNotifier,
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: state.color,
            title: const Text('Inverter - Mediator Pattern'),
            actions: [
              IconButton(
                tooltip: 'Toggle Mode',
                onPressed: state.canToggle ? state.toggle : null,
                icon: const Icon(Icons.compare_arrows),
              ),
              IconButton(
                tooltip: 'Switch Off',
                onPressed: state.canSwitchOff ? state.switchOff : null,
                icon: const Icon(Icons.power_off),
              ),
              IconButton(
                tooltip: 'Switch On',
                onPressed: state.canSwitchOn ? state.switchOn : null,
                icon: const Icon(Icons.power),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: Container(
                    key: ValueKey(state.runtimeType),
                    padding: const EdgeInsets.all(24),
                    color: state.color.withValues(alpha: 0.1),
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(state.icon, size: 100, color: state.color),
                        const SizedBox(height: 20),
                        Text(state.modeName,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: state.color,
                            )),
                        const SizedBox(height: 12),
                        Text(state.description,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(),
              Container(
                height: 160,
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("History Log",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: inverterMediator.history.length,
                        itemBuilder: (context, index) => Text(
                            inverterMediator.history[index],
                            style: const TextStyle(fontSize: 12)),
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

/// ===================== MEDIATOR =======================

class InverterMediator {
  final stateNotifier = ValueNotifier<InverterState>(SwitchedOffState());
  final historyNotifier = ValueNotifier<List<String>>([]);
  List<String> get history => historyNotifier.value;

  void init() {
    stateNotifier.value.setMediator(this);
    _log(stateNotifier.value.modeName);
  }

  void _log(String name) {
    history.insert(0, "${DateTime.now().toIso8601String()} → $name");
    historyNotifier.value = List.from(history);
  }

  void changeState(InverterState newState) {
    newState.setMediator(this);
    stateNotifier.value = newState;
    _log(newState.modeName);
  }
}

/// ===================== STATE ==========================

abstract class InverterState {
  late InverterMediator mediator;

  void setMediator(InverterMediator mediator) => this.mediator = mediator;

  String get modeName;
  String get description;
  IconData get icon;
  Color get color;

  bool get canToggle => false;
  bool get canSwitchOn => false;
  bool get canSwitchOff => false;

  void toggle() {}
  void switchOn() {}
  void switchOff() {}
}

/// Switched Off
class SwitchedOffState extends InverterState {
  @override
  String get modeName => "Switched Off";

  @override
  String get description => "Inverter is off. Tap power to turn it on.";

  @override
  IconData get icon => Icons.power_off;

  @override
  Color get color => Colors.grey;

  @override
  bool get canSwitchOn => true;

  @override
  void switchOn() => mediator.changeState(BatteryModeState());
}

/// Shared switched on state
abstract class SwitchedOnState extends InverterState {
  @override
  bool get canSwitchOff => true;

  @override
  void switchOff() => mediator.changeState(SwitchedOffState());
}

/// Battery Mode
class BatteryModeState extends SwitchedOnState {
  @override
  String get modeName => "Battery Mode";

  @override
  String get description => "Running on backup battery power.";

  @override
  IconData get icon => Icons.battery_charging_full;

  @override
  Color get color => Colors.green;

  @override
  bool get canToggle => true;

  @override
  void toggle() => mediator.changeState(SolarModeState());
}

/// Solar Mode
class SolarModeState extends SwitchedOnState {
  @override
  String get modeName => "Solar Mode";

  @override
  String get description => "Harnessing solar energy.";

  @override
  IconData get icon => Icons.solar_power;

  @override
  Color get color => Colors.orange;

  @override
  bool get canToggle => true;

  @override
  void toggle() => mediator.changeState(UtilityModeState());
}

/// Utility Mode
class UtilityModeState extends SwitchedOnState {
  @override
  String get modeName => "Utility Mode";

  @override
  String get description => "Powered by WAPDA/grid.";

  @override
  IconData get icon => Icons.electrical_services;

  @override
  Color get color => Colors.blueAccent;

  @override
  bool get canToggle => true;

  @override
  void toggle() => mediator.changeState(BatteryModeState());
}
