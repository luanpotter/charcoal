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
| `flat.toJson`      |  **0.90** |              1.70 |          2.15 |      1.73 |
| `flat.fromJson`    |  **0.79** |              1.25 |          1.68 |      1.27 |
| `flat.toMap`       |  **0.23** |              0.26 |          0.56 |      0.26 |
| `flat.fromMap`     |  **0.07** |          **0.07** |          0.33 |  **0.07** |
| `book.toJson`      |  **4.28** |              6.63 |         12.05 |      6.63 |
| `book.fromJson`    |  **3.32** |              5.36 |          8.98 |      5.28 |
| `book.toMap`       |  **1.32** |              1.47 |          6.80 |      1.48 |
| `book.fromMap`     |  **1.63** |          **1.75** |          3.87 |  **1.75** |
| `catalog.toJson`   | **5,042** |             7,300 |        14,584 |     7,601 |
| `catalog.fromJson` | **3,358** |             5,693 |        10,653 |     5,481 |
| `catalog.toMap`    | **1,395** |             1,587 |         8,852 |     1,622 |
| `catalog.fromMap`  | **1,916** |         **2,061** |         5,213 | **1,878** |

Build times are mostly `build_runner` compiling its builders from cold, so they say little about the actual generators, but I still measured it:

| Library           | Build (s) | Generated code (KB) | Executable (KB) |
| :---------------- | --------: | ------------------: | --------------: |
| Charcoal          |        36 |                  13 |           6,522 |
| json_serializable |        36 |                   2 |           6,541 |
| dart_mappable     |        38 |                  18 |           7,042 |
| freezed           |        39 |                  40 |           6,584 |

You can check the exact code for each test on this folder. Note that these are from local runs on a Linux, with Dart 3.13, so treat them with skepticism.


## Ultra-Fast

Ultra-fast means Charcoal pays a hefty cost: a lot of the internal is hand-rolled and not using shared fundamentals (such as Dart's json libraries):

- **Writing JSON:** Charcoal's direct writer takes about a third less time than `json_serializable` and about a third of the time of `dart_mappable`. It writes straight to a buffer, with no intermediate map.
- **Reading JSON:** Charcoal takes about 40% less time than `json_serializable` and about a third of the time of `dart_mappable`. It parses straight into the class, while the others build a map through `jsonDecode` first.
- **Maps:** Charcoal takes about 10% less time than `json_serializable` on `toMap`, and is tied on `fromMap`, where parsing the date in `book` is most of the work for everyone. The gaps are smaller here because both are direct code. `dart_mappable` is several times slower, as it dispatches at runtime.
- **freezed:** it matches `json_serializable`, as it generates its JSON code through it.
