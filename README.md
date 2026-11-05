# doublecmd-folder-yaml

让 [Double Commander](https://doublecmd.sourceforge.io/) 多出一列「描述」：直接读每个文件夹里的 `.folder.yaml`，把说明显示在文件列表里。文件名和路径完全不动。

和 [nautilus-folder-yaml](https://github.com/folderyaml/nautilus-folder-yaml) 消费同一份元数据 —— 同一棵树，在 GNOME Files 和 Double Commander 里看到的是同一批描述。

## 效果

```
名称                          描述
..                            
.folder.yaml                  
notes                         一切写成字的东西。判断按「验证过没有」分，不按主题分
works                         工作台。前四类按产出归属分（自己的、别人的、纯研究、随…
```

- 文件夹 → 读它自己 `.folder.yaml` 的 `desc`
- 文件 → 读父目录 `.folder.yaml` 里 `file-desc` 的对应条目
- 没有描述的条目就是空白，不会报错
- 描述用灰色显示，和文件名区分开（Light / Dark 主题各一套灰）

## 它由两部分组成

| 部分 | 是什么 | 负责 |
|---|---|---|
| `plugin/folderyaml.wdx.lua` | 真的 DC 插件（WDX 内容字段插件，Lua 写） | 给每个文件/文件夹算出一行描述 |
| 「描述视图」列集 | 纯配置（`doublecmd.xml` + `colors.json`） | 名称 + 描述两列怎么显示、什么颜色 |

DC 没有「列集插件」这种分发形式，所以列集只能靠脚本写进你的配置 —— 这就是 `install.sh` 存在的原因。

## 依赖

- Double Commander **1.2 以上**（需要 Lua 插件支持）
- Lua 5.1 运行库
  - Arch / CachyOS：`sudo pacman -S lua51`
  - Debian / Ubuntu：`sudo apt install liblua5.1-0`
- `python3`（安装脚本改配置用）

## 安装

### 一键

```bash
git clone https://github.com/folderyaml/doublecmd-folder-yaml.git
cd doublecmd-folder-yaml
bash install.sh
```

脚本做的事：

1. 找到 DC 的配置目录（`$XDG_CONFIG_HOME/doublecmd` 或 `~/.config/doublecmd`）
2. 把 `doublecmd.xml` / `colors.json` / `tabs.xml` 备份到 `backup-folder-yaml-<时间戳>/`
3. 装插件到 `<配置目录>/plugins/folderyaml.wdx.lua`
4. 往 `doublecmd.xml` 加三样：`<Lua>` 库路径、`描述视图` 列集、插件注册
5. 往 `colors.json` 加描述列的灰色（Light / Dark 各一份）

装完启动 DC，**右键点列头 → 自定义列 → 选「描述视图」**。

脚本是幂等的：重复跑不会重复插入；已经装过会提示跳过。

先体检不改文件：

```bash
bash install.sh --check
```

会报：DC 是否在 PATH、配置目录在哪、有没有便携模式标记、Lua 库找没找到、插件和列集是否已就位。

### 只想装插件，用自己现有的列集

不需要那个灰色预设的话，只要两步：

1. 把 `plugin/folderyaml.wdx.lua` 放到 `~/.config/doublecmd/plugins/`
2. 在 `doublecmd.xml` 的 `<WdxPlugins>` 里注册：

```xml
<WdxPlugin>
  <Name>folderyaml</Name>
  <Path>/home/你的用户名/.config/doublecmd/plugins/folderyaml.wdx.lua</Path>
  <DetectString>EXT="*"</DetectString>
</WdxPlugin>
```

然后在任意自定义列集的列内容里写：

```
[PLUGIN(folderyaml).Desc{}]
```

### 手动配置

不想跑脚本、想自己拼列集和配色：见 [`docs/columns.md`](docs/columns.md)，里面有可复制的 XML / JSON 片段和 GUID 说明。

## 使用

- **切换列集**：右键列头 → 自定义列 → 选「描述视图」；切回别的视图同理
- **调列宽**：拖动列头分隔线，DC 会记住
- **改字号**：配置 → 选项 → 文件视图 → 列 → 选「描述视图」→ 改字体大小
- **改颜色**：配置 → 选项 → 颜色 → 文件面板，或直接改 `colors.json` 里描述列的 `TextColor`
- **加回大小/日期列**：配置 → 选项 → 文件视图 → 列 → 添加列

## 限制

**Ctrl+滚轮缩放对这套列集无效。** DC 的机制：自定义列集里每列字体是固定值，而 Ctrl+滚轮只改主字体（`DoMainFontZoom` 只动 `gFonts[dcfMain]`）。想要滚轮就得放弃自定义列集，也就没有描述列和灰色。二者只能选一个，配置改不出来。

其他：

- 描述过长会被列宽截断，DC 不支持单元格换行
- 描述和名称必须分两列才能不同颜色（单元格不支持一段文字两种颜色）
- Windows 上理论上能跑（DC 跨平台），但没测过：Lua 库路径、配置目录都不一样，`install.sh` 只处理 Linux
- 不做 AUR 包：列集在用户 `~/.config` 里，包管理器管不到，装了也不会自动生效

## 卸载

```bash
bash install.sh --uninstall
```

会删掉插件文件、插件注册、`描述视图` 列集、`colors.json` 里的对应配色（`<Lua>` 节点保留，无害）。

或者手工：DC 里切回 `Default` 列集，插件留着不影响使用。

## 目录

```
install.sh                 # 安装 / --check / --uninstall
plugin/folderyaml.wdx.lua  # WDX 插件本体
docs/columns.md            # 手动配置片段
```

## 许可

MIT
