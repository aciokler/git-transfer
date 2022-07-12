
# constants:
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

function printError {
  printf "${Red}$1${Color_Off}"
}

function printSuccess {
  printf "${Green}$1${Color_Off}"
}

function printInfo {
  printf "${Cyan}$1${Color_Off}"
}

function printWarning {
  printf "${Yellow}$1${Color_Off}"
}

function processArguments {
  for arg in "$@"
  do
    echo "$arg"
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
    elif [[ $arg == --dry-run=* ]]; then
      DRY_RUN=$(echo $arg | cut -d'=' -f 2)
    elif [[ $arg == --force-delete=* ]]; then
      FORCE_DELETE=$(echo $arg | cut -d'=' -f 2)
    fi
  done

  if [ $VERBOSE ]; then
    printInfo "\n\nVariables:\n"
    printf "${Green}SOURCE_REPO_PATH${Color_Off}=${Yellow}$SOURCE_REPO_PATH${Color_Off}\n"
    printf "${Green}TARGET_REPO_PATH${Color_Off}=${Yellow}$TARGET_REPO_PATH${Color_Off}\n"
    printf "${Green}SOURCE_REPO_REMOTE${Color_Off}=${Yellow}$SOURCE_REPO_REMOTE${Color_Off}\n"
    printf "${Green}FILE_WITH_FILES_TO_TRANSFER${Color_Off}=${Yellow}$FILE_WITH_FILES_TO_TRANSFER${Color_Off}\n"
    printf "${Green}BRANCH_NAME${Color_Off}=${Yellow}$BRANCH_NAME${Color_Off}\n"
    printf "${Green}DRY_RUN${Color_Off}=${Yellow}$DRY_RUN${Color_Off}\n"
    printf "${Green}FORCE_DELETE${Color_Off}=${Yellow}$FORCE_DELETE${Color_Off}\n"
  fi
    printf "\n\n"

  validateParameters
  readFilesToTransferAndValidate
}

function validateParameters {
  if [[ -z "$SOURCE_REPO_PATH" ]]; then
      printError "exiting: SOURCE_REPO_PATH cannot be empty. Exiting...\n"
      exit 1
    elif [[ -z "$TARGET_REPO_PATH" ]]; then
      printError "exiting: TARGET_REPO_PATH cannot be empty. Exiting...\n"
      exit 1
     elif [[ -z "$SOURCE_REPO_REMOTE" ]]; then
      printError "exiting; SOURCE_REPO_REMOTE cannot be empty. Exiting...\n"
      exit 1
     elif [[ -z "$FILE_WITH_FILES_TO_TRANSFER" ]]; then
      printError "exiting: FILE_WITH_FILES_TO_TRANSFER cannot be empty. Exiting...\n"
      exit 1
     elif [[ -z "$BRANCH_NAME" ]]; then
      printError "exiting: BRANCH_NAME cannot be empty/ Exiting...\n"
      exit 1
  fi

  [ ! -d $SOURCE_REPO_PATH ] && printError "source repo path '$SOURCE_REPO_PATH' not valid folder. Exiting...\n" && exit 1
  [ ! -d $TARGET_REPO_PATH ] && printError "target repo path '$TARGET_REPO_PATH' not valid folder. Exiting...\n" && exit 1
  [ ! -f $FILE_WITH_FILES_TO_TRANSFER ] && printError "File '$FILE_WITH_FILES_TO_TRANSFER' is not a valid file. Exiting...\n" && exit 1
}

function readFilesToTransferAndValidate {
  while IFS= read -r line
  do
    if [[ ! -z "$line" ]]; then # only append non empty lines
      filesToKeep="$filesToKeep ! -name $line"
    fi
  done < "$FILE_WITH_FILES_TO_TRANSFER"

  
  printInfo "File Contents:\n"
  echo "--------------------"
  printf "${Purple}"
  cat "$FILE_WITH_FILES_TO_TRANSFER"
  printf "${Color_Off}"
  echo "--------------------"

  # exit if no files are being transferred
  if [[ -z "$filesToKeep" ]]; then
    printError "file $FILE_WITH_FILES_TO_TRANSFER cannot be empty\n"
    exit 1
  fi

  [ $VERBOSE ] && printInfo "\nfinal files: $filesToKeep\n\n"
}

function switchRepoAndCreateTemporaryBranch {
  printInfo "\nSwitch to repo in path '$1' and create temporary branch $BRANCH_NAME\n"
  cd $1
  printWarning "Repo: $(pwd)\n\n"
  [ $(pwd) == $HOME ] && printError "Error! should not perform deletion operations in the home folder! Exiting...\n" && exit 1

  printf "${Blue}"
  git checkout master
  printf "${Color_Off}"
  echo ""

  git branch -D $BRANCH_NAME
  git push -d origin $BRANCH_NAME
  echo ""

  printf "${Blue}"
  git checkout -b $BRANCH_NAME
  printf "${Color_Off}"
  #git push origin $BRANCH_NAME
}

function addRemoteSourceRepoToTargetRepoAndMergeBranches {
  printInfo "merge changes from target temporary branch into source temporary branch\n"
  git remote add source-repo $SOURCE_REPO_REMOTE
  git fetch source-repo $BRANCH_NAME
  git merge source-repo/$BRANCH_NAME --allow-unrelated-histories
}

function performDryOrNormalRemoval {
  if [ $DRY_RUN ]; then
    printf "${Yellow}ATTENTION!!!!${Color_Off} Performing a dry run! The following files are candidates to be deleted:\n"
    echo ""
    printf "${Red}"
    find $SOURCE_REPO_PATH $filesToKeep -not -path "*/.git*"
    printf "${Color_Off}"
  else
    removeFilesNotBeingTransferred
  fi
}

function removeFilesNotBeingTransferred {
    printf "${Yellow}ATTENTION!!!!${Color_Off} The following files will be deleted:\n"
    echo ""
    
    # display all the file to be deleted
    printf "${Red}"
    find $SOURCE_REPO_PATH $filesToKeep -not -path "*/.git*"
    printf "${Color_Off}"

    if [[ ! $FORCE_DELETE ]]; then
      printWarning "Please confirm the deletion of above files [y/n]: "
      read CONFIRM_DELETE

      if [[ $CONFIRM_DELETE == 'y' ]] || [[ $CONFIRM_DELETE == "Y" ]]; then
        # delete files quietly...
        find . $filesToKeep -not -path "*/.git*" -delete 2>/dev/null
        find . -name .gitignore -delete
        printInfo "\nRemoved files...\n"
      else
        printInfo "\n\nNo files removed...\n"
      fi
    fi
}

function commitPushChangesIntoSourceTemporaryBranch {
  
  printInfo "\n\n Committing and pushing changes\n\n"
  printf "${Red}"
  git add .
  git commit -m 'Remove unrelated files'
  printf "${Color_Off}"
  echo ""

  git push origin $BRANCH_NAME
  printInfo "\ncommitted and pushed changes to source temporary branch $BRANCH_NAME\n"
}

function doTransferOfRepos {

  switchRepoAndCreateTemporaryBranch $SOURCE_REPO_PATH
  echo ""
  performDryOrNormalRemoval
  echo ""

  if [ ! $DRY_RUN ]; then
    commitPushChangesIntoSourceTemporaryBranch
    echo ""
    switchRepoAndCreateTemporaryBranch $TARGET_REPO_PATH
    echo ""
    addRemoteSourceRepoToTargetRepoAndMergeBranches
  fi
  printSuccess "\n\nDone! Success! :)\n\n"
}

# handle the arguments and variable initialization
processArguments $@
doTransferOfRepos