#import "@preview/polylux:0.4.0": later, only, slide, uncover
#import "@preview/simplebnf:0.2.0": Or, Prod, bnf
#import "@preview/tdtr:0.5.5": tidy-tree-graph
#import "@preview/ctheorems:1.1.3": thmrules
#import "@preview/curryst:0.6.0": prooftree, rule
#import "@preview/fletcher:0.5.8": diagram, edge, node
#import "../common/common.typ": license

#set page(paper: "presentation-16-9")
#show heading: set block(below: 1em)
#show figure.where(kind: image): set figure(supplement: "图")

// font and styles

#set text(size: 23pt, font: ("Source Sans 3", "Source Han Sans SC"))
#show raw: set text(size: 1.1em, font: "Sarasa Mono Slab SC")
#show link: set text(fill: blue.darken(25%))
#show: thmrules

// codly

#import "@preview/codly:1.3.0": codly-init, codly-reset, codly
#import "@preview/codly-languages:0.1.10": codly-languages
#show: codly-init.with()
#let setup-codly() = {
  codly-reset()
  codly(languages: codly-languages)
  codly(zebra-fill: luma(250))
}
#setup-codly()

// other

#let date = datetime(
  year: 2026,
  month: 6,
  day: 13,
)

// helper

#let note(body) = {
  text(size: 0.85em, fill: gray.darken(40%))[
    _#body _
  ]
}

#let syntax-tree(..args) = tidy-tree-graph(
  text-size: 0.9em,
  node-inset: 0.4em,
  spacing: (20pt, 20pt),
  ..args,
)

#let lc = [$lambda$-演算]
#let step(subscript) = $attach(arrow.r, br: #subscript)$
#let steps(subscript) = $attach(arrow.r, tr: "*", br: #subscript)$
#let equal(subscript) = $attach(=, br: #subscript)$
#let app-node = [@]
#let important(..args) = text(fill: blue, weight: 600, ..args)
#let warning(..args) = text(fill: red, weight: 600, ..args)
#let mathimportant(body, ..args) = text(
  fill: blue,
  ..args,
  math.underline(body),
)
#let wrong(body, ..args) = text(fill: red, ..args, body)
#let doalpha(body, ..args) = text(fill: green, ..args, math.underline(body))
#let dobeta(body, ..args) = text(fill: blue, ..args, math.underline(body))
#let doeta(body, ..args) = text(fill: orange, ..args, math.underline(body))
#let desugar(body, ..args) = text(fill: purple, ..args, math.underline(body))
#let code(body, ..args) = math.overline(body, ..args)
#let letin(x, item) = $"let" x = item "in"$
#let ruleitem(name, body) = align(center)[
  *规则#name*:
  #body
]
#let FV = $"FV"$
#let item-box(body, caption: none, ..args) = block(
  inset: 0.5em,
  stroke: 0.5pt + gray,
  radius: 4pt,
  width: 100%,
  ..args,
  align(center)[
    #if caption != none [
      #caption
      #v(-0.5em)
    ]

    #body
  ],
)

#slide[
  == #lc; - 开始之前

  #set text(size: 0.8em)

  你可能想要：

  #columns(2)[
    #set align(center)
    #image("images/this-slides.png", width: 7cm)

    获取本幻灯片

    #colbreak()

    #image("images/lambdacalc-dev.png", width: 7cm)

    在线#lc;解释器

    #link("https://lambdacalc.dev")[lambdacalc.dev]
  ]
]

#slide[
  #set align(horizon)

  #grid(columns: 2, gutter: 0.5cm)[
    #image("images/this-slides.png", width: 7cm)
  ][
    #text(size: 1.2em)[= 给 Nix 用户的 #lc;基础]
    #v(-0.5em)
    #text(size: 1.0em)[= $lambda$-Calculus Basics for Nix Users]

    #v(0.5em)

    #text(size: 1.1em)[Yinfeng]
    #v(-0.5em)
    #date.display()
  ]

  #license()
]

#slide[
  == 关于我


  #set align(horizon)
  #grid(columns: 2, gutter: 2cm)[
    #align(center)[
      #text(size: 1.2em)[*Yinfeng*]

      #v(10pt, weak: true)
      #image("../common/images/yinfeng-qrcode.svg", width: 8cm)
      #v(10pt, weak: true)
      #link("https://github.com/linyinfeng")[github.com/linyinfeng]
    ]
  ][
    也算是个研究程序设计语言的。
  ]
]

#slide[
  == #lc;？


  - 回想我第一次尝试使用 NixOS 的时候，对 Nix 语言非常不适应；
  - 学了 #lc;后，第二次接触 NixOS 语言时，我的感想完全变了。

    这 Nix 语言不就是：
    #align(center)[
      #lc + bool + int + string + attrset + derivation#footnote[包含 string context。]
    ]
    味太对了。
]

#slide[
  == 目录


  #columns(2)[
    + #lc;简介
    + 用 #lc;编程
    + 语法糖
    + #lc;的扩展
    + #lc;的形式语义
    + #lc;的求值顺序
    + 不动点
    #colbreak()
    #set enum(start: 8)
    + 理解 Nix 语法和库
      - `let` & `rec` & `lib.fix`
      - Overlay & NixOS modules
    + 扩展知识
      + 不动点组合子
      + 希尔伯特可判定性问题与\
        邱奇-图灵论题
      + #lc;的实现
  ]
]

#slide[
  == #lc;简介

  #grid(
    columns: 2,
    gutter: 1em,
    [
      #align(figure(caption: "阿隆佐·邱奇")[
        #block(clip: true, radius: 10pt, image(
          "images/alonzo-church.jpg",
          height: 70%,
        ))
      ])
    ],
    [
      - Lambda calculus
        - 一种理想化的编程语言
        - 一个形式系统
        - 一种计算模型
      - 阿隆佐·邱奇（Alonzo Church，1903--1995）在 1930 年代提出
    ],
  )
]

#slide[
  == #lc;简介

  作为一种理想化的程序设计语言，#lc;只有三种语法：

  #columns(2)[
    #bnf(
      Prod(
        $M, N$,
        {
          Or[$x$][_variable_]
          Or[$lambda x. M$][_abstraction_]
          Or[$M N$][_application_]
        },
      ),
    )
    #colbreak()
    #later[
      ```nix
      x     # variable
      x: M  # abstraction
      M N   # application
      ```
    ]
  ]

  #later[
    Abstraction 在这里就是函数的另一种说法。
  ]

  #later[
    $M, N$ 被叫作 #important[$lambda$-项（terms）]，也被称作 #important[lambda 表达式]，也就是“程序”。
  ]
]

#slide[
  == #lc;简介 -- 书写规则

  $ M, N = x | lambda x. M | M N $

  #only(1)[
    $lambda$-项的定义是抽象语法树，有时我们需要在书写中添加一些括号来明确项到底是怎么结合的。

    比如：

    $ (x y) z != x ( y z ) $

    $ lambda x. (x y) != (lambda x. x) y $

    我们需要规定形如 $x y z$ 或 $lambda x. x y$ 的项究竟是哪一个项。
  ]

  #only(2)[
    #ruleitem(1)[函数应用（applications）是左结合的]

    #grid(columns: 2, gutter: 1em)[
      #item-box(caption: [$x y z = (x y) z$])[
        #syntax-tree[
          - #app-node
            - #app-node
              - $x$
              - $y$
            - $z$
        ]
      ]
    ][
      #item-box(caption: [$x (y z)$])[
        #syntax-tree[
          - #app-node
            - $x$
            - #app-node
              - $y$
              - $z$
        ]
      ]
    ]
  ]

  #only(3)[
    #ruleitem(
      2,
    )[抽象（abstractions）的优先级比应用低（$lambda x.$ 作用到最远的位置）]

    #grid(columns: 2, gutter: 1em)[
      #item-box(caption: [$lambda x. x y = lambda x. (x y)$])[
        #syntax-tree[
          - $lambda x.$
            - #app-node
              - $x$
              - $y$
        ]
      ]
    ][
      #item-box(caption: [$(lambda x. x) y$])[
        #syntax-tree[
          - #app-node
            - $lambda x.$
              - $x$
            - $y$
        ]
      ]
    ]
  ]
]



#slide[
  == #lc;简介

  #set text(size: 0.9em)

  在 #lc;中，所有抽象（abstractions）都是“*匿名函数*”。在许多程序设计语言中都可以找到类似物。

  $lambda x. M$ 在不同语言中的类似物：

  #align(center, columns(2, [
    #table(
      columns: (auto, auto),
      inset: 7pt,
      table.header([*语言*], [*写法*]),
      [Nix], ```nix x: M```,
      [Haskell], ```haskell \x -> M```,
      [Scheme], ```lisp (lambda (x) M)```,
      [Python], ```python lambda x: M```,
      [Rust], ```rust |x| M```,
      [JavaScript], ```javascript function(x) { return M; }```,
      [JavaScript], ```javascript x => M```,
      [C++], ```cpp [](auto x) { return M; }```,
      [Kotlin], ```kotlin { x -> M }```,
      [Swift], ```swift  { x in M }```,
    )
  ]))
]

#slide[
  == #lc;简介 -- 例子

  通过几个例子，我们可以在不形式化的情况下简单理解 #lc;的语义。

  #only(1)[
    + 恒等函数 $I$（identity）：$I eq.def lambda x. x$

      $
        desugar(I) y &= dobeta((lambda x. x)) y step(beta)y \
        desugar(I I) &= dobeta((lambda x. x) (lambda x. x)) step(beta)(lambda x. x) \
        desugar(I I I) &= dobeta((lambda x. x) (lambda y. y)) (lambda z. z) step(beta)dobeta((lambda y. y) (lambda z. z)) step(beta)(lambda z. z)
      $

    #note[
      - 此处 $I$ 并不是一个语法/变量，只是为了方便，将 $lambda x. x$ 简写成了 $I$。
      - 我们并没有定义 $I y$ 中的 $y$ 是什么，它是一个*自由变量*。
      - 可以通过类比其他语言中的匿名函数进行理解。
    ]
  ]

  #only(2)[
    #set enum(start: 2)
    + 常数函数 K（const）： $K eq.def lambda x. lambda y. x$

      $
        desugar(K) a b = dobeta((lambda x. lambda y. x) a) b step(beta)dobeta((lambda y. a) b) step(beta)a
      $
  ]

  #only(3)[
    #set enum(start: 3)
    + $omega$ 组合子：$omega eq.def lambda x. x x$

      $
        desugar(omega I) = dobeta((lambda x. x x) (lambda y. y)) step(beta)dobeta((lambda y. y) (lambda z.z)) step(beta)(lambda z. z)
      $

    + $Omega$ 组合子：$Omega eq.def omega omega$

      $
        desugar(Omega) = desugar(omega) omega = dobeta((lambda x. x x) omega) step(beta)omega omega = Omega
      $

    #note[
      注意到，虽然我们将 $I$ 定义为 $lambda x. x$，但将 $x$ 改名为 $y$ 所得到的 $lambda y.y$ 与 $lambda x. x$ 等价，这被称为 $alpha$-等价（$alpha$-equivalence），将在之后涉及。
    ]
  ]
]

#slide[
  == 用 #lc;编程


  只有函数和函数应用的程序设计语言，真的能写程序吗？

  能，而且它图灵完备。

  #grid(columns: 2, gutter: 3em, [
    - 布尔值
    - 自然数
    - 对（pair）
    - 列表
    - ...],[
    这些数据结构和它们的操作都可以用 $lambda$-项表示。

    我们将会介绍一种表示方式：
    #align(
      center,
    )[邱奇编码#footnote[https://en.wikipedia.org/wiki/Church_encoding]（Church encoding）]
  ])
]

#slide[
  == 用 #lc;编程 -- 邱奇编码 -- 布尔值

  $
                 T & = lambda x. lambda y. x \
                 F & = lambda x. lambda y. y \
    "if_then_else" & = lambda b. lambda t. lambda f. b t f
  $

  第一次见可能难以理解，让我们看看以下这两个 $lambda$-项等于什么。
  - $"if_then_else" T M N$
  - $"if_then_else" F M N$
]

#slide[
  == 用 #lc;编程 -- 邱奇编码 -- 布尔值 -- 验证

  #set text(size: 0.9em)

  $
    desugar("if_then_else" T) space M N=& dobeta((lambda b. lambda t. lambda f. b t f) (lambda x. lambda y. x)) M N \
    step(beta)& dobeta((lambda t. lambda f. (lambda x. lambda y. x) t f) M) N \
    step(beta)& dobeta((lambda f. (lambda x. lambda y. x) M f)) N \
    step(beta)& dobeta((lambda x. lambda y. x) M) N \
    step(beta)& dobeta((lambda y. M) N) \
    step(beta)& M \
    "if_then_else" F M N steps(beta)& N
  $
]

#slide[
  == 用 #lc;编程 -- 邱奇编码 -- 布尔值

  很自然的，我们可以定义 $"not" eq.def lambda b. "if_then_else" b F T$.

  $
    desugar("not") =&lambda b. desugar("if_then_else") space b F T \
    =& lambda b. dobeta((lambda b. lambda t. lambda f. b t f) b) F T \
    step(beta)& lambda b. dobeta((lambda t. lambda f. b t f) F) T \
    step(beta)& lambda b. dobeta((lambda f. b F f) T) \
    step(beta)& lambda b. b F T
  $

  #note[可以注意到，不同于上一页，我们在函数未被应用前就进行了“求值”。我们将在讲到求值顺序的时候讨论这件事情。]
]

#slide[
  == 用 #lc;编程 -- 邱奇编码 -- 布尔值 -- 构造与使用

  #set text(size: 0.9em)

  #columns(2)[
    一个数据结构有哪些要素？
    #later[
      - 如何构造 -- $T$ 和 $F$
      - 如何使用 -- $"if_then_else"$
    ]
    #colbreak()
    $
                   T & = lambda x. lambda y. x \
                   F & = lambda x. lambda y. y \
      "if_then_else" & = lambda b. lambda t. lambda f. b t f
    $
  ]

  #uncover("2-")[
    让我们再次仔细观察它们的定义。
  ]
  #uncover("3-")[

    - $T$ 接受两个参数，返回第一个；$F$ 也接受两个参数，返回第二个。
    - $"if_then_else"$ 实际上在效果上和恒等函数 $I$ 是类似的。

      #columns(2)[
        $lambda x. M x$ 可以被视作等价于 $M$。

        #note[这其实被称为 $eta$-等价，将在之后涉及。]
        #colbreak()
        $
          desugar("if_then_else") & step(eta) lambda b. lambda t. doeta(lambda f. b t f) \
                                  & step(eta) lambda b. doeta(lambda t. b t) \
                                  & step(eta) lambda b. b = I
        $
      ]
  ]
]

#slide[
  == 用 #lc;编程 -- 邱奇编码 -- 布尔值 -- 构造与使用

  #set text(size: 0.9em)

  邱奇编码的独特之处在于，构造出的数据结构用函数直接编码了“使用”。

  $
    "and" eq.def & lambda a. lambda b. a b F \
     "or" eq.def & lambda a. lambda b. a T b
  $

  因为 $a$ 本身就等价于 $I a$ 等价于 $"if_then_else" a$ 。不难验证：

  #columns(2)[
    $
      & "and" T T & steps(beta) & T \
      & "and" T F & steps(beta) & F \
      & "and" F T & steps(beta) & F \
      & "and" F F & steps(beta) & F
    $
    #colbreak()
    $
      & "or" T T & steps(beta) & T \
      & "or" T F & steps(beta) & T \
      & "or" F T & steps(beta) & T \
      & "or" F F & steps(beta) & F
    $
  ]
]

#slide[
  == 用 #lc;编程 -- 邱奇编码 -- 自然数

  #set text(size: 0.88em)

  一个非常重要的邱奇编码是自然数（包含零）的编码。

  用 $0, 1, 2, dots, n, dots$ 表示数学中的自然数。在数上加横线，用 $code(0), code(1), code(2), dots, code(n), dots$ 表示它在 #lc;中的编码。

  $
    code(0) eq.def & lambda f. lambda x. x \
    code(1) eq.def & lambda f. lambda x. f x \
    code(2) eq.def & lambda f. lambda x. f (f x) \
    & dots.c \
    #uncover("2-", $code(n) eq.def & lambda f. lambda x. f^n x$)
  $

  #uncover("2-")[
    #let underbrace-text = [n 个 $f$]
    #note[我们用 $f^n x$ 表示 $underbrace(f \(f \(dots.c \(f \(f, #underbrace-text) x))dots.c))$，
      也就是将 $f$ 应用 n 次。]
  ]
]

#slide[
  == 用 #lc;编程 -- 邱奇编码 -- 自然数 -- 构造

  自然数的编码也可以从构造和使用的角度来考虑。

  $
    code(0) eq.def & lambda f. lambda x. x \
          S eq.def & lambda n. lambda f. lambda x. f (n f x)
  $

  $code(0)$ 和后继函数 $S$ 能构造出所有自然数的编码。
  $ S^n code(0) steps(beta) code(n) $
]

#slide[
  == 用 #lc;编程 -- 邱奇编码 -- 自然数 -- 使用

  #warning[（可选）]怎么理解自然数的邱奇编码的“使用”呢？

  $code(n) = lambda f. lambda x. f^n x$ 传入 $f$ 和 $x$ 后，将自然数 $n$ “折叠”成一个值 $M$。
  + 如果 $n = 0$，$M = x$；
  + 如果 $n$ 是 $m$ 的后继#footnote[即 $n = m + 1$。]，且 $code(m) f x = N$，$M = f N$。

  #note[
    - 熟悉自然数的#link("https://en.wikipedia.org/wiki/Mathematical_induction")[数学归纳法]的同学会发现，这个跟它很像；并且还很熟悉 Rocq#footnote[Rocq 定理证明器，从前叫作 Coq。]的同学会发现，这个就是 `Nat` 的 #link("https://rocq-prover.org/doc/V9.2.0/refman/language/core/inductive.html#term-induction-principle")[induction principles]。
    - 熟悉 #link("https://ncatlab.org/nlab/show/recursion+scheme")[recursion scheme] 的同学会发现，这个就是 #link("https://ncatlab.org/nlab/show/catamorphism")[catamorphism]。
  ]
]

#slide[
  == 用 #lc;编程 -- 邱奇编码 -- 自然数 -- 运算

  #set text(size: 0.9em)

  如果能理解自然数邱奇编码的原理，不难定义自然数的运算。

  以下仅作简单展示，大家可自行思考（你可以给出其他定义吗？）。

  $
    "add" eq.def & lambda n. lambda m. underline(lambda f. lambda x. n f (m f x)) \
    "mult" eq.def & lambda n. lambda m. underline(lambda f. n (m f)) \
    "iszero" eq.def & lambda n. underline(n (K F) T) \
  $

  经典习题：定义 $"pred"$ 函数，使得 $"pred" code(n) = code(n minus.dot 1)$，其中 $minus.dot$ 运算符定义如下：
  $
    n minus.dot m := cases(0 "if" n - m <= 0, n - m "else",)
  $
]

#slide[
  == 用 #lc;编程

  邱奇编码的介绍就到这里。

  - 如果大家对更多数据结构的邱奇编码感兴趣，可以看看#link("https://en.wikipedia.org/wiki/Church_encoding")[维基百科 - Church encoding]。
  - 邱奇编码并不完美，也有其他编码方式。
    - Mogensen–Scott encoding
    - Parigot encoding
]

#slide[
  == 语法糖

  #set text(size: 0.9em)

  书写 lambda calculus 其实不太方便。
  - 函数总是只有一个参数；
  - 没法直接定义一个变量；
  - 参数即使没被使用，也必须是个变量；
  - 等等

  很多时候会用一些语法糖来简化书写，最典型的有以下几个：
  $
           (letin(x, M) N) eq.def & (lambda x. N) M \
    lambda x y dots.c z. M eq.def & lambda x. lambda y. dots.c lambda z. M \
              lambda \_. M eq.def & lambda x. M quad #[$x$ 不是 $M$ 中的自由变量]
  $
]

#slide[
  == #lc;的扩展

  #set text(size: 0.85em)

  我们不会想要用 #lc;编码所有数据类型，这在真实的硬件上非常低效。
  我们可以在内存中直接存储整数和布尔值，也可以用指针或者成块的内存表示对和列表。

  这些数据类型可以直接作为一种扩展加入语言中，例如可以直接加入布尔值和自然数。

  #align(center)[
    #bnf(
      Prod(
        $M, N$,
        {
          Or[$...$][]
          Or[$"true" | "false"$][_boolean_]
          Or[$"if" M "then" N_1 "else" N_2$][]
          Or[$n$][_natural number_]
          Or[$M "op" N$][_natural number operation_]
        },
      ),
    )
    其中 $"op" in { +, -, *, \/, =, !=, ... }$
  ]
]

#slide[
  == #lc;的扩展 -- 例子

  新增语法可以和 #lc;和谐共存。

  $
    "church_to_boolean" eq.def & lambda b. b "true" "false" \
    "boolean_to_church" eq.def & lambda b. "if" b "then" T "else" F \
        "church_to_nat" eq.def & lambda n. n (lambda m. m + 1) 0 \
           "square_nat" eq.def & lambda n. n * n \
  $

  经典练习：在整个分享结束后，编写一个 $"nat_to_church"$#footnote[现在你可能还没有完成这个练习的知识。]。
]

#slide[
  == #lc;的形式语义

  我们说 #lc;不仅是一个理想化的程序设计语言，还是一个“形式系统”。

  我将非常简单（但会保证精确）地过一遍 #lc;的形式语义。
]

#slide[
  == #lc;的形式语义 -- $alpha$-等价

  我们先从所谓的 $alpha$-等价开始，之前我们提到过：
  $ lambda x. x x = lambda y. y y $
  #later[
    这很显然，但考虑更加复杂一些的情形呢？
    $
      lambda x. lambda x. x != & lambda y. lambda x. y \
       lambda x. lambda x. x = & lambda x. lambda y. y
    $
  ]
]

#slide[
  == #lc;的形式语义 -- $alpha$-等价

  #columns(2)[
    #set align(center)
    #prooftree(rule(
      name: text(fill: purple)[$(alpha)$],
      $y in.not FV(M)$,
      $lambda x. M = lambda y. M[y slash x]$,
    ))
    #prooftree(rule(
      name: $(xi)$,
      $M = M'$,
      $lambda x. M = lambda x. M'$,
    ))
    #prooftree(rule(
      name: $("cong")$,
      $M = M'$,
      $N = N'$,
      $M N = M' N'$,
    ))
    #colbreak()
    #prooftree(rule(
      name: $("refl")$,
      $M = M$,
    ))
    #prooftree(rule(
      name: $("sym")$,
      $N = M$,
      $M = N$,
    ))
    #prooftree(rule(
      name: $("trans")$,
      $M_1 = M_2$,
      $M_2 = M_3$,
      $M_1 = M_3$,
    ))
  ]

  #note[
    最核心的规则就是 $(alpha)$，它表示将 $lambda x. M$ 中的 $x$ 替换为 $y$ 之后获得的 $lambda$-项和原来的项等价。但是替换如何定义很重要，我们会在后面简单讨论替换的精确定义。
  ]
]

#slide[
  == #lc;的形式语义 -- 操作语义

  #set text(size: 0.9em)

  #lc;的形式语义有很多种，但现在通常我们会定义小步操作语义（small-step operational semantics），因为它展现了 #lc;的计算过程。

  #columns(2)[
    #set align(center)
    #prooftree(rule(
      name: text(fill: purple)[$(beta)$],
      $(lambda x. M) N step(beta) M[N slash x]$,
    ))
    #prooftree(rule(
      name: $(xi)$,
      $M step(beta) M'$,
      $lambda x. M step(beta) lambda x. M'$,
    ))
    #colbreak()
    #prooftree(rule(
      name: $("cong1")$,
      $M step(beta) M'$,
      $M N step(beta) M' N$,
    ))
    #prooftree(rule(
      name: $("cong2")$,
      $N step(beta) N'$,
      $M N step(beta) M N'$,
    ))
  ]

  - 应用 $(beta)$ 规则又被称为做 $beta$-规约（reduction），$(lambda x. M) N$ 又被称为 $beta$-redex。不存在 redex 的表达式被称为规范形式（normal form）。
  - （Church-Rosser 定理）如果 $M steps(beta) M_1$ 和 $M steps(beta) M_2$，那么存在项 $N$，有 $M_1 steps(beta) N$ 和 $M_2 steps(beta) N$。
]

#slide[
  == #lc;的形式语义 -- 替换

  简单看一下如何定义 $M[N slash x]$。

  $
    x[N slash x] &eq.def N \
    y[N slash x] &eq.def y quad "if" x != y \
    (M_1 M_2)[N slash x] &eq.def (M_1[N slash x]) (M_2[N slash x]) \
    (lambda x. M')[N slash x] &eq.def mathimportant(lambda x. M') \
    (lambda y. M')[N slash x] &eq.def lambda y. M'[N slash x] quad "if" x != y, mathimportant(y in.not FV(N)) \
    (lambda y. M')[N slash x] &eq.def mathimportant(lambda y'. M'[y'slash y])[N slash x] quad "if" x != y\, mathimportant(y in FV(N))\, mathimportant(y' "fresh")
  $
]


#slide[
  == #lc;的形式语义 -- 替换

  最后一条规则
  $
    (lambda y. M')[N slash x] &eq.def mathimportant(lambda y'. M'[y'slash y])[N slash x] quad "if" x != y\, mathimportant(y in FV(N))\, mathimportant(y' "fresh")
  $
  可以处理以下情形。
  $
    dobeta((lambda x. lambda y. x) y) step(beta) (lambda y. x)[y slash x] = & lambda y'. y \
                                                               != & lambda y.y
  $
]

#slide[
  == #lc;的形式语义 -- 自由变量

  最后，自由变量的定义比较简单。

  $
    FV(x) = {x} \
    FV(lambda x. M) = FV(M) without { x } \
    FV(M N) = FV(M) union FV(N)
  $
]

#slide[
  == #lc;的求值策略

  你可能经常会听到以下词汇：
  - 某个语言的求值是#important[“eager”]或#important[“lazy”]的
  - 某个语言是#important[“strict”]/#important[“non-strict”]的
  这些词都跟求值策略有关。
]

#slide[
  == #lc;的求值策略 -- Call-by-Value

  Call-by-value（eager 求值），函数调用必须传入一个“值”。

  - 我们首先定义什么叫“值”，在 #lc;中，值就是函数。
    #align(center, bnf(
      Prod(
        $v$,
        {
          Or[$lambda x. M$][]
        },
      ),
    ))
  - 然后限定求值顺序。
    #columns(2)[
      #set align(center)
      #prooftree(rule(
        name: $("cong1")$,
        $M step(beta) M'$,
        $M N step(beta) M' N$,
      ))
      #prooftree(rule(
        name: text(fill: purple)[$(beta)$],
        $(lambda x. M) mathimportant(v) step(beta) M[mathimportant(v) slash x]$,
      ))
      #colbreak()
      #prooftree(rule(
        name: $("cong2")$,
        $N step(beta) N'$,
        $mathimportant(v) N step(beta) mathimportant(v) N'$,
      ))
    ]
]

#slide[
  == #lc;的求值策略 -- Call-by-Name

  Call-by-name，函数参数总是原样传入函数，直到真正被用到时才求值。

  #columns(2)[
    #set align(center)
    #prooftree(rule(
      name: $("cong1")$,
      $M step(beta) M'$,
      $M N step(beta) M' N$,
    ))
    #colbreak()
    #prooftree(rule(
      name: text(fill: purple)[$(beta)$],
      $(lambda x. M) N step(beta) M[N slash x]$,
    ))
  ]

  #note[没有 $("cong2")$ 和 $(xi)$ 规则。]

  在这种求值顺序下，函数的参数只有真正被使用的时候才会被求值。
]

#slide[
  == #lc;的求值策略 -- Call-by-Name

  实际上，没有什么现代语言在使用 Call-by-name，因为如果我们多次使用同一个函数参数，那么这个参数会被求值多次。

  #columns(2)[
    - Call-by-name 下，以下 $lambda$-项需要四步求值。
      $
        dobeta((lambda x. x x) (I I)) step(beta) & dobeta((I I)) (I I) \
                                      step(beta) & dobeta(I (I I)) \
                                      step(beta) & dobeta((I I)) \
                                               = & I \
      $

    - 而在 Call-by-value 下，同样的项只需三步求值。
      $
        (lambda x. x x) dobeta((I I)) step(beta) & dobeta((lambda x. x x) I) \
                                      step(beta) & dobeta(I I) \
                                               = & I \
      $
  ]
]

#slide[
  == #lc;的求值策略 - Call-by-Need

  如果我们对 Call-by-name 做一个优化，让同一个参数的多次使用的求值可以共享，就变成了 Call-by-need。

  可以用“图规约”来理解 call-by-need，还是以 $(lambda x. x x) (I I)$ 为例子。
  #columns(4)[
    #set align(center)
    #diagram(cell-size: 10mm, spacing: 1.5em, {
      let (app1, omega, app2, i1, i2) = (
        (0, 0),
        (-0.5, 1),
        (0.5, 1),
        (0, 2),
        (1, 2),
      )
      node(app1, $@$)
      node(omega, $lambda x. x x$)
      node(app2, $@$)
      node(i1, $I$)
      node(i2, $I$)
      edge(app1, omega, "->")
      edge(app1, app2, "->")
      edge(app2, i1, "->")
      edge(app2, i2, "->")
    })
    #colbreak()
    #diagram(cell-size: 10mm, spacing: 1.5em, {
      let (app1, app2, i1, i2) = ((0, 0), (0, 1), (-0.5, 2), (0.5, 2))
      node(app1, $@$)
      node(app2, $@$)
      node(i1, $I$)
      node(i2, $I$)
      edge(app1, app2, "->", bend: 20deg)
      edge(app1, app2, "->", bend: -20deg)
      edge(app2, i1, "->")
      edge(app2, i2, "->")
    })
    #colbreak()
    #diagram(cell-size: 10mm, spacing: 1.5em, {
      let (app1, i) = ((0, 0), (0, 1))
      node(app1, $@$)
      node(i, $I$)
      edge(app1, i, "->", bend: 20deg)
      edge(app1, i, "->", bend: -20deg)
    })
    #colbreak()
    #diagram(cell-size: 10mm, spacing: 1.5em, {
      let (i) = (0, 0)
      node(i, $I$)
    })
  ]
]

#slide[
  == #lc;的求值策略

  我们介绍了常见的三种求值策略：
  - Call-by-value
  - Call-by-name
  - Call-by-need

  那么一些常见程序设计语言中的说法对应这里的哪种求值策略呢？

  #columns(2)[
    #set align(center)
    #table(
      columns: 2,
      inset: 0.5em,
      [Eager], [Call-by-value],
      [Lazy], [Call-by-name/need],
    )
    #table(
      columns: 2,
      inset: 0.5em,
      [Strict], [Call-by-value],
      [Non-strict], [Call-by-name/need],
    )
  ]
]

#slide[
  == #lc;的求值策略 -- Strict vs. Non-strict

  Lazy 和 eager 比较好理解：
  - Lazy 的求值策略，项只有在真正被用到的时候才被求值；
  - Eager 的求值策略，总是先将参数求值完毕再传入。

  可什么是 strict 和 non-strict 呢？
  - 在 strict 的语言中，一定有 $f bot = bot$；
  - 在 non-strict 的语言中，可以存在函数 $f$，使得 $f bot != bot$，比如 $f = K I$。

  这里的 $bot$ 就是不停机或者出错的意思。
]

#slide[
  == #lc;的求值策略 -- 在 Nix 里试试

  Nix 是 call-by-need，lazy，和 non-strict 的语言。

  - Call-by-need
    ```nix
    (x: x x) (builtins.trace "once" (x: x))
    ```
  - Lazy
    ```nix
    (x: "value1") (builtins.trace "not evaluated" "value2")
    ```
  - Non-strict：
    ```nix
    (x: "ok") (throw "error")
    ```
]



#slide[
  == 不动点 -- 引入

  现在我们来介绍一个经典且极其重要的 #lc;构造，不动点。

  为了方便理解，我用前述的#important[扩展了布尔值和自然数]的 #lc;来做引入。

  让我们在扩展的 #lc;上尝试定义一个阶乘函数：
  $
    wrong("factorial") wrong(eq.def) lambda n. "if" n = 0 "then" 1 "else" wrong("factorial") (n - 1) * n
  $
  你看出什么问题了吗？

  #later[
    #important[循环定义！]
  ]
]

#slide[
  == 不动点 -- 引入

  $
    wrong("factorial") wrong(eq.def) & lambda n. "if" n = 0 "then" 1 "else" wrong("factorial") (n - 1) * n
  $
  让我们把刚才的错误定义拆解改写一下：
  $
    wrong("factorial") wrong(eq.def) & "factorial_gen" wrong("factorial") \
    "factorial_gen" eq.def & lambda f. lambda n. "if" n = 0 "then" 1 "else" f (n - 1) * n
  $

  #later[
    要定义 $"factorial"$，我们就要找到某个函数 $f$，使得 $f$ 的语义和 $"factorial_gen" f$ 的语义相同，然后将 $f$ 作为 $"factorial"$ 的定义。
  ]

  #later[
    我们要找的 $f$ 叫作 $"factorial_gen"$ 的不动点（fixed-point）。
  ]
]

#slide[
  == 不动点

  数学上，函数 $f : A -> B$ 的不动点指的是某个 $c in A inter B$，满足：$ f(c) = c $

  同样也可以对 #lc;中的函数定义不动点，对于 $lambda$-项 $f$，它的不动点也是一个项 $c$ 满足：$f(c)$ 和 $c$ 的语义相同，还是写作 $f(c) = c$。

  #later[
    但是，什么是 $lambda$-项之间的等价关系（$=$）？我们希望这个等价关系刻画了 $lambda$-项的#important[语义等价]。
  ]
]

#slide[
  == 不动点 -- $lambda$-项的等价关系

  #set text(size: 0.85em)

  （简单看一眼吧）

  #columns(2)[
    #set align(center)
    #prooftree(rule(
      name: text(fill: purple)[$(alpha)$],
      $y in.not FV(M)$,
      $lambda x. M = lambda y. M[y slash x]$,
    ))
    #prooftree(rule(
      name: text(fill: purple)[$(beta)$],
      $(lambda x. M) N = M[N slash x]$,
    ))
    #prooftree(rule(
      name: text(fill: purple)[$(eta)$],
      $x in.not FV(M)$,
      $lambda x. M x = M$,
    ))
    #prooftree(rule(
      name: $(xi)$,
      $M = M'$,
      $lambda x. M = lambda x. M'$,
    ))
    #colbreak()
    #prooftree(rule(
      name: $("cong")$,
      $M = M'$,
      $N = N'$,
      $M N = M' N'$,
    ))
    #prooftree(rule(
      name: $("refl")$,
      $M = M$,
    ))
    #prooftree(rule(
      name: $("sym")$,
      $N = M$,
      $M = N$,
    ))
    #prooftree(rule(
      name: $("trans")$,
      $M_1 = M_2$,
      $M_2 = M_3$,
      $M_1 = M_3$,
    ))
  ]

  #note[
    $(eta)$ 规则的存在使该等价关系有函数外延性（extensionality），即 $(forall N. M_1 N = M_2 N)$ 蕴含 $M_1 = M_2$。
  ]
]

#slide[
  == 不动点 -- $lambda$-项的等价关系

  #set text(size: 0.9em)

  换一种方式解释，这个等价关系描述了，只要两个 $lambda$-项，能求值成同一个项（包含 $alpha$-等价和外延性），那么它们就等价。因此这种等价是语义上的。

  对外延性，组合 $(xi)$，$("cong1")$，$("cong2")$ 和下面的 $(eta)$ 规则，定义 $step(eta)$：
  #align(center, prooftree(rule(
    name: text(fill: purple)[$(eta)$],
    $x in.not FV(M)$,
    $lambda x. M x step(eta) M$,
  )))
  组合 $(xi)$，$("cong1")$，$("cong2")$，$(beta)$，$(eta)$ 定义 $step(beta eta)$。
  然后我们就可以说，
  #align(
    center,
  )[$M_1 = M_2$ 当且仅当存在 $N$，$M_1 steps(beta eta) N$ 和 $M_2 steps(beta eta) N$。]

  #note[
    我们定义的 $=$ 是包含 $(beta)$ 和 $(eta)$ 的 $equal(beta eta)$，还可以定义仅包含 $(beta)$ 的 $equal(beta)$ 和仅包含 $(eta)$ 的 $equal(eta)$。
  ]
]

#slide[
  == 不动点 -- 不动点组合子

  #set text(size: 0.9em)

  如何获得 $"factorial_gen"$ 的不动点？

  #later[
    如何获得任意函数 $f$ 的不动点？
  ]
]

#slide[
  == 不动点 -- 不动点组合子

  在 #lc;中，存在不动点组合子 $Y$，使得对于任意函数 $f$，都有：
  $
    f (Y f) = Y f
  $

  #later[
    从计算/操作语义的角度来看：
    $
      Y f step(beta) & f (Y f) \
          step(beta) & f (f (Y f)) \
         steps(beta) & f (dots.c (f (Y f)) dots.c)
    $

    #note[
      还有其他不动点组合子，比如 $Z$，用在 strict 的语言中。
    ]
  ]
]

#slide[
  == 不动点 -- 不动点组合子

  #set text(size: 0.9em)

  $
    Y f steps(beta) & f (Y f)
  $

  现在我们可以先假定这个魔法般的组合子存在，但是它为什么不会无限递归？

  #align(center)[
    #wrong[error:] infinite recursion encountered
  ]

  #later[
    答案是 #important[call-by-need]，在 lazy 的语言中 $Y f$ #important[可以不]无限递归！

    在 call-by-need 的求值策略下，只要我们不在 $f$ 中总是使用 $Y f$，而是有递归终止条件，就不会无限递归。
  ]
]

#slide[
  == 不动点 -- 例子

  #set text(size: 0.95em)

  $
    "factorial" eq.def & Y "factorial_gen" \
    "factorial_gen" eq.def & lambda f. lambda n. "if" n = 0 "then" 1 "else" f (n - 1) * n
  $

  $
    desugar("factorial") = & dobeta(Y "factorial_gen") \
    steps(beta) & "factorial_gen" desugar((Y "factorial_gen")) \
    = & desugar("factorial_gen") "factorial" \
    = & dobeta((lambda f. lambda n. "if" n = 0 "then" 1 "else" f (n - 1) * n) "factorial") \
    steps(beta) & lambda n. "if" n = 0 "then" 1 "else" "factorial" (n - 1) * n \
    "factorial" = & lambda n. "if" n = 0 "then" 1 "else" "factorial" (n - 1) * n
  $
]

#slide[
  == 理解 Nix 语法和库

  理解不动点和 #important[call-by-name] 的概念有助于我们理解一些 Nix 语法和库，因为它们大量使用不动点。

  - `lib.fix` 函数
  - Nix `let` 语法
  - Nix `rec` 语法
  - Nixpkgs overlays 机制
  - NixOS module

  #note[
    Call-by-name 在这些机制的理解中相当重要。
  ]
]

#slide[
  == 理解 Nix 语法和库 -- `lib.fix`

  #set text(size: 0.9em)

  Nix 的 ```nix lib.fix``` 就是一个不动点组合子，和 $Y$ 等价。

  ```nix
  let
    factorial_gen = f: n: if n == 0 then 1 else f (n - 1) * n;
    factorial = lib.fix factorial_gen;
  in
    factorial 5 # 120
  ```

  因为 Nix 的 `let` 直接支持递归，`lib.fix` 的定义如下。

  ```nix
  fix = f: let x = f x; in x
  ```
]

#slide[
  == 理解 Nix 语法和库 -- `let`

  #set text(size: 0.9em)

  ```nix
  let factorial = n: if n == 0 then 1 else factorial (n - 1) * n;
  in factorial 5 # 120
  ```

  #align(center)[可以理解为：]

  ```nix
  let factorial = lib.fix (f: n: if n == 0 then 1 else f (n - 1) * n);
  in factorial 5 # 120
  ```
]

#slide[
  == 理解 Nix 语法和库 -- `let`

  #set text(size: 0.9em)

  Nix 的 `let` 还支持互递归（mutual recursion）：

  ```nix
  let odd  = n: if n == 0 then false else even (n - 1);
      even = n: if n == 0 then true  else odd  (n - 1);
  in odd 100
  ```

  #align(center)[可以理解为：]

  ```nix
  let fs = { odd  = n: if n == 0 then false else fs.even (n - 1);
             even = n: if n == 0 then true  else fs.odd  (n - 1); };
  in fs.odd 100
  ```
]

#slide[
  == 理解 Nix 语法和库 -- `rec`

  ```nix
  rec { a = 1; b = a + 1; } # { a = 1; b = 2; }
  ```

  #align(center)[可以理解为：]

  ```nix
  lib.fix (self: { a = 1; b = self.a + 1; })
  ```
]

#slide[
  == 理解 Nix 语法和库 -- Nixpkgs overlays 机制

  #set text(size: 0.8em)

  ```nix
  final: prev: { ... }
  ```
  整个 nixpkgs 其实就是由一堆 overlays 生成的#footnote[#link("https://github.com/NixOS/nixpkgs/blob/efde0aa842acd479121e85c3c86f58d6119d5bd3/pkgs/top-level/stage.nix#L312-L336")[nixos/nixpkgs - pkgs/top-level/stage.nix -- L312-L336]]。以下是经过修改便于理解的代码。
  ```nix
  let extends = f: overlay:
        final: let prev = f final; in prev // overlay final prev;
      toFix = lib.foldl' extends (self: { }) allOverlays;
  in lib.fix toFix
  ```

  `final` 是最终的 nixpkgs，而 `prev` 是上一个 overlay 生成的 nixpkgs，overlay 被传入这两个参数后与 `prev` 组合。最终 `final` 是通过 `fix` 被传入的。
]

#slide[
  == 理解 Nix 语法和库 -- NixOS module - `config`

  NixOS module 中也有一些特别的和不动点有关的机制，需要特别关注它们的用法，这里做一个简介。
]

#slide[
  == 理解 Nix 语法和库 -- NixOS module

  #set text(size: 0.9em)

  Module 的参数中有 `config`，表示 `evalModules` 将所有 module 合并后获得的结果。所以这个结果是一个不动点。

  ```nix
  (lib.evalModules { modules = [
    ({ config, ... }: {
      options = rec { a = lib.mkOption { type = lib.types.int; }; b = a; };
      a = 1; b = config.a; })
    ({ ... }: { a = lib.mkForce 2; })
  ]; }).config # { a = 2; b = 2; }
  ```
]

#slide[
  == 理解 Nix 语法和库 -- NixOS module - `_module.args`

  Module 中可以包含 `_module.args`，而 `_module.args` 又会变成所有 module 的参数。
  ```nix
  { pkgs, ... }: { _module.args.pkgs = ...; }
  ```
  在这个 module 中 `pkgs` 既是它的输入又是它的输出，同样是一个不动点。
]

#slide[
  == 理解 Nix 语法和库 -- NixOS module - `imports`

  #set text(size: 0.80em)

  Module 可以 import 其他 module：
  ```nix
  { ... }: { imports = [ ./path/to/other/modules.nix ]; }
  ```

  如果 `imports` 路径包含 `evalModules` 的结果，就会 infinite recursion。

  ```nix
  { config, ... }:
  { imports = [ config.module.defined.in.options ]; } # bad
  ```


  ```nix
  { pkgs, ... }:
  { imports = [ "${pkgs}/nixos/modules/path/to/module.nix" ]; } # bad
  ```

  如果要向 modules 中传入路径以在 `imports` 中使用，需要 `specialArgs` 而不是 `_module.args`。
]


#slide[
  == 扩展知识 - 不动点组合子

  首次接触 #lc;的同学可能很疑惑，我们前面一直假设不动点组合子 $Y$ 存在，但 Nix 是用内置的 `let` 语法实现 `lib.fix` 的，$Y$ 真的存在吗？

  $ Y f steps(beta) f (Y f) $

  #later[
    答案当然是存在，让我们一步步重新发现 $Y$。
  ]
]

#slide[
  == 扩展知识 - 不动点组合子

  $ Y f steps(beta) f (Y f) $

  为了定义 $Y f$，我们需要将 $Y f$ 自身传入 $f$。在 #lc;中，我们没有递归，如何获得函数本身？

  思考：有没有一种办法在一个函数中获得函数自身？

  #later[
    当然有！
    $ (lambda x. x x)(lambda s. M) $


    在 $(lambda s. M)$ 这个函数中，$s$ 就是 $(lambda s. M)$ 自身。
  ]
]

#slide[
  == 扩展知识 - 不动点组合子

  $ Y f steps(beta) f (Y f) $

  $s$ 就是 $(lambda s. M)$ 自身，这样的话，在 $M$ 中，我们就有 $s s = M$。
  $ (lambda x. x x)(lambda s. M) = M $

  看出来了吗？

  #later[
    令 $M = f (s s)$，就有 $M = f (s s) = f M$：
    $ M= (lambda x. x x)(lambda s. f (s s)) $
    $M$ 就是 $f$ 的不动点。
  ]
]


#slide[
  == 扩展知识 - 不动点组合子

  将 $f$ #important[抽象]出来，我们就得到了 $Y$。

  $
         M = & (lambda x. x x)(lambda s. f (s s)) \
    Y eq.def & lambda f. (lambda x. x x)(lambda s. f (s s)) \
      eq.def & lambda f. (lambda x. f (x x)) (lambda x. f (x x))
  $

  第二种写法是更常见的。

  非常容易验证：
  $ Y f steps(beta) f (Y f) $
]

#slide[
  == 希尔伯特可判定性问题与邱奇-图灵论题

  #grid(
    columns: 2,
    gutter: 1em,
    [
      #align(figure(caption: "大卫·希尔伯特")[
        #block(clip: true, radius: 10pt, image(
          "images/david-hilbert.jpg",
          height: 70%,
        ))
      ])
    ],
    [
      #set text(size: 0.9em)
      1928年，数学家大卫·希尔伯特（David Hilbert）提出了“希尔伯特计划”，试图构建一套公理集，为全部的数学提供一个安全的理论基础。

      这个基础应该能够实现：
      - 所有数学的形式化；
      - 完备性：所有真命题都能被证明；
      - 一致性：不可能导出矛盾；
      - 可判定性：能用#important[算法]判定命题是真命题还是假命题。
    ],
  )
]

#slide[
  == 希尔伯特可判定性问题与邱奇-图灵论题

  #grid(columns: 2, gutter: 1em, [
    #align(figure(caption: "库尔特·哥德尔")[
      #block(clip: true, radius: 10pt, image(
        "images/kurt-godel.jpg",
        height: 70%,
      ))
    ])], [
    但希尔伯特的宏伟设想被证明是无法实现的。

    1931 年，库尔特·哥德尔（Kurt Gödel）提出哥德尔不完备定理。证明了计划中的完备性是不可能做到的。
  ])
]

#slide[
  == 希尔伯特可判定性问题与邱奇-图灵论题

  #grid(columns: 2, gutter: 1em, [
    #align(figure(caption: "斯蒂芬·克莱尼")[
      #block(clip: true, radius: 10pt, image(
        "images/stephen-kleene.jpg",
        height: 70%,
      ))
    ])],[
    哥德尔为了证明不完备定理，定义了原始递归函数类（Primitive Recursive Functions），他的学生斯蒂芬·克莱尼（Stephen Kleene）等人将其扩充，提出了一般递归函数类（General Recursive Functions）。

    如今，一般递归函数又被称为#important[直觉可计算]函数。
  ])
]

#slide[
  == 希尔伯特可判定性问题与邱奇-图灵论题

  #grid(columns: 2, gutter: 1em, [
    #align(figure(caption: "艾伦·图灵")[
      #block(clip: true, radius: 10pt, image(
        "images/alan-turing.jpg",
        height: 70%,
      ))
    ])], [
    随后，有两个重要的工作独立地提出了#important[计算]的模型，证明了“可判定性”也是不可能做到的，顺便奠定了#important[计算机]的基础。

    - 艾伦·图灵（Alan Turing）提出了图灵机否定了“可判定性”。
    - 阿隆佐·邱奇用 #lc;作为计算模型否定了“可判定性”。
  ])
]

#slide[
  == 希尔伯特可判定性问题与邱奇-图灵论题

  #set text(size: 0.9em)

  20 世纪 30 年代，人们从算术、函数抽象和机械计算三个完全不同的角度提出了三种计算模型：

  #align(center)[
    #columns(3)[
      #important[一般递归函数]
      #colbreak()
      #important[#lc]
      #colbreak()
      #important[图灵机]
    ]
  ]

  并证明它们刻画了同一类函数，它们具有同等的计算能力。

  这种惊人的一致性促成了邱奇–图灵论题：
  #align(center)[
    #important[“可计算”]这一非形式化概念可以由这些等价的形式模型准确刻画。
  ]
]

#slide[
  == #lc;的实现

  #set text(size: 0.9em)

  或者说，如何在硬件上运行 #lc;？

  - 在操作语义中，#lc;的操作语义是用“替换”来实现的，但替换是纯语法的。

  - 另一种方式是使用类似 Python 或者 Scheme 的基于环境的语义#footnote[可见 #link("https://standards.scheme.org/corrected-r7rs/r7rs-Z-H-8.html#TAG:__tex2page_sec_6.12")[R7RS specification]。]。

    #align(center)[
      $"Closure" = "Code" + "Environment"$

      $"Environment"："Variables" -> "Values"$
    ]

    #note[
      如果你学习过 #lc;的指称语义（denotational semantics），其实基于环境的语义就是 #lc;指称语义的一种实现。
    ]
]

#slide[
  == #lc;的实现 - 闭包

  #set text(size: 0.9em)

  #align(center)[
      $"Closure" = "Code" + "Environment"$

      $"Environment"："Variables" -> "Values"$
  ]

  等等？什么是#important[闭包（closure）]？为什么我们讲完了 #lc;却不需要讲闭包？

  #later[
    闭包其实就是词法作用域（lexical scope）的一种实现方式。
  ]

  #later[
    等等？什么是#important[词法作用域]？为什么我们讲完了 #lc;却不需要讲作用域？
  ]

  #later[
    因为词法作用域已经体现在替换中。

    #align(center)[
      #prooftree(rule(
        name: $(beta)$,
        $(lambda x. M) N step(beta) M[N slash x]$,
      ))
    ]
  ]
]

#slide[
  == #lc;的实现 - Call-by-Need

  #set text(size: 0.85em)

  Nix 是 call-by-need 的语言，如何实现 call-by-need 呢？

  - 一种方式是继续使用基于环境的语义，但我们向值中加入所谓的“thunk” -- 延迟计算。
    $ (lambda x. M) N $
    $N$ 被打包成一个 thunk $t$，对 $M$ 求值时，环境为 ${ x mapsto t }$，当 $t$ 被使用时才求值 $N$。

  - 另一种方式是图规约，编译到 G-machine#footnote[感兴趣的同学可以学习 Simon Peyton Jones 的《Implementing functional languages: a tutorial》]及其衍生技术。

    #note[Haskell 使用的就是 STG machine（Spineless Tagless G-machine）。]
]

#slide[
  #set align(center + horizon)

  == 谢谢！

  #columns(2)[
    #image("images/this-slides.png", width: 7cm)

    获取本幻灯片

    #colbreak()

    #image("images/lambdacalc-dev.png", width: 7cm)

    在线#lc;解释器

    #link("https://lambdacalc.dev")[lambdacalc.dev]
  ]
]
