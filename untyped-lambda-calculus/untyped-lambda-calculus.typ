#import "@preview/polylux:0.4.0": *

#set page(paper: "presentation-16-9")

// font and styles

#set text(size: 23pt, font: ("Source Sans 3", "Source Han Sans SC"))
#show raw: set text(size: 1.1em, font: ("Sarasa Mono Slab SC"))
#show link: set text(fill: blue.darken(25%))

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

#slide[
  #set align(horizon)

  #grid(columns: 2, gutter: 0.5cm)[
    // #image("images/blog-link-qrcode.svg", width: 7cm)
  ][
    #text(size: 1.2em)[= 给 Nix 用户的 $lambda$-演算基础]
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
  #v(1em)

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
    也勉强算是个研究程序设计语言的。
  ]
]

#slide[
  == $lambda$-演算？
  #v(1em)

  先做一个小调查：
  #align(center)[
    在座的各位有多少曾经学习过“$lambda$-演算”？
  ]
]

#slide[
  == $lambda$-演算？
  #v(1em)

  - 回想我第一次尝试使用 NixOS 的时候，对 Nix 语言非常不适应；
  - 学了 $lambda$-演算后，第二次接触 Nix 语言时，我的感想完全变了。

    这语言不就是：
    #align(center)[
      $lambda$-演算 + bool + int + string + attrset + derivation#footnote[包含 string context。]
    ]
    味太对了。
]

#slide[
  == 目录
  #v(1em)

  #columns(2)[
    + Lambda 演算简介
    + 用 Lambda 演算编程
    + 语法糖
    + 扩展
    + Lambda 演算的形式语义
    + 求值顺序
    + 不动点
    #colbreak()
    #set enum(start: 8)
    + 理解 Nix 库
      - `let` & `rec` & `lib.fix`
      - Overlay & NixOS modules
    + 扩展知识
      + 不动点组合子
      + Lambda 演算的实现
  ]
]

#slide[
  == Lambda 演算简介
  #v(1em)

  #columns(2)[
    #figure(caption: "Alonzo Chuch")[
      #image("images/alonzo-church.jpg", height:70%)
    ]
    #colbreak()
    -
  ]
]
