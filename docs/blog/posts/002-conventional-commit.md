---
categories:
  - Tool
  - DevOps
  - Chinese
draft: false
date:
  created: 2024-04-07
---

# Dev Envrionment As Code - Devbox 使用指南

## TLDR


## 挑战

切换项目是一个 TWer 需要面对的挑战, 当做为一个项目新人, 比较重要的一项工作就是下载代码, 安装依赖, 使代码能正确在本地启动并运行.

常常需要以下几个步骤

1. 下载应用的运行环境或编译环境, 如`JDK`, `NodeJs`, `ruby`, `python`, `gcc` 或 `rustup`, 并且版本需要一致
2. 下载应用包管理程序, `yarn`, `gradle/maven`, `sbt`, `cargo`, `bundler`, 并保证版本一致
3. 设置一些构建/运行程序必要环境变量, 比如企业内部maven repository地址/token, npm retristry 地址/Token
4. 下载安装一些能帮助开发/部署/管理应用的脚本/命令, 如 `pre-commit`, `tf-lint`, `kubectl`, `awscli`等
5. 手动运行一些初始化脚本, 如 `pre-commit init` 安装 `git-hooks`
6. 学习使用一些项目定制好的脚本, 可以快速启动项目


通常项目代码里的 `README.md` 会提供详细的运行文档, 新人根据文档手动执行各种命令, 完成安装运行; 如果遇到问题, 找人提供对应的指导. 这种模式存在几个问题:

1. **文档更新滞后** - 大多数时候, 随着项目的演进, 文档大部分时候总是滞后并缺少维护. 最终都是新人花很多的时间进行定位
2. **运行环境不一致** - 项目中成员的机器可能都装了不同版本的 JVM, NodeJs, ruby, python 作为默认开发环境, 各个版本五花八门. 导致应用在某些特定版本的开发环境上表现不一致. 当在不同项目中切换时, 经常需要引入不同虚拟机管理工具 如 `NVM`, `RVM`, `asdf`, `SDKMan`
3. **手动安装的不可重复性** - 手动安装的命令/程序不可靠,
   * 如命令版本太新/太旧导致, 导致不能运行
   * 如经常会漏掉执行一些初始化脚本

## 为什么是 Devbox

[Devbox](https://www.jetpack.io/devbox/docs/) 系统级(System level)的包管理程序, 如`yarn/npm` 之余 NodeJs.

`Devbox` 根植于 [Nix-shell](https://nixos.org/manual/nix/stable/command-ref/nix-shell), 不同于 `Nix-shell`繁杂的配置脚本, `Devbox` 提供了用户友好的配置方式.

一份`Devbox` 的配置文件(`devbox.json`)文件如下

```json
{
  "$schema": "https://raw.githubusercontent.com/jetpack-io/devbox/0.10.1/.schema/devbox.schema.json",
  "packages": [
    "pre-commit@latest",
    "gitleaks@latest",
    "cz-cli@latest",
    "nodePackages.pnpm@latest",,
    "python@3.12"
  ],
  "env": {
    "ARTIFACTORY_URL": "https://artifacts.i.internal-maven.com/artifactory"
  },
  "shell": {
    "init_hook": [
      "source $VENV_DIR/bin/activate"
    ],
    "scripts": {
      "init": [
        "pip install -r requirements.txt -q",
        "pre-commit install",
        "if [[ ! -e ./node_modules/cz-git ]]; then commitizen init cz-git --pnpm --save-dev --save-exact --force; fi",
      ]
    }
  }
}
```

根据上面的配置文件，Devbox可以帮助简化环境配置:

1. 帮助自动安装上面配置文件中声明的所有依赖项，例如JDK, NodeJS, 请参照配置中 `packages`
2. 将环境变量导入 shell，参照上面的字段 `env`.
3. 声明 `init_hooks`, 来准备一些数据或初始化shell环境，参考上面的 `init_hook` 字段.
4. 声明日常使用的随手命令，参考上面的字段 `scrpts`.

并且 `devbox` 会生成 `devbox.lock`, 类似于 `yarn.lock`, 进行锁定版本. 当将 `devbox.json` 和 `devbox.lock` 托管到 git 后, `devbox install` 就能帮助下载所有的依赖, 并保证所有版本一致.

### 快速上手

因为 `Nix-shell` 仅对 `Linux`, `macOS` 这两个平台做了支持, 所以 `Devbox` 也只支持了这两个平台.

更多细节可以参考官方文档 [quick start](https://www.jetpack.io/devbox/docs/quickstart/)

* 安装/初始化 `devbox`

```bash
> curl -fsSL https://get.jetpack.io/devbox | bash
> mkdir test_repo && cd test_repo
> devbox init
```

* 查找安装包

```bash
> # Search package
> devbox search openjdk --show-all
* openjdk  (19.0.1+10, 19.0.1, 17.0.3, 17.0.3+7, 17.0.1, 17.0.1+12, 16.0.1, 16+36, 16.0.0, 15.0.1-ga, 14.0.2-ga, 8u265-ga, 8u242-b08)
* openjdk8  (8u352-ga, 8.0.292, 8u322-ga, 8u272-b10, 8.36.0.1, 8u265-ga, 8u242-b08)
* openjdk11  (11.0.17+8, 11.0.11, 11.0.15+10, 11.0.12+7, 11.0.11+9, 11.0.10+9, 11.0.9+11, 11.0.8+10, 11.0.7-ga, 11.0.6-ga)
* openjdk14  (14.0.2-ga, 14.0.1-ga)
* openjdk15  (15.0.1-ga)
* openjdk16  (16.0.1, 16+36, 16.0.1, 16.0.0)
* openjdk17  (17.0.5+8, 17.0.3, 17.0.3+7, 17.0.1, 17.0.1+12, 16.0.1)
* openjdk19  (19.0.1+10, 19.0.1)

# Install JDK
> devbox add openjdk@17.0.3
> devbox add nodejs

> ls
devbox.json  devbox.lock

> cat devbox.json
{
  "packages": [
    "openjdk@17.0.3",
    "nodejs@latest"
  ],
  "shell": {
    "init_hook": [
      "echo 'Welcome to devbox!' > /dev/null"
    ],
    "scripts": {
      "test": [
        "echo \"Error: no test specified\" && exit 1"
      ]
    }
  }
}
```

* 加载 devbox shell, 启用 devbox 安装的依赖

```bash
# Start a isolated shell
> devbox shell
> java -version
openjdk version "17.0.3" 2022-04-19 LTS
OpenJDK Runtime Environment Zulu17.34+19-CA (build 17.0.3+7-LTS)
OpenJDK 64-Bit Server VM Zulu17.34+19-CA (build 17.0.3+7-LTS, mixed mode, sharing)
```

## 进阶使用

在引入了 devbox 之后, 我们可以最大程度定制化团队的开发环境. 以下是我们团队的一些实践

### 在终端(terminal)自动加载 devbox shell

[direnv](https://direnv.net/) 是 shell 的扩展程序. 他可以根据用户在终端进入到目录。自动加载和卸载环境变量.

利用 direnv，我们可以在进入项目目录时自动加载/卸载 devbox.

* 安装 `direnv`

```bash
brew install direnv  # Will take times, be patients
# This command is only for zsh
# The other shell hook, pls refer to: https://direnv.net/docs/hook.html
cat <<EOF >> ~/.zshrc
eval "\$(direnv hook zsh)"
EOF
```

* 在项目目录中添加 `.envrc` 文件

```bash
cat <<EOF > .envrc
eval "\$(devbox generate direnv --print-envrc)"
EOF
```

至此, 团队成员只需首次安装 `direnv` 和 `devbox` 即可.它们将自动帮助团队统一(unify)开发环境, 且无需任何额外配置.

### 自动初始化 - pre-commit hooks

[pre-commit](https://pre-commit.com/#intro) 是一个命令行工具, 它可通过一个简单的配置文件管理和维护 `git commit/push` 钩子。

`pre-commit` 允许我们共享一些通用的 git hooks，从而使团队获得统一的 git 体验.

遗憾的是，每当我们开始开发一个新仓库时，开发人员都需要使用 `brew install pre-commit && pre-commit install` 命令手动安装 pre-commit.

有了 `devbox`, 这种手动的工作就可以省去了. devbox 自动为你初始化

```bash
{
  "packages": [
    "pre-commit@latest"
  ],
  "shell": {
    "init_hook": [
      "pre-commit install"
    ]
  }
}
```

`pre-commit` 配置文件如下,开发人员的修改都会在 commit 前根据下面列出的所有规则进行检查.

```yaml
fail_fast: true
default_install_hook_types:
  - pre-commit
  - pre-push
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: check-added-large-files
      - id: check-merge-conflict
      - id: check-yaml
      - id: detect-private-key
      - id: end-of-file-fixer
      - id: fix-byte-order-marker
      - id: mixed-line-ending
      - id: trailing-whitespace
```

### 定制化脚本 - co-author.sh

结对编程(pair programming)在我们的日常编码工作中扮演着重要角色.在结对过程中，当在 git 中提交信息时，一般都需要在提交信息(commit message)中指定的结对对象.

根据 [github 的规范](https://docs.github.com/en/pull-requests/committing-changes-to-your-project/creating-and-editing-commits/creating-a-commit-with-multiple-authors#creating-co-authored-commits-using-github-desktop), 可以在 commit message 按照如下格式指定 co-author, github 就会按照内容标记提交人.

```bash
$ git commit -m "Refactor usability tests.
>
>
Co-authored-by: NAME <NAME@EXAMPLE.COM>
Co-authored-by: ANOTHER-NAME <ANOTHER-NAME@EXAMPLE.COM>"
```

下面这个脚本可以如果设置为 git hooks - `prepare-commit-msg`, 可以让在写完提交信息之后, 会弹出选择列表, 让选择 `Co-author`.

```bash
#!/bin/bash
set -euo pipefail
if [ ! -t 1 ] ; then exit 0; fi
BRANCH_NAME=$(git branch | grep '*' | sed 's/* //')
if [[ "$BRANCH_NAME" =~ 'no branch' ]] ; then exit 0; fi
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
echo "$MESSAGE" > $1
```

借助 `devbox`, 我们可以安装这个脚本需要用到的依赖 `fzf`, 并且自动将脚本挂载到 `.git/hooks/prepare-commit-msg`

```json
{
  "packages": [
    "fzf@latest"
  ],
  "shell": {
    "init_hook": [
      "cp ./tooling/co-author.sh .git/hooks/prepare-commit-msg"
    ]
  }
}
```

### 统一的提交格式 - 约定式提交(Conventional Commits)

[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) 是

> A specification for adding human and machine readable meaning to commit messages

按照传统的提交方式，提交信息的结构应如下所示：

```plain
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

```plain
fix: prevent racing of requests

Introduce a request id and a reference to latest request. Dismiss
incoming responses other than from latest request.

Remove timeouts which were used to mitigate the racing issue but are
obsolete now.

Reviewed-by: Z
Refs: #123
```

使用 Conventional Commits, repo 中的所有提交信息都会保持一致.引入 [git-cz](https://github.com/streamich/git-cz) 和 [cz-git](https://cz-git.qbb.sh/guide/introduction) 工具，团队就能轻松地以交互式的方式生成 `Conventional Commits`

![git-cz](https://user-images.githubusercontent.com/40693636/188255006-b9df9837-4678-4085-9395-e2905d7ec7de.gif)

借助 `devbox`, 我们也能自动化所有 `git-cz` 的安装操作, 之后，我们就可以使用 `git cz` 以交互方式提交代码了.

```json
{
  "packages": [
    "nodejs@16.20.2",
    "nodePackages.pnpm@latest",
    "cz-cli@latest"
  ],
  "shell": {
    "init_hook": [
      "if [[ ! -e ./node_modules/cz-git ]]; then commitizen init cz-git --pnpm --save-dev --save-exact --force; fi",
    ],
    "scripts": {}
  }
}
```

### 定制命令

借助 `direnv` 的自动加载功能, 以及 devbox 安装依赖. 我们可以为项目定制快捷操作

`.envrc` 代码如下

```bash
alias_dir=$PWD/.direnv/aliases

export_alias() {
  local name=$1
  shift
  local target="$alias_dir/$name"
  mkdir -p "$alias_dir"
  echo "#!/usr/bin/env bash -e" > "$target"
  echo "$@" >> "$target"
  chmod +x "$target"
}

export_alias c "pre-commit run && git cz --no-verify"
export_alias c-retry "pre-commit run && git cz --retry"
export_alias a "git add . -p"
export_alias gpush "git push --set-upstream origin \$(git symbolic-ref --short HEAD) \${@} && mkdocs gh-deploy"
export_alias grebase "git fetch origin main && git rebase origin/main"
export_alias up "devbox services up"

export_alias h "$(
cat <<EOCOMMOND

cat <<EOF | csvlook -d ';' | lolcat
Handy commands;Usage
a; alias for 'git add . -p'
c; check and commit
c-retry; commit with previous message
up; devbox services up
h; print all help links and commands
gpush; push to origin main and deploy
gpush -f; push to origin main force and deploy
grebase; fetch remote main and rebase to main
EOF

EOCOMMOND
)"

PATH_add "$alias_dir"
```

以上代码会在项目中创建 创建临时目录 `.direnv/aliases`, 并写入一些快捷命令, 如

* `c`, 使用 `pre-commit` 快速检查, 并使用 `git cz` 生成符合规范的提交
* `a`, 为 `git add . -p` 的别名
* `gpush`, 推送代码到远端分支
* `h`, 帮助列出所有的快捷命令, 但是需要 `devbox` 提前安装 `csvlook` 和 `lolcat`



#### 链接

### 本地秘钥管理

在日常工作中, 开发人员有时需要在 shell 中设置一些环境变量来执行命令, 例如 `ARTIFACTORY_TOKEN`, `GITHUB_TOKEN`. 通常, 我们会把这些秘钥都放在 `.zshrc` 或 `.bashrc` 中, 但这样做并不雅观, 会污染全局环境.

使用 `envrc`, 我们可以在项目中设置环境.

在 `.envrc` 中，添加代码 `[[ -e .env.local ]] && source .env.local`
要求开发人员在本地项目创建 `.env.local`

```bash
export ARTIFACTORY_USER="xxxx"
export ARTIFACTORY_TOKEN="$(security find-generic-password -s artifactory-token -w)"
export ARTIFACTORY_AUTH_TOKEN=$(echo -n "${ARTIFACTORY_USER}:${ARTIFACTORY_TOKEN}" | base64 -w 0)
export GITHUB_TOKEN='xxx'
```

同时不要忘记将 `.env.local` 添加到 `.gitignore`

至此, 在进入目录项目后, 这些关于秘钥的环境变量才会加载.

## Other

Replace for docker
