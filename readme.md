git-requisition
===============

git-requisition is a script that lets you change the ownership of a commit
or range of commits. It affects both the git author and git committer
metadata variables for the commits. This allows you to fix errors of
authorship or correct accidentally-assigned co-authors, such as may happen
during `git rebase`. (This latter type of error can be seen in GitHub's
commit history as "AUTHOR commited with COMMITTER".)

Usage
-----

For usage, please run `git-requisition -h` or view `git-requisition.sh`.

Requirements
------------

git-requisition requires only that you have the `git` command available
from the command line.
