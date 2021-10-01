#!/usr/bin/env bash
set -e

# check if there are any changes in spec in the latest commit
if git diff --name-only --exit-code HEAD~1 HEAD 'spec/*.json' >> /dev/null; then
  echo "no changes in spec detected, skipping publishing spec"
  exit 0
fi

# "mangle" name to not overwrite for someone running locally
WEBSITE_DIR=${WEBSITE_DIR:-$HOME/website-123412}

if [[ -d $WEBSITE_DIR ]]; then
  echo "deleting $WEBSITE_DIR"
  rm -rf $WEBSITE_DIR
fi

git clone --depth 1 git@github.com:OpenLineage/OpenLineage.github.io $WEBSITE_DIR

git diff --name-only HEAD~1 HEAD 'spec/*.json' | while read LINE; do
  # extract target file name from $id field in spec files
  URL=$(cat $LINE | jq -r '.["$id"]')

  # extract target location in website repo
  LOC="${WEBSITE_DIR}/${URL#*//*/}"
  LOC_DIR="${LOC%/*}"

  # create dir if necessary, and copy files
  mkdir -p $LOC_DIR
  cp $LINE $LOC
  echo
done

# commit new spec and push
git --git-dir "$WEBSITE_DIR/.git" --work-tree "$WEBSITE_DIR" add -A spec/
git --git-dir "$WEBSITE_DIR/.git" --work-tree "$WEBSITE_DIR" commit -m "openlineage specification update"
git --git-dir "$WEBSITE_DIR/.git" --work-tree "$WEBSITE_DIR" push
