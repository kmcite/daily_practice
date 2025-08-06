import 'package:flutter/material.dart';

// --- Abstract BlocBase class ---
abstract class Bloc<S, E> extends ChangeNotifier {
  S get initialState;
  late S _state;
  S get state => _state;

  final Map<Type, List<Function>> _eventHandlers = {};

  Bloc() {
    _state = initialState;
  }
  void on<T extends E>(void Function(T event) handler) {
    _eventHandlers[T] = (_eventHandlers[T] ?? [])..add(handler);
  }

  void off<T extends E>(void Function(T event) handler) {
    final handlers = _eventHandlers[T];
    if (handlers != null) {
      handlers.remove(handler);
    }
  }

  @protected
  void call(E event) {
    final handlers = _eventHandlers[event.runtimeType];
    if (handlers != null) {
      for (final handler in List<Function>.from(handlers)) {
        handler(event);
      }
    }
  }

  @protected
  void update(S newState) {
    _state = newState;
    notifyListeners();
  }
}

// --- Events ---
abstract class CounterEvent {}

class Increment extends CounterEvent {}

class Decrement extends CounterEvent {}

// --- State ---
class CounterState {
  final int count;
  CounterState(this.count);
}

// --- Bloc Implementation ---
class CounterBloc extends Bloc<CounterState, CounterEvent> {
  @override
  CounterState get initialState => CounterState(0);
  CounterBloc() {
    on<Increment>((event) {
      update(CounterState(state.count + 1));
    });
    on<Decrement>((event) {
      update(CounterState(state.count - 1));
    });
  }

  // Expose this for UI to add events
  void add(CounterEvent event) => call(event);
}

// --- Flutter UI Example ---
final counterBloc = CounterBloc();

class CounterBlocApp extends StatelessWidget {
  const CounterBlocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Simple Bloc Example')),
        body: Center(
          child: AnimatedBuilder(
            animation: counterBloc,
            builder: (context, _) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Count: ${counterBloc.state.count}',
                    style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => counterBloc(Increment()),
                      child: const Text('Increment'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () => counterBloc.add(Decrement()),
                      child: const Text('Decrement'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// To run: use CounterBlocApp() as your main widget in main.dart
