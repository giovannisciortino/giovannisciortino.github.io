---
layout: post
title:  "Clone git repo to a non-empty directory"
tags: [git]
---

Cloning a git repo to a non-empty directory can be sometimes useful.

For example, you can have a remote git repository containing already some files and you want merge them with files contained in a existing local directory.

If you try to clone the remote repository to non-empty directory you obtain the following error message:

{% highlight bash %}
[root@puppet ~]# LOCAL_REPO="/etc/puppet/modules"
[root@puppet ~]# REMOTE_REPO="https://github.com/rarefatto/puppet-modules-roles-profiles.git"

[root@puppet ~]# git clone $REMOTE_REPO $LOCAL_REPO
fatal: destination path '/etc/puppet/modules' already exists and is not an empty directory.
{% endhighlight %}



To avoid this error cloning the remote git repository you can execute the following commands:

{% highlight bash %}
[root@puppet ~]# git clone --bare $REMOTE_REPO $LOCAL_REPO/.git
Cloning into bare repository '/etc/puppet/modules/.git'...
remote: Counting objects: 4, done.
remote: Compressing objects: 100% (4/4), done.
remote: Total 4 (delta 0), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (4/4), done.

[root@puppet ~]# cat $LOCAL_REPO/.git/config
[core]
        repositoryformatversion = 0
        filemode = true
        bare = true
[remote "origin"]
        url = https://github.com/rarefatto/puppet-modules-roles-profiles.git


# Replace "bare = true" with "bare = false" in the configuration file $LOCAL_REPO/.git/config
[root@puppet ~]# sed -i 's/bare = true/bare = false/' $LOCAL_REPO/.git/config

[root@puppet ~]# cd $LOCAL_REPO


# Your local repository still contains only the non-empty directory.
# Now the remote repository files are listed as deleted files.
[root@puppet modules]# git status  
# On branch master
# Changes to be committed:
#
#       deleted:    .gitignore
#       deleted:    LICENSE
#
# Untracked files:
#
#       httpd/
#       motd/
#       profile/
#       role/


# This command allow to rescue deleted files
[root@puppet modules]# git checkout $LOCAL_REPO


# Now the local repository contains a clone of remote repository
# and the file previously contained in the directory
[root@puppet modules]# ls -latr
total 32
drwxr-xr-x 6 root root  4096 Nov  4 20:53 motd
drwxr-xr-x 5 root root   108 Mar 28 20:31 ..
drwxr-xr-x 5 root root    96 Apr  1 14:31 httpd
drwxr-xr-x 5 root root    96 Apr  1 18:13 role
drwxr-xr-x 5 root root    96 Apr  1 18:14 profile
-rw-r--r-- 1 root root   702 Apr  1 21:36 .gitignore
drwxr-xr-x 7 root root    96 Apr  1 21:36 .
-rw-r--r-- 1 root root 18047 Apr  1 21:36 LICENSE
drwxr-xr-x 7 root root  4096 Apr  1 21:36 .git
{% endhighlight %}
