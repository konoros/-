# 机械组 技术文档

整理机械组的技术资料：每份文档都提供「Markdown 在线预览 / 正文插图 / Word 原件」三件套，另附可运行的源码。目前收录：

| 文档 | 内容 |
|---|---|
| [轮腿机器人设计理论报告](docs/wheel-leg-robot-theory.md) | 轮腿（双轮足）机器人的平衡与倒立摆模型、关节电机扭矩推导、并联腿 / 偏置并联构型对比、连杆参数设计与跳跃高度计算 |
| [弹簧重补 技术报告](docs/spring-report.md) | 云台弹簧重力补偿的完整资料，含 MATLAB 弹簧选型脚本 |

## 📄 Markdown 预览

- [轮腿机器人设计理论报告（在线预览）](docs/wheel-leg-robot-theory.md) —— 公式为 LaTeX，GitHub 原生渲染
- [弹簧重补 技术报告（在线预览）](docs/spring-report.md)

## 🖼 图片

- [轮腿机器人设计理论报告插图：images/wheel-leg-robot-theory-1.png … images/wheel-leg-robot-theory-13.png（共 13 张，从原文档内嵌图片按顺序导出）](images/wheel-leg-robot-theory-1.png)
- [弹簧重补 技术报告插图：images/spring-report-1.png … images/spring-report-13.png（共 13 张）](images/spring-report-1.png)

图片目录：`images/`，正文里用相对路径 `../images/…` 引用，预览页直接显示。

## 📦 原文件下载

- [轮腿机器人设计理论报告.docx（Word 原件）](originals/wheel-leg-robot-theory.docx)
- [弹簧重补 技术报告.docx（Word 原件）](originals/spring-report.docx)

打开后点右上角 Download 即可下载。

## 💻 源码

- [spring_pianlong.m（MATLAB 弹簧选型脚本）](code/spring_pianlong.m) —— 在 MATLAB 里直接打开运行，改 l1 / l2 后重跑即可；输出内径 5–10 mm、形变量 ≥100 mm 的候选弹簧

## 目录说明

| 目录 | 内容 | 用途 |
|---|---|---|
| `docs/` | `*.md` | 可直接在 GitHub 上预览的 Markdown 正文（公式用 LaTeX，GitHub 原生渲染） |
| `images/` | 正文引用的图片 | 文档插图，使用相对路径 `../images/` 引用 |
| `originals/` | `*.docx` | Word 原件，供下载 |
| `code/` | `.m` 源码 | MATLAB 脚本，可直接运行 |

文档中的图片使用相对路径引用，在 GitHub 预览页会直接渲染；如需原始文件，请到 `originals/` 下载，代码到 `code/` 获取。
