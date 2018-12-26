#!/bin/sh
#Here is a way to list hidden directories in the current directory using glob:
shopt -s dotglob nullglob

SEARCH_FOLDER=`pwd`
GIT_DIRECTORY=".git"
BRANCH_COMMAND="git branch | grep '*' | awk '{print \$2}'"
git_arr=()    # git directories array
branch_arr=() # branch kept for git directory
max_len=0
function check_directories()
{
    if [ -d "$GIT_DIRECTORY" ]; then
        local dir=`pwd`
        if [ ${#dir} -gt $max_len ];then
            echo "dir len" ${#dir} " max_len" $max_len
            max_len=${#dir}
        fi
        git_arr+=("$dir")
        return 0
    fi
    for f in $1/*
    do
        if [ -d $f ]; then
            cd $f
            check_directories $f
            cd ../
        fi
    done
}
#check_for_git_directory
check_directories $SEARCH_FOLDER

for i in "${git_arr[@]}"
do
    cd $i
    branch=$(eval "$BRANCH_COMMAND")
    printf "%-${max_len}s %s\n" $i $branch
done
