#!/bin/bash

#append yaml header
header=$(cat <<EOF
---
---
EOF
)

if grep -Fxq -- "---" $1
then
    echo "header already found"
else
    echo "$header
$(cat $1)" > $1
fi

#replace selected true with newlined

sed -i 's/note = {selected: true}/selected={true}/' $1
