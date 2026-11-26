# 机械组 技术文档

整理机械组的技术资料：每份文档都提供「Markdown 在线预览 / 正文插图 / Word 原件」三件套，另附可运行的源码。目前收录：

| 文档 | 内容 |
|---|---|
| [庆园阁过洞步兵机械设计技术传承手册](docs/tunnel-infantry-manual.md) | 过洞步兵整车的结构设计传承手册：项目参数、整车布局、电机与轴系、Yaw 同步带、折叠双俯仰与四连杆、底盘轮组、悬挂、车架刚度、供弹、摩擦轮与装配验证 |
| [轮腿机器人设计理论报告](docs/wheel-leg-robot-theory.md) | 轮腿（双轮足）机器人的平衡与倒立摆模型、关节电机扭矩推导、并联腿 / 偏置并联构型对比、连杆参数设计与跳跃高度计算 |
| [MATLAB 轮腿机器人计算代码学习日志](docs/wheel-leg-matlab-log.md) | 复刻轮腿机器人 MATLAB 计算过程的学习记录：语法要点、符号推导、雅可比矩阵与关节扭矩、行程计算与线性拟合 |
| [弹簧重补 技术报告](docs/spring-report.md) | 云台弹簧重力补偿的完整资料，含 MATLAB 弹簧选型脚本 |

## 📄 Markdown 预览

- [庆园阁过洞步兵机械设计技术传承手册（在线预览）](docs/tunnel-infantry-manual.md) —— 12 章，含参数表、方案对比表与公式，参考链接可直接点开
- [轮腿机器人设计理论报告（在线预览）](docs/wheel-leg-robot-theory.md) —— 公式为 LaTeX，GitHub 原生渲染
- [MATLAB 轮腿机器人计算代码学习日志（在线预览）](docs/wheel-leg-matlab-log.md) —— MATLAB 代码按源码块排版，可直接对照阅读
- [弹簧重补 技术报告（在线预览）](docs/spring-report.md)

## 🖼 图片

- [庆园阁过洞步兵机械设计技术传承手册插图：images/tunnel-infantry-manual-1.png … images/tunnel-infantry-manual-11.png（共 11 张，从原文档内嵌图片按顺序导出）](images/tunnel-infantry-manual-1.png)
- [轮腿机器人设计理论报告插图：images/wheel-leg-robot-theory-1.png … images/wheel-leg-robot-theory-13.png（共 13 张）](images/wheel-leg-robot-theory-1.png)
- [MATLAB 轮腿机器人计算代码学习日志插图：images/wheel-leg-matlab-log-1.png（共 1 张）](images/wheel-leg-matlab-log-1.png)
- [弹簧重补 技术报告插图：images/spring-report-1.png … images/spring-report-13.png（共 13 张）](images/spring-report-1.png)

图片目录：`images/`，正文里用相对路径 `../images/…` 引用，预览页直接显示。

## 📦 原文件下载

- [庆园阁过洞步兵机械设计技术传承手册.docx（Word 原件）](originals/tunnel-infantry-manual.docx)
- [轮腿机器人设计理论报告.docx（Word 原件）](originals/wheel-leg-robot-theory.docx)
- [MATLAB 轮腿机器人计算代码学习日志.docx（Word 原件）](originals/wheel-leg-matlab-log.docx)
- [弹簧重补 技术报告.docx（Word 原件）](originals/spring-report.docx)

打开后点右上角 Download 即可下载。

## 💻 源码

- [spring_pianlong.m（MATLAB 弹簧选型脚本）](code/spring_pianlong.m) —— 在 MATLAB 里直接打开运行，改 l1 / l2 后重跑即可；输出内径 5–10 mm、形变量 ≥100 mm 的候选弹簧
- [腿（MATLAB 串联腿计算）](code/腿) —— 用符号计算求 C 点坐标与 k 的关系：先画圆法列 C 点方程，再取物理可行解；改 k / l1 / l2 后重跑即可

## 目录说明

| 目录 | 内容 | 用途 |
|---|---|---|
| `docs/` | `*.md` | 可直接在 GitHub 上预览的 Markdown 正文（公式用 LaTeX，代码用源码块） |
| `images/` | 正文引用的图片 | 文档插图，使用相对路径 `../images/` 引用 |
| `originals/` | `*.docx` | Word 原件，供下载 |
| `code/` | `.m` 源码 | MATLAB 脚本，可直接运行 |

文档中的图片使用相对路径引用，在 GitHub 预览页会直接渲染；如需原始文件，请到 `originals/` 下载，代码到 `code/` 获取。

