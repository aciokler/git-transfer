
function processArguments {
  for arg in "@"
  do
    if [[ $arg == --source-path=* ]]; then
      SOURCE_REPO_PATH=$(echo $arg | cut -d'=' -f 2)
    elif [[ $arg == --source-remote=* ]]; then
      SOURCE_REPO_REMOTE=$(echo $arg | cut -d'=' -f 2)
    elif [[ $arg == --target-path=* ]]; then
      TARGET_REPO_PATH=$(echo $arg | cut -d'=' -f 2)
    elif [[ $arg == --remove-exclude-file=* ]]; then
      FILE_WITH_FILES_TO_TRANSFER=$(echo $arg | cut -d'=' -f 2)
    elif [[ $arg == --branch-name=* ]]; then
      BRANCH_NAME=$(echo $arg | cut -d'=' -f 2)
    elif [[ $arg == --verbose=* ]]; then
      VERBOSE=$(echo $arg | cut -d'=' -f 2)
    fi
  done

  if [ $VERBOSE ]; then
    echo "SOURCE_REPO_PATH"
    echo "TARGET_REPO_PATH"
    echo "SOURCE_REPO_REMOTE"
    echo "FILE_WITH_FILES_TO_TRANSFER"
    echo "BRANCH_NAME"
  fi
}

# handle the arguments and variable initialization
processArguments

echo "switch to source repo and create temporary branch $BRANCH_NAME"
cd $SOURCE_REPO_PATH
git branch -d $BRANCH_NAME
git push origin --delete $BRANCH_NAME
git checkout -b $BRANCH_NAME

while IFS= read -r line
do
  filesToKeep="$filesToKeep $line"
  echo "$filesToKeep"
done < "$FILE_WITH_FILES_TO_TRANSFER"

echo "file to keep: $filesToKeep"
rm !($filesToKeep)
echo "removed files..."

git add .
git commit -m 'Remove unrelated files'
git push origin $BRANCH_NAME
echo "committed and pushed changes to source temporary branch $BRANCH_NAME"

"switching to target repo and creating temporary branch $BRANCH_NAME"
cd $TARGET_REPO_PATH
git branch -d $BRANCH_NAME
git push origin --delete $BRANCH_NAME
git checkout -b $BRANCH_NAME

echo "merge changes from target temporary branch into source temporary branch"
git remote add source-repo $SOURCE_REPO_REMOTE
git fetch source-repo $BRANCH_NAME
git merge source-repo$BRANCH_NAME --allow-unrelated-histories

echo "done! success! :)"