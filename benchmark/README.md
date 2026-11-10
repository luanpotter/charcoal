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
| `flat.toJson`      |  **0.86** |         1.72 |              1.71 |          2.14 |      1.73 |
| `flat.fromJson`    |  **0.76** |         1.25 |              1.23 |          1.68 |      1.25 |
| `flat.toMap`       |  **0.22** |     **0.23** |              0.26 |          0.57 |      0.26 |
| `flat.fromMap`     |  **0.07** |     **0.07** |          **0.07** |          0.33 |  **0.07** |
| `book.toJson`      |  **4.15** |         6.26 |              6.61 |         12.04 |      6.78 |
| `book.fromJson`    |  **3.30** |         5.10 |              5.22 |          8.83 |      5.29 |
| `book.toMap`       |  **1.28** |     **1.25** |              1.44 |          6.72 |      1.50 |
| `book.fromMap`     |  **1.62** |     **1.58** |              1.80 |          3.71 |      1.86 |
| `catalog.toJson`   | **4,841** |        7,357 |             6,941 |        13,511 |     8,317 |
| `catalog.fromJson` | **3,448** |        6,167 |             5,534 |         9,454 |     6,657 |
| `catalog.toMap`    | **1,375** |    **1,319** |             1,543 |         7,945 |     1,715 |
| `catalog.fromMap`  | **1,783** |        2,121 |         **1,955** |         4,004 |     2,625 |


### Sealed families

| Scenario            | Charcoal | Hand-written | json_serializable | dart_mappable |  freezed |
| :------------------ | -------: | -----------: | ----------------: | ------------: | -------: |
| `sealed2.toJson`    | **30.1** |         68.2 |              73.5 |          93.0 |     71.9 |
| `sealed8.toJson`    | **30.7** |         69.2 |              75.2 |          99.7 |     72.1 |
| `sealed44.toJson`   | **31.7** |         69.5 |              75.5 |         103.0 |     72.9 |
| `sealed2.fromJson`  | **26.5** |         35.2 |              34.3 |          65.8 |     36.1 |
| `sealed8.fromJson`  | **27.3** |         35.7 |              34.6 |          74.3 |     36.8 |
| `sealed44.fromJson` | **32.5** |         39.8 |              39.3 |         110.8 |     41.0 |
| `sealed2.toMap`     |  **9.8** |     **10.4** |              17.3 |          38.5 |     12.4 |
| `sealed8.toMap`     | **10.1** |     **10.9** |              19.1 |          44.1 |     13.0 |
| `sealed44.toMap`    | **11.0** |     **11.2** |              19.3 |          45.5 |     13.1 |
| `sealed2.fromMap`   |  **5.0** |      **4.9** |           **5.3** |          40.3 |      6.1 |
| `sealed8.fromMap`   |  **5.5** |      **5.5** |           **5.8** |          48.7 |      6.8 |
| `sealed44.fromMap`  |  **8.8** |      **9.3** |           **9.5** |          83.6 |     10.7 |


### Strings

1 KB of text, with no escapes and with many of them:

| Scenario           | Charcoal | Hand-written | json_serializable | dart_mappable |  freezed |
| :----------------- | -------: | -----------: | ----------------: | ------------: | -------: |
| `plain.toJson`     | **2.30** |     **2.44** |              2.75 |          2.98 | **2.49** |
| `plain.fromJson`   | **1.70** |         2.13 |              2.13 |          2.04 | **1.84** |
| `escaped.toJson`   | **17.4** |         28.2 |              28.1 |          28.6 |     28.6 |
| `escaped.fromJson` |  **9.4** |         27.1 |              27.6 |          28.4 |     28.0 |


### Equality and hash

`equalsOtherFirst` and `equalsOtherLast` differ only in the first or the last thing the value holds. `json_serializable` has neither, so it is left out.

| Scenario                   |  Charcoal | Hand-written | dart_mappable | freezed |
| :------------------------- | --------: | -----------: | ------------: | ------: |
| `flat.equals`              | **0.015** |    **0.014** |         0.304 |   0.021 |
| `flat.hashCode`            | **0.022** |        0.030 |         0.289 |   0.032 |
| `book.equals`              |     0.165 |    **0.132** |         2.389 |   0.753 |
| `book.equalsOtherFirst`    |     0.015 |    **0.011** |         0.132 |   0.015 |
| `book.equalsOtherLast`     | **0.017** |        0.131 |         2.442 |   0.752 |
| `book.hashCode`            | **0.191** |        0.239 |         2.653 |   0.407 |
| `catalog.equals`           |       185 |      **165** |         2,553 |     852 |
| `catalog.equalsOtherFirst` | **0.017** |        0.019 |         0.818 |   0.070 |
| `catalog.equalsOtherLast`  |       190 |      **154** |         2,548 |     862 |
| `catalog.hashCode`         |   **213** |          270 |         2,824 |     511 |
| `sealed2.equals`           |  **0.32** |     **0.32** |         21.62 |    2.96 |
| `sealed8.equals`           |  **0.53** |         1.05 |         25.73 |    4.00 |
| `sealed44.equals`          |  **1.09** |         1.37 |         26.57 |    3.67 |
| `sealed2.hashCode`         |  **0.79** |         1.27 |         16.12 |    3.27 |
| `sealed8.hashCode`         |  **0.88** |         1.27 |         19.43 |    4.40 |
| `sealed44.hashCode`        |  **1.34** |     **1.28** |         21.04 |    4.14 |


### Copying

`copyWith` is passed nothing, a new `title`, or a null `notes`. All of these are shallow, sharing what the value holds.

| Scenario             |  Charcoal | Hand-written | dart_mappable |   freezed |
| :------------------- | --------: | -----------: | ------------: | --------: |
| `flat.copyWith`      | **0.019** |        0.021 |         0.133 | **0.021** |
| `flat.copyWithValue` | **0.020** |    **0.021** |         0.187 | **0.020** |
| `flat.copyWithNull`  | **0.019** |        0.023 |         0.182 | **0.020** |
| `book.copyWith`      | **0.026** |    **0.028** |         0.267 | **0.026** |
| `book.copyWithValue` | **0.025** |    **0.027** |         0.322 | **0.027** |
| `book.copyWithNull`  | **0.025** |        0.030 |         0.312 | **0.026** |


### Charcoal-only

What the direct writer and reader save, against going through maps with `dart:convert`:

| Scenario  | `toJson` | `jsonEncode(toMap())` | `fromJson` | `fromMap(jsonDecode())` |
| :-------- | -------: | --------------------: | ---------: | ----------------------: |
| `book`    |     4.15 |                  6.22 |       3.30 |                    5.36 |
| `catalog` |    4,841 |                 7,796 |      3,448 |                   6,045 |

What a mutable class has instead: a deep `copy`, rebuilding its collections and mutable classes, and comparing by content.

| Scenario   |  `copy` | `contentEquals` | `contentHash` |
| :--------- | ------: | --------------: | ------------: |
| `book`     |   0.102 |           0.118 |         0.118 |
| `catalog`  |     132 |             167 |           176 |
| `sealed2`  |    0.99 |            0.47 |          0.79 |
| `sealed8`  |    1.12 |            0.67 |          0.86 |
| `sealed44` |    1.82 |            1.28 |          1.39 |


### Build Step

Build times are mostly `build_runner` compiling its builders from cold, so they say little about the actual generators. Charcoal's generated code is not comparable here, as it also generates a mutable copy of every family and of `book`, which no other library has.

| Library           | Build (s) | Generated code (KB) | Executable (KB) |
| :---------------- | --------: | ------------------: | --------------: |
| Charcoal          |        36 |                 452 |           7,104 |
| Hand-written      |        20 |                   0 |           6,688 |
| json_serializable |        35 |                  18 |           6,671 |
| dart_mappable     |        36 |                 219 |           7,378 |
| freezed           |        40 |                 244 |           6,805 |

You can check the exact code for each test on this folder. Note that these are from local runs, so treat them with skepticism.


## Ultra-Fast

Ultra-fast means Charcoal pays a hefty cost: a lot of the internal is hand-rolled and not using shared fundamentals (such as Dart's json libraries):

- **Writing JSON:** Charcoal's direct writer takes about a third less time than `json_serializable` and about a third of the time of `dart_mappable`. It writes straight to a buffer, with no intermediate map.
- **Reading JSON:** Charcoal takes about a third less time than `json_serializable` and well under half the time of `dart_mappable`. It parses straight into the class, while the others build a map through `jsonDecode` first.
- **Maps:** Charcoal takes about 10% less time than `json_serializable` on `toMap` and `fromMap`, and matches hand-written code. The gaps are smaller here because both are direct code. `dart_mappable` is several times slower, as it dispatches at runtime.
- **freezed:** it matches `json_serializable` on JSON, as it generates its JSON code through it, but its `==` is several times slower than Charcoal's on anything holding a collection.
- **Sealed families:** picking a leaf to write costs almost nothing, even with 44 of them, as it is a `switch` on the type. Picking one to read is what grows: a `switch` over strings compares tags one by one, so `sealed44.fromMap` costs nearly twice `sealed2.fromMap`, in Charcoal as in hand-written code. `dart_mappable` takes about 9 times as long as Charcoal there.
- **Escaped strings:** reading them takes a third of the time of anything built on `jsonDecode`.
- **Equality and copies:** a holder calls the generated `$equals` and `$hash` of what it holds directly, through a `switch` for a sealed family, rather than making a dynamic call to `==`. They are inlined, and `copyWith` is a closure rather than a tear-off, which would be a second call.
- **Whole-program types:** the AOT compiler works out which concrete class each field holds across the whole program, and where it cannot, every `.length` or `[]` on that field becomes a dynamic call, everywhere. So the direct reader holds what it reads in fields of a small class rather than in locals, whose types the compiler loses across the loop.


### Where Charcoal Falls Short

- **`==` loses to hand-written code on `book` and `catalog`**, taking about 25% more on `book`. The comparison code is not the cause: `copyWith` is a function type, and the compiler cannot see what callers pass through one, so `Book`'s list and map fields could hold any class, and every use of them goes dynamic. A plain method or a wrapper object, as `freezed` has, gives `book.equals` 115 ns against 168, beating hand-written code at 130, in a separate comparison. Each gives up exact types or trips a lint, so the function type stays. A real app often widens such fields anyway, by building them from more than one list class.


## Questions Settled

- **Ordering comparisons by cost is worth it:** when only a cheap field differs, `book.equalsOtherLast` takes 0.017 against 0.130 for hand-written code in declaration order. The order is fixed at build time, so it adds nothing at run time.
- **Generating an enum `switch` is not worth it:** in a separate comparison, it was only about 20% faster than `values.byName`, as both compare names one by one, at 97 against 118 ns for the last of 44 values.
- **Calling `$equals` directly is worth it:** going through `==` and with nothing inlined, `sealed8.equals` took 1.97, against 0.90 with it, and `sealed8.hashCode` 2.25, against 1.34. With the inlining below, the executable grew by 1.4%, from 7,004 to 7,104 KB.
- **Inlining `$equals` and `$hash` is worth it:** in a separate comparison, it took `flat.equals` from 10.8 to 9.1 ns, and `sealed44.equals` from 1.61 to 1.34 µs.
- **Holding what the reader reads in fields is worth it:** it costs reading nothing, and took `sealed2.equals` from 0.73 to 0.32, `sealed8.equals` from 0.90 to 0.53, `sealed44.equals` from 1.49 to 1.09, and `sealed44.hashCode` from 1.87 to 1.34.
- **A `copyWith` call costs nothing for its exact types:** returning a closure took `book.copyWith` from 0.039 to 0.025, against 0.025 for a plain method in a separate comparison. A wrapper object, as `freezed` has, would trip `avoid_redundant_argument_values` on `copyWith(notes: null)`. What the function type does cost is elsewhere, in `==` above.
