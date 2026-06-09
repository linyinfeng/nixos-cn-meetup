#import "@preview/polylux:0.4.0": *
#import "@preview/simplebnf:0.2.0": *
#import "@preview/pinit:0.2.2": *
#import "@preview/tdtr:0.5.5": *
#import "@preview/ctheorems:1.1.3": *

#set page(paper: "presentation-16-9")
#show heading: set block(below: 1em)
#show figure.where(kind: image): set figure(supplement: "图")

// font and styles

#set text(size: 23pt, font: ("Source Sans 3", "Source Han Sans SC"))
#show raw: set text(size: 1.1em, font: "Sarasa Mono Slab SC")
#show link: set text(fill: blue.darken(25%))
#show: thmrules

// codly

#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.10": *
#show: codly-init.with()
#let setup-codly() = {
  codly-reset()
  codly(languages: codly-languages)
  codly(zebra-fill: luma(250))
}

// other

#let date = datetime(
  year: 2026,
  month: 6,
  day: 13,
)

// helper

#let def(name, ..args) = {
  let body = args.pos().first()
  block(inset: 6pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
    *#name：*#body
  ]
}

#let note(body) = {
  text(size: 0.85em, fill: gray.darken(40%))[
    _#body _
  ]
}

#let point-explain(fill: blue.darken(40%), ..args, body) = {
  pinit-point-from(
    fill: fill,
    ..args,
    rect(fill: fill, radius: 0.25em, text(fill: white, body)),
  )
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
#let app-node = [app]
#let important(..args) = text(fill: blue, weight: 600, ..args)
#let warning(..args) = text(fill: red, weight: 600, ..args)
#let doalpha(body, ..args) = text(fill: green, ..args, math.underline(body))
#let dobeta(body, ..args) = text(fill: blue, ..args, math.underline(body))
#let doeta(body, ..args) = text(fill: orange, ..args, math.underline(body))
#let desugar(body, ..args) = text(fill: purple, ..args, math.underline(body))
#let code(body, ..args) = math.overline(body, ..args)
#let letin(x, item) = $"let" x = item "in"$
#let rule(name, body) = align(center)[
  *规则#name*:
  #body
]
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
  #set align(horizon)

  #grid(columns: 2, gutter: 0.5cm)[
    // #image("images/blog-link-qrcode.svg", width: 7cm)
  ][
    #text(size: 1.2em)[= 给 Nix 用户的 #lc;基础]
    #v(-0.5em)
    #text(size: 1.0em)[= $lambda$-Calculus Basics for Nix Users]

    #v(0.5em)

    #text(size: 1.1em)[Yinfeng]
    #v(-0.5em)
    #date.display()
  ]
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
    #show link: set text(weight: "bold")
    也算是个研究程序设计语言的。
  ]
]

#slide[
  == #lc;？


  先做一个小调查：
  #align(center)[
    在座的各位有多少曾经学习过"#lc"？
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
    + 理解 Nix 库
      - `let` & `rec` & `lib.fix`
      - Overlay & NixOS modules
    + 扩展知识
      + 不动点组合子
      + 希尔伯特判定性问题与\ 邱奇-图灵论题
      + #lc;的实现
  ]
]

#slide[
  == #lc;简介

  #columns(2)[
    #align(figure(caption: "阿隆佐·邱奇")[
      #block(clip: true, radius: 10pt, image(
        "images/alonzo-church.jpg",
        height: 70%,
      ))
    ])
    #colbreak()
    - Lambda calculus
      - 一种理想化的编程语言
      - 一个形式系统
      - 一种计算模型
    - 阿隆佐·邱奇（Alonzo Church，1903--1995）在1930 年代提出
  ]
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
          Or[$lambda x. M$][_abstraction_#pin("abstraction")]
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
    #point-explain(
      "abstraction",
      offset-dx: 20pt,
      offset-dy: 38pt,
      body-dx: -270pt,
    )[在这里就是函数的另一种说法]
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
    #rule(1)[函数应用（applications）是左结合的]

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
    #rule(
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
      [Kotlin], ```kotlin fun(x) = M```,
      [Swift], ```swift  { x in M }```,
    )
  ]))
]

#slide[
  == #lc;简介 -- 例子

  通过几个例子，我们可以在不形式化的情况下简单理解 #lc;的语义。

  #only(1)[
    + 恒等函数 $I$（identity）：$I eq.def lambda x. x$

      $ desugar(I) y &= dobeta((lambda x. x)) y step(beta)y \
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
        desugar(omega I) = dobeta((lambda x. x x) (lambda y. y)) step(beta)dobeta((lambda y. y) (lambda y.y)) step(beta)(lambda y. y)
      $

    + $Omega$ 组合子：$Omega eq.def omega omega$

      $
        desugar(Omega) = desugar(omega) omega = dobeta((lambda x. x x) omega) step(beta)omega omega = Omega
      $

    #note[
      注意到，虽然我们将 $omega$ 定义为 $lambda x. x x$，但将 $x$ 改名为 $y$ 所得到的 $lambda y.y y$ 与 $lambda x. x x$ 等价，这被称为 $alpha$-等价（$alpha$-equivalence）。
    ]
  ]
]

#slide[
  == 用 #lc;编程


  只有函数和函数应用的程序设计语言，真的能写程序吗？

  能，而且它图灵完备。

  #columns(2)[
    - 布尔值
    - 自然数
    - 对（pair）
    - 列表
    - ...
    #colbreak()
    这些数据结构和它们的操作都可以用 $lambda$-项表示。

    我们将会介绍一种表示方式：
    #align(
      center,
    )[邱奇编码#footnote[https://en.wikipedia.org/wiki/Church_encoding]（Church encoding）]
  ]
]

#slide[
  == 用 #lc;编程 -- 邱奇编码 -- 布尔值

  $
            "true" & = lambda x. lambda y. x \
           "false" & = lambda x. lambda y. y \
    "if_then_else" & = lambda b. lambda t. lambda f. b t f
  $

  第一次见可能难以理解，让我们看看以下这两个 $lambda$-项等于什么。
  - $"if_then_else" "true" M N$
  - $"if_then_else" "false" M N$
]

#slide[
  == 用 #lc;编程 -- 邱奇编码 -- 布尔值 -- 验证

  #set text(size: 0.9em)

  $
    desugar("if_then_else" "true") space M N=& dobeta((lambda b. lambda t. lambda f. b t f) (lambda x. lambda y. x)) M N \
    step(beta)& dobeta((lambda t. lambda f. (lambda x. lambda y. x) t f) M) N \
    step(beta)& dobeta((lambda f. (lambda x. lambda y. x) M f)) N \
    step(beta)& dobeta((lambda x. lambda y. x) M) N \
    step(beta)& dobeta((lambda y. M) N) \
    step(beta)& M \

    "if_then_else" "false" M N steps(beta)& N
  $
]

#slide[
  == 用 #lc;编程 -- 邱奇编码 -- 布尔值

  很自然的，我们可以定义 $"not" eq.def lambda b. "if_then_else" b "false" "true"$.

  $
    desugar("not") =&lambda b. desugar("if_then_else") space b "false" "true" \
    =& lambda b. dobeta((lambda b. lambda t. lambda f. b t f) b) "false" "true" \
    step(beta)& lambda b. dobeta((lambda t. lambda f. b t f) "false") "true" \
    step(beta)& lambda b. dobeta((lambda f. b "false" f) "true") \
    step(beta)& lambda b. b "false" "true"
  $

  #note[可以注意到，不同于上一页，我们在函数未被应用前就进行了“求值”。我们将在讲到求值顺序的时候讨论这件事情。]
]

#slide[
  == 用 #lc;编程 -- 邱奇编码 -- 布尔值 -- 构造与使用

  #set text(size: 0.9em)

  #columns(2)[
    一个数据结构有哪些要素？
    #later[
      - 如何构造 -- $"true"$ 和 $"false"$
      - 如何使用 -- $"if_then_else"$
    ]
    #colbreak()
    $
              "true" & = lambda x. lambda y. x \
             "false" & = lambda x. lambda y. y \
      "if_then_else" & = lambda b. lambda t. lambda f. b t f
    $
  ]

  #uncover("2-")[
    让我们再次仔细观察它们的定义。
  ]
  #uncover("3-")[

    - $"true"$ 接受两个参数，返回第一个；$"false"$ 也接受两个参数，返回第二个。
    - $"if_then_else"$ 实际上 $"if_then_else"$ 和恒等函数 $I$ 等价。

      #columns(2)[
        考虑任意 $lambda x. M x$，因为#lc;中 $M$ 总是一个函数，$lambda x. M x$ 等价于 $M$。
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

  #set text(0.9em)

  邱奇编码的独特之处在于，构造出的数据结构用函数直接编码了“使用”。

  $
    "and" eq.def & lambda a. lambda b. a b "false" \
    "or" eq.def & lambda a. lambda b. a "true" b
  $

  因为 $a$ 本身就等价于 $I a$ 等价于 $"if_then_else" a$ 。不难验证：

  #columns(2)[
    $
      & "and" "true" "true" &steps(beta)& "ture" \
      & "and" "true" "false" &steps(beta)& "false" \
      & "and" "false" "true" &steps(beta)& "false" \
      & "and" "false" "false" &steps(beta)& "false"
    $
    #colbreak()
    $
      & "or" "true" "true" &steps(beta)& "ture" \
      & "or" "true" "false" &steps(beta)& "ture" \
      & "or" "false" "true" &steps(beta)& "ture" \
      & "or" "false" "false" &steps(beta)& "false"
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
    - 熟悉自然数的#link("https://en.wikipedia.org/wiki/Mathematical_induction")[数学归纳法]的同学会发现，这个跟它很像；并且还很熟悉 Rocq#footnote[Rocq 定理证明器，从前叫作 Coq。]的同学会发现，这个就是 `Nat` 的 #link("https://rocq-prover.org/doc/V9.2.0/refman/language/core/inductive.html#term-induction-principle")[induction priciples]。
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
    "iszero" eq.def & lambda n. underline(n (K "false") "true") \
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
    (letin(x, M) N) eq.def& (lambda x. N) M \
    lambda x y dots.c z. M eq.def& lambda x. lambda y. dots.c lambda z. M \
    lambda \_. M eq.def & lambda x. M quad #[$x$ 不是 $M$ 中的自由变量]
  $
]

#slide[
  == #lc;的扩展

  #set text(size: 0.9em)

  我们不会想要用 #lc;编码所有数据类型，这在真实的硬件上非常低效。
  我们可以在内存中直接存储整数和布尔值，也可以用指针或者成块的内存表示对和列表。

  这些数据类型可以直接作为一种扩展加入语言中，例如可以直接加入布尔值和自然数。

  #align(center)[
    #bnf(
      Prod(
        $M, N$,
        {
          Or[$...$][]
          Or[$T | F$][]
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
    "church_to_nat" eq.def & lambda n. n (lambda m. m + 1) 0 \
    "square_nat" eq.def & lambda n. n * n \
  $
]

#slide[
  == Church 编码 —— 自然数


  #set text(size: 0.92em)
  $n$ 编码为：对 $f$ 应用 $n$ 次。

  #v(0.4em)
  #grid(columns: 2, gutter: 2em)[
    #block(inset: 8pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
      $accent(0, -) = lambda f . lambda x . x$ \
      $accent(1, -) = lambda f . lambda x . f space x$ \
      $accent(2, -) = lambda f . lambda x . f space (f space x)$ \
      $accent(3, -) = lambda f . lambda x . f space (f space (f space x))$ \
      $dots$
    ]
  ][
    #block(inset: 8pt, stroke: 0.5pt + blue, radius: 4pt, width: 100%)[
      ```nix
      0 = f: x: x;
      1 = f: x: f x;
      2 = f: x: f (f x);
      3 = f: x: f (f (f x));
      ```
    ]
  ]

  #v(0.5em)
  #align(center)[
    $accent(n, -) space f space x = f space (f space dots.h.c (f space x) dots.h.c)$
    #h(1em) ($f$ 出现 $n$ 次)
  ]
]

#slide[
  == Church 编码 —— 算术


  #set text(size: 0.88em)
  #grid(columns: 2, gutter: 2em)[
    #block(inset: 8pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
      后继： \
      $upright("succ") = lambda n . lambda f . lambda x . f space (n space f space x)$ \
      #v(0.3em)
      加法： \
      $upright("add") = lambda m . lambda n . lambda f . lambda x . m space f space (n space f space x)$ \
      #v(0.3em)
      乘法： \
      $upright("mul") = lambda m . lambda n . lambda f . m space (n space f)$
    ]
  ][
    #block(inset: 8pt, stroke: 0.5pt + blue, radius: 4pt, width: 100%)[
      ```nix
      succ = n: f: x: f (n f x);
      add  = m: n: f: x: m f (n f x);
      mul  = m: n: f: m (n f);
      ```
    ]
  ]

  #v(0.5em)
  $upright("add") space accent(2, -) space accent(3, -) space f space x
  = f space (f space (f space (f space (f space x)))) = accent(5, -) space f space x$。
  #note[✓]
]

// ---------- 对 ----------

#slide[
  == Church 编码 —— 对 & 列表


  #set text(size: 0.88em)
  #grid(columns: 2, gutter: 2em)[
    #block(inset: 8pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
      *对 (Pair)* \
      $upright("pair") = lambda a . lambda b . lambda f . f space a space b$ \
      $upright("fst") = lambda p . p space (lambda a . lambda b . a)$ \
      $upright("snd") = lambda p . p space (lambda a . lambda b . b)$ \
      #v(0.5em)
      *列表* \
      $upright("nil") = lambda f . lambda x . x$ \
      $upright("cons") = lambda h . lambda t . lambda f . lambda x . f space h space (t space f space x)$ \
      $upright("null") = lambda l . l space (lambda h . lambda t . upright("false")) space upright("true")$
    ]
  ][
    #block(inset: 8pt, stroke: 0.5pt + blue, radius: 4pt, width: 100%)[
      ```nix
      pair = a: b: f: f a b;
      fst  = p: p (a: b: a);
      snd  = p: p (a: b: b);

      nil  = f: x: x;
      cons = h: t: f: x: f h (t f x);
      null = l: l (h: t: false) true;
      ```
    ]
  ]
]

#slide[
  == Church 编码 —— 列表操作


  #set text(size: 0.88em)
  #grid(columns: 2, gutter: 2em)[
    #block(inset: 8pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
      $upright("head") = lambda l . l space (lambda h . lambda t . h) space upright("nil")$ \
      $upright("tail") = lambda l . upright("fst") space (l space (lambda h . lambda t . upright("pair") space t space (upright("cons") space h space t)) space (upright("pair") space upright("nil") space upright("nil")))$ \
      #v(0.4em)
      $upright("fold") = lambda f . lambda z . lambda l . l space f space z$ \
      #v(0.4em)
      $upright("sum") = upright("fold") space upright("add") space accent(0, -)$
    ]
  ][
    #block(inset: 8pt, stroke: 0.5pt + blue, radius: 4pt, width: 100%)[
      ```nix
      head = l: l (h: t: h) nil;
      tail = l: fst
        (l (h: t: pair t (cons h t))
           (pair nil nil));

      fold = f: z: l: l f z;
      sum  = fold add 0;
      ```
    ]
  ]
]

// ==================== 3. 语法糖 ====================

#slide[
  == 语法糖


  标准 #lc;的写法很冗长，引入 *语法糖* 来简化。

  #v(0.6em)
  #set text(size: 0.92em)
  #grid(columns: 2, gutter: 2em)[
    #block(inset: 8pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
      #align(center)[*#lc;语法糖*]
      #v(0.3em)
      $lambda x y . M$ 是 $lambda x . lambda y . M$ \
      $M space N space P$ 是 $(M space N) space P$ \
      $upright("let") space x = N space upright("in") space M$ \
      #h(1.5em) 是 $(lambda x . M) space N$
    ]
  ][
    #block(inset: 8pt, stroke: 0.5pt + blue, radius: 4pt, width: 100%)[
      #align(center)[*Nix 语法糖*]
      #v(0.3em)
      `x: y: body` 是 `x: (y: body)` \
      `f x y` 是 `(f x) y` \
      ```nix
      let x = n; in body
      ```
      是 `(x: body) n`
    ]
  ]
]

#slide[
  == let 也是语法糖


  `let` 绑定可以嵌套展开：

  #v(0.4em)
  #set text(size: 0.92em)
  #grid(columns: 2, gutter: 2em)[
    #block(inset: 8pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
      $upright("let") space x = N space upright("in") space M$ \
      #h(1.5em) $arrow.r$ $(lambda x . M) space N$ \
      #v(0.3em)
      $upright("let") space x = N; space y = P space upright("in") space M$ \
      #h(1.5em) $arrow.r$ $(lambda x y . M) space N space P$
    ]
  ][
    #block(inset: 8pt, stroke: 0.5pt + blue, radius: 4pt, width: 100%)[
      ```nix
      let x = n; in body
      # => (x: body) n

      let x = n; y = m; in body
      # => (x: y: body) n m
      ```
    ]
  ]

  #v(0.8em)
  #align(center)[
    $upright("let")$ 就是 $lambda$-抽象 + 应用。
  ]
]

#slide[
  == Church 编码汇总


  #set text(size: 0.88em)
  #align(center)[
    #table(
      columns: 4,
      align: (center, center, center, left),
      stroke: 0.5pt + gray,
      table.header[*概念*][*#lc*][*Nix*][*直觉*],
      [true], [$lambda t lambda f . t$], [`t: f: t`], [选第一个],
      [false], [$lambda t lambda f . f$], [`t: f: f`], [选第二个],
      [$accent(0, -)$],
      [$lambda f lambda x . x$],
      [`f: x: x`],
      [对 $f$ 应用 0 次],

      [$accent(n, -)$],
      [$lambda f lambda x . f^n x$],
      [`f: x: f^n x`],
      [对 $f$ 应用 $n$ 次],

      [pair],
      [$lambda a lambda b lambda f . f space a space b$],
      [`a: b: f: f a b`],
      [二元组],

      [nil], [$lambda f lambda x . x$], [`f: x: x`], [空列表],
      [cons],
      [$lambda h lambda t lambda f lambda x . f space h space (t space f space x)$],
      [`h: t: f: x: f h (t f x)`],
      [非空列表],
    )
  ]

  #v(0.6em)
  #note[全部都是 lambda。没有原始类型，没有特殊形式。]
]

#slide[
  == 用 Church 编码写程序


  #set text(size: 0.88em)
  例如，用纯 #lc;写 `sum (cons 3 (cons 5 nil))`：

  #v(0.3em)
  #block(inset: 8pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
    $(lambda f . lambda x . f space (f space (f space x)))$ \
    $space space ((lambda f . lambda x . f space (f space (f space (f space (f space x)))))$ \
    $space space space space (lambda f . lambda x . x))$
  ]

  #v(0.3em)
  上面这个纯 $lambda$-项的值是 $accent(8, -)$（$3 + 5 = 8$）。

  #v(0.5em)
  #note[
    但写起来非常痛苦。这就是为什么 Nix 加了 bool、int、string 和 attrset。
  ]
]

// ==================== 5. 形式语义 ====================

#slide[
  == #lc;的形式语义


  到目前为止，我们只是"感觉" #lc;能算。\
  现在来精确地定义什么是"算"。

  #v(0.6em)

  $lambda$-项的语法：
  #align(center)[
    $M, N ::=
    x
    space | space
    lambda x . M
    space | space
    M space N$
  ]

  其中变量 $x$ 可以是 *自由的* 或 *绑定的*。 \
  $lambda x$ 把 $M$ 中所有自由出现的 $x$ 绑定起来。
]

#slide[
  == $beta$-归约


  #def("定义：β-归约")[
    $(lambda x . M) space N arrow.r.long_beta M[x := N]$
  ]

  #v(0.4em)

  把函数体 $M$ 中所有自由出现的 $x$ 替换为 $N$。

  #v(0.4em)

  #set text(size: 0.88em)
  例如：
  #align(center)[
    $(lambda x . x space y) space z arrow.r.long_beta z space y$
  ]

  #v(0.6em)

  #def("定义：范式 (Normal Form)")[
    一个项如果不存在任何 β-归约，则处于 *范式*（NF）。
  ]

  #v(0.4em)

  #note[
    替换时要避免"变量捕获"——$N$ 中的自由变量不能被 $M$ 中的绑定变量意外捕获。
    需要先做 α-转换（重命名绑定变量）。
  ]
]

#slide[
  == $alpha$-转换


  #def("定义：α-等价")[
    绑定变量的名字不影响含义：
    $lambda x . M equiv_lambda lambda y . M[x := y]$
  ]

  #v(0.4em)

  $lambda x . x equiv_lambda lambda y . y$，都是恒等函数。

  #v(0.4em)

  但要注意捕获问题：
  #align(center)[
    $(lambda y . lambda x . y) space x$
    $arrow.r.long_beta lambda x . y[y := x] = lambda x . x$ #text(
      fill: red,
    )[← 错！]
  ]

  应该先 $alpha$-转换：$lambda y . lambda x . y arrow.r.long_alpha lambda z . lambda x . z$

  #v(0.3em)
  #note[Nix 的求值器内部也会做类似的处理。]
]

// ==================== 6. 求值顺序 ====================

#slide[
  == 求值顺序


  β-归约允许我们"选择先算哪里"。选择会影响计算过程，甚至影响结果。

  #v(0.4em)

  #grid(columns: 2, gutter: 2em)[
    #block(inset: 8pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
      #align(center)[*正则序* (Normal Order)]
      最外层、最左边优先
      #v(0.3em)
      $(lambda x . y) space ((lambda x . x x) space (lambda x . x x))$
      $arrow.r.long y$
    ]
  ][
    #block(inset: 8pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
      #align(center)[*应用序* (Applicative Order)]
      最内层、最左边优先
      #v(0.3em)
      同一个项：
      #v(0.3em)
      无限循环！
    ]
  ]

  #v(0.6em)
  #note[正则序保证：如果有范式，一定能找到；应用序不一定。]
]

#slide[
  == 惰性求值（Call-by-Need）
  #v(0.5em)

  Nix 既不是正则序，也不是应用序，而是 *惰性求值*。

  #v(0.15em)

  #set text(size: 0.85em)
  #align(center)[
    #table(
      columns: 3,
      align: center,
      stroke: 0.5pt + gray,
      inset: (x: 5pt, y: 3pt),
      table.header[*策略*][*何时算参数*][*特点*],
      [正则序], [用到时才算，每次用都重算], [最慢，但能找到范式],
      [应用序], [调用前就算], [可能在不需要的参数上发散],
      [惰性求值], [用到时才算，算过一次就缓存], [兼顾效率和正确性],
    )
  ]

  #v(0.2em)
  Nix 的惰性求值意味着：
  - `if cond then a else b` 只算 `a` 或 `b` 其中一个
  - `let x = expensive; in ...` 只有用到 `x` 时才计算
  - 如果同一个 `x` 被用了多次，只算一次

  #v(0.15em)
  #note[惰性求值 = 正则序的正确性 + 应用序的效率（缓存）。]
]

// ==================== 7. 不动点 ====================

#slide[
  == 不动点
  #v(0.8em)

  问题：#lc;里没有 `let rec`，函数不能直接调用自己。

  #v(0.4em)
  $lambda f . f space f$？可以把 $f$ 传给自己，但无法递归调用任意函数。

  #v(0.5em)

  #def("定义：不动点 (Fixed Point)")[
    如果 $f space p = p$，则 $p$ 是 $f$ 的不动点。
  ]

  #v(0.4em)
  例：$g space x = x^2$ 的不动点是 $0$ 和 $1$。

  #v(0.5em)
  #align(center)[
    *关键洞察：如果我们能为任意 $f$ 找到不动点，就能实现递归。*
  ]
]

#slide[
  == Y 组合子


  Haskell Curry 发现了 $Y$ 组合子，它是计算不动点的"函数"：

  #v(0.5em)
  #align(center)[
    $Y = lambda f . (lambda x . f space (x space x)) space (lambda x . f space (x space x))$
  ]

  #v(0.6em)

  验证：
  $Y space f$
  $= (lambda x . f space (x space x)) space (lambda x . f space (x space x))$
  $= f space ((lambda x . f space (x space x)) space (lambda x . f space (x space x)))$
  $= f space (Y space f)$ #note[✓]

  #v(0.5em)
  #align(center)[
    $Y space f = f space (Y space f)$，即 $Y space f$ 是 $f$ 的不动点。
  ]
]

#slide[
  == 用 Y 组合子写递归


  #set text(size: 0.88em)
  #grid(columns: 2, gutter: 2em)[
    #block(inset: 8pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
      *阶乘* \
      $upright("fact") = Y space (lambda f . lambda n . upright("if") space (upright("iszero") space n)$
      #h(
        3em,
      ) $accent(1, -) space (upright("mul") space n space (f space (upright("pred") space n))))$
      #v(0.4em)
      $upright("fact") space accent(3, -) arrow.r.long^* accent(6, -)$
    ]
  ][
    #block(inset: 8pt, stroke: 0.5pt + blue, radius: 4pt, width: 100%)[
      ```nix
      fact = Y (f: n:
        if isZero n
          1
          (mul n (f (pred n))));

      fact 3
      # => 6
      ```
    ]
  ]

  #v(0.6em)
  注意 $f$ 并没有引用自己——是 $Y$ 帮它"自己调自己"的。
]

#slide[
  == 不动点的威力


  $Y$ 组合子可以为 *任何* 函数找到不动点，不只是数值函数。

  #v(0.5em)
  例如，用 $Y$ 定义斐波那契：
  #v(0.3em)
  #block(inset: 8pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
    $upright("fib") = Y space (lambda f . lambda n . upright("if") space (upright("leq") space n space accent(1, -))$
    #h(
      3em,
    ) $n space (upright("add") space (f space (upright("pred") space n)) space (f space (upright("pred") space (upright("pred") space n)))))$
  ]

  #v(0.5em)
  #note[
    $Y$ 组合子是惰性语言用的版本（Haskell Curry 的版本）。
    严格语言（eager language）需要 $Z$ 组合子，延迟参数的求值：
    $Z = lambda f . (lambda x . f space (lambda y . x space x space y)) space (lambda x . f space (lambda y . x space x space y))$
  ]
]

// ==================== 8. 理解 Nix 库 ====================

#slide[
  == 理解 Nix 库


  现在我们知道不动点了。看看它在 Nix 中无处不在的应用：

  #v(0.5em)
  #columns(2)[
    + `let` & `rec` & `lib.fix`
    + Overlay
    + NixOS modules
    #colbreak()
    #note[
      它们全都是同一个数学概念：\
      不动点。
    ]
  ]
]

#slide[
  == `lib.fix`
  #v(0.8em)

  #set text(size: 0.85em)
  #grid(columns: 2, gutter: 2em)[
    #block(inset: 8pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
      *Y 组合子：* \
      $Y space f = f space (Y space f)$
    ]
  ][
    #block(inset: 8pt, stroke: 0.5pt + blue, radius: 4pt, width: 100%)[
      ```nix
      # lib.nix 中的 fix
      fix = f: let x = f x; in x;
      ```
    ]
  ]

  #v(0.4em)

  `fix` 是 $Y$ 的 Nix 版本。它接受一个函数 $f$，返回 $f$ 的不动点。

  #v(0.3em)
  ```nix
  fix (self: {
    a = 1;
    b = self.a + 2;
  })
  # => { a = 1; b = 3; }
  ```
  #note[`self` 引用的就是最终的结果——一个不动点。]
]

#slide[
  == `let` vs `rec` vs `fix`
  #v(0.5em)

  #set text(size: 0.75em)
  *普通 `let`*：没有递归。
  ```nix
  let x = 1; y = x + 1; in y   # => 2，但 x 不能引用 y
  ```

  #v(0.15em)
  *`rec`*：递归 attrset。
  ```nix
  rec { a = 1; b = a + 1; }    # => { a = 1; b = 2; }
  ```
  内部的 `a` 能引用同一 attrset 里的其他字段。

  #v(0.15em)
  `rec` 本质上是 `fix` 的语法糖：
  ```nix
  # rec { a = 1; b = a + 1; }
  # 等价于
  fix (self: { a = 1; b = self.a + 1; })
  ```
]

#slide[
  == Overlay：高阶函数的不动点
  #v(0.5em)

  #set text(size: 0.72em)
  Overlay 是一个函数：`final: prev: { ... }`

  #v(0.1em)
  - `prev`：上一个版本的包集
  - `final`：最终的包集（不动点！）

  #v(0.2em)
  ```nix
  # Overlay 1：添加一个包
  (final: prev: { my-pkg = prev.callPackage ./mypkg.nix {}; })
  # Overlay 2：修改已有包
  (final: prev: { openssl = prev.openssl.overrideAttrs { ... }; })
  ```

  #v(0.2em)

  多个 overlay 叠加后，用 `lib.extends` 构造一个函数，然后对它求不动点：
  ```nix
  fix (lib.extends overlay2 (lib.extends overlay1 basePkgs))
  ```

  #v(0.1em)
  #note[overlay 的 `final` 参数就是最终的不动点——整个包集。]
]

#slide[
  == NixOS Module System：更大的不动点


  #set text(size: 0.88em)
  NixOS 模块系统是不动点思想的极致应用：

  #v(0.4em)
  ```nix
  # 每个模块的 config 是最终配置的"局部视图"
  { config, lib, ... }: {
    options.services.foo.enable = lib.mkEnableOption "foo";
    config = lib.mkIf config.services.foo.enable {
      # config 引用了最终结果的字段
      networking.firewall.allowedTCPPorts = [ 8080 ];
    };
  }
  ```

  #v(0.4em)
  所有模块的 `config` 属性合并后，用 `lib.fix` 求不动点。\
  每个模块看到的 `config` 就是最终的系统配置。

  #v(0.5em)
  #align(center)[
    $upright("config") = upright("merge") space (upright("module1") space upright("config")) space (upright("module2") space upright("config")) space dots.h.c$
  ]
  #note[这就是一个不动点方程。]
]

// ==================== 9. 扩展知识 ====================

#slide[
  == 扩展知识


  #columns(2)[
    #block(inset: 8pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
      不动点组合子 \
      更多的不动点组合子
    ]
    #v(0.5em)
    #block(inset: 8pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
      #lc;的实现 \
      变量绑定的表示
    ]
    #colbreak()
    不动点思想贯穿了整个讲义。\
    这一小节补充更多细节。
  ]
]

#slide[
  == 更多不动点组合子


  #set text(size: 0.88em)
  $Y$ 不是唯一的不动点组合子。还有：
  #v(0.4em)

  #grid(columns: 2, gutter: 2em)[
    #block(inset: 8pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
      *Turing 组合子：* \
      $Theta = (lambda x lambda y . y space (x space x space y)) space (lambda x lambda y . y space (x space x space y))$
      #v(0.3em)
      $Theta space f = f space (Theta space f)$
    ]
  ][
    #block(inset: 8pt, stroke: 0.5pt + gray, radius: 4pt, width: 100%)[
      *Z 组合子（严格版 $Y$）：* \
      $Z = lambda f . (lambda x . f space (lambda y . x space x space y)) space (lambda x . f space (lambda y . x space x space y))$
      #v(0.3em)
      $Z space f = f space (Z space f)$
    ]
  ]

  #v(0.6em)
  所有不动点组合子都有 $X space f = f space (X space f)$ 的形式。

  #v(0.3em)
  #note[Nix 的 `fix = f: let x = f x; in x;` 直接用了惰性求值的特性，比 $Y$ 更简洁。]
]

#slide[
  == #lc;的实现


  #set text(size: 0.88em)
  如何在代码里表示 $lambda$-项？一个经典问题：变量名冲突。

  #v(0.4em)
  解决方案：*de Bruijn 指数*——用数字代替变量名。

  #v(0.4em)
  #align(center)[
    #table(
      columns: 3,
      align: center,
      stroke: 0.5pt + gray,
      table.header[*项*][*带名字*][*de Bruijn*],
      [恒等函数], [$lambda x . x$], [$lambda . 0$],
      [常量函数], [$lambda x . lambda y . x$], [$lambda . lambda . 1$],
      [应用], [$(lambda x . x) space y$], [$(lambda . 0) space y$],
    )
  ]

  #v(0.4em)
  $lambda . 1$ 表示"引用外层第二个 $lambda$ 绑定的变量"。

  #v(0.3em)
  #note[Nix 内部求值器也用了类似的技术来避免变量名冲突。]
]

#slide[
  == Nix 实现的 #lc;解释器
  #v(0.6em)

  #set text(size: 0.75em)
  用 de Bruijn 指数实现：
  #v(0.2em)
  ```nix
  let
    Var  = index: { inherit index; type = "var"; };
    Lam  = body: { inherit body;   type = "lam"; };
    App  = func: arg: { inherit func arg; type = "app"; };
  in ...
  ```

  #v(0.2em)
  项的定义用 Nix attrset 表示：
  #v(0.1em)
  #align(center)[
    #table(
      columns: 3,
      align: center,
      stroke: 0.5pt + gray,
      inset: (x: 6pt, y: 3pt),
      table.header[*构造*][*语义*][*Nix*],
      [`Var 0`], [当前绑定的变量], [`{ index = 0; type = "var"; }`],
      [`Lam body`], [函数], [`{ body = ...; type = "lam"; }`],
      [`App f x`], [函数应用], [`{ func = ...; arg = ...; type = "app"; }`],
    )
  ]
]

#slide[
  == $beta$-归约实现
  #v(0.8em)

  #set text(size: 0.75em)
  求值器遍历项，遇到 `App (Lam body) arg` 就替换：
  #v(0.2em)
  ```nix
  substitute = term: value: depth:
    if term.type == "var" then
      if term.index == depth then value
      else if term.index > depth then Var (term.index - 1)
      else term
    else if term.type == "lam" then
      Lam (substitute term.body (shift value 1 0) (depth + 1))
    else if term.type == "app" then
      App (substitute term.func value depth)
          (substitute term.arg value depth)
    else term;
  ```

  #v(0.2em)
  求值：
  ```nix
  eval = term: args:
    if term.type == "app" then
      eval term.func ([ term.arg ] ++ args)
    else if term.type == "lam" && args != [] then
      eval (substitute term.body (builtins.head args) 0)
           (builtins.tail args)
    else term;
  ```

  #v(0.2em)
  #note[这是 β-归约的朴素实现，还有更高效的策略（如 Krivine machine）。]
]

#slide[
  == 总结


  + #lc;只有 *三条规则*：变量、抽象、应用
  + *Church 编码*：用纯 $lambda$-项表示数据（bool、nat、pair、list...）
  + *语法糖*：`let` 等价于 $lambda$-抽象 + 应用
  + *形式语义*：$beta$-归约 + $alpha$-转换
  + *求值顺序*：Nix 用惰性求值（call-by-need）
  + *不动点*：$Y$ 组合子实现递归
  + *Nix 库*：`rec`、`fix`、overlay、modules 全都是不动点

  #v(0.6em)
  #align(center)[
    #block(inset: 10pt, stroke: 0.5pt + blue, radius: 6pt)[
      Nix 语言 = #lc + bool + int + string + attrset + derivation \
      学会了 #lc，就理解了 Nix 的核心。
    ]
  ]
]
