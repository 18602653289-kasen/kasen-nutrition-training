#!/bin/sh
# ============================================================
# title-sync.sh — 专题标题同步脚本
# 
# 用法: sh title-sync.sh
# 
# 从 SYNC.md 读取专题名称，同步到所有关联文件
# 先编辑 SYNC.md 中的「专题名称」，再运行本脚本
# ============================================================

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR" || exit 1

# ── 从 SYNC.md 解析元数据 ──
TOPIC_TITLE=$(grep -E '^\| \*\*专题名称\*\*' SYNC.md | sed 's/.*| //' | sed 's/ |$//')
TOPIC_SHORT=$(grep -E '^\| \*\*简称（文件名用）\*\*' SYNC.md | sed 's/.*| //' | sed 's/ |$//')

if [ -z "$TOPIC_TITLE" ]; then
  echo "❌ 无法从 SYNC.md 读取专题名称"
  echo "   请检查 SYNC.md 中「专题名称」行的格式"
  exit 1
fi

echo "🔄 开始同步标题…"
echo "   专题名称: $TOPIC_TITLE"
echo "   文件简称: $TOPIC_SHORT"
echo ""

# ── 1. README.md ──
README_TITLE="🧬 $TOPIC_TITLE"
if grep -q "^# 🧬" README.md 2>/dev/null; then
  sed -i '' "1s/^# 🧬 .*/# $README_TITLE/" README.md
  echo "✅ README.md — 标题已更新"
else
  echo "⚠️  README.md — 未找到 # 🧬 标题行，跳过"
fi

# ── 2. HTML 学习手册 ──
HTML_FILE="${TOPIC_SHORT}.html"
# 尝试精确文件名匹配（可能包含特殊字符）
MATCHED_HTML=$(ls *.html 2>/dev/null | grep -v "index\.html" | grep -v "\._")
if [ -n "$MATCHED_HTML" ]; then
  HTML_FILE="$MATCHED_HTML"
fi

if [ -f "$HTML_FILE" ]; then
  # Update <title>
  sed -i '' "s|<title>[^<]*</title>|<title>$TOPIC_TITLE</title>|" "$HTML_FILE"
  # Update <h1>
  sed -i '' "s|<h1>[^<]*</h1>|<h1>$TOPIC_TITLE</h1>|" "$HTML_FILE"
  echo "✅ $HTML_FILE — 标题已更新"
else
  echo "⚠️  未找到 HTML 学习手册文件，跳过"
fi

# ── 3. MD 学习手册 ──
MD_FILE="${TOPIC_SHORT}.md"
MATCHED_MD=$(ls *.md 2>/dev/null | grep -v "README\|SYNC\|index" | grep -v "\._")
if [ -n "$MATCHED_MD" ]; then
  MD_FILE="$MATCHED_MD"
fi

if [ -f "$MD_FILE" ]; then
  # First line is the H1 heading
  sed -i '' "1s/^# 📘 .*/# 📘 $TOPIC_TITLE/" "$MD_FILE"
  echo "✅ $MD_FILE — 标题已更新"
else
  echo "⚠️  未找到 MD 学习手册文件，跳过"
fi

# ── 4. 考试页面 ──
if [ -f "考试/综合考试.html" ]; then
  sed -i '' "s|<title>综合考试 · [^<]*</title>|<title>综合考试 · $TOPIC_TITLE</title>|" "考试/综合考试.html"
  # Update subtitle line (usually the second .sub element)
  sed -i '' "/<div class=\"sub\">[^<]*<\/div>/s|<div class=\"sub\">[^<]*<\/div>|<div class=\"sub\">$TOPIC_TITLE</div>|" "考试/综合考试.html"
  echo "✅ 考试/综合考试.html — 标题已更新"
else
  echo "⚠️  考试/综合考试.html 不存在，跳过"
fi

# ── 5. 学习卡页面 ──
if [ -f "学习卡/index.html" ]; then
  sed -i '' "/<div class=\"sub\">[^<]*<\/div>/s|<div class=\"sub\">[^<]*<\/div>|<div class=\"sub\">$TOPIC_TITLE</div>|" "学习卡/index.html"
  echo "✅ 学习卡/index.html — 标题已更新"
else
  echo "⚠️  学习卡/index.html 不存在，跳过"
fi

# ── 6. 文件名提示 ──
echo ""
echo "📝 注意：文件名不会自动修改（含中文路径）"
echo "   如果需要改名，手动执行："
echo "   mv \"<旧文件名>\" \"$TOPIC_SHORT.md\""
echo "   mv \"<旧文件名>\" \"$TOPIC_SHORT.html\""
echo ""
echo "✅ 同步完成"
