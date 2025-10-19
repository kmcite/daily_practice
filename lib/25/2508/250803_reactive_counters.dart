// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';

/// this also demonstrates how to build features
/// by using reactive repository
/// and bloc pattern
///
/// you need repository, bloc/vm & ui to build a feature
/// in repo you need data class to stire the source of truth

/// the  purpose of this demo was to build reactive repository
/// i did create a reative repository which uses a single stream controller
/// used two methods to watch the controller
/// i used mutation method in repo to mutate the source of truth
/// i used watchAll method to watch all counters
/// i used watch method to watch a single counter

/// to strat the app
void main() => runApp(App());

/// material wrappr
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Main(),
    );
  }
}

/// main screen
class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

/// bloc for the main screen

class _MainState extends State<Main> {
  /// access to repo
  late CountersRepository _countersRepository;

  /// state to be emitted in responce to changes from repo
  late Iterable<Counter> counters = _countersRepository.counters.values;
  late StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();

    /// inits repos to single final instance already created near the Repo
    _countersRepository = countersRepository;

    /// listens to all counters
    _subscription = _countersRepository.watchAll().listen(
      (counters) {
        setState(() => this.counters = counters);
      },
    );
  }

  /// method to mutate the state of repo
  /// without using setState here
  void put(Counter counter) => _countersRepository.put(counter);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
        itemCount: counters.length,
        itemBuilder: (_, i) {
          final counter = counters.elementAt(i);
          return ListTile(
            title: Text(counter.id),
            subtitle: Text(counter.value.toString()),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Details(id: counter.id),
                ),
              );
            },
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => put(
                    Counter(counter.id, counter.value + 1),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () => put(
                    Counter(counter.id, counter.value - 1),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => put(
          // [UniqueKey] to create ids
          Counter(UniqueKey().toString(), 0),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// details screen
class Details extends StatefulWidget {
  final String id;
  const Details({
    super.key,
    required this.id,
  });

  @override
  State<Details> createState() => _DetailsState();
}

/// bloc for details
class _DetailsState extends State<Details> {
  /// access to repo
  late CountersRepository _countersRepository;

  /// state to be managed by this page
  late Counter counter = _countersRepository.get(widget.id);
  StreamSubscription<Counter>? _subscription;

  @override
  void initState() {
    super.initState();

    /// repo created
    _countersRepository = countersRepository;

    /// subscribed for changes
    _subscription = _countersRepository.watch(widget.id).listen(
      (counter) {
        setState(
          () => this.counter = counter,
        );
      },
    );
  }

  /// method to mutate the state of repo
  /// without using setState here
  void put(Counter counter) => _countersRepository.put(counter);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id),
      ),
      body: Column(
        children: [
          Text(
            counter.id,
            style: TextStyle(fontSize: 44),
          ),
          Text(
            counter.value.toString(),
            style: TextStyle(fontSize: 144),
          ),
        ],
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 8,
        children: [
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => put(
              Counter(widget.id, counter.value + 1),
            ),
            child: Icon(Icons.add),
          ),
          FloatingActionButton(
            heroTag: 'remove',
            onPressed: () => put(
              Counter(widget.id, counter.value - 1),
            ),
            child: Icon(Icons.remove),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// single final instance of repo [SSOT]
final CountersRepository countersRepository = CountersRepository();

/// repo declaration
class CountersRepository {
  final StreamController<Counter> _controller = StreamController.broadcast();

  /// main source of truth
  final counters = <String, Counter>{};

  /// get counter by id
  Counter get(String byId) => counters[byId] ?? Counter.none();

  /// mutation
  void put(Counter counter) {
    counters[counter.id] = counter;
    _controller.add(counter);
  }

  /// watch for changes by id
  Stream<Counter> watch(String byId) async* {
    // Yield initial value
    if (counters.containsKey(byId)) yield counters[byId]!;

    // Yield subsequent changes
    await for (var counter in _controller.stream) {
      if (counter.id == byId) yield counter;
    }
  }

  /// watch all counters
  Stream<Iterable<Counter>> watchAll() async* {
    yield counters.values; // initial
    await for (var _ in _controller.stream) {
      yield counters.values;
    }
  }
}

/// data class
class Counter {
  final String id;
  int value;
  Counter(this.id, this.value);
  factory Counter.none() => Counter('NONE', -0);
  @override
  String toString() {
    if (id == 'NONE') return 'Counter.none()';
    return 'Counter($id, $value)';
  }
}
