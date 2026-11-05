# doublecmd-folder-yaml 项目指南

Double Commander 的「描述」列：一个 Lua 写的 WDX 插件负责取数，一套列集配置负责显示。

**核心事实：DC 没有「列集插件」这种分发形式。** 插件能单独分发，列集只能写进用户的 `doublecmd.xml` / `colors.json`。所以这个仓库是「插件 + 安装器」，不是纯插件。

## 开工前必读

1. 加载 `doublecmd-customization` skill —— DC 配置的机制、坑、验证方法都在那儿
2. `docs/columns.md` —— 手动配置片段，也是安装器写出来的东西
3. 改配置前先 `pkill -x doublecmd`（它退出时会用内存状态覆盖配置文件）

## 结构

| 路径 | 作用 |
|---|---|
| `plugin/folderyaml.wdx.lua` | WDX 插件本体，纯 Lua，无依赖 |
| `install.sh` | 安装 / `--check` / `--uninstall`，幂等 |
| `docs/columns.md` | 手动配置与排错表 |

## 命令

```bash
bash install.sh --check        # 体检，不改文件
DC_CFG=/tmp/test bash install.sh   # 装到临时配置目录试跑
bash install.sh --uninstall
```

改动 install.sh 后必须至少跑一遍 `--check` + 试装到 `DC_CFG=<临时目录>`，确认 XML 合法、JSON 可解析。

## 约定

- 列集 GUID `8F2B7C41-…` 和列 GUID `7C1E4A52-…` **不许改**：`colors.json` 靠它们绑定颜色
- 插件字段名固定为 `Desc`，列内容写 `[PLUGIN(folderyaml).Desc{}]`
- 安装器只碰 `doublecmd.xml` / `colors.json` / `tabs.xml` 三个文件，且每次都先备份
- 不打包 AUR：配置在用户 home，包管理器管不到

## 已知限制（改代码前先读）

- 自定义列集（`CustomView=True`）下 Ctrl+滚轮缩放无效，这是 DC 机制，不是 bug。想要缩放就得放弃每列颜色和插件列
- 描述超长会被列宽截断，DC 不支持单元格换行
- 单元格不支持一段文字两种颜色，所以描述必须独立成列
- Windows 未测试

## 提交

- 只提交必要文件；`.folder.yaml` 的 `desc` 与 GitHub 仓库描述保持一致
- 一个可交付的改动提交并推送一次
