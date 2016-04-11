#!/usr/bin/env bash
#==============================================================================
# HEADER
#==============================================================================
#% SYNOPSIS
#+    ${SCRIPT_NAME} -c|-u|start_commit [end_commit] [-hvf] [-n <name>] [-e <email>]
#%
#% DESCRIPTION
#%    Overwrites git commit metadata so that a user can take
#%    ownership of a series of commits.
#%
#% OPTIONS
#%    start_commit                  The start of the commit range
#%    end_commit                    The end of the commit range
#%                                  defaults to HEAD
#%    -n, --name                    Requisitioner's name
#%                                  defaults to `git config user.name`
#%    -e, --email                   Requisitioner's email
#%                                  defaults to `git config user.email`
#%    -u, --undo                    Undo the last requisition
#%    -c, --clean                   Lock in the last requisition
#%    -f, --force                   Pass --force to `git filter-branch`
#%    -h, --help                    Print this help
#%    -v, --version                 Print script information
#%
#% EXAMPLES
#%    ${SCRIPT_NAME} HEAD~6 HEAD~3
#%    ${SCRIPT_NAME} b1a9b6b^ d4c18b0 -n "John Doe" -e john@doe.com
#%    ${SCRIPT_NAME} --clean
#%    ${SCRIPT_NAME} --undo
#%
#==============================================================================
#- IMPLEMENTATION
#-    version         ${SCRIPT_NAME} 0.0.1
#-    author          Connor KRAMMER
#-    copyright       Copyright (c) Connor KRAMMER
#-    license         GNU General Public License
#-
#==============================================================================
#  DEBUG OPTION
#    set -n  # Uncomment to check your syntax, without execution.
#    set -x  # Uncomment to debug this shell script
#
#==============================================================================
# END_OF_HEADER
#==============================================================================

# Variables needed for usage functions
SCRIPT_HEADSIZE=$(head -200 ${0} |grep -n "^# END_OF_HEADER" | cut -f1 -d:)
SCRIPT_NAME="$(basename ${0})"

# Usage functions
# Source: http://stackoverflow.com/a/29579226
usage()      { printf "Usage: "; head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#+" | sed -e "s/^#+[ ]*//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g" ; }
usagefull()  { head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#[%+-]" | sed -e "s/^#[%+-]//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g" ; }
scriptinfo() { head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "^#-" | sed -e "s/^#-//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g"; }

# Information about the current branch
branch=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')
clean_command="git update-ref -d refs/original/refs/heads/$branch"
undo_command="git reset --hard refs/original/refs/heads/$branch"

# Variable defaults
start_commit=''
end_commit=HEAD
name=$(git config user.name)
email=$(git config user.email)
help_arg=0
info_arg=0
clean_arg=0
undo_arg=0

# Parse command line
# Based on code by http://stackoverflow.com/a/24597113
for ((i=1;i<=$#;i++)); do

    # -h | --help
    if [ ${!i} = "-h" ] || [ ${!i} = "--help" ]; then
        help_arg=1

    # -v | --version
    elif [ ${!i} = "-v" ] || [ ${!i} = "--version" ]; then
        info_arg=1

    # -f | --force
    elif [ ${!i} = "-f" ] || [ ${!i} = "--force" ]; then
        force=${!i}

    # -c | --clean
    elif [ ${!i} = "-c" ] || [ ${!i} = "--clean" ]; then
        clean_arg=1

    # -u | --undo
    elif [ ${!i} = "-u" ] || [ ${!i} = "--undo" ]; then
        undo_arg=1

    # -n | --name
    elif [ ${!i} = "-n" ] || [ ${!i} = "--name" ]; then
        ((i++))
        name=${!i}

    # -e | --email
    elif [ ${!i} = "-e" ] || [ ${!i} = "--email" ]; then
        ((i++))
        email=${!i}

    # start_commit
    elif [ $i = 1 ]; then
        start_commit=$(git rev-parse $1)

    # end_commit
    elif [ $i = 2 ]; then
        end_commit=$(git rev-parse $2)
    fi
done

# Handle the --help and --version flags
if [ $help_arg = 1 ]; then
    usagefull
    exit
elif [ $info_arg = 1 ]; then
    scriptinfo
    exit
fi

# Handle the clean and undo flags
if [ $clean_arg = 1 ]; then
    echo "Running \`$clean_command\`"
    eval $clean_command
    exit
elif [ $undo_arg = 1 ]; then
    echo "Running \`$undo_command\`"
    eval $undo_command
    exit
fi

# If start_commit hasn't been set then print usage information
if [ -z $start_commit ]; then
    usage
    exit
fi

# Readability helper for assigning HEREDOC strings to variables
# Source: http://stackoverflow.com/a/8088167
define() { read -r -d '' ${1} || true; }

define command << EOF
if git rev-list $start_commit^..$end_commit | grep \$GIT_COMMIT; then
    GIT_AUTHOR_EMAIL=$email;
    GIT_AUTHOR_NAME="$name";
    GIT_COMMITTER_EMAIL=$email;
    GIT_COMMITTER_NAME="$name";
fi
EOF

# Run the filter-branch command
git filter-branch --env-filter "$command" $force -- ^$start_commit HEAD

# If we were successful, tell the user how to proceed
if [[ $? == 0 ]]; then

    echo ""
    echo "Check to make sure the changes were correct, then execute one of the following:"
    echo "  \`$SCRIPT_NAME --clean\`   (calls \`$clean_command\`)"
    echo "  \`$SCRIPT_NAME --undo\`    (calls \`$undo_command\`)"
fi
