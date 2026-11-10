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


Microseconds per run, the median of 5 rounds; best in each run (within 10% noise) is bolded:


### JSON

| Scenario           |  Charcoal | Hand-written | json_serializable | dart_mappable |   freezed |
| :----------------- | --------: | -----------: | ----------------: | ------------: | --------: |
| `flat.toJson`      |  **0.86** |         1.70 |              1.67 |          2.10 |      1.73 |
| `flat.fromJson`    |  **0.76** |         1.21 |              1.20 |          1.66 |      1.20 |
| `flat.toMap`       |  **0.22** |     **0.22** |              0.25 |          0.56 |      0.25 |
| `flat.fromMap`     |  **0.07** |     **0.06** |          **0.07** |          0.33 |  **0.07** |
| `book.toJson`      |  **4.17** |         6.18 |              6.40 |         11.72 |      6.55 |
| `book.fromJson`    |  **3.35** |         5.01 |              5.03 |          8.74 |      5.09 |
| `book.toMap`       |  **1.26** |     **1.22** |              1.43 |          6.65 |      1.48 |
| `book.fromMap`     |  **1.57** |     **1.56** |          **1.72** |          3.65 |  **1.71** |
| `catalog.toJson`   | **4,680** |        6,472 |             6,530 |        12,627 |     6,671 |
| `catalog.fromJson` | **3,428** |        5,049 |             5,191 |         9,217 |     5,170 |
| `catalog.toMap`    | **1,323** |    **1,243** |             1,528 |         7,647 |     1,593 |
| `catalog.fromMap`  | **1,665** |    **1,645** |             1,812 |         3,906 | **1,798** |


### Sealed families

| Scenario            | Charcoal | Hand-written | json_serializable | dart_mappable |  freezed |
| :------------------ | -------: | -----------: | ----------------: | ------------: | -------: |
| `sealed2.toJson`    | **29.8** |         67.0 |              73.0 |          91.7 |     69.0 |
| `sealed8.toJson`    | **30.1** |         67.3 |              74.1 |          98.5 |     69.3 |
| `sealed44.toJson`   | **30.8** |         68.0 |              75.0 |         100.6 |     70.1 |
| `sealed2.fromJson`  | **27.0** |         34.9 |              34.0 |          64.7 |     34.8 |
| `sealed8.fromJson`  | **27.7** |         35.4 |              34.5 |          73.1 |     35.4 |
| `sealed44.fromJson` | **34.0** |         39.3 |              39.1 |         110.5 |     39.9 |
| `sealed2.toMap`     | **10.2** |     **10.2** |              17.2 |          37.5 |     11.9 |
| `sealed8.toMap`     | **10.5** |     **10.8** |              19.1 |          43.4 |     12.6 |
| `sealed44.toMap`    | **11.0** |     **11.1** |              19.1 |          44.8 |     12.5 |
| `sealed2.fromMap`   |  **5.0** |      **4.8** |           **5.2** |          38.0 |      6.0 |
| `sealed8.fromMap`   |  **5.5** |      **5.5** |           **5.8** |          45.6 |      6.7 |
| `sealed44.fromMap`  |  **9.7** |      **9.3** |           **9.5** |          83.9 |     10.5 |


### Strings

1 KB of text, with no escapes and with many of them:

| Scenario           | Charcoal | Hand-written | json_serializable | dart_mappable |  freezed |
| :----------------- | -------: | -----------: | ----------------: | ------------: | -------: |
| `plain.toJson`     | **2.25** |     **2.41** |              2.73 |          2.92 | **2.46** |
| `plain.fromJson`   |     2.11 |         2.11 |              2.12 |          2.01 | **1.79** |
| `escaped.toJson`   | **17.8** |         28.0 |              27.8 |          28.8 |     28.3 |
| `escaped.fromJson` |  **8.8** |         27.1 |              27.4 |          28.3 |     27.8 |


### Equality and hash

`equalsOtherFirst` and `equalsOtherLast` differ only in the first or the last thing the value holds. `json_serializable` has neither, so it is left out.

| Scenario                   |  Charcoal | Hand-written | dart_mappable | freezed |
| :------------------------- | --------: | -----------: | ------------: | ------: |
| `flat.equals`              | **0.015** |    **0.014** |         0.294 |   0.021 |
| `flat.hashCode`            | **0.022** |        0.030 |         0.282 |   0.031 |
| `book.equals`              |     0.164 |    **0.130** |         2.406 |   0.746 |
| `book.equalsOtherFirst`    |     0.015 |    **0.011** |         0.130 |   0.016 |
| `book.equalsOtherLast`     | **0.017** |        0.130 |         2.347 |   0.740 |
| `book.hashCode`            | **0.186** |        0.237 |         2.597 |   0.400 |
| `catalog.equals`           |       182 |      **140** |         2,511 |     796 |
| `catalog.equalsOtherFirst` |     0.025 |    **0.019** |         0.806 |   0.070 |
| `catalog.equalsOtherLast`  |       181 |      **140** |         2,474 |     797 |
| `catalog.hashCode`         |   **208** |          249 |         2,724 |     469 |
| `sealed2.equals`           |      0.73 |     **0.32** |         20.63 |    3.05 |
| `sealed8.equals`           |  **0.90** |         1.05 |         25.51 |    3.94 |
| `sealed44.equals`          |  **1.49** |     **1.37** |         26.32 |    3.64 |
| `sealed2.hashCode`         |  **1.24** |     **1.28** |         16.16 |    3.29 |
| `sealed8.hashCode`         |  **1.34** |     **1.28** |         19.53 |    4.35 |
| `sealed44.hashCode`        |      1.87 |     **1.28** |         20.78 |    4.13 |


### Copying

`copyWith` is passed nothing, a new `title`, or a null `notes`. All of these are shallow, sharing what the value holds.

| Scenario             |  Charcoal | Hand-written | dart_mappable |   freezed |
| :------------------- | --------: | -----------: | ------------: | --------: |
| `flat.copyWith`      | **0.019** |        0.021 |         0.134 | **0.020** |
| `flat.copyWithValue` | **0.020** |    **0.021** |         0.188 |     0.024 |
| `flat.copyWithNull`  | **0.020** |        0.023 |         0.185 |     0.028 |
| `book.copyWith`      | **0.025** |    **0.027** |         0.266 | **0.026** |
| `book.copyWithValue` | **0.025** |    **0.027** |         0.315 | **0.026** |
| `book.copyWithNull`  | **0.024** |        0.029 |         0.310 | **0.026** |


### Charcoal-only

What the direct writer and reader save, against going through maps with `dart:convert`:

| Scenario  | `toJson` | `jsonEncode(toMap())` | `fromJson` | `fromMap(jsonDecode())` |
| :-------- | -------: | --------------------: | ---------: | ----------------------: |
| `book`    |     4.17 |                  6.30 |       3.35 |                    4.90 |
| `catalog` |    4,680 |                 6,755 |      3,428 |                   4,821 |

What a mutable class has instead: a deep `copy`, rebuilding its collections and mutable classes, and comparing by content.

| Scenario   |  `copy` | `contentEquals` | `contentHash` |
| :--------- | ------: | --------------: | ------------: |
| `book`     |   0.095 |           0.118 |         0.117 |
| `catalog`  |     118 |             141 |           136 |
| `sealed2`  |    0.99 |            0.47 |          0.79 |
| `sealed8`  |    1.17 |            0.65 |          0.86 |
| `sealed44` |    1.81 |            1.23 |          1.30 |


### Build Step

Build times are mostly `build_runner` compiling its builders from cold, so they say little about the actual generators. Charcoal's generated code is not comparable here, as it also generates a mutable copy of every family and of `book`, which no other library has.

| Library           | Build (s) | Generated code (KB) | Executable (KB) |
| :---------------- | --------: | ------------------: | --------------: |
| Charcoal          |        35 |                 441 |           7,104 |
| Hand-written      |        20 |                   0 |           6,688 |
| json_serializable |        34 |                  18 |           6,671 |
| dart_mappable     |        34 |                 219 |           7,378 |
| freezed           |        34 |                 244 |           6,805 |

You can check the exact code for each test on this folder. Note that these are from local runs, so treat them with skepticism.


## Ultra-Fast

Ultra-fast means Charcoal pays a hefty cost: a lot of the internal is hand-rolled and not using shared fundamentals (such as Dart's json libraries):

- **Writing JSON:** Charcoal's direct writer takes about a third less time than `json_serializable` and about a third of the time of `dart_mappable`. It writes straight to a buffer, with no intermediate map.
- **Reading JSON:** Charcoal takes about a third less time than `json_serializable` and well under half the time of `dart_mappable`. It parses straight into the class, while the others build a map through `jsonDecode` first.
- **Maps:** Charcoal takes about 10% less time than `json_serializable` on `toMap`, and is tied on `fromMap`, where parsing the date in `book` is most of the work for everyone. It matches hand-written code. The gaps are smaller here because both are direct code. `dart_mappable` is several times slower, as it dispatches at runtime.
- **freezed:** it matches `json_serializable` on JSON, as it generates its JSON code through it, but its `==` is several times slower than Charcoal's on anything holding a collection.
- **Sealed families:** picking a leaf to write costs almost nothing, even with 44 of them, as it is a `switch` on the type. Picking one to read is what grows: a `switch` over strings compares tags one by one, so `sealed44.fromMap` costs nearly twice `sealed2.fromMap`, in Charcoal as in hand-written code. `dart_mappable` takes about 9 times as long as Charcoal there.
- **Escaped strings:** reading them takes a third of the time of anything built on `jsonDecode`.
- **Equality and copies:** a holder calls the generated `$equals` and `$hash` of what it holds directly, through a `switch` for a sealed family, rather than making a dynamic call to `==`. They are inlined, and `copyWith` is a closure rather than a tear-off, which would be a second call.


### Where Charcoal Falls Short

- **`==` loses to hand-written code on `book` and `catalog`**, taking about 25% more. This is not explained yet.
- **`sealed2.equals`** takes over twice as long as hand-written code, which a dynamic call between only two leaves suits best. This is not explained yet either.
- **`sealed44.hashCode`** takes about 45% more than hand-written code, as the `switch` over 44 leaves checks them one by one, where a dynamic call does not grow.
- **`plain.fromJson`** is tied with everyone but `freezed`. An earlier run had Charcoal at 1.70, but neither the code before these changes nor after gets that again on its own, so it was noise.


## Questions Settled

- **Ordering comparisons by cost is worth it:** when only a cheap field differs, `book.equalsOtherLast` takes 0.017 against 0.130 for hand-written code in declaration order. The order is fixed at build time, so it adds nothing at run time.
- **Generating an enum `switch` is not worth it:** in a separate comparison, it was only about 20% faster than `values.byName`, as both compare names one by one, at 97 against 118 ns for the last of 44 values.
- **Calling `$equals` directly is worth it:** going through `==` and with nothing inlined, `sealed8.equals` took 1.97, against 0.90 now, and `sealed8.hashCode` 2.25, against 1.34. With the inlining below, the executable grew by 1.4%, from 7,004 to 7,104 KB.
- **Inlining `$equals` and `$hash` is worth it:** in a separate comparison, it took `flat.equals` from 10.8 to 9.1 ns, and `sealed44.equals` from 1.61 to 1.34 µs.
- **`copyWith` costs nothing for its exact types:** returning a closure took `book.copyWith` from 0.039 to 0.025, against 0.025 for a plain method in a separate comparison. A wrapper object, as `freezed` has, would trip `avoid_redundant_argument_values` on `copyWith(notes: null)`.
- **`catalog.fromMap` was noise:** with 5 rounds, it is 1,665 against 1,645 for hand-written code.
