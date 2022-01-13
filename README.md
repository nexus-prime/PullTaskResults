# PullTaskResults
Download metadata for completed BOINC tasks by a specified host

To use run:

bash PullTaskResults.sh [project name] [HostID for project] [pages of tasks to return] [Output File name]
    
    
[project name] - name of project i.e. primegrid Seti YOYO
    There is a search function based on keywords in /PullTaskResults/resources/WhiteList_URL_Lookup.txt
  
[HostID for project] - Each computer (host) has a unique host ID for every BOINC project. Enter the host ID for which you want to search.

[pages of tasks to return] - Tasks are stored in pages of 20 tasks. Script will return tasks from the newest to the oldest.
  
[Output File name] - Self explanatory
