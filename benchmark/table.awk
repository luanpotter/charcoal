# Pivots benchmark_harness output, one file per library, into one table.
{
  library = FILENAME
  gsub(/^\.\/|\.txt$/, "", library)
  name = $1
  sub(/\(RunTime\):$/, "", name)
  if (!(name in seen)) {
    seen[name] = 1
    order[++count] = name
  }
  times[name, library] = $2
}

END {
  columns = split(libraries, names, " ")
  printf "%-18s", "us per run"
  for (c = 1; c <= columns; c++) printf "%20s", names[c]
  print ""
  for (i = 1; i <= count; i++) {
    printf "%-18s", order[i]
    for (c = 1; c <= columns; c++) printf "%20.3f", times[order[i], names[c]]
    print ""
  }
}
