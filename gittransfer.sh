
function processArguments {
  for arg in "$@"
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
    echo "SOURCE_REPO_PATH=$SOURCE_REPO_PATH"
    echo "TARGET_REPO_PATH=$TARGET_REPO_PATH"
    echo "SOURCE_REPO_REMOTE=$SOURCE_REPO_REMOTE"
    echo "FILE_WITH_FILES_TO_TRANSFER=$FILE_WITH_FILES_TO_TRANSFER"
    echo "BRANCH_NAME=$BRANCH_NAME"
  fi
}

function switchRepoAndCreateTemporaryBranch {
  echo "switch to source repo and create temporary branch $BRANCH_NAME"
  cd $1
  pwd
  git checkout master
  git branch -d $BRANCH_NAME
  git push -d origin $BRANCH_NAME
  git checkout -b $BRANCH_NAME
  #git push origin $BRANCH_NAME
}

function addRemoteSourceRepoToTargetRepoAndMergeBranches {
  echo "merge changes from target temporary branch into source temporary branch"
  git remote add source-repo $SOURCE_REPO_REMOTE
  git fetch source-repo $BRANCH_NAME
  git merge source-repo/$BRANCH_NAME --allow-unrelated-histories
}

function readFilesToTransferAndRemoveTheRest {
  while IFS= read -r line
  do
    filesToKeep="$filesToKeep ! -name $line"
  done < "$FILE_WITH_FILES_TO_TRANSFER"
  echo "files to keep: $filesToKeep"

  # replace the '/' characters with spaces to exclude the folders from the deletion
  # filesToKeep=$(echo $filesToKeep | sed 's/\// /g')
  echo "final files: $filesToKeep"
  find . $filesToKeep -not -path "*/.git*" -delete
  find . -name .gitignore -delete
  echo "removed files..."
}

function commitPushChangesIntoSourceTemporaryBranch {
  git add .
  git commit -m 'Remove unrelated files'
  git push origin $BRANCH_NAME
  echo "committed and pushed changes to source temporary branch $BRANCH_NAME"
}

function doTransferOfRepos {

  switchRepoAndCreateTemporaryBranch $SOURCE_REPO_PATH
  echo ""
  readFilesToTransferAndRemoveTheRest
  echo ""

  commitPushChangesIntoSourceTemporaryBranch
  echo ""
  switchRepoAndCreateTemporaryBranch $TARGET_REPO_PATH
  echo ""
  addRemoteSourceRepoToTargetRepoAndMergeBranches

  echo "done! success! :)"
}

# handle the arguments and variable initialization
processArguments $@
doTransferOfRepos