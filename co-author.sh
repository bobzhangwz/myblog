#!/bin/bash
set -euo pipefail

if [ ! -t 1 ] ; then exit 0; fi

BRANCH_NAME=$(git branch | grep '*' | sed 's/* //')

if [[ "$BRANCH_NAME" =~ 'no branch' ]] ; then exit 0; fi

# exec >/dev/tty 2>&1
exec < /dev/tty

echo 'Please select your pair from the authors list:'

MESSAGE=$(
cat <<EOF
$(cat $1)


$(git shortlog -sce | cut -c8- | fzf -m --height 30% --border --prompt="Multi select by <tab>, No select by <C-c>:" | xargs -I '{}' echo "Co-authored-by: {}")
EOF
)

exec <&-

sed -i.bak "/Co-authored-by:.*/d" $1

echo "$MESSAGE" > $1l
