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
  printf "%-28s", "us per run"
  for (c = 1; c <= columns; c++) printf "%20s", names[c]
  print ""
  for (i = 1; i <= count; i++) {
    printf "%-28s", order[i]
    for (c = 1; c <= columns; c++) {
      if ((order[i], names[c]) in times) {
        printf "%20.3f", times[order[i], names[c]]
      } else {
        printf "%20s", "-"
      }
    }
    print ""
  }
}
