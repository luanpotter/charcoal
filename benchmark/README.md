# Benchmarks

How Charcoal compares to [json_serializable](https://pub.dev/packages/json_serializable), [dart_mappable](https://pub.dev/packages/dart_mappable) and [freezed](https://pub.dev/packages/freezed) on the same models and payloads.


## Why

Why yet another serialization library? The real reason is not the `json_serializable` and `freezed` are slow, they are actually reasonably fast. But they are very hard to work with and lack many quality of life features (such as supporting inheritance, sealed chains, extension types, and more). They are also incomplete, not generating all methods I'd want. `dart_mappable` on the other hand solves all these problems, but it is much more: it is a dynamic dispatch library that allows for runtime overrides. That causes it to be upwards of 10x slower than the others, which is causing real life issues on my applications.

So, while I am including here benchmarking against all three alternatives, this is not purely masturbatory. There is a real performance issue with `dart_mappable` for certain use cases, and the comparison with the others is more in terms of lacking features than on speed alone. That being said, Charcoal's ultra-fast hand-rolled methods are slightly faster than even the state-of-the-art alternatives.


## Technique

```bash
scripts/bench.sh                  # every library, with comparison tables
scripts/bench.sh --only charcoal  # one library, as plain benchmark_harness output
scripts/bench.sh --rounds 5       # more rounds, 3 by default
```


## Results

Microseconds per run; best in each run (within noise) is bolded:

| Scenario           |  Charcoal | json_serializable | dart_mappable |   freezed |
| :----------------- | --------: | ----------------: | ------------: | --------: |
| `flat.toJson`      |  **0.86** |              1.70 |          2.21 |      1.68 |
| `flat.fromJson`    |  **0.77** |              1.24 |          1.73 |      1.20 |
| `flat.toMap`       |  **0.22** |              0.26 |          0.58 |      0.26 |
| `flat.fromMap`     |  **0.07** |          **0.07** |          0.33 |  **0.07** |
| `book.toJson`      |  **3.38** |              5.57 |         11.16 |      5.55 |
| `book.fromJson`    |  **1.98** |              3.59 |          7.77 |      3.49 |
| `book.toMap`       |  **0.79** |              0.98 |          6.11 |      0.99 |
| `book.fromMap`     |  **0.44** |              0.54 |          2.41 |      0.53 |
| `catalog.toJson`   | **3,921** |             6,416 |        13,324 |     6,437 |
| `catalog.fromJson` | **1,989** |             3,938 |         8,257 |     3,814 |
| `catalog.toMap`    |   **828** |             1,068 |         7,461 |     1,052 |
| `catalog.fromMap`  |   **480** |               591 |         2,831 |       592 |

Build times are mostly `build_runner` compiling its builders from cold, so they say little about the actual generators, but I still measured it:

| Library           | Build (s) | Generated code (KB) | Executable (KB) |
| :---------------- | --------: | ------------------: | --------------: |
| Charcoal          |        35 |                  12 |           6,481 |
| json_serializable |        35 |                   2 |           6,516 |
| dart_mappable     |        36 |                  18 |           7,023 |
| freezed           |        37 |                  39 |           6,558 |

You can check the exact code for each test on this folder. Note that these are from local runs on a Linux, with Dart 3.13, so treat them with skepticism.


## Ultra-Fast

Ultra-fast means Charcoal pays a hefty cost: a lot of the internal is hand-rolled and not using shared fundamentals (such as Dart's json libraries):

- **Writing JSON:** Charcoal's direct writer takes about 40% less time than `json_serializable` and about a third of the time of `dart_mappable`. It writes straight to a buffer, with no intermediate map.
- **Reading JSON:** Charcoal takes about half the time of `json_serializable` and about a quarter of `dart_mappable`. It parses straight into the class, while the others build a map through `jsonDecode` first, which is where most of their time goes.
- **Maps:** Charcoal takes about 20% less time than `json_serializable` on `book` and `catalog`, and ties on the smallest case, `flat.fromMap`. The gaps are smaller here because both are direct code. `dart_mappable` is several times slower, as it dispatches at runtime.
- **freezed:** it matches `json_serializable`, as it generates its JSON code through it.
