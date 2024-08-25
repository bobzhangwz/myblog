---
categories:
  - Tool
  - Chinese
draft: false
date:
  created: 2024-05-19
---

# 程序中的错误处理


## 错误的分类

编程中遇到的非正常情况, 一般有两类:

1. 错误(Error), 错误指可能出现问题的地方出现了问题, 比如 HTTP 连接超时, 打开一个不存在的文件; 意料之中, 有办法解决, 通常和业务相关联.
2. 异常(Exception), 完全不可预料的错误. 比如 空指针, 数组越界; 通常是非业务相关的

很多语言没有对这些错误进行划分, 如 Java, Ruby, JS 都没有在语言层面上对以上情况进行划分. 以至于开发者把一切**非正常**情况, 都当做异常处理, 这样的做法不利于管理.

而在开发过程中有些错误需要在第一时间暴露出来, 才不至于传播到生产环境造成进一步危害.

一些编程语言在语言层面做了一些区别, 如 GO 在语言层面上区分了 异常(Panic) 和 错误(Error), 强制开发人员显式地处理错误. Rust 也增加了 `Result<L, R>` 和 `Panic` 类型, 帮助对各种错误进行分类

另外对于一些没有语言层面做支持的编程语言, 社区开发一些函数式的库, 也提供了解决办法, 如 Java 的函数式库`vavr` 提供了 `Either` 类型, `Kotlin` 的 `arrow` 提供了 `Either` 类型.

<!-- more -->

### Java 中的错误处理

在传统 Java 语言中, 开发者会通过给方法增加诸如 `throws XXXException` 的签名, 强制方法调用者必须对异常进行处理. 来保证异常被正确暴露, 并被及时处理.

由此, 在 Java 世界中, 也可以将错误分为两类

1. `Exception` - 需要在代码中处理, 保证业务正常执行.
2. `RuntimeException`, 不可预料的错误, 遇到错误直接终止.

这是一个很好的语言特性, 但是在实际开发过程当中, `Exception` 的强制性处理机制, 会让代码中充斥着 `try/catch`, 严重影响代码结构且特别影响易读性.

以至于开发者通常不会在方法声明中显式声明异常, 而是使用更加方便处理的 `RuntimeException`. - 这就与 `Exception` 设计初衷相悖了. 类型强制检查在 Java 中是一个很鸡肋的特性

* 参考: https://www.artima.com/articles/the-trouble-with-checked-exceptions

### Kotlin 的缺失

作为 Java 的继任者, Kotlin 对 Java 做了一些改进. 比如取消了强制异常检查. 这带来了一些好处, 同样也失去了异常类型检查带来的代码健壮性.

那么如何`既要`, `又要`?  借鉴函数式开发社区, 可以很轻松地找到解决方案 - `Either`.

## 什么是 `Either` 类型


```kotlin
sealed class Either<L, R>
data class Left<L>(value: L) : Either<L, R>
data class Right<R>(value: R) : Either<L, R>
```

`Either` 是一个抽象类型, 有两个子类, `Left` 和 `Right`; 当一个方法的返回结果是 `Either<L, R>`, 就表示这个返回结果可能是正确 `Right` 的, 也可能是错误 `Left` 的. 用 `Either` 就能表示返回结果的两种可能性(不是正确的(right), 就是错误(left)).

就像 `Optional` 之于 `NullPointerException`, 帮助解决程序中的空指针问题; `Either` 是 `Optional` 的泛化, 通过类型来帮助程序员管理各种异常, 保持程序健壮.

## 如何使用 `Either`

### 定义 Either

任何需要主动扔出异常的方法, 都可以使用 `Either` 包装返回值

如定义一个除法的方法, 当除数为 0 时, 可能会扔出 `InvalidDividerError`. 定义如下

```kotlin
fun divide(num1: Double, num2: Double): Either<InvalidDividerError, Double>  {
  if(num2 == 0) return InvalidDividerError().left()
  return (num1/num2).right()
}

fun divide(num1: Double, num2: Double): Either<InvalidDividerError, Double>  = either {
  if(num2 == 0) raise(InvalidDividerError())
  return num1/num2
}
```

### 编排 Either

```kotlin
fun compute(divider: Double): Either<InvalidDividerError, Double> = {
  // 4/divider + 3/divider
}
```

```kotlin
// Version 1
fun compute(divider: Double) = {
  // 4/divider + 3/divider
  val maybe1 = divide(4, divider)
  val maybe2 = divide(5, divider)
  try {
    val v1 = maybe1.getOrThrow()
  } catch(e: InvalidDividerError) {
    return e.left()
  }
  try {
    val v2 = maybe2.getOrThrow()
  } catch(e: InvalidDividerError) {
    return e.left()
  }

  return (v1 + v2).right()
}

// version 2
fun compute(divider: Double) = either {
  val maybe1 = divide(4, divider)
  val maybe2 = divide(5, divider)

  val v1 = maybe1.bind()
  val v2 = maybe2.bind()

  return v1 + v2
}
```

### 简单使用 Either

```kotlin
val result = compute(1)
// version 1
when(result) {
  is Left -> log.error(result.value)
  is Right -> log.info(result.value)
}

compute(1).fold(recover = { e: InvalidDividerError -> 0 }, transform = { result -> result })

compute(1).recover {
  e: InvalidDividerError -> 0
}
```
