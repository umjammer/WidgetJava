#!/usr/bin/env zsh -f

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export MAVEN_OPTS="-Djansi.passthrough=true -Dstyle.color=never $MAVEN_OPTS"

MY_HOME=/Users/nsano
export HOME="${MY_HOME}"

echo "=== WidgetJava ==="
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Host: $(hostname -s)"
echo "Uptime: $(uptime | sed 's/.*up \([^,]*\),.*/\1/')"
if command -v java >/dev/null 2>&1; then
  echo "Java: $(java -version 2>&1 | head -n 1)"
fi
