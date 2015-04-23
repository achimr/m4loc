#summary Development procedures and technical guidelines.

# Quality Assurance #
While the project does not require strict [test-driven development](http://en.wikipedia.org/wiki/Test-driven_development), tests should be submitted for all code. As M4Loc deals with data intensive processing, representative sets of test data should be submitted with the code.

## Issue Tracking ##
There is a good quick start introduction to the issue tracker available at  [Issue Tracker](http://code.google.com/p/support/wiki/IssueTracker). For now we will not use project-specific labels, but please try to follow the [issue life-cycle](http://code.google.com/p/support/wiki/IssueTracker#Concepts).

# Code Reviews #
Committers can request code reviews from other members with check-in privileges.

# Git Repository #

  * If you are unfamiliar with the Git distributed version control system please read this [tutorial](http://www.vogella.de/articles/Git/article.html).
  * For more in-depth informatin there are two books with free online versions available
    * [Git Community Book](http://book.git-scm.com/)
    * [Pro Git](http://progit.org/book/)
  * Make sure all files contain the LGPL v3 boilerplate text
```
# Copyright <year> <your (company) name>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
```
  * To ensure the proper handling of line endings on different platforms it is very important to set this global option for your Git client
```
git config --global core.autocrlf true
```