# Reduces rounds of benchmark_harness output to one, with the median of each.
{
  name = $1
  if (!(name in count)) {
    order[++names] = name
  }
  values[name, ++count[name]] = $2
}

END {
  for (i = 1; i <= names; i++) {
    name = order[i]
    size = count[name]
    for (a = 2; a <= size; a++) {
      value = values[name, a]
      for (b = a - 1; b >= 1 && values[name, b] + 0 > value + 0; b--) {
        values[name, b + 1] = values[name, b]
      }
      values[name, b + 1] = value
    }
    middle = int((size + 1) / 2)
    median = (values[name, middle] + values[name, size + 1 - middle]) / 2
    printf "%s %s us.\n", name, median
  }
}
