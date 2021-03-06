find . -type f -name '*.csv' -exec sh -c '
  for file do
    echo "$file"
    diff "$file" "/some/other/path/$file"
    read line </dev/tty
  done
' exec-sh {} +

# while IFS= read -r -d '' file; do
# echo ${file}

IFS= while read -r file; do ls "$file"; done < <(find . -name '* *.xml')