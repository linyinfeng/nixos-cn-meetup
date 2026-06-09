#import "@preview/polylux:0.4.0": *
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.10": *

#set page(paper: "presentation-16-9")
#set text(size: 23pt, font: ("Source Sans 3", "Source Han Sans SC"))
#show raw: set text(size: 1.1em, font: "Sarasa Mono Slab SC")

#show link: set text(fill: blue.darken(25%))

#show: codly-init.with()
#let setup-codly() = {
  codly-reset()
  codly(languages: codly-languages)
  codly(zebra-fill: luma(250))
}

#let rainbow(body) = text(fill: gradient.linear(..color.map.rainbow), box(body))
#let rainbow-highlight(body) = highlight(
  fill: gradient.linear(
    (rgb(124, 213, 255), 0%),
    (rgb(166, 251, 202), 33%),
    (rgb(255, 243, 124), 66%),
    (rgb(255, 164, 157), 100%),
    angle: -7deg,
  ),
  radius: 0.25em,
  body,
)

#let date = datetime(
  year: 2026,
  month: 6,
  day: 13,
)

#slide[
  #set align(horizon)

  #grid(columns: 2, gutter: 0.5cm)[
    #image("images/blog-link-qrcode.svg", width: 7cm)
  ][
    #text(size: 1.2em)[= #rainbow[土制] Nix S3 Binary Cache]
    #v(-0.5em)
    #text(size: 1.0em, fill: gray)[= #rainbow[Homemade] Nix S3 Binary Cache]

    #v(0.5em)

    #text(size: 1.1em)[Yinfeng]
    #v(-0.5em)
    #date.display()
  ]
]

#slide[
  #align(center)[
    == 关于我
  ]

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
    Nix 相关项目：
    - #link("https://github.com/linyinfeng/nix-cache-overlay")[nix-cache-overlay] - S3 cache 代理
    - #link("https://github.com/linyinfeng/nix-gc-s3")[nix-gc-s3] - 为 S3 cache 做 GC
    - #link("https://github.com/linyinfeng/dotfiles")[dotfiles] - 我的配置文件
    - #link("https://github.com/linyinfeng/commit-notifier")[commit-notifier] - NixOS CN 群的 PR 通知
    - #link("https://github.com/linyinfeng/angrr")[angrr] - 自动 Nix GC Roots 管理
    - #link("https://github.com/linyinfeng/flat-flake")[flat-flake] - 扁平化 flake inputs 检查
    - #link("https://github.com/linyinfeng/oranc")[oranc] - OCI registry as Nix cache（实验性）
  ]
]

#slide[
  == 简介

  #v(1em)

  #set text(size: .9em)

  一个我已经使用了三年多的 Nix S3 Binary Cache 方案。

  + #rainbow[*土制灵车*]

  + *极低成本*：使用 Cloudflfare R2 等有免费额度的 S3 服务，每月 *0 USD*

  + *几乎 Serverless*：稳定，高性能，无服务器瓶颈

  + *极佳兼容性*：使用 `nix copy` 直接上传

  #v(0.5em)

  #text(size: .8em)[注：第一点与其他特色并没有冲突。]
]

#slide[
  == 目标

  #v(1em)

  + 增进大家对 Nix binary cache 的了解
  + 向大家介绍我写的两个简单的小工具：
    - #link(
        "https://github.com/linyinfeng/nix-cache-overlay",
      )[`github:linyinfeng/nix-cache-overlay`]
    - #link(
        "https://github.com/linyinfeng/nix-gc-s3",
      )[`github:linyinfeng/nix-gc-s3`]
  + 抛砖引玉
]

#slide[
  == Nix binary cache 简介

  #v(1em)

  #only(1)[
    Nix 客户端如何利用 HTTP binary cache？

    + 当 Nix 要构建某个 derivation 的输出时，通常#footnote[非 content-addressed derivation] Nix 计算出输出的 store path，例如：

      ```console
      $ nix eval nixpkgs#hello^out --raw
      /nix/store/zi2bj2hlavv8q743li2s9diqbcpmrf9b-hello-2.12.3
      ```
  ]

  #let example-hash = text(
    fill: green.darken(25%),
  )[`zi2bj2hlavv8q743li2s9diqbcpmrf9b`]
  #let example-narinfo = [#example-hash#text(fill: orange)[*`.narinfo`*]]

  #only(2)[
    #set enum(start: 2)
    + Store path
      #align(center)[`/nix/store/`#example-hash`-hello-2.12.3`]
      中的 hash #example-hash 被认为是不会重复的，这是 binary cache 的索引。

      Nix 随即尝试从 `substituters` 下载 #align(center)[#example-narinfo] 文件。
  ]

  #only(3)[
    #set text(size: 0.9em)
    `curl `#link("https://cache.nixos.org/zi2bj2hlavv8q743li2s9diqbcpmrf9b.narinfo")[`https://cache.nixos.org/`#example-narinfo]

    #set text(size: .78em)

    ```txt
    StorePath: /nix/store/zi2bj2hlavv8q743li2s9diqbcpmrf9b-hello-2.12.3
    URL: nar/1zzwzcsbpsghsbfjdw416dgmfankjs4chksx1cic1p1z8v6vr0s8.nar.xz
    Compression: xz
    FileHash: sha256:1zzwzcsbpsghsbfjdw416dgmfankjs4chksx1cic1p1z8v6vr0s8
    FileSize: 58480
    NarHash: sha256:0vwm6sr61cx6hydqlx3phhg1a0830k61dbfwqlkhilkpcbppjmdw
    NarSize: 279624
    References: 57iz36553175g3178pvxjij8z5rcsd4n-glibc-2.42-61 zi2bj2hlavv8q743li2s9diqbcpmrf9b-hello-2.12.3
    Deriver: 67mdzby3g0maqqp93xj03rc99nnrpdp9-hello-2.12.3.drv
    Sig: cache.nixos.org-1:DwOHEUMyxq4aUrwzcZJrPPqqlImdA7042VJ+HWOnyjZeBMaKkSQxFS2vArnR...
    ```
  ]

  #only(4)[
    #set text(size: .90em)

    #set enum(start: 3)
    + 根据 `Sig` 验证签名后，Nix 下载 #align(center)[`URL: nar/1zzwzcsbpsghsbfjdw416dgmfankjs4chksx1cic1p1z8v6vr0s8.nar.xz`]

      解压并加入 store。

      可以注意到 nar 的路径中也有一个 hash，这个 hash 是 nar 文件本身的 hash，也就是说，它 “content-addressed”，与 store path 里的 hash 并不相同。

    + #link("https://cache.nixos.org")[cache.nixos.org] CDN 的上游其实#footnote[NixOS 的基础设施配置是很透明公开的，见：#link("https://github.com/NixOS/infra/blob/main/terraform/cache.tf")[NixOS/infra - terraform/cache.tf]。]直接是一个 AWS S3 服务的 public URL。
  ]
]

#slide[
  == 最简单的 Nix S3 Binary Cache

  #v(1em)

  #set text(size: .83em)

  `nix copy` 命令支持拷贝到各种 “Nix store”。而 S3 binary cache 也是一种 Nix store，URL 形如 *`s3://BUCKET_NAME`*。

  支持任何 AWS S3 兼容服务：Cloudflare R2、Backblaze B2、自建 Garage 等等。

  ```bash
  export AWS_ACCESS_KEY_ID="..."
  export AWS_SECRET_ACCESS_KEY="..."
  # AWS
  nix copy "nixpkgs#hello" --to "s3://$BUCKET_NAME"
  # 非 AWS
  export AWS_EC2_METADATA_DISABLED=true
  nix copy "nixpkgs#hello" --to "s3://$BUCKET_NAME?endpoint=$ENDPOINT_URL"
  ```
]

#slide[
  == 签名

  #v(1em)

  #set text(size: .74em)

  通常我们会想要给 cache 签名，可以直接使用 `nix store sign` 在本地签名，然后 `nix copy`。

  ```bash
  # 生成密钥
  nix key generate-secret --key-name "$KEY_NAME"
  # 签名
  nix store sign "nixpkgs#hello" --recursive --key-file "$SECRET_KEY_FILE"
  # 上传
  nix copy "nixpkgs#hello" --to "s3://$BUCKET_NAME?endpoint=$ENDPOINT_URL"
  ```

  导出公钥：

  ```bash
  cat "$SECRET_KEY_FILE" | nix key convert-secret-to-public
  ```

  公钥形如：`cache.li7g.com:YIVuYf8AjnOc5oncjClmtM19RaAZfOKLFFyZUpOrfqM=`
]

#slide[
  == 我的配置

  #v(1em)

  #set text(size: .60em)

  使用 Cloudflare R2 + 自定义域名 `cache.li7g.com`。

  ```terraform
  resource "cloudflare_r2_bucket" "cache" {
    account_id    = ...
    name          = "cache-li7g-com"
    location      = "APAC"
    storage_class = "Standard"
  }
  resource "cloudflare_r2_custom_domain" "cache" {
    account_id  = ...
    enabled     = true
    bucket_name = cloudflare_r2_bucket.cache.name
    domain      = "cache.li7g.com"
    zone_id     = cloudflare_zone.com_li7g.id
  }
  ```
]

#slide[
  == 使用搭建好的 cache

  #v(1em)

  使用 cache 只需要通过任意方式指定好 Nix 选项：

  ```ini
  substituters = ... https://cache.li7g.com
  trusted-public-keys = ... cache.li7g.com:YIVuYf8AjnOc5oncjClmtM19RaAZfOKLFFyZUpOrfqM=
  ```
]

#slide[
  == 忽略上游已有内容

  #v(1em)

  #set text(size: .9em)

  `nix copy` 上传时*不会检查上游*，比如 #link("https://cache.nixos.org")[cache.nixos.org] 中是否已有相同内容。

  我的主力机 closure 大小：

  ```console
  $ nix path-info /run/current-system \
        --closure-size --human-readable
  /nix/store/...-nixos-system-parrot-26.05...   35.5 GiB
  ```

  35.5 GiB，远超 R2 免费额度（10 GB）。

  #later[
    需要避免重复存储上游已有内容。
  ]
]

#slide[
  == `nix copy` 的行为

  #v(1em)

  `nix copy` 在上传前会检查目标 cache 中是否已有 `narinfo` 文件：

  1. 如果 store path 文件名为：`/nix/store/`#text(fill: purple)[`i3zw7h6p...4v5w`]`-hello-2.12.2`

  2. narinfo 文件名：#text(fill: purple)[`i3zw7h6p...4v5w`]`.narinfo`

  3. 通过 S3 `GetObject` 检查该文件是否存在

  #v(1em)

  #later[
    #align(center)[
      从上游 cache 偷个 narinfo 文件，返回给 Nix 客户端，就能避免重复上传。
    ]
  ]
]

#slide[
  == nix-cache-overlay -- 轻量 `nix copy` 代理服务器

  #v(1em)

  #link(
    "https://github.com/linyinfeng/nix-cache-overlay",
  )[`github:linyinfeng/nix-cache-overlay`]

  #only((1, 3))[
    做两件事：

    1. 把 `narinfo` 的 `GET`/`HEAD` 请求转发到上游 cache
      - 上游返回 200 $->$ 返回给客户端
      - 上游返回 404 $->$ 尝试下一个上游

    2. 所有上游都 404 $->$ 认证后签上 SigV4 签名，转发到 S3 服务器
  ]

  #only(2)[
    认证方式：忽略签名，把 `AWS_ACCESS_KEY_ID` 当 token 使用。

    代价是降低了一些安全性，好处是不用受 SigV4 的折磨（大雾
  ]

  #only(3)[
    因为它只是一个简单的代理服务器，所以它直接支持 S3 multipart 上传，还可以直接支持上传构建日志等等特殊功能。
  ]
]

#slide[
  == nix-cache-overlay 配置

  #v(1em)

  #only(1)[
    引入项目的 Nixpkgs overlay 与 NixOS 模块后，NixOS module 配置：

    #set text(size: 0.93em)
    ```nix
    {
      services.nix-cache-overlay = {
        enable = true;
        listen = "[::1]:8080";
        endpoint = "https://host.of.s3.endpoint";
        environmentFile = /path/to/env/file;
      };
    }
    ```
  ]

  #only(2)[
    `environmentFile` 内容：

    ```txt
    # 用于代理连接 S3 的认证
    AWS_ACCESS_KEY_ID=...
    AWS_SECRET_ACCESS_KEY=...

    NIX_CACHE_OVERLAY_TOKEN=... # 用于客户端连接代理的认证

    AWS_EC2_METADATA_DISABLED=true # 非 AWS 需要
    ```
  ]
]

#slide[
  == 使用 nix-cache-overlay

  #v(1em)

  #set text(size: .85em)

  ```bash
  export AWS_ACCESS_KEY_ID="$NIX_CACHE_OVERLAY_TOKEN"
  export AWS_SECRET_ACCESS_KEY="-" # 不重要
  export AWS_EC2_METADATA_DISABLED=true
  nix store sign "nixpkgs#hello" --recursive --key-file "$SECRET_KEY_FILE"
  nix copy "nixpkgs#hello" --to "s3://$BUCKET_NAME?endpoint=http://[::1]:8080"
  ```

  #v(0.5em)

  #text(size: .95em)[
    *注意*：`nix copy` 对 narinfo 查询的并发非常恐怖，建议把 overlay 部署在本地，不要通过反向代理访问，会把反代打爆。
  ]

  ```log
  Jan 22 23:30:21 nuc nginx[85266]: [alert] 512 worker_connections are not enough
  ```
]

#slide[
  == 我的配置

  #v(1em)

  使用 nix-cache-overlay 后，存储我一堆机器的系统的 binary cache 只需要不到 6 GiB 的存储空间。

  ```console
  $ mc du r2-cache/cache-li7g-com
  5.7GiB	14352 objects	cache-li7g-com
  ```

  目前每个月 Cloudflare 账单都是 0 USD。
]

#slide[
  == GC

  #v(1em)

  Nix 本身只支持上传 S3 binary cache，但不支持 GC，需要自己实现。

  GC 其实分两部分：

  1. 管理 GC roots

  2. 根据 GC roots 进行 GC
]

#slide[
  == 管理 GC roots

  #v(1em)

  我的方案：正好我有自建的 Hydra CI#footnote[即 NixOS 的官方 CI #link("https://github.com/NixOS/hydra")[github:NixOS/hydra]。]，直接让它来管理 GC roots。

  - Hydra 提供了 GC roots 目录
  - Job set 的 "Number of evaluations to keep" 配置#footnote[Hydra 声明式配置中的 `keepnr`。]控制保留数量
  - Binary cache 只用来存储 hydra 构建的内容，不做随意的 push
]

#slide[
  == 根据 GC roots 进行 GC

  #v(1em)
  #set text(size: .85em)

  做一个 tracing GC，解析 `narinfo` 文件获取依赖列表，递归找到所有可达的 store path。

  典型的 narinfo 文件：

  ```plain
  StorePath: /nix/store/i3zw7h6p...-hello-2.12.2
  URL: nar/0jra6lgd...nar.xz
  References: i3zw7h6p...-hello-2.12.2 j193mfi0...-glibc-2.40-66
  Sig: cache.nixos.org-1:K25JMfP0...
  ```

  Hydra 服务器上，closure 本地都有，直接用 `nix-store --query --requisites` 判断依赖关系，比较快。最后调用 S3 API 批量删除（一次最多 1000 个对象）。

  代码见 #link("https://github.com/linyinfeng/nix-gc-s3")[linyinfeng/nix-gc-s3]。
]

#slide[
  == 一个经典的坑

  #v(1em)
  #set text(size: 0.9em)

  我们提到过， nar 文件的路径中的 hash 是通过 nar 文件本身的内容计算出来的。

  ```txt
  StorePath: /nix/store/zi2bj2hlavv8q743li2s9diqbcpmrf9b-hello-2.12.3
  URL: nar/1zzwzcsbpsghsbfjdw416dgmfankjs4chksx1cic1p1z8v6vr0s8.nar.xz
  ...
  ```

  #later[
    因此完全可能出现多个 narinfo 文件的 `URL` 指向同一个 nar 文件。
  ]

  #later[
    所以 GC 时，必须下载所有需要被保留的 narinfo 文件，才能判断哪些 nar 文件应该被删除。
  ]
]

#slide[
  == 限制

  #v(1em)

  `nix-gc-s3` 和 `nix copy` *不应该同时运行*。

  我一般在固定的 systemd 服务中运行这两个服务，脚本中使用 `flock` 加互斥锁。

  正因如此，我的方案只适合由一台机器专门上传 binary cache 和做 GC。
]

#slide[
  == 总结

  #v(1em)

  #set text(size: .9em)

  该方案作为 #rainbow[*土制灵车*]，确实*极低成本* + *几乎 Serverless* + *极佳兼容性*。

  #v(0.5em)

  #text(fill: red)[*局限性*]：基本只适用于配合自建 Hydra CI 一起使用。

  + 没有基于时间的 GC，必须自己维护 GC roots；
  + GC 时要求 binary cache 中的内容必须在本地都有；
  + 只适合由一台机器专门上传 binary cache 和做 GC；
  + 将 Hydra CI 考虑在内，不再 Serverless，但服务器故障不影响 cache 可用性。


  #v(0.5em)

  其他方案：#link("https://github.com/Mic92/niks3")[github:Mic92/niks3]。
]

#slide[
  #set align(center + horizon)

  == 谢谢！

  #v(0.5em)

  #image("images/blog-link-qrcode.svg", width: 7cm)

  博客文章：#link("https://blog.linyinfeng.com/posts/homemade-nix-s3-cache/")[blog.linyinfeng.com/posts/homemade-nix-s3-cache]
]
