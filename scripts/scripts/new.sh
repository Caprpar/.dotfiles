touch "$(date +'%Y-%m-%d')".md

echo "# $(date +'%Y-%m-%d')" >>"<!-- markdownlint-disable MD013 -->".md
echo "# $(date +'%Y-%m-%d')" >>"$(date +'%Y-%m-%d')".md

nvim "$(date +'%Y-%m-%d')".md
