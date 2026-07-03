#!/bin/sh
# ============================================================
# backup.sh — 文件备份与回退工具
# ============================================================
# 用法:
#   sh backup.sh save    创建新备份（自动打时间戳）
#   sh backup.sh list    查看所有备份
#   sh backup.sh restore <时间戳>  从指定备份恢复
#   sh backup.sh diff <时间戳>     对比当前文件与备份的差异
# ============================================================

DIR="$(cd "$(dirname "$(dirname "$0")")" && pwd)"
BACKUP_DIR="$DIR/_backup"
DATE=$(date +%Y%m%d_%H%M%S)

# 需要备份的关键文件（相对路径，用换行分隔）
FILES='
学习平台.html
线上链接.html
内部培训/01-消化系统专题/消化系统（上）— 结构功能与慢病根源.html
内部培训/01-消化系统专题/消化系统（上）— 结构功能与慢病根源.md
内部培训/01-消化系统专题/考试/综合考试.html
内部培训/01-消化系统专题/学习卡/index.html
内部培训/01-消化系统专题/大纲/index.html
考核评分体系/判卷后台.html
考核评分体系/评分规则.md
'

case "$1" in
  save)
    echo "📦 创建备份: $DATE"
    mkdir -p "$BACKUP_DIR/$DATE"
    count=0
    echo "$FILES" | while IFS= read -r f; do
      [ -z "$f" ] && continue
      if [ -f "$DIR/$f" ]; then
        target_dir="$BACKUP_DIR/$DATE/$(dirname "$f")"
        mkdir -p "$target_dir"
        cp "$DIR/$f" "$BACKUP_DIR/$DATE/$f"
        count=$((count + 1))
      fi
    done
    echo "   ✓ $count 个文件已备份"
    # Update latest link
    rm -f "$BACKUP_DIR/latest"
    ln -sf "$DATE" "$BACKUP_DIR/latest"
    echo "   ✓ latest -> $DATE"
    ;;

  list)
    echo "📋 可用备份:"
    echo ""
    for d in $(ls -1t "$BACKUP_DIR" | grep -v latest); do
      file_count=$(find "$BACKUP_DIR/$d" -type f | wc -l | tr -d ' ')
      echo "  $d  （${file_count}个文件）"
    done
    echo ""
    echo "  使用: sh backup.sh restore <时间戳>"
    ;;

  restore)
    if [ -z "$2" ]; then
      echo "❌ 请指定要恢复的备份时间戳"
      echo "   用法: sh backup.sh restore <时间戳>"
      echo "   查看: sh backup.sh list"
      exit 1
    fi
    RESTORE="$BACKUP_DIR/$2"
    if [ ! -d "$RESTORE" ]; then
      echo "❌ 备份不存在: $2"
      echo "   查看: sh backup.sh list"
      exit 1
    fi
    echo "🔄 从 $2 恢复..."
    count=0
    echo "$FILES" | while IFS= read -r f; do
      [ -z "$f" ] && continue
      if [ -f "$RESTORE/$f" ]; then
        DATE_BEFORE=$(date +%Y%m%d_%H%M%S)
        mkdir -p "$BACKUP_DIR/_auto_$DATE_BEFORE/$(dirname "$f")"
        cp "$DIR/$f" "$BACKUP_DIR/_auto_$DATE_BEFORE/$f"
        cp "$RESTORE/$f" "$DIR/$f"
        count=$((count + 1))
      fi
    done
    echo "   ✓ $count 个文件已恢复"
    echo "   ⚠️  恢复前已自动存档到 _auto_$DATE_BEFORE"
    echo "   ⚠️  恢复到 GitHub 需运行: cd $DIR && git add -A && git commit -m \"Rollback to $2\" && git push"
    ;;

  diff)
    if [ -z "$2" ]; then
      echo "❌ 请指定要对比的备份时间戳"
      exit 1
    fi
    DIFF="$BACKUP_DIR/$2"
    if [ ! -d "$DIFF" ]; then
      echo "❌ 备份不存在: $2"
      exit 1
    fi
    echo "📊 对比 $2 与当前文件:"
    echo ""
    echo "$FILES" | while IFS= read -r f; do
      [ -z "$f" ] && continue
      if [ -f "$DIFF/$f" ] && [ -f "$DIR/$f" ]; then
        if ! diff -q "$DIFF/$f" "$DIR/$f" > /dev/null 2>&1; then
          echo "  ⚠️  $f  — 已修改"
        fi
      fi
    done
    ;;

  *)
    echo "Kasen Nutrition · 文件备份与回退工具"
    echo ""
    echo "用法:"
    echo "  sh backup.sh save               创建新备份"
    echo "  sh backup.sh list               查看所有备份"
    echo "  sh backup.sh restore <时间戳>    从备份恢复"
    echo "  sh backup.sh diff <时间戳>       对比当前文件与备份"
    echo ""
    echo "备份目录: $BACKUP_DIR"
    ;;
esac
