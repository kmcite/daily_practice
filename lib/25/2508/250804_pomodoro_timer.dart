// ⏳ 3. Pomodoro Timer
// Screens: Main timer screen, settings
// Features:

// Start/stop/reset timer

// Configurable session length

// Watch elapsed time as reactive signal

// 🧠 Learn:

// Timer streams

// State mutation with countdown logic

// ✅ FEATURES TO BUILD NOW
// Start a Pomodoro session (25 mins)

// Show countdown timer

// Auto-switch to short break (5 mins) after Pomodoro

// After 4 Pomodoros, switch to long break (15 mins)

// Reset / Pause / Resume

// Optional: session counter

import 'dart:async';

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => TimerScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Time time = Time();
  Iterable<Pomodoro> pomodoros = [];
  final List<StreamSubscription> _subs = [];
  @override
  void initState() {
    super.initState();
    final timerSub = timerRepository.watch().listen(
      (time) {
        setState(() => this.time = time);
      },
    );
    final pomoSub = pomodorosRepository.watchAll().listen(
      (pomodoros) {
        this.pomodoros = pomodoros;
      },
    );
    _subs.addAll([timerSub, pomoSub]);
  }

  late final put = pomodorosRepository.put;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pomodoro Timer'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle),
            onPressed: () {
              put(Pomodoro(
                name: faker.person.name(),
              ));
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.settings),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: pomodoros.length,
              itemBuilder: (context, i) {
                final pomodoro = pomodoros.elementAt(i);
                return ListTile(
                  title: Text(pomodoro.name),
                );
              },
            ),
          ),
          Center(
            child: Text(
              '${time.seconds ~/ 60}:${time.seconds % 60}',
              style: TextStyle(fontSize: 48),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => timerRepository.start(),
        child: Icon(Icons.play_arrow),
      ),
    );
  }

  @override
  void dispose() {
    for (var sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    super.dispose();
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  StreamSubscription? _subscription;
  Settings settings = Settings();
  @override
  void initState() {
    super.initState();
    _subscription = settingsRepository.settings.listen(
      (settings) => setState(() => this.settings = settings),
    );
  }

  late final setLengthOfPomodoro = settingsRepository.setLengthOfPomodoro;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('Pomodoro Length ${settings.lengthOfPomodoro}'),
            subtitle: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setLengthOfPomodoro(settings.lengthOfPomodoro + 60);
                  },
                  icon: Icon(Icons.add),
                ),
                IconButton(
                  onPressed: () {
                    setLengthOfPomodoro(settings.lengthOfPomodoro - 60);
                  },
                  icon: Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}

/// REPOSITORIES

final timerRepository = TimerRepository();

enum TimerState { running, idle, paused }

class Time {
  int seconds = 0;
  TimerState state = TimerState.idle;
}

class TimerRepository {
  final controller = StreamController<Time>.broadcast();
  Stream<Time> watch() => controller.stream;
  Time time = Time();

  Duration duration = Duration(seconds: 1);
  Timer? timer;
  void start() {
    time.state = TimerState.running;
    timer = Timer.periodic(
      duration,
      tick,
    );
  }

  void tick(Timer _) {
    time.seconds++;
    controller.add(time);
  }

  void reset() {
    timer?.cancel();
    timer = null;
    time = Time();
  }

  void pause() {
    time.state = TimerState.paused;
    timer?.cancel();
  }

  void resume() {
    time.state = TimerState.running;
    timer = Timer.periodic(duration, tick);
  }
}

class Settings {
  int lengthOfPomodoro = 0;
  int lengthOfShortBreak = 0;
  int lengthOfLongBreak = 0;
  int numberOfPomodoroBeforeLongBreak = 0;
}

final settingsRepository = SettingsRepository();

class SettingsRepository {
  var value = Settings();

  Stream<Settings> get settings => _controller.stream;
  final _controller = StreamController<Settings>.broadcast();

  void setLengthOfPomodoro(int length) {
    _controller.add(value..lengthOfPomodoro = length);
  }

  void setLengthOfShortBreak(int length) {
    _controller.add(value..lengthOfShortBreak = length);
  }

  void setLengthOfLongBreak(int length) {
    _controller.add(value..lengthOfLongBreak = length);
  }

  void setNumberOfPomodoroBeforeLongBreak(int number) {
    _controller.add(value..numberOfPomodoroBeforeLongBreak = number);
  }
}

/// POMODOROS
final pomodorosRepository = PomodorosRepository();

class PomodorosRepository {
  final controller = StreamController<Iterable<Pomodoro>>.broadcast();
  Stream<Iterable<Pomodoro>> watchAll() => controller.stream;
  Stream<Pomodoro> watch(String byName) {
    return controller.stream.map(
      (pomo) => pomo.firstWhere((pomo) => pomo.name == byName),
    );
  }

  final pomodoros = <String, Pomodoro>{};

  void put(Pomodoro pomodoro) {
    pomodoros[pomodoro.name] = pomodoro;
    controller.add(pomodoros.values);
  }
}

class PomodoroBreak {
  final length = 1; // in mins
}

class Pomodoro {
  final String name;
  final int length = 20; // in seconds
  List<PomodoroBreak> breaks = [];

  Pomodoro({required this.name});
}

void review() {
// ---
// ## 🔍 **Brutally Honest Review (Total: 100 marks)**
// | **Component**                       | **Marks** | **Critical Notes** |
// | ----------------------------------- | --------- | ------------------ |
// | **🧱 Overall architecture pattern** | **7/15**  |                    |

// * Good instinct with repos and streams.
// * BUT: `faker` in production logic? Meh.
// * `Time`, `Settings`, `Pomodoro` models are not cohesive.
// * No state layer separation (bloc/viewmodel), so logic leaks into UI.
// * TimerRepository holds UI-timer state directly: **tight coupling**.
//   |

// \| **⏱ TimerRepository logic**             | **8/15** |

// * Works, yes.
// * BUT: no separation of session type (`work`, `break`), no duration binding from settings, no cycle control.
// * No timer completion callback or onTick pattern.
// * `controller.add(time)` happens with mutable shared `time` — can lead to bugs if multiple consumers mutate or expect immutability.
//   |

// \| **🧠 Session Flow Logic (core feature)** | **2/15** |

// * No actual Pomodoro session system.
// * No auto-switching.
// * No session state transitions.
// * No round tracking.
// * Not even a stub for this logic — the timer is just ticking blindly.
//   |

// \| **🛠 Settings Screen**                   | **4/10** |

// * Incomplete. No short/long break fields, no persistence.
// * No UI input validation or min-max limits.
// * Lacks usability — just two icon buttons.
// * `Settings` model uses default `0` values — doesn’t reflect real durations.
//   |

// \| **📲 UI/UX (Timer Screen)**             | **5/10** |

// * Countdown is displayed, but raw formatting: `1:3` instead of `01:03`.
// * No session label (“Working” / “Break”).
// * Button layout is basic.
// * Adding Pomodoro sessions seems unrelated to timer.
// * Not intuitive what the floating button does.
//   |

// \| **📦 Repositories**                     | **7/10** |

// * Structure is there, but incomplete abstraction.
// * No error handling.
// * Repositories leak mutable state (`Time` is shared mutable object).
// * Settings repo uses `..` mutation pattern without any `copyWith` — unsafe for scale.
//   |

// \| **🧪 Testability & Isolation**           | **2/5** |

// * Everything is mutable state.
// * No pure functions or injectable logic.
// * Difficult to write unit tests for timer/session flow because logic is embedded in side-effect-heavy classes.
//   |

// \| **📈 Extendability**                    | **4/5** |

// * Potential is there with repo-stream pattern.
// * But you're just one level short of real reuse.
// * Lack of timer abstraction (e.g., ticking engine, state machine) will block scaling.
//   |

// \| **🧹 Code Quality / Cleanliness**        | **4/5** |

// * Mostly clean.
// * Overuse of `late` fields, magic values (0 seconds everywhere), poor default safety.
// * UI and logic are not separated well, but you’re clearly trying.
//   |

// ---

// ## 🧾 **Final Score: 43 / 100** (Grade: **C–**, Raw & Unfinished)

// ---

// ## 🔥 Summary (Hard Truths)

// You **started correctly**, but stopped at the shell:

// * Timer works, but has no **brain** (no session state, no phase transitions).
// * Settings are a stub.
// * No clear connection between pomodoros list and timer session (no context of what's being timed).
// * Repos mimic a pattern but don't **encapsulate logic** or support scaling.
// * Code is readable and clean, but architecture is **immature**.

// ---

// ## 🚧 Key Fix Priorities

// 1. **Implement a state machine or session type**:

//    * Track: `Work`, `ShortBreak`, `LongBreak`
//    * Add transitions and durations.

// 2. **Make `Time` immutable**:

//    * Add a `copyWith()`, emit new object per tick.

// 3. **Introduce a bloc or controller layer**:

//    * Timer logic should not be in the repo.
//    * Repos = data, not behavior.

// 4. **Connect Pomodoro list to actual sessions**:

//    * Track completed sessions.
//    * Show progress toward long break.

// 5. **Upgrade Settings UI**:

//    * Sliders or number pickers with reasonable bounds.
//    * Default values.
//    * Save and load on app start.

// ---
}
