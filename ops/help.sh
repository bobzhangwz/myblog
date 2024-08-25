#!/usr/bin/env bash
set -eo pipefail

base_path=$(git rev-parse --show-toplevel)
commands_file="commands.yaml"

cd "$base_path"

passed_selected_name=$2
selected_options=$1

select_options() {
  category=$1
  selected_key=$2

  selected_value=$(yq ".${category}.[] | select(.name == \"$passed_selected_name\") | .${selected_key}" $commands_file)
  if [[ -z "$selected_value" ]]; then
    selected_name=$(yq ".${category}.[].name" $commands_file | \
          fzf --reverse --border --height=40% \
              --preview "yq -C '.${category}.[] | select(.name == \"{}\") | del(.name)' $commands_file"
        )
    selected_value=$(yq ".${category}.[] | select(.name == \"$selected_name\") | .${selected_key}" $commands_file)
  fi

  echo "$selected_value"
}


options=("command: exec build-in command" "links: open handy links")

if [[ -z "$selected_options" ]]; then
  selected=$(printf '%s\n' "${options[@]}" | fzf --height 15% --border)
  selected_options=$(cut -d : -f 1 <<< "$selected")
fi

bin_path="$base_path/.bin"

case "$selected_options" in
    command | c )
      bash -c "$(select_options "commands" "command")"
    ;;
    links | l | link)
      python -m webbrowser "$(select_options "links" "url")"
    ;;
    path )
      echo "$bin_path"
    ;;
    alias )
      rm -fr "$bin_path"
      mkdir -p "$bin_path"
      readarray commands_info < <(yq -o=j -I=0 ".commands.[] | select(.alias)" commands.yaml)
      for item in "${commands_info[@]}"; do
        name=$(echo "$item" | yq ".name")
        alias=$(echo "$item" | yq ".alias")
        command=$(echo "$item" | yq ".command")

        case "$alias" in
          yes | true )
            alias="$name"
          ;;
        esac
        echo "Creating alias $alias in $bin_path"
        echo "#!/usr/bin/env bash -e" > "$bin_path/$alias"
        echo "$command" >> "$bin_path/$alias"
        chmod a+x "$bin_path/$alias"
      done
    ;;
esac
