# 手动配置参考

不想跑 `install.sh` 时，按这里拼配置。三处改动，缺一不可 —— 少任何一处都表现为「列在，但内容全空」或「列不存在」。

改之前**先关掉 DC**（`pkill -x doublecmd`）。DC 退出时会用内存状态整体重写这些文件，运行中改的会被覆盖。

## 1. Lua 库路径（漏了插件不加载）

`doublecmd.xml` 根节点下：

```xml
<Lua>
  <PathToLibrary>/usr/lib/liblua5.1.so.5.1</PathToLibrary>
</Lua>
```

路径按发行版换：

| 发行版 | 路径 |
|---|---|
| Arch / CachyOS（`lua51` 包） | `/usr/lib/liblua5.1.so.5.1` |
| Debian / Ubuntu（`liblua5.1-0`） | `/usr/lib/x86_64-linux-gnu/liblua5.1.so.0` |

从 Windows 抄来的配置这里常常是 `lua5.1.dll`，Linux 上 dlopen 失败，插件静默不加载 —— 这是最常见的原因。

## 2. 注册插件

`doublecmd.xml` → `<Plugins>` → `<WdxPlugins>` 里加：

```xml
<WdxPlugin>
  <Name>folderyaml</Name>
  <Path>/home/你的用户名/.config/doublecmd/plugins/folderyaml.wdx.lua</Path>
  <DetectString>EXT="*"</DetectString>
</WdxPlugin>
```

`<Path>` 用绝对路径，`~` 不会被展开。

## 3. 列集

`doublecmd.xml` → `<ColumnsSets>` 里加（`CustomView=True` 才能用自定义字体和每列颜色）：

```xml
<ColumnsSet UseFrameCursor="False">
  <Name>描述视图</Name>
  <Unique>8F2B7C41-5D6E-4A93-9B18-3C7D2E5A4F60</Unique>
  <CustomView>True</CustomView>
  <FileSystem>&lt;General&gt;</FileSystem>
  <PixelsPerInch>96</PixelsPerInch>
  <CursorBorder Enabled="False"/>
  <Columns>
    <Column>
      <Title>名称</Title>
      <Unique>EB7B0A91-09E4-4D5E-9942-3AEB00758D3A</Unique>
      <FuncString>[DC().GETFILENAME{}]</FuncString>
      <Width>460</Width>
      <Align>0</Align>
      <Font><Name>default</Name><Size>9</Size><Style>0</Style><Quality>0</Quality></Font>
      <UseInvertedSelection>False</UseInvertedSelection>
      <UseInactiveSelColor>False</UseInactiveSelColor>
      <Overcolor>True</Overcolor>
    </Column>
    <Column>
      <Title>描述</Title>
      <Unique>7C1E4A52-9D3B-4F81-B0C7-2E5A6D9F3B14</Unique>
      <FuncString>[PLUGIN(folderyaml).Desc{}]</FuncString>
      <Width>500</Width>
      <Align>0</Align>
      <Font><Name>default</Name><Size>9</Size><Style>0</Style><Quality>0</Quality></Font>
      <UseInvertedSelection>False</UseInvertedSelection>
      <UseInactiveSelColor>False</UseInactiveSelColor>
      <Overcolor>True</Overcolor>
    </Column>
  </Columns>
</ColumnsSet>
```

**两个 `<Unique>` 不要改。** 列颜色在 `colors.json` 里靠这两个 GUID 绑定，改了配色就断链（列还在，只是变回默认色）。

## 4. 描述列的灰色

颜色**不在** `doublecmd.xml` 里，而在 `colors.json` 的 `Styles → ColumnSets → Columns`，Light 和 Dark 各写一份：

```json
{
  Unique : "8F2B7C41-5D6E-4A93-9B18-3C7D2E5A4F60",
  Name : "描述视图",
  CursorBorderColor : 0,
  Columns : [
    { Unique : "EB7B0A91-09E4-4D5E-9942-3AEB00758D3A", Title : "名称", TextColor : 0, ... },
    { Unique : "7C1E4A52-9D3B-4F81-B0C7-2E5A6D9F3B14", Title : "描述", TextColor : 10132122, ... }
  ]
}
```

- TColor 是 `0x00BBGGRR` 整数。灰色三个通道相同，直接写十进制：Light `8421504`（#808080），Dark `10132122`（#9A9A9A）
- `TextColor: 0` 表示「跟随面板默认前景色」
- 其余字段（Background / MarkColor / CursorColor …）从同一套里的「名称」列复制一份最省事
- `colors.json` 是「无引号键」的类 JSON，改坏 DC 启动直接崩。改完先自己解析一遍：给行首键补引号 → `json.loads`，能过再启动

## 5. 让标签页默认用这套列集（可选）

`tabs.xml` 里每个标签页：

```xml
<ColumnsSet>描述视图</ColumnsSet>
```

不设也行，启动后右键列头手动切一次，DC 会记住。

## 排错

| 现象 | 原因 |
|---|---|
| 列在，内容全空 | `<Lua><PathToLibrary>` 不对，插件没加载 |
| 没有「描述视图」可选 | 列集没写进 `<ColumnsSets>`，或 DC 运行中被覆盖了 |
| 描述有内容但没变灰 | `colors.json` 里 GUID 对不上，或改在了运行中的文件上 |
| DC 启动直接退出 | `colors.json` 被改坏（日志里 `EJSONParser ... Expected comma`），从备份恢复 |
