<div align="center">

# EMHentai

**一个简易、小巧、快速、纯 Swift 的 E-Hentai iOS 客户端**

[![Swift](https://img.shields.io/badge/Swift-5-orange.svg?style=flat)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue.svg?style=flat)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat)](LICENSE)

[English](README.md)

</div>

---

## 功能

| 分类 | 详情 |
|------|------|
| **浏览** | 查看 E-Hentai 本子，E-Hentai / ExHentai 切换 |
| **搜索** | 高级搜索（按语言、评分、分类等），相关 Tag 搜索 |
| **管理** | 历史记录，下载管理，后台下载 |
| **扩展** | Tag 翻译，分享功能，支持过滤 AI / 猎奇向内容 |
| **登录** | 账号密码登录，Cookie 登录 |
| **适配** | iPhone & iPad，暗黑模式，横竖屏，中英双语，iOS 17 ~ 26 |

## 预览图

<p align="center">
<img src="https://github.com/yuman07/EMHentai/blob/main/Screenshots/IMG_1136.PNG?raw=true" width="200"/>
&nbsp;&nbsp;
<img src="https://github.com/yuman07/EMHentai/blob/main/Screenshots/IMG_1140.PNG?raw=true" width="200"/>
&nbsp;&nbsp;
<img src="https://github.com/yuman07/EMHentai/blob/main/Screenshots/IMG_1139.PNG?raw=true" width="200"/>
</p>

<p align="center">
<img src="https://github.com/yuman07/EMHentai/blob/main/Screenshots/IMG_1142.PNG?raw=true" width="200"/>
&nbsp;&nbsp;
<img src="https://github.com/yuman07/EMHentai/blob/main/Screenshots/IMG_1138.PNG?raw=true" width="200"/>
&nbsp;&nbsp;
<img src="https://github.com/yuman07/EMHentai/blob/main/Screenshots/IMG_1143.PNG?raw=true" width="200"/>
</p>

<p align="center"><sub>更多预览图请查看 <a href="Screenshots/">Screenshots</a> 文件夹</sub></p>

## 安装

> 考虑到 E-Hentai 的法律风险，不直接提供 IPA 安装包。

**环境要求：** macOS（最新版）+ Xcode（最新版）+ iPhone / iPad（iOS >= 17.0）

```bash
git clone https://github.com/yuman07/EMHentai.git
open EMHentai/EMHenTai.xcodeproj
# 按 ⌘R 运行即可，无需付费开发者账号
```

## 常见问题

**Q：为什么我网页登录成功了，但 APP 中仍显示未登录？**

A：这是因为 EH 会对频繁登录的 IP 拒绝访问，可以通过切换节点（推荐使用欧美 IP）然后再次登录。

## 参与贡献

本项目**长期维护**，欢迎提 PR 或建议！

有任何 BUG、功能需求或代码问题，欢迎提 [Issue](https://github.com/yuman07/EMHentai/issues) —— **保证 24 小时内回复**。

## 致谢

- 部分 UI 设计参考了 [@Dai-Hentai](https://github.com/DaidoujiChen/Dai-Hentai)
- Tag 翻译使用了 [@EhTagTranslation](https://github.com/EhTagTranslation/Database)

## 许可证

本项目基于 [MIT License](LICENSE) 开源。
