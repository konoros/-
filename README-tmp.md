# 作品资料

本仓库按**用途分类**存放比赛申报材料。

## 📄 Markdown 预览

- [大概思路（在线预览）](docs/idea.md)
- [弹簧重补 技术报告（在线预览）](docs/spring-report.md)

## 🖼 图片

- 图片目录：[images/](images/)
- [作品原型照片](images/robot-prototype.jpg)
- 弹簧重补报告插图：`images/spring-report-1.png` … `images/spring-report-13.png`（共 13 张，从原文档内嵌图片按顺序导出）

## 📦 原文件下载

- [大概思路？.docx（Word 原件）](originals/idea.docx)
- [弹簧重补 技术报告.docx（Word 原件）](originals/spring-report.docx)

## 💻 源码

- [spring_pianlong.m（MATLAB 弹簧选型脚本）](code/spring_pianlong.m) —— 在 MATLAB 里直接打开运行，改 `l1` / `l2` 后重跑即可；输出内径 5–10 mm、形变量 ≥100 mm 的候选弹簧

---

### 目录说明

| 目录 | 内容 | 用途 |
|---|---|---|
| `docs/` | `idea.md`、`spring-report.md` | 可直接在 GitHub 上预览的 Markdown 正文（公式用 LaTeX，GitHub 原生渲染） |
| `images/` | 正文引用的图片 | 文档插图，使用相对路径 `../images/` 引用 |
| `originals/` | 对应 Word 原件 | 打开后点右上角 **Download** 下载 |
| `code/` | `spring_pianlong.m` | MATLAB 源码，可直接运行 |

> 文档中的图片使用相对路径引用，在 GitHub 预览页会直接渲染；如需原始文件，请到 `originals/` 下载，代码到 `code/` 获取。
