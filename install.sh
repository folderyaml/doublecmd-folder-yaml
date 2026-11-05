#!/usr/bin/env bash
# doublecmd-folder-yaml —— 给 Double Commander 加一列「描述」，内容来自 .folder.yaml
#
#   bash install.sh              # 安装（默认动作）
#   bash install.sh --check      # 只体检，不改任何文件
#   bash install.sh --uninstall  # 卸载（删插件、删列集、删配色）
#
# 环境变量 DC_CFG 可指定别的配置目录（试跑用）。
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTION="${1:---install}"

case "$ACTION" in
  --check|--install|--uninstall|-h|--help) ;;
  *) echo "用法: bash install.sh [--check|--uninstall]"; exit 2 ;;
esac

if [ "$ACTION" = "-h" ] || [ "$ACTION" = "--help" ]; then
  sed -n '2,9p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
fi

# ---------- 找 DC 配置目录 ----------
find_cfg() {
  if [ -n "${DC_CFG:-}" ]; then echo "$DC_CFG"; return; fi
  for d in "${XDG_CONFIG_HOME:-$HOME/.config}/doublecmd" "$HOME/.config/doublecmd"; do
    [ -f "$d/doublecmd.xml" ] && { echo "$d"; return; }
  done
  echo ""
}

CFG="$(find_cfg)"

# ---------- 找 Lua 5.1 ----------
find_lua() {
  for p in /usr/lib/liblua5.1.so.5.1 /usr/lib/liblua5.1.so.0 \
           /usr/lib/x86_64-linux-gnu/liblua5.1.so.0 /usr/lib/liblua5.1.so \
           /usr/lib64/liblua5.1.so.0 /usr/local/lib/liblua5.1.so; do
    [ -e "$p" ] && { echo "$p"; return; }
  done
  echo ""
}
LUALIB="$(find_lua)"

# ---------- 体检 ----------
if [ "$ACTION" = "--check" ]; then
  say() { printf '· %s：%s\n' "$1" "$2"; }
  echo "== 体检 =="
  say "DC 可执行文件" "$(command -v doublecmd || echo '未找到（不在 PATH，可能只装了桌面项）')"
  say "配置目录" "${CFG:-未找到 ~/.config/doublecmd/doublecmd.xml}"
  if [ -e /opt/doublecmd/doublecmd.cfg ] || [ -e /opt/doublecmd/settings/doublecmd.inf ]; then
    say "便携模式标记" "存在！DC 可能把配置写到 /opt/doublecmd/settings，本脚本改的配置不会生效"
  else
    say "便携模式标记" "无（正常）"
  fi
  say "Lua 5.1 库" "${LUALIB:-未找到 —— 插件不会加载（Arch: pacman -S lua51 / Debian: apt install liblua5.1-0）}"
  if [ -n "$CFG" ] && [ -f "$CFG/doublecmd.xml" ]; then
    grep -q "folderyaml.wdx.lua" "$CFG/doublecmd.xml" && say "插件注册" "已注册" || say "插件注册" "未注册"
    grep -q "8F2B7C41-5D6E-4A93-9B18-3C7D2E5A4F60" "$CFG/doublecmd.xml" \
      && say "列集「描述视图」" "已存在" || say "列集「描述视图」" "不存在"
    [ -f "$CFG/plugins/folderyaml.wdx.lua" ] && say "插件文件" "已就位" || say "插件文件" "缺失"
  fi
  exit 0
fi

# ---------- 前置检查 ----------
if [ -z "$CFG" ] || [ ! -f "$CFG/doublecmd.xml" ]; then
  echo "找不到 Double Commander 配置（\$XDG_CONFIG_HOME/doublecmd/doublecmd.xml）。"
  echo "先启动一次 DC 让它生成配置，或用 DC_CFG=<目录> 指定。"
  exit 1
fi

if [ -e /opt/doublecmd/doublecmd.cfg ] || [ -e /opt/doublecmd/settings/doublecmd.inf ]; then
  echo "警告：检测到便携版标记（/opt/doublecmd/settings 或 doublecmd.cfg）。"
  echo "      便携版 DC 会把配置写在程序目录，本脚本改的 $CFG 不会生效。"
  echo "      删掉那两个标记文件后 DC 才用 ~/.config/doublecmd。"
fi

if pgrep -x doublecmd >/dev/null 2>&1; then
  echo "警告：Double Commander 正在运行。它退出时会用内存状态覆盖配置，"
  echo "      请先 pkill -x doublecmd 再执行本脚本，否则改动会丢。"
  exit 1
fi

# ---------- 备份 ----------
STAMP="$(date +%Y%m%d-%H%M%S)"
BK="$CFG/backup-folder-yaml-$STAMP"
mkdir -p "$BK"
for f in doublecmd.xml colors.json tabs.xml; do
  [ -f "$CFG/$f" ] && cp "$CFG/$f" "$BK/"
done

# ---------- 卸载 ----------
if [ "$ACTION" = "--uninstall" ]; then
  python3 - "$CFG" uninstall <<'PY'
import json, os, re, sys
cfg, mode = sys.argv[1], sys.argv[2]
SET_UNIQUE = "8F2B7C41-5D6E-4A93-9B18-3C7D2E5A4F60"

p = os.path.join(cfg, "doublecmd.xml")
x = open(p, encoding="utf-8").read()
x = re.sub(r'[ \t]*<ColumnsSet UseFrameCursor="False">\s*<Name>描述视图</Name>.*?</ColumnsSet>\n', '', x, flags=re.S)
x = re.sub(r'[ \t]*<WdxPlugin>\s*<Name>folderyaml</Name>.*?</WdxPlugin>\n', '', x, flags=re.S)
open(p, "w", encoding="utf-8").write(x)
print("doublecmd.xml: 已移除列集与插件注册（<Lua> 节点保留，无害）")

p = os.path.join(cfg, "colors.json")
if os.path.exists(p):
    s = open(p, encoding="utf-8").read()
    t = re.sub(r'(?m)^(\s*)([A-Za-z_]\w*)\s*:', r'\1"\2":', s)
    t = re.sub(r',(\s*[\]\}])', r'\1', t)
    data = json.loads(t)
    n = 0
    for st in data.get("Styles", []):
        before = len(st.get("ColumnSets", []))
        st["ColumnSets"] = [cs for cs in st.get("ColumnSets", []) if cs.get("Unique") != SET_UNIQUE]
        n += before - len(st["ColumnSets"])
    open(p, "w", encoding="utf-8").write(json.dumps(data, ensure_ascii=False, indent=2))
    print("colors.json: 已移除 %d 条列集配色" % n)

pl = os.path.join(cfg, "plugins", "folderyaml.wdx.lua")
if os.path.exists(pl):
    os.remove(pl)
    print("已删除插件文件")
PY
  echo "卸载完成。备份留在 $BK"
  exit 0
fi

# ---------- 安装 ----------
mkdir -p "$CFG/plugins"
cp "$SELF_DIR/plugin/folderyaml.wdx.lua" "$CFG/plugins/folderyaml.wdx.lua"

if [ -z "$LUALIB" ]; then
  echo "警告：没找到 liblua5.1，插件不会加载。"
  echo "      Arch: pacman -S lua51   Debian/Ubuntu: apt install liblua5.1-0"
  LUALIB="/usr/lib/liblua5.1.so.0"
fi

python3 - "$CFG" "$LUALIB" <<'PY'
import json, os, re, sys
cfg, lualib = sys.argv[1], sys.argv[2]

SET_NAME    = "描述视图"
SET_UNIQUE  = "8F2B7C41-5D6E-4A93-9B18-3C7D2E5A4F60"
COL_UNIQUE  = "7C1E4A52-9D3B-4F81-B0C7-2E5A6D9F3B14"
NAME_UNIQUE = "EB7B0A91-09E4-4D5E-9942-3AEB00758D3A"
DEFAULT_SET = "36DC580F-B38E-4AF8-8929-D6DFB2DB424B"

COL_SET = f'''    <ColumnsSet UseFrameCursor="False">
      <Name>{SET_NAME}</Name>
      <Unique>{SET_UNIQUE}</Unique>
      <CustomView>True</CustomView>
      <FileSystem>&lt;General&gt;</FileSystem>
      <PixelsPerInch>96</PixelsPerInch>
      <CursorBorder Enabled="False"/>
      <Columns>
        <Column>
          <Title>名称</Title>
          <Unique>{NAME_UNIQUE}</Unique>
          <FuncString>[DC().GETFILENAME{{}}]</FuncString>
          <Width>460</Width>
          <Align>0</Align>
          <Font>
            <Name>default</Name>
            <Size>9</Size>
            <Style>0</Style>
            <Quality>0</Quality>
          </Font>
          <UseInvertedSelection>False</UseInvertedSelection>
          <UseInactiveSelColor>False</UseInactiveSelColor>
          <Overcolor>True</Overcolor>
        </Column>
        <Column>
          <Title>描述</Title>
          <Unique>{COL_UNIQUE}</Unique>
          <FuncString>[PLUGIN(folderyaml).Desc{{}}]</FuncString>
          <Width>500</Width>
          <Align>0</Align>
          <Font>
            <Name>default</Name>
            <Size>9</Size>
            <Style>0</Style>
            <Quality>0</Quality>
          </Font>
          <UseInvertedSelection>False</UseInvertedSelection>
          <UseInactiveSelColor>False</UseInactiveSelColor>
          <Overcolor>True</Overcolor>
        </Column>
      </Columns>
    </ColumnsSet>'''

# ---------- doublecmd.xml ----------
p = os.path.join(cfg, "doublecmd.xml")
x = open(p, encoding="utf-8").read()
did = []

if SET_UNIQUE not in x:
    if "</ColumnsSets>" not in x:
        print("错误：doublecmd.xml 里没有 <ColumnsSets>，DC 版本可能太旧"); sys.exit(1)
    x = x.replace("  </ColumnsSets>", COL_SET + "\n  </ColumnsSets>")
    did.append("列集")

if "<PathToLibrary>" in x:
    x = re.sub(r"<PathToLibrary>.*?</PathToLibrary>", f"<PathToLibrary>{lualib}</PathToLibrary>", x, count=1)
    did.append("Lua 库路径(更新)")
else:
    x = x.replace("  <Toolbars>", f"  <Lua>\n    <PathToLibrary>{lualib}</PathToLibrary>\n  </Lua>\n  <Toolbars>", 1)
    did.append("Lua 库路径")

if "folderyaml.wdx.lua" not in x:
    plug = f'''      <WdxPlugin>
        <Name>folderyaml</Name>
        <Path>{cfg}/plugins/folderyaml.wdx.lua</Path>
        <DetectString>EXT="*"</DetectString>
      </WdxPlugin>
'''
    x = x.replace("    </WdxPlugins>", plug + "    </WdxPlugins>")
    did.append("插件注册")

open(p, "w", encoding="utf-8").write(x)
print("doublecmd.xml:", "、".join(did) or "无改动")

# ---------- colors.json ----------
p = os.path.join(cfg, "colors.json")
if not os.path.exists(p):
    print("colors.json 不存在，跳过（描述列跟随面板默认颜色）")
else:
    s = open(p, encoding="utf-8").read()
    t = re.sub(r'(?m)^(\s*)([A-Za-z_]\w*)\s*:', r'\1"\2":', s)
    t = re.sub(r',(\s*[\]\}])', r'\1', t)
    data = json.loads(t)

    grays = {0: 8421504, 1: 10132122}   # Light #808080 / Dark #9A9A9A
    touched = []
    for i, style in enumerate(data.get("Styles", [])):
        sets = style.setdefault("ColumnSets", [])
        if any(cs.get("Unique") == SET_UNIQUE for cs in sets):
            continue
        default = next((cs for cs in sets if cs.get("Unique") == DEFAULT_SET), None)
        if not default:
            continue
        base = next((c for c in default.get("Columns", []) if c.get("Unique") == NAME_UNIQUE), None)
        if not base:
            continue
        name_col = dict(base)
        desc_col = dict(base)
        desc_col["Unique"] = COL_UNIQUE
        desc_col["Title"] = "描述"
        desc_col["TextColor"] = grays.get(i, 10132122)
        newset = dict(default)
        newset["Unique"] = SET_UNIQUE
        newset["Name"] = SET_NAME
        newset["Columns"] = [name_col, desc_col]
        sets.append(newset)
        touched.append(style.get("Name", str(i)))

    if touched:
        open(p, "w", encoding="utf-8").write(json.dumps(data, ensure_ascii=False, indent=2))
        print("colors.json: 已写入描述列灰色（%s）" % "、".join(touched))
    else:
        print("colors.json: 配色已存在，跳过")
PY

echo
echo "装好了。下一步："
echo "  1. 启动 DC：doublecmd &"
echo "  2. 右键点列头 → 自定义列 → 选「描述视图」"
echo "  3. 体检：bash install.sh --check"
echo "备份：$BK"
