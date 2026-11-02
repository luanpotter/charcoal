# Benchmarks

How Charcoal compares to [json_serializable](https://pub.dev/packages/json_serializable), [dart_mappable](https://pub.dev/packages/dart_mappable), [freezed](https://pub.dev/packages/freezed), and hand-written code on the same models and payloads.


## Why

Why yet another serialization library? The real reason is not the `json_serializable` and `freezed` are slow, they are actually reasonably fast. But they are very hard to work with and lack many quality of life features (such as supporting inheritance, sealed chains, extension types, and more). They are also incomplete, not generating all methods I'd want. `dart_mappable` on the other hand solves all these problems, but it is much more: it is a dynamic dispatch library that allows for runtime overrides. That causes it to be upwards of 10x slower than the others, which is causing real life issues on my applications.

So, while I am including here benchmarking against all three alternatives, this is not purely masturbatory. There is a real performance issue with `dart_mappable` for certain use cases, and the comparison with the others is more in terms of lacking features than on speed alone. That being said, Charcoal's ultra-fast hand-rolled methods are slightly faster than even the state-of-the-art alternatives.


## Technique

```bash
scripts/bench.sh                  # every library, with comparison tables
scripts/bench.sh --only charcoal  # one library, as plain benchmark_harness output
scripts/bench.sh --rounds 5       # more rounds, 3 by default
```

Every library has the same models and runs the same payloads, compiled AOT and warmed; the reports are the median across rounds. Tests are run on **hand-written**, what a careful person could hand-write with no package, going through maps and `dart:convert` for JSON; plus all the other libraries. Features missing are shown as `-`, except for **Sealed families**, which we hand rolled for `json_serializable` (not a faire comparison, but good for context).


## Results


-Microseconds per run; best in each run (within 10% noise) is bolded:


### JSON

| Scenario           |  Charcoal | Hand-written | json_serializable | dart_mappable |   freezed |
| :----------------- | --------: | -----------: | ----------------: | ------------: | --------: |
| `flat.toJson`      |  **0.88** |         1.76 |              1.75 |          2.17 |      1.72 |
| `flat.fromJson`    |  **0.78** |         1.25 |              1.28 |          1.73 |      1.21 |
| `flat.toMap`       |  **0.23** |     **0.23** |              0.26 |          0.57 |      0.26 |
| `flat.fromMap`     |  **0.07** |     **0.07** |          **0.07** |          0.34 |  **0.07** |
| `book.toJson`      |  **4.26** |         6.30 |              6.64 |         12.17 |      6.58 |
| `book.fromJson`    |  **3.29** |         5.11 |              5.26 |          9.12 |      5.10 |
| `book.toMap`       |  **1.27** |     **1.23** |              1.45 |          6.84 |      1.49 |
| `book.fromMap`     |  **1.66** |     **1.67** |          **1.78** |          3.86 |  **1.70** |
| `catalog.toJson`   | **5,150** |        7,660 |             8,016 |        15,209 |     6,838 |
| `catalog.fromJson` | **3,704** |        5,800 |             6,117 |        11,098 |     5,282 |
| `catalog.toMap`    | **1,405** |    **1,340** |             1,604 |         8,915 |     1,621 |
| `catalog.fromMap`  |     2,395 |        2,202 |             2,229 |         5,035 | **1,827** |


### Sealed families

| Scenario            | Charcoal | Hand-written | json_serializable | dart_mappable |  freezed |
| :------------------ | -------: | -----------: | ----------------: | ------------: | -------: |
| `sealed2.toJson`    | **31.2** |         70.3 |              75.8 |          95.3 |     69.0 |
| `sealed8.toJson`    | **31.3** |         71.3 |              77.2 |         104.2 |     70.3 |
| `sealed44.toJson`   | **32.4** |         71.4 |              78.1 |         106.5 |     69.9 |
| `sealed2.fromJson`  | **27.2** |         35.7 |              34.9 |          68.4 |     35.0 |
| `sealed8.fromJson`  | **27.6** |         36.5 |              35.3 |          92.5 |     35.7 |
| `sealed44.fromJson` | **32.7** |         40.6 |              40.1 |         140.9 |     40.0 |
| `sealed2.toMap`     | **10.9** |     **10.8** |              17.8 |          40.1 |     11.9 |
| `sealed8.toMap`     | **11.0** |     **11.2** |              19.5 |          46.3 |     12.7 |
| `sealed44.toMap`    | **11.7** |     **11.6** |              20.1 |          48.3 | **12.7** |
| `sealed2.fromMap`   |  **5.2** |      **5.0** |           **5.3** |          55.1 |      6.0 |
| `sealed8.fromMap`   |  **5.6** |      **5.7** |           **5.9** |          72.0 |      6.6 |
| `sealed44.fromMap`  |  **9.2** |      **9.5** |           **9.7** |         129.6 |     10.8 |


### Strings

1 KB of text, with no escapes and with many of them:

| Scenario           | Charcoal | Hand-written | json_serializable | dart_mappable |  freezed |
| :----------------- | -------: | -----------: | ----------------: | ------------: | -------: |
| `plain.toJson`     | **2.35** |     **2.48** |              2.78 |          3.00 | **2.42** |
| `plain.fromJson`   | **1.70** |         2.13 |              2.15 |          2.07 | **1.78** |
| `escaped.toJson`   | **18.8** |         28.9 |              28.5 |          29.2 |     28.1 |
| `escaped.fromJson` |  **8.8** |         27.8 |              28.1 |          29.2 |     27.8 |


### Equality and hash

`equalsOtherFirst` and `equalsOtherLast` differ only in the first or the last thing the value holds. `json_serializable` has neither, so it is left out.

| Scenario                   |  Charcoal | Hand-written | dart_mappable | freezed |
| :------------------------- | --------: | -----------: | ------------: | ------: |
| `flat.equals`              |     0.017 |    **0.014** |         0.305 |   0.021 |
| `flat.hashCode`            | **0.025** |        0.030 |         0.288 |   0.031 |
| `book.equals`              |     0.184 |    **0.133** |         2.454 |   0.742 |
| `book.equalsOtherFirst`    |     0.015 |    **0.011** |         0.132 |   0.016 |
| `book.equalsOtherLast`     | **0.018** |        0.133 |         2.499 |   0.743 |
| `book.hashCode`            | **0.193** |        0.241 |         2.738 |   0.400 |
| `catalog.equals`           |       240 |      **176** |         2,795 |     802 |
| `catalog.equalsOtherFirst` |     0.028 |    **0.020** |         0.854 |   0.070 |
| `catalog.equalsOtherLast`  |       243 |      **178** |         2,797 |     806 |
| `catalog.hashCode`         |   **263** |          353 |         2,971 |     480 |
| `sealed2.equals`           |      1.92 |     **0.32** |         22.35 |    2.97 |
| `sealed8.equals`           |      1.97 |     **1.04** |         32.10 |    4.00 |
| `sealed44.equals`          |      1.96 |     **1.35** |         27.55 |    3.65 |
| `sealed2.hashCode`         |      2.25 |     **1.28** |         16.68 |    3.27 |
| `sealed8.hashCode`         |      2.25 |     **1.28** |         21.19 |    4.23 |
| `sealed44.hashCode`        |      2.27 |     **1.28** |         21.62 |    4.15 |


### Copying

`copyWith` is passed nothing, a new `title`, or a null `notes`. All of these are shallow, sharing what the value holds.

| Scenario             | Charcoal | Hand-written | dart_mappable |   freezed |
| :------------------- | -------: | -----------: | ------------: | --------: |
| `flat.copyWith`      |    0.025 |    **0.021** |         0.131 | **0.020** |
| `flat.copyWithValue` |    0.025 |        0.024 |         0.189 | **0.020** |
| `flat.copyWithNull`  |    0.026 |        0.031 |         0.185 | **0.020** |
| `book.copyWith`      |    0.039 |    **0.028** |         0.263 | **0.026** |
| `book.copyWithValue` |    0.039 |    **0.027** |         0.318 | **0.026** |
| `book.copyWithNull`  |    0.040 |        0.030 |         0.316 | **0.026** |


### Charcoal-only

What the direct writer and reader save, against going through maps with `dart:convert`:

| Scenario  | `toJson` | `jsonEncode(toMap())` | `fromJson` | `fromMap(jsonDecode())` |
| :-------- | -------: | --------------------: | ---------: | ----------------------: |
| `book`    |     4.26 |                  6.42 |       3.29 |                    5.53 |
| `catalog` |    5,150 |                 7,877 |      3,704 |                   6,578 |

What a mutable class has instead: a deep `copy`, rebuilding its collections and mutable classes, and comparing by content.

| Scenario   |  `copy` | `contentEquals` | `contentHash` |
| :--------- | ------: | --------------: | ------------: |
| `book`     |   0.102 |           0.122 |         0.130 |
| `catalog`  |     130 |             172 |           183 |
| `sealed2`  |    1.05 |            0.55 |          0.84 |
| `sealed8`  |    1.22 |            0.75 |          0.93 |
| `sealed44` |    1.88 |            1.33 |          1.45 |


### Build Step

Build times are mostly `build_runner` compiling its builders from cold, so they say little about the actual generators. Charcoal's generated code is not comparable here, as it also generates a mutable copy of every family and of `book`, which no other library has.

| Library           | Build (s) | Generated code (KB) | Executable (KB) |
| :---------------- | --------: | ------------------: | --------------: |
| Charcoal          |        39 |                 425 |           7,004 |
| Hand-written      |        22 |                   0 |           6,688 |
| json_serializable |        38 |                  18 |           6,671 |
| dart_mappable     |        39 |                 219 |           7,378 |
| freezed           |        40 |                 244 |           6,805 |

You can check the exact code for each test on this folder. Note that these are from local runs, so treat them with skepticism.


## Ultra-Fast

Ultra-fast means Charcoal pays a hefty cost: a lot of the internal is hand-rolled and not using shared fundamentals (such as Dart's json libraries):

- **Writing JSON:** Charcoal's direct writer takes about a third less time than `json_serializable` and about a third of the time of `dart_mappable`. It writes straight to a buffer, with no intermediate map.
- **Reading JSON:** Charcoal takes about 35% less time than `json_serializable` and about a third of the time of `dart_mappable`. It parses straight into the class, while the others build a map through `jsonDecode` first.
- **Maps:** Charcoal takes about 10% less time than `json_serializable` on `toMap`, and is tied on `fromMap`, where parsing the date in `book` is most of the work for everyone. It matches hand-written code. The gaps are smaller here because both are direct code. `dart_mappable` is several times slower, as it dispatches at runtime.
- **freezed:** it matches `json_serializable` on JSON, as it generates its JSON code through it, but its `==` is several times slower than Charcoal's on anything holding a collection.
- **Sealed families:** picking a leaf to write costs almost nothing, even with 44 of them, as it is a `switch` on the type. Picking one to read is what grows: a `switch` over strings compares tags one by one, so `sealed44.fromMap` costs nearly twice `sealed2.fromMap`, in Charcoal as in hand-written code. `dart_mappable` takes 14 times as long as Charcoal there.
- **Escaped strings:** reading them takes a third of the time of anything built on `jsonDecode`.


### Where Charcoal Falls Short

- **`==` loses to hand-written code**, taking about 40% more on `book` and more on sealed families. It comes from the extra call into the generated `$equals`, not from the cast: a separate comparison of a small class gave 8.9 ns as generated, 5.4 ns with that call inlined, and 7.0 ns by hand. This is not fixed yet.
- **`copyWith` takes about 50% more than `freezed`** on `book`, or 13 ns. A separate comparison puts about 2 ns of that on the function type that keeps `copyWith(x: null)` clear of `avoid_redundant_argument_values`, and it is still cheaper than a wrapper object once a value is passed. The rest is not explained yet.
- **`catalog.fromMap`** is behind everyone, at 2,395 against 1,827 for `freezed`. A longer run before this suite measured Charcoal at 1,916, so this row is noisy, and needs more rounds before reading anything into it.


## Questions Settled

- **Ordering comparisons by cost is worth it:** when only a cheap field differs, `book.equalsOtherLast` takes 0.018 against 0.133 for hand-written code in declaration order. The order is fixed at build time, so it adds nothing at run time.
- **Generating an enum `switch` is not worth it:** in a separate comparison, it was only about 20% faster than `values.byName`, as both compare names one by one, at 97 against 118 ns for the last of 44 values.
