#let unnumbered-footnote(body) = {
  footnote(numbering: _ => [])[#body]
  counter(footnote).update(n => n - 1)
}

#let license() = unnumbered-footnote[
  #set text(size: 0.65em)
  #set align(horizon)
  #image("images/by-nc-sa-88x31.svg", alt: "by-nc-sa.svg")
  本作品采用#link("https://creativecommons.org/licenses/by-nc-sa/4.0/")[署名-非商业性使用-相同方式共享 4.0 协议国际版协议]授权。
]
