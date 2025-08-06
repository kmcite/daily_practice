import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';

/// ---------- UI Layer ----------
abstract class UI<T extends Bloc> extends StatefulWidget {
  const UI({super.key});
  T get controller => find<T>();

  @override
  State<UI<T>> createState() => _UIState<T>();
  Widget build(BuildContext context);
}

class _UIState<T extends Bloc> extends State<UI<T>> {
  late final T controller = find();

  @override
  void initState() {
    super.initState();
    withBlocContext(controller, controller.initState);
    controller.addListener(listener);
  }

  void listener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context);
  }
}

/// ---------- Bloc ----------
abstract class Bloc with ChangeNotifier {
  final _subscriptions = <StreamSubscription>[];

  T watch<T>() => find(notifyListeners);

  void subscribe<T>(Repository<T> repository) {
    final sub = repository.stream.listen((_) => notifyListeners());
    _subscriptions.add(sub);
  }

  void initState() {}

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  /// extension
  void _maybeSubscribe(Object? instance) {
    if (instance is Repository) {
      subscribe(instance);
    }
  }
}

/// ---------- Repository ----------
extension BoolRepos on Repository<bool> {
  void toggle() => emit(!value);
}

abstract class Repository<T> {
  Repository(this._value) {
    _controller.add(_value);
  }

  T _value;
  T get value => _value;
  T call() => value;
  final _controller = StreamController<T>.broadcast(
    onListen: _onListen,
    onCancel: _onCancel,
  );

  Stream<T> get stream => _controller.stream;

  void emit(T value) {
    _value = value;
    _controller.add(value);
  }

  static void _onListen() => _subscriberCount++;
  static void _onCancel() {
    _subscriberCount--;
    if (_subscriberCount == 0 && _autoDisposeEnabled) {
      _lastInstance?._disposeSelf();
    }
  }

  static int _subscriberCount = 0;
  static bool _autoDisposeEnabled = false;
  static Repository? _lastInstance;

  void enableAutoDispose() {
    _autoDisposeEnabled = true;
    _lastInstance = this;
  }

  void _disposeSelf() {
    dispose();
    registered.remove(runtimeType);
  }

  @mustCallSuper
  void dispose() {
    _controller.close();
  }
}

/// ---------- Registry ----------
final registered = <Type, dynamic>{};
Bloc? _contextBloc;

/// Register instance
void put<T>(T instance) {
  registered[T] = instance;
  _contextBloc?._maybeSubscribe(instance);
  log('[${instance is Repository ? 'R' : 'B'}] -> $T');
}

/// Find instance
T find<T>([void Function()? listener]) {
  final instance = registered[T];
  if (instance == null) throw Exception('No instance of type $T found');
  if (instance is Repository && listener != null) {
    instance.stream.listen((_) => listener());
  }
  _contextBloc?._maybeSubscribe(instance);
  return instance;
}

/// Dispose everything
void disposeAll() {
  for (final obj in registered.values) {
    if (obj is Bloc) obj.dispose();
    if (obj is Repository) obj.dispose();
  }
  registered.clear();
}

/// Bloc context
R withBlocContext<R>(Bloc bloc, R Function() run) {
  final prev = _contextBloc;
  _contextBloc = bloc;
  try {
    return run();
  } finally {
    _contextBloc = prev;
  }
}
