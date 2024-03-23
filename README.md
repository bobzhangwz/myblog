# Blog by mkdocs-material

## How to run

Install `direnv` & `devbox`

```shell
curl -fsSL https://get.jetpack.io/devbox | bash
devbox install

brew install direnv  # Will take times, be patients
# This command is only for zsh
# The other shell hook, pls refer to: https://direnv.net/docs/hook.html
cat <<EOF >> ~/.zshrc
eval "\$(direnv hook zsh)"
EOF

sudo chown -R "$USER" /nix
source ~/.zshrc
```

## TODO

* [x] pre-commit
* [ ] commitizen
* [ ] command alias
* [ ] github action
* [ ] gitleaks
* [x] devbox service
* [ ] renovate
