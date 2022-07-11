### git-transfer
git transfer tools

### sample commands

```bash
./gittransfer.sh --source-path=[relative/absolute path] --source-remote="git@[git-repo-url].git" --target-path=[relative/absolute path] --remove-exclude-filroe=../file.txt --branch-name=temporary-merge --verbose=false
```

```bash
./gittransfer.sh '--source-path=[path to source repo folder]' \
'--source-remote=[remote git repo: git@*.git]' \
'--target-path=[target repo folder path]' \
'--remove-exclude-file=[path to file with filenames to transfer from source repo]' \
'--branch-name=[name of temporary git branch to use for transfer]' \
'--verbose=[optional if you want to see extra logging]'
```

### parameters

`--source-path`: Local path to the source git repository. This is the repository that contains the files that will be transferred.
`--source-remote`: Remote git url of the source git repository. This is needed so the repository can be added as a remote repository.
`--target-path`: Local path to the target git repository. This is where the files coming from the source repository will be merged.
`--remove-exclude-file`: Path to a text file containing the names of the files wanted to be transferrred and merged from the source into the target repositories.
`--branch-name`: Name of the temporary branch to be used during the transfer of the files. Notice these branches are temporary and will get deleted each time the script runs. The temporary branch will be kept after a run so that users can then make merge/pull request into the master branch.
`--verbose`: Optional flag to include extra logging during the running of the script.
`--dry-run`: Optional flag to run the script in dry mode. This mode will not perform any file transfers/removal of files. It will only display which files would be transferred if it ran normally. This is recommended to use before running it normally so ensure the script is setup correctly.
`--force-delete`: Optional flag to skip the prompt to confirm the removal and transfer of the files into the target repository. During a normal run, the script will prompt the user to confrim with a `y` or `n` before proceding with the removal and transfer of files. This is intentional to avoid deleting not desired files in the computer. However if you feel confident that the script parameters are setup correctly, then you can use this option. This option is only recommended for advance usages. I recommend relying on the prompt if you don't need this option.