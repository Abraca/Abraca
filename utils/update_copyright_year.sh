git grep -l -E "Copyright.+Abraca Team" | \
    xargs -I {} sed -i -r -e"s/Copyright \(C\) ([0-9]{4})-?[0-9]* Abraca Team/Copyright (C) \1-`date +%Y` Abraca Team/g" {}
