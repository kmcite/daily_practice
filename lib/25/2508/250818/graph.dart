// main.dart
import 'package:flutter/material.dart';
import 'package:faker/faker.dart';
import 'package:signals_flutter/signals_flutter.dart';

class City extends Entity {
  City(super.id);
  String get name => id;
}

void main() {
  final graph = Graph<City, String>();
  runApp(GraphApp(graph: graph));
}

class GraphApp extends StatelessWidget {
  final Graph<City, String> graph;
  const GraphApp({super.key, required this.graph});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: AppBar(title: const Text('Graph Demo')),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  children: graph.vertices.map((vertex) {
                    final neighbors = graph.relationsFrom(vertex);
                    return Card(
                      child: ListTile(
                        title: Text(vertex.name),
                        subtitle: Text(
                          neighbors.isEmpty
                              ? "No relations"
                              : neighbors
                                  .map((e) => "${e.key.name} (${e.value})")
                                  .join(", "),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: graph.vertices.map((source) {
                  return Builder(builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              child: ListView(
                                shrinkWrap: true,
                                children: graph.vertices
                                    .where((dest) => dest != source)
                                    .map((dest) => ListTile(
                                          title: Text(dest.name),
                                          onTap: () {
                                            graph.addRelation(
                                              source,
                                              dest,
                                              "flight",
                                            );
                                            Navigator.pop(context);
                                          },
                                        ))
                                    .toList(),
                              ),
                            );
                          },
                        );
                      },
                      child: Text("Add relation from ${source.name}"),
                    );
                  });
                }).toList(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              final city = City(faker.address.city());
              graph.addVertex(city);
            },
            child: const Icon(Icons.add),
          ),
        ),
      );
    });
  }
}

// ---------- Graph core ----------

class Entity {
  final String id;
  Entity(this.id);

  @override
  bool operator ==(Object other) => other is Entity && id == other.id;
  @override
  int get hashCode => id.hashCode;
}

class Graph<E extends Entity, R> {
  // Single signal holding the entire adjacency map.
  // Map<E, Set<_Rel<E, R>>> so edges are unique.
  final Signal<Map<E, Set<_Rel<E, R>>>> _adjacency =
      signal(<E, Set<_Rel<E, R>>>{});

  /// Reactive: reading this inside Watch tracks changes.
  Iterable<E> get vertices {
    final m = _adjacency.value; // track
    return m.keys;
  }

  void addVertex(E entity) {
    final m = _adjacency.value;
    if (m.containsKey(entity)) return;
    _adjacency.value = {
      ...m,
      entity: <_Rel<E, R>>{},
    };
  }

  void removeVertex(E entity) {
    final m = _adjacency.value;
    if (!m.containsKey(entity)) return;

    final next = <E, Set<_Rel<E, R>>>{};
    for (final entry in m.entries) {
      if (entry.key == entity) continue;
      // drop edges pointing to 'entity'
      final filtered = entry.value.where((r) => r.to != entity).toSet();
      next[entry.key] = filtered;
    }
    _adjacency.value = next;
  }

  void addRelation(E from, E to, R relation) {
    final m = _adjacency.value;

    final fromSet = m[from] ?? <_Rel<E, R>>{};
    final newFromSet = {...fromSet, _Rel(to, relation)};

    _adjacency.value = {
      // ensure both endpoints exist
      if (!m.containsKey(to)) ...{to: m[to] ?? <_Rel<E, R>>{}},
      ...m,
      from: newFromSet,
    };
  }

  void removeRelation(E from, E to) {
    final m = _adjacency.value;
    final fromSet = m[from];
    if (fromSet == null) return;

    final newFromSet = fromSet.where((r) => r.to != to).toSet();
    _adjacency.value = {
      ...m,
      from: newFromSet,
    };
  }

  /// Reactive snapshot of (to, relation) pairs from `entity`.
  Iterable<MapEntry<E, R>> relationsFrom(E entity) {
    final m = _adjacency.value; // track
    final set = m[entity] ?? <_Rel<E, R>>{};
    return set.map((r) => MapEntry(r.to, r.relation));
  }

  Iterable<E> neighbors(E entity) => relationsFrom(entity).map((e) => e.key);
}

class _Rel<E, R> {
  final E to;
  final R relation;
  const _Rel(this.to, this.relation);

  @override
  bool operator ==(Object other) =>
      other is _Rel<E, R> && other.to == to && other.relation == relation;
  @override
  int get hashCode => Object.hash(to, relation);
}
//
