#import "@preview/polylux:0.4.0": slide, later, uncover, only
#import "@preview/simplebnf:0.2.0": bnf, Prod, Or
#import "@preview/tdtr:0.5.5": tidy-tree-graph
#import "@preview/ctheorems:1.1.3": thmrules
#import "@preview/curryst:0.6.0": rule, prooftree, rule-set
#import "@preview/fletcher:0.5.8": diagram, node, edge

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
#let app-node = [@]
#let important(..args) = text(fill: blue, weight: 600, ..args)
#let warning(..args) = text(fill: red, weight: 600, ..args)
#let mathimportant(body, ..args) = text(fill: blue, ..args, math.underline(body))
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
#let substto = math.arrow.bar
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
    "and" eq.def & lambda a. lambda b. a b F \
    "or" eq.def & lambda a. lambda b. a T b
  $

  因为 $a$ 本身就等价于 $I a$ 等价于 $"if_then_else" a$ 。不难验证：

  #columns(2)[
    $
      & "and" T T &steps(beta)& T \
      & "and" T F &steps(beta)& F \
      & "and" F T &steps(beta)& F \
      & "and" F F &steps(beta)& F
    $
    #colbreak()
    $
      & "or" T T &steps(beta)& T \
      & "or" T F &steps(beta)& T \
      & "or" F T &steps(beta)& T \
      & "or" F F &steps(beta)& F
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
    (letin(x, M) N) eq.def& (lambda x. N) M \
    lambda x y dots.c z. M eq.def& lambda x. lambda y. dots.c lambda z. M \
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
    $ lambda x. lambda x. x != & lambda y. lambda x. y \
      lambda x. lambda x. x = & lambda x. lambda y. y $
  ]
]

#slide[
  == #lc;的形式语义 -- $alpha$-等价

  #columns(2)[
    #set align(center)
    #prooftree(rule(
      name: text(fill: purple)[$(alpha)$],
      $lambda x. M = lambda y. M[y slash x]$
    ))
    #prooftree(rule(
      name: $(xi)$,
      $M = M'$,
      $lambda x. M = lambda x. M'$
    ))
    #prooftree(rule(
      name: $("cong")$,
      $M = M'$, $N = N'$,
      $M N = M' N'$
    ))
    #colbreak()
    #prooftree(rule(
      name: $("refl")$,
      $M = M$
    ))
    #prooftree(rule(
      name: $("sym")$,
      $N = M$,
      $M = N$
    ))
    #prooftree(rule(
      name: $("trans")$,
      $M_1 = M_2$,
      $M_2 = M_3$,
      $M_1 = M_3$
    ))
  ]

  #note[
    最核心的规则就是 $(alpha)$，它表示将 $lambda x. M$ 中的 $x$ 替换为 $y$ 之后获得的 $lambda$-项和原来的项等价。但是替换如何定义很重要，我们会在后面简单讨论替换的精确定义。
  ]
]

#slide[
  == #lc;的形式语义 -- 操作语义

  #set text(size: 0.9em)

  #lc;的形式语义有很多种，但通常我们会定义小步操作语义（small-step operational semantics），因为它展现了 #lc;的计算过程。

  #columns(2)[
    #set align(center)
    #prooftree(rule(
      name: text(fill: purple)[$(beta)$],
      $(lambda x. M) N step(beta) M[N slash x]$
    ))
    #prooftree(rule(
      name: $(xi)$,
      $M step(beta) M'$,
      $lambda x. M step(beta) lambda x. M'$
    ))
    #colbreak()
    #prooftree(rule(
      name: $("cong1")$,
      $M step(beta) M'$,
      $M N step(beta) M' N$
    ))
    #prooftree(rule(
      name: $("cong2")$,
      $N step(beta) N'$,
      $M N step(beta) M N'$
    ))
  ]

  - 应用 $(beta)$ 规则又被称为做 $beta$-规约（reduction），$(lambda x. M) N step(beta)$ 又被称为 $beta$-redex。
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
  $ (lambda y. M')[N slash x] &eq.def mathimportant(lambda y'. M'[y'slash y])[N slash x] quad "if" x != y\, mathimportant(y in FV(N))\, mathimportant(y' "fresh") $
  可以处理以下情形。
  $ dobeta((lambda y. x) y) step(beta) (lambda y. x)[y slash x] =& lambda y'. y \
    !=& lambda y.y $
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
        $M N step(beta) M' N$
      ))
      #prooftree(rule(
        name: text(fill: purple)[$(beta)$],
        $(lambda x. M) mathimportant(v) step(beta) M[mathimportant(v) slash x]$
      ))
      #colbreak()
      #prooftree(rule(
        name: $("cong2")$,
        $N step(beta) N'$,
        $mathimportant(v) N step(beta) mathimportant(v) N'$
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
      $M N step(beta) M' N$
    ))
    #colbreak()
    #prooftree(rule(
      name: text(fill: purple)[$(beta)$],
      $(lambda x. M) N step(beta) M[N slash x]$
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
          dobeta((lambda x. x x) (I I)) step(beta)& dobeta((I I)) (I I) \
                                step(beta)& dobeta(I (I I)) \
                                step(beta)& dobeta((I I)) \
                                =& I \
        $

    - 而在 Call-by-value 下，同样的项只需三步求值。
      $
        (lambda x. x x) dobeta((I I)) step(beta)& dobeta((lambda x. x x) I) \
                              step(beta)& dobeta(I I) \
                              =& I \
      $
  ]
]

#slide[
  == #lc;的求值策略 - Call-by-Need

  如果我们对 Call-by-name 做一个优化，让同一个参数的多次使用的求值可以共享，就变成了 Call-by-need。

  可以用“图规约”来理解 call-by-need，还是以 $(lambda x. x x) (I I)$ 为例子。
  #columns(4)[
    #set align(center)
    #diagram(cell-size: 10mm,
    spacing: 1.5em,
      {
      let (app1, omega, app2, i1, i2) = ((0, 0), (-0.5, 1), (0.5, 1), (0, 2), (1, 2))
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
    #diagram(cell-size: 10mm,
    spacing: 1.5em,
     {
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
    #diagram(cell-size: 10mm,
    spacing: 1.5em,
     {
      let (app1, i) = ((0, 0), (0, 1))
      node(app1, $@$)
      node(i, $I$)
      edge(app1, i, "->", bend: 20deg)
      edge(app1, i, "->", bend: -20deg)
    })
    #colbreak()
    #diagram(cell-size: 10mm,
    spacing: 1.5em,
     {
      let (i) = ((0, 0))
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
      [Non-strict], [Call-by-name/need]
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

  这里的 $bot$ 就是出错的意思。
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
  == 不动点

  数学上，函数 $f : A -> B$ 的不动点指的是某个 $c in A inter B$，满足：$ f(c) = c $


]
