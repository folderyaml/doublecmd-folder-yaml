-- Double Commander WDX 插件：从 .folder.yaml 读取描述
-- 字段 Desc：文件夹 → 自己 .folder.yaml 的 desc；文件 → 父目录 .folder.yaml 的 file-desc[文件名]

function ContentGetSupportedField(Index)
  if Index > 0 then
    return '', '', 0; -- ft_nomorefields
  end
  return 'Desc', '', 8; -- FieldName, Units, ft_string
end

function ContentGetDefaultSortOrder(FieldIndex)
  return 1;
end

function ContentGetDetectString()
  return 'EXT="*"';
end

local function read_file(path)
  local f = io.open(path, 'r');
  if not f then return nil end
  local s = f:read('*a');
  f:close();
  return s;
end

local function strip_quotes(v)
  if v == nil then return '' end
  v = v:gsub('%s+$', '');
  if #v >= 2 then
    local a = v:sub(1, 1);
    local b = v:sub(-1);
    if (a == '"' and b == '"') or (a == "'" and b == "'") then
      return v:sub(2, -2);
    end
  end
  return v;
end

-- 极简 YAML：只取顶层 desc 与 file-desc 块
local function parse(s)
  local desc = '';
  local fdesc = {};
  local in_fdesc = false;
  for raw in s:gmatch('[^\n]*') do
    local line = raw:gsub('\r$', '');
    if line:match('^%s*$') or line:match('^%s*#') then
      -- 空行 / 注释
    elseif line:match('^%s') then
      if in_fdesc then
        local k, v = line:match('^%s+(.-)%s*:%s*(.*)$');
        if k and k ~= '' then
          k = strip_quotes(k);
          v = strip_quotes(v);
          if v ~= '' then fdesc[k] = v end
        end
      end
    else
      local k, v = line:match('^([^:]-)%s*:%s*(.*)$');
      if k == 'desc' then
        desc = strip_quotes(v);
        in_fdesc = false;
      elseif k == 'file-desc' then
        in_fdesc = true;
      else
        in_fdesc = false;
      end
    end
  end
  return desc, fdesc;
end

local function dirname(p)
  local d = p:match('^(.*)/[^/]*$');
  if d == nil or d == '' then return '/' end
  return d;
end

local function basename(p)
  return p:match('([^/]*)$') or p;
end

function ContentGetValue(FileName, FieldIndex, UnitIndex, flags)
  if FieldIndex ~= 0 then return nil end
  if FileName == nil or FileName == '' then return nil end

  local name = basename(FileName);
  if name == '' or name == '..' or name == '.' then return nil end

  -- 1) 目录：读自己的 .folder.yaml
  local own = read_file(FileName .. '/.folder.yaml');
  if own then
    local d = parse(own);
    if d ~= '' then return d end
  end

  -- 2) 文件 / 无 desc 的目录：读父目录的 file-desc
  local parent = read_file(dirname(FileName) .. '/.folder.yaml');
  if parent then
    local _, fd = parse(parent);
    local v = fd[name];
    if v then return v end
  end

  return nil;
end
