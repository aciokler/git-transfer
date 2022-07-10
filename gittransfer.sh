SOURCE_REPO_PATH=$1
TARGET_REPO_PATH=$2
SOURCE_REPO_REMOTE=$3
FILE_WITH_FILES_TO_TRANSFER=$4

BRANCH_NAME=transfer-branch

cd $SOURCE_REPO_PATH

git checkout -b $BRANCH_NAME

while IFS= read -r line
do
  filesToKeep="$filesToKeep$line"
  echo "$filesToKeep"
done < "$FILE_WITH_FILES_TO_TRANSFER"

rm !($filesToKeep)

git add .
git commit -m 'Remove unrelated files'
git push origin $BRANCH_NAME

cd $TARGET_REPO_PATH
git checkout -b $BRANCH_NAME
git remote add source-repo $SOURCE_REPO_REMOTE
git fetch source-repo $BRANCH_NAME
git merge source-repo$BRANCH_NAME --allow-unrelated-histories

