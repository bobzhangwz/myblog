---
categories:
  - Tool
  - DevOps
  - Chinese
draft: false
date:
  created: 2024-03-26
---

# 开发工具箱 - pre-commit

## TLDR

本文介绍了一个工具 [pre-commit](https://pre-commit.com/), 是用来管理 `git-hook`. 推荐几个常用插件, 并总结了一些项目中的最佳实践.

## 正文

`GIT` 是一个非常流量的版本工具. 在程序员的日常开发中, `GIT` 帮助我们非常有效率地管理代码的历史几率.
通过 `GIT`, 开发者可以使用各种命令 `commit`, `push`, `merge`, 来管理源代码, 和其他开发者一起协作来开发应用.

在日常开发中, 我们会经常使用 `Git Hooks` 来进行提交前(pre-commit, pre-push)检查, 来保证推到远程的代码符合规范, 并且测试通过, 以提早发现问题, 从而不阻塞部署流水线.

然而在每次克隆(clone)新代码库时, `Git Hooks` 都需要手动初始化一遍,
比如前端开发会重使用 [husky](https://typicode.github.io/husky/) 来管理和安装 `Git Hooks`.
而像一些由 `Gradle` 构建的 Java 项目, 会在构建脚本 `build.gradle` 中加入一些如下初始化代码, 帮助自动安装 `Git Hooks`脚本. 如下所示

```groovy
task("addPreCommitGitHookOnBuild") {
    exec {
        commandLine("cp", "./.scripts/pre-commit", "./.git/hooks")
    }
    println("Added Pre Commit Git Hook Script.")
}
build.dependsOn addPreCommitGitHookOnBuild
```

[pre-commit](https://pre-commit.com/) 正是一个开源的专注于管理 `Git Hooks` 的框架, 虽然他是由 python 编写的, 但他并不像 `husky` 一样, 仅仅只局限于一种语言,
他对多种编程语言做了支持, 并提供了插件机制, 所以他可以是`通用`的.

## 简单入门

参照[pre-commit](https://pre-commit.com/)官方网站, 快速上手.

这里以一个 gradle 构建的 Java 项目为例

### 安装

```bash
pip install pre-commit
# 或
brew install pre-commit
```

### 配置文件

需要在项目根目录创建 `.pre-commit-config.yaml`

```yaml
fail_fast: true
# 指定需要初始化安装的 hooks
default_install_hook_types:
  - pre-commit
  - pre-push
repos:
  - repo: local
    hooks:
      - id: unit-backend
        name: unit-backend
        entry: ./gradlew check

        language: system
        pass_filenames: false
        # 当指定的文件类型改变时, 才会执行 hook
        types_or: [kotlin, sql, groovy, java-properties]
        # 只有当 src 下面的文件改变时, 才执行 hook
        files: 'src/.*'
        verbose: true
        # 指定 pre-push 才执行
        stages: [ push ]
```

通过配置 `files: 'src/.*'` 和 `types_or: [kotlin, sql, groovy, java-properties]`, 开发提交代码时, 如果没有改动的对应的后端代码, `gradle check` 就不会执行.

### 初始化 hooks

新克隆的代码都需要执行如下脚本, 来初始化 `Git Hooks`. 之后当每次新推(push)代码, 并且满足配置文件的条件时, 就会触发 `./gradlew check` 命令

```bash
$ pre-commit install
pre-commit installed at .git/hooks/pre-commit
$ pre-commit install-hooks
```

## 最佳实践

### 使用插件

`pre-commit` 提供了插件机制, 开发人员能方便地将通用的一些检查抽成可复用的插件. 通过配置, 项目库中可以快速引入这些插件. 更多插件, 请移步 [插件库](https://pre-commit.com/hooks.html)

`pre-commit` 官方提供一些常用的插件, 比如 `trailing-whitespace`, `end-of-file-fixer` 等等, 更多内容, 可以参考 [pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks).

下面的 `pre-commit` 配置, 基本在所有项目都能使用, 他能帮助开发者在提交代码前快速做一些检查, 并且修复一些发现的问题, 保证代码风格一致.

```yaml
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

#### 推荐插件

这里推荐一些日常开发中常用到的一些 `pre-commit` 插件, 适用于大部分项目

##### 1. checkov

`checkov`, 能帮助扫描一些有潜在配置风险的代码扫描工具, 如果你的代码里有 `terraform` 配置文件, `kubernetes`, `ansible` 之类的IoC(基础设置即代码)代码, 推荐使用. 参考[官网文档](https://www.checkov.io/4.Integrations/pre-commit.html)
```yaml
- repo: https://github.com/bridgecrewio/checkov.git
  rev: '3.2.47' # change to tag or sha
  hooks:
  - id: checkov
    # - id: checkov_container
    # - id: checkov_diff
    # - id: checkov_diff_container
    # - id: checkov_secrets
    # - id: checkov_secrets_container
```

##### 2. gitleaks

`gitleaks` 能帮助开发者扫描代码库中可能泄露的密码, 秘钥; 参考[官方文档](https://github.com/gitleaks/gitleaks/tree/master?tab=readme-ov-file#pre-commit)
```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.16.1
    hooks:
      - id: gitleaks
```

##### 3. Conventional Commits

[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) 是一个关于 commit message 的约定, 开发者可以通过一些工具自动生成符合格式的 提交信息, 如 [commitizen](https://github.com/commitizen-tools/commitizen), [cz-cli](https://github.com/commitizen/cz-cli). 通过其 `pre-commit` 插件, 让开发者们有统一风格的提交信息.
```yaml
repos:
  - repo: https://github.com/commitizen-tools/commitizen
    rev: v3.13.0
    hooks:
      - id: commitizen
```

### 实时查看输出结果

`pre-commit` 会假设所有的检查会在很短的时间内执行完, 所以都是在等命令执行完成之后, 输出对应的结果.
当时如果有时候执行的 hook 需要很长的时间运行(>3min), 开发者不能实时收到运行状态.

如下例, 当测试过多, 并且依赖过多, 会导致 `gradle check`, 执行时间超过 `5 min`, 如果开发人员不能实时得到允许的状态, 会对运行的检查产生怀疑, 从而跳过检查. 体验不友好.

```yaml
repos:
  - repo: local
    hooks:
      - id: unit-backend
        entry: ./gradlew check
        language: system
        types_or: [kotlin, sql, groovy, java-properties]
```

所以当跑到任务时间过长(>30s), 需要实时接收到消息时, 可以使用 `bash -c './gradlew check &>/dev/tty'`, 让开发者能实时知道任务进度.

### 只检查修改到的文件

有时候开发提交代码时, 会执行 `yarn lint` 命令, 去检查代码风格按照约定的格式执行.
`lint` 命令通常会对全部的文件进行扫描, 不管你有没有做了更改. 如果项目比较大, 这会导致很长的检查时间, 不能有效率的提交代码.

```yaml
repos:
  - repo: local
    hooks:
      - id: unit-front
        entry: yarn lint
        language: system
        types_or: [javascript]
        stages: [ push ]
```

`pre-commit` 提供了一个参数, `pass_filenames`, 如果设置为 `true`, 在运行脚本时, `pre-commit`会将更改到的文件名传入脚本. 利用这个特性, 我们就能让 `lint` 只检查修改到的文件, 从而大大提高提交效率.

```yaml
repos:
  - repo: local
    hooks:
      - id: unit-front
        entry: yarn lint
        pass_filenames: true
        language: system
        types_or: [javascript]
        stages: [ push ]
```

### hook 执行策略

在实践中, 通常对于代码的检查分为两种

1. `lint`, 对代码风格进行验证, 运行时间短.
2. `test`, 执行测试代码, 运行时间长.

同时对于代码的提交也分为两种

1. `commit`, 提交代码, 通常会比较频繁
2. `push`, 推送代码, 相对不频繁

所以一种兼顾效率和质量的方式就是, 在 `pre-commit` 做 `lint` 检查, 在 `pre-push` 阶段跑 `test`, 从而提升开发体验.

```yaml
repo: local
hooks:
  - id: lint-backend
    name: lint-backend
    entry: bash -c './gradlew -p backend ktlint &>/dev/tty'
    files: 'backend/.*'
    language: system
    pass_filenames: false
    types_or: [ kotlin ]
    verbose: true
    stages: [ commit ]

  - id: unit-backend
    name: unit-backend
    entry: bash -c './gradlew -p backend check &>/dev/tty'
    files: 'backend/.*'
    language: system
    pass_filenames: false
    types_or: [ kotlin, sql, groovy, java-properties ]
    verbose: true
    stages: [ push ]
```

## 总结

`pre-commit` 极大的简化了 git-hooks 的管理工作, 同时他丰富的插件生态, 能方便的帮助一个项目集成一些 安全检查工具, 风格检查工具 和 测试工具, 提高开发/交付效率.

推荐指数: ⭐️⭐️⭐️⭐️⭐️
