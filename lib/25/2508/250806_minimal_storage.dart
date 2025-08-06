import 'dart:async' show StreamController;
import 'dart:io';
import 'dart:math';

import 'package:async/async.dart';
import '250805_reactive_architecture.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

/// Create a simple storage library (key,value) pairs

class MinimalStorage extends Storage<String, String> {
  MinimalStorage(String path) {
    _file = File(path);
    if (!_file.existsSync()) {
      _file.createSync();
      // create file
    }

    _lastModified = _file.lastModifiedSync();
    _startPolling();
  }

  late final File _file;
  late DateTime _lastModified;
  final _controller = StreamController<void>.broadcast();
  bool _running = true;

  void _startPolling() {
    // to reflect changes originating in file system
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      final currentModified = _file.lastModifiedSync();
      if (currentModified.isAfter(_lastModified)) {
        _lastModified = currentModified;
        _controller.add(null);
      }
      return _running;
    });
  }

  @override
  String? get(String key) {
    final lines = _file.readAsLinesSync();
    for (final line in lines) {
      final map = jsonDecode(line);
      if (map['key'] == key) {
        return map['value'];
      }
    }
    return null;
  }

  @override
  Iterable<(String, String)> get pairs {
    final lines = _file.readAsLinesSync();
    return lines.map((line) {
      final map = jsonDecode(line);
      return (map['key'] as String, map['value'] as String);
    });
  }

  @override
  void set(String key, String value) {
    final lines = _file.readAsLinesSync();
    final updated = <String>[];
    var found = false;

    for (final line in lines) {
      final map = jsonDecode(line);
      if (map['key'] == key) {
        updated.add(jsonEncode({'key': key, 'value': value}));
        found = true;
      } else {
        updated.add(line);
      }
    }

    if (!found) {
      updated.add(jsonEncode({'key': key, 'value': value}));
    }

    _file.writeAsStringSync(updated.join('\n'));
    _lastModified = _file.lastModifiedSync();
    _controller.add(null);
  }

  @override
  void remove(String key) {
    final lines = _file.readAsLinesSync();
    final filtered = lines.where((line) {
      final map = jsonDecode(line);
      return map['key'] != key;
    }).toList();

    _file.writeAsStringSync(filtered.join('\n'));
    _lastModified = _file.lastModifiedSync();
    _controller.add(null);
  }

  @override
  Stream<void> get stream => _controller.stream;

  void dispose() {
    _running = false;
    _controller.close();
  }
}

abstract class Storage<K, V> {
  void set(K key, V value);
  V? get(K key);
  Iterable<(K key, V value)> get pairs;
  Stream get stream;
  void remove(K key);
}

typedef FromJson<V> = V Function(Map<String, dynamic> json);
typedef ToJson<V> = Map<String, dynamic> Function(V value);

class InMemoryStorageImpl<V> extends Storage<String, V> {
  final Map<String, V> _storage = {};
  FromJson<V> fromJson;
  InMemoryStorageImpl(this.fromJson);
  final controller = StreamController<(String, V)>.broadcast();
  @override
  V? get(key) {
    return _storage[key];
  }

  @override
  void set(key, value) {
    _storage[key] = value;
    controller.add((key, value));
  }

  @override
  Iterable<(String, V)> get pairs => _storage.entries.map(
        (e) => (e.key, e.value),
      );
  @override
  Stream get stream => controller.stream;

  @override
  void remove(String key) {
    _storage.remove(key);
    controller.add((key, null as V));
  }
}

void main() async {
  final storage = MinimalStorage(
    '${Directory.current.path}\\minimal_storage.txt',
  );
  put(StorageRepository(storage));
  put(Dark());
  put(StorageBloc());
  runApp(StorageApp());
}

class StorageBloc extends Bloc {
  late final Dark dark = watch();
  late final StorageRepository storage = watch();
  bool get _dark => bool.tryParse(storage().get('DARK') ?? 'false') ?? dark();

  void toggle() {
    storage().set('DARK', dark().toString());
    dark.toggle();
  }
}

class StorageApp extends UI<StorageBloc> {
  const StorageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: controller._dark ? ThemeData.dark() : ThemeData(),
      home: Home(),
    );
  }
}

class StorageRepository extends Repository<MinimalStorage> {
  StorageRepository(super.value);
  @override
  Stream<MinimalStorage> get stream => StreamGroup.merge(
        [
          value.stream.map((_) => value),
          super.stream,
        ],
      );
}

class Dark extends Repository<bool> {
  Dark() : super(true);
}

class Home extends UI<StorageBloc> {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minimal Storage'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: controller.toggle,
              icon: Icon(controller._dark ? Icons.dark_mode : Icons.light_mode),
            ),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: controller.storage().pairs.length,
        itemBuilder: (c, i) {
          final pair = controller.storage().pairs.elementAt(i);
          return ListTile(
            title: Text(pair.$1.toString()),
            subtitle: Text(pair.$2.toString()),
            onTap: () => controller.storage().remove(pair.$1),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final random = Random();
          final key = random.nextInt(1000000).toString();
          final value = random.nextInt(1000000).toString();
          controller.storage().set(key, value);
          controller.toggle();
        },
        label: Text(
          'create random key value',
        ),
      ),
    );
  }
}
