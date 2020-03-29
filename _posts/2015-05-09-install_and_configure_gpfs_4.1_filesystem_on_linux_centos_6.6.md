---
layout: post
title:  "Install and configure GPFS 4.1 filesystem on Linux Centos 6.6"
tags: [cluster, linux]
---

The General Parallel File System (GPFS) is a high-performance clustered file system developed by IBM. It can be deployed in shared-disk infrastructure or in shared-nothing architecture. It’s used by many large company and in serveral supercomputers on the Top 500 List.

GPFS allows to configure a high available filesystem allowing concurrent access from a cluster of nodes.
Cluster nodes can be server using AIX, Linux or Windows operatng system.

GPFS provides high performance allowing striping blocks of data over multiple disk reading and writing this blocks in parallel. It offers also block replication over different disks in order to guarantee the availability of the filesystem also during disk failures.

The following list contains some of the most interesting features of GPFS:

- Provide a POSIX compliant interface
- Allow filesystem mounting to client accessing data though LAN connection
- Many filesystem maintenance tasks can be performed while the filesystem is mounted
- Support quota
- Distributes metadata over different disks
- Have really high scalability limits

This post describes the step required to implement a basic configuration of GPFS filesystem on a cluster composed by two Centos 6.6 servers.

![gpfs architecture diagram](/assets/2015-05-09-install_and_configure_gpfs_4.1_filesystem_on_linux_centos_6.6_img1.jpg){: .center-image }

The server architectures showed in the images is composed by two server gpfs01 and gpfs02 sharing two disk device (sdb and sdc) each one of 10 GB size. Each server has an ethernet connection on subnet 172.17.0.0/16 allowing the communication between gpfs cluster nodes. The gpfs version used for installation is 4.1.0-5.

The following sequence of tasks show how install and configure GPFS on this couple of servers.

## 1. Install GPFS rpm

Install gpfs rpm on both nodes

{% highlight bash %}
[root@gpfs01 gpfs_repo]# find $PWD
/root/gpfs_repo
/root/gpfs_repo/gpfs.ext-4.1.0-5.x86_64.rpm
/root/gpfs_repo/gpfs.docs-4.1.0-5.noarch.rpm
/root/gpfs_repo/kmod-gpfs-4.1.0-5.15.sdl6.x86_64.rpm
/root/gpfs_repo/gpfs.base-4.1.0-5.0.1.x86_64.rpm
/root/gpfs_repo/gpfs.gskit-8.0.50-32.x86_64.rpm
/root/gpfs_repo/gpfs.msg.en_US-4.1.0-5.noarch.rpm
/root/gpfs_repo/gpfs.gpl-4.1.0-5.noarch.rpm

[root@gpfs02 gpfs_repo]# yum localinstall *.rpm

[root@gpfs02 gpfs_repo]# find $PWD
/root/gpfs_repo
/root/gpfs_repo/gpfs.ext-4.1.0-5.x86_64.rpm
/root/gpfs_repo/gpfs.docs-4.1.0-5.noarch.rpm
/root/gpfs_repo/kmod-gpfs-4.1.0-5.15.sdl6.x86_64.rpm
/root/gpfs_repo/gpfs.base-4.1.0-5.0.1.x86_64.rpm
/root/gpfs_repo/gpfs.gskit-8.0.50-32.x86_64.rpm
/root/gpfs_repo/gpfs.msg.en_US-4.1.0-5.noarch.rpm
/root/gpfs_repo/gpfs.gpl-4.1.0-5.noarch.rpm

[root@gpfs01 gpfs_repo]# yum localinstall *.rpm
{% endhighlight %}

## 2. Configure /etc/hosts

Configure hosts file on both nodes in order to allow name resolution.

{% highlight bash %}
[root@gpfs01 gpfs_repo]# cat /etc/hosts
127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
::1 localhost localhost.localdomain localhost6 localhost6.localdomain6
172.17.0.101 gpfs01 gpfs01.example.com
172.17.0.102 gpfs02 gpfs02.example.com

[root@gpfs02 gpfs_repo]# cat /etc/hosts
127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
::1 localhost localhost.localdomain localhost6 localhost6.localdomain6
172.17.0.101 gpfs01 gpfs01.example.com
172.17.0.102 gpfs02 gpfs02.example.com
{% endhighlight %}

## 3. Exchange root ssh key between nodes

GPFS requires that each gpfs cluster nodes can execute ssh commands on all other nodes using root user in order to allow remote administration of other nodes. In order to allow it you have to exchange ssh root keys between each cluster node.

{% highlight bash %}
[root@gpfs01 ~]# ssh-copy-id root@gpfs01
[root@gpfs01 ~]# ssh-copy-id root@gpfs02
[root@gpfs02 ~]# ssh-copy-id root@gpfs01
[root@gpfs02 ~]# ssh-copy-id root@gpfs02
{% endhighlight %}

## 4. Test ssh password-less connection

Verify the previous step executing a ssh connection between each couple of nodes.

{% highlight bash %}
[root@gpfs01 ~]# ssh gpfs01 date
Sat Apr 18 10:52:08 CEST 2015

[root@gpfs01 ~]# ssh gpfs02 date
Sat Apr 18 10:52:09 CEST 2015

[root@gpfs02 ~]# ssh gpfs01 date
Mon Apr 13 21:44:52 CEST 2015

[root@gpfs02 ~]# ssh gpfs02 date
Mon Apr 13 21:44:53 CEST 2015
{% endhighlight %}

## 5. Compile GPFS portability layer rpm

The GPFS portability layer is a loadable kernel module that allows the GPFS daemon to interact with the operating system.

IBM provides the source code of this module. It must be compiled for the kernel version used by your servers. This step can be executed on a single node then the rpm containing the kernel module can be distributed and installed over all the other gpfs nodes. In this example this module will be compiled on server gpfs01.

In order to avoid the error “Cannot determine the distribution type. /etc/redhat-release is present, but the release name is not recognized. Specify the distribution type explicitly.” during module compiling replace content of /etc/redhat-release with the string “Red Hat Enterprise Linux Server release 6.6 (Santiago)”.

{% highlight bash %}
[root@gpfs01 src]# mv /etc/redhat-release /etc/redhat-release.original
[root@gpfs01 src]# echo "Red Hat Enterprise Linux Server release 6.6 (Santiago)" &gt;&gt; /etc/redhat-release
{% endhighlight %}

In order to avoid the error “Cannot find a valid kernel include directory” during module compiling install the rpm required for compile module for your kernel version (kernel source, rpmbuild, ...).

{% highlight bash %}
[root@gpfs01 src]# yum install kernel-headers-2.6.32-504.12.2.el6

[root@gpfs01 src]# yum install kernel-devel-2.6.32-504.12.2.el6
[root@gpfs01 src]# yum install imake gcc-c++ rpmbuild
{% endhighlight %}

## 6. Install GPFS portability layer rpm

Distribute GPFS portability layer rpm on each node and install it.

{% highlight bash %}
[root@gpfs01 src]# scp /root/rpmbuild/RPMS/x86_64/gpfs.gplbin-2.6.32-504.12.2.el6.x86_64-4.1.0-5.x86_64.rpm gpfs02:/tmp/gpfs.gplbin-2.6.32-504.12.2.el6.x86_64-4.1.0-5.x86_64.rpm

[root@gpfs01 src]# yum localinstall /root/rpmbuild/RPMS/x86_64/gpfs.gplbin-2.6.32-504.12.2.el6.x86_64-4.1.0-5.x86_64.rpm

[root@gpfs02 ~]# yum localinstall /tmp/gpfs.gplbin-2.6.32-504.12.2.el6.x86_64-4.1.0-5.x86_64.rpm
{% endhighlight %}

## 7. Create GPFS cluster

In this step the cluster is created adding the node gpfs01 with the role of cluster manager and quorum manager. In the next steps the gpfs02 node will be added to the cluster.

{% highlight bash %}
[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmcrcluster -N gpfs01:manager-quorum -p gpfs01 -r /usr/bin/ssh -R /usr/bin/scp

mmcrcluster: Performing preliminary node verification ...
mmcrcluster: Processing quorum and other critical nodes ...
mmcrcluster: Finalizing the cluster data structures ...
mmcrcluster: Command successfully completed
mmcrcluster: Warning: Not all nodes have proper GPFS license designations.
Use the mmchlicense command to designate licenses as needed
{% endhighlight %}

{% highlight bash %}
[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmlscluster

===============================================================================
| Warning: |
| This cluster contains nodes that do not have a proper GPFS license |
| designation. This violates the terms of the GPFS licensing agreement. |
| Use the mmchlicense command and assign the appropriate GPFS licenses |
| to each of the nodes in the cluster. For more information about GPFS |
| license designation, see the Concepts, Planning, and Installation Guide. |
===============================================================================
GPFS cluster information
========================
GPFS cluster name: gpfs01
GPFS cluster id: 14526312809412325839
GPFS UID domain: gpfs01
Remote shell command: /usr/bin/ssh
Remote file copy command: /usr/bin/scp
Repository type: CCR

Node Daemon node name IP address Admin node name Designation
--------------------------------------------------------------------
1 gpfs01 172.17.0.101 gpfs01 quorum-manager
{% endhighlight %}

You need to accept the GPFS server license for node gpfs01.

{% highlight bash %}
[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmchlicense server --accept -N gpfs01

The following nodes will be designated as possessing GPFS server licenses:
gpfs01
mmchlicense: Command successfully completed
{% endhighlight %}

## 8. Start gpfs cluster on node gpfs01

Start gpfs cluster on node gpfs01

{% highlight bash %}
[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmstartup -N gpfs01
Fri Apr 24 18:43:35 CEST 2015: mmstartup: Starting GPFS ...
{% endhighlight %}

Verify the node status

{% highlight bash %}
[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmgetstate -a

Node number Node name GPFS state
------------------------------------------
1 gpfs01 active
{% endhighlight %}

## 9. Add the second node to GPFS

In this step the second server gpfs02 will be added to the gpfs cluster.

{% highlight bash %}
[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmaddnode -N gpfs02
Fri Apr 24 18:44:54 CEST 2015: mmaddnode: Processing node gpfs02
mmaddnode: Command successfully completed
mmaddnode: Warning: Not all nodes have proper GPFS license designations.
Use the mmchlicense command to designate licenses as needed.
mmaddnode: Propagating the cluster configuration data to all
affected nodes. This is an asynchronous process.

Now the command mmlscluster shows that the cluster is composed by two servers.

[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmlscluster

GPFS cluster information

========================
GPFS cluster name: gpfs01
GPFS cluster id: 14526312809412325839
GPFS UID domain: gpfs01
Remote shell command: /usr/bin/ssh
Remote file copy command: /usr/bin/scp
Repository type: CCR

Node Daemon node name IP address Admin node name Designation
--------------------------------------------------------------------
1 gpfs01 172.17.0.101 gpfs01 quorum-manager
2 gpfs02 172.17.0.102 gpfs02
{% endhighlight %}

## 10. Start GPFS on gpfs02 node

{% highlight bash %}
[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmstartup -N gpfs02
Fri Apr 24 18:47:32 CEST 2015: mmstartup: Starting GPFS ...

[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmgetstate -a

Node number Node name GPFS state
------------------------------------------
1 gpfs01 active
2 gpfs02 active
{% endhighlight %}

## 11. Create NSD configuration

Now you have to create a file containing the configuration of the disk that will be used by gpfs. The disk used by GPFS are called Network Shared Disk (NSD) using GPFS terminology.

The file diskdef.txt showed below contain the NSD configuration used by GPFS.

Two NSD disk has been defined, their name are mynsd1 and mynsd2 and the device files of these disks are respectively /dev/sdb and /dev/sdc. Both disks will be used to store data and metadata.

{% highlight bash %}
[root@gpfs01 ~]# cat diskdef.txt

%nsd:
device=/dev/sdb
nsd=mynsd1
usage=dataAndMetadata

%nsd:
device=/dev/sdc
nsd=mynsd2
usage=dataAndMetadata
{% endhighlight %}

Configure the NSD using this configuration file
{% highlight bash %}
[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmcrnsd -F diskdef.txt
mmcrnsd: Processing disk sdb
mmcrnsd: Processing disk sdc
mmcrnsd: Propagating the cluster configuration data to all
affected nodes. This is an asynchronous process.
{% endhighlight %}

Show the NSD configuration
{% highlight bash %}
[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmlsnsd

File system Disk name NSD servers
---------------------------------------------------------------------------
(free disk) mynsd1 (directly attached)
(free disk) mynsd2 (directly attached)
{% endhighlight %}

## 13. Create GPFS filesystem

The following command create a gpfs filesystem called fs_gpfs01 using the NSD defined in diskdef.txt file that will be mounted on /fs_gpfs01 mount point

{% highlight bash %}
[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmcrfs fs_gpfs01 -F diskdef.txt -A yes -T /fs_gpfs01

The following disks of fs_gpfs01 will be formatted on node gpfs01.example.com:
mynsd1: size 10240 MB
mynsd2: size 10240 MB
Formatting file system ...
Disks up to size 103 GB can be added to storage pool system.
Creating Inode File
86 % complete on Fri Apr 24 19:30:27 2015
100 % complete on Fri Apr 24 19:30:27 2015
Creating Allocation Maps
Creating Log Files
Clearing Inode Allocation Map
Clearing Block Allocation Map
Formatting Allocation Map for storage pool system
Completed creation of file system /dev/fs_gpfs01.
mmcrfs: Propagating the cluster configuration data to all
affected nodes. This is an asynchronous process.
{% endhighlight %}

## 14. Mount/Unmount gpfs

This step shows some useful command to mount and unmount the gpfs filesystem

- Mount on all nodes

{% highlight bash %}
[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmmount /fs_gpfs01 -a
Thu May 7 21:30:33 CEST 2015: mmmount: Mounting file systems ...
{% endhighlight %}

- Unmount on all nodes

{% highlight bash %}
[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmumount /fs_gpfs01 -a
{% endhighlight %}

- Mount on local node

{% highlight bash %}
[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmmount /fs_gpfs01
{% endhighlight %}

- Unmount on local node

{% highlight bash %}
[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmumount /fs_gpfs01
{% endhighlight %}

## 15. Verify mount gpfs filesystem

You can verify that gpfs filesystem is mounted using the command mmlsmount or using df

{% highlight bash %}
[root@gpfs01 ~]# /usr/lpp/mmfs/bin/mmlsmount all
File system fs_gpfs01 is mounted on 2 nodes.

[root@gpfs01 ~]# df
Filesystem 1K-blocks Used Available Use% Mounted on
/dev/mapper/vg_gpfs01-lv_root 17938864 1278848 15742104 8% /
tmpfs 1958512 0 1958512 0% /dev/shm
/dev/sda1 487652 69865 392187 16% /boot
/dev/fs_gpfs01 20971520 533248 20438272 3% /fs_gpfs01
{% endhighlight %}

## 16. Log location

GPFS filesystem are located in the directory gpfs /var/adm/ras

{% highlight bash %}
[root@gpfs01 ~]# ls -latr /var/adm/ras
total 20
drwxr-xr-x. 3 root root 4096 Apr 13 16:46 ..
lrwxrwxrwx 1 root root 35 Apr 24 20:33 mmfs.log.previous -&gt; mmfs.log.2015.04.24.20.33.44.gpfs01
-rw-r--r-- 1 root root 3835 May 7 21:11 mmfs.log.2015.04.24.20.33.44.gpfs01
-rw-r--r-- 1 root root 195 May 7 21:11 mmsdrserv.log
lrwxrwxrwx 1 root root 35 May 7 21:24 mmfs.log.latest -&gt; mmfs.log.2015.05.07.21.24.18.gpfs01
drwxr-xr-x. 2 root root 4096 May 7 21:24 .
-rw-r--r-- 1 root root 2717 May 7 21:24 mmfs.log.2015.05.07.21.24.18.gpfs01
{% endhighlight %}

GPFS records also system and disk failure using syslog, gpfs error log can be retrieved using the command:

{% highlight bash %}
grep "mmfs:" /var/log/messages
{% endhighlight %}

## 17. Add /usr/lpp/mmfs/bin/ to PATH environment variable

In order to avoid to use the full path for gpfs command the directory /usr/lpp/mmfs/bin/ can be added to the environment PATH variable of root

Add the line “PATH=$PATH:/usr/lpp/mmfs/bin/” in /root/.bash_profile before the line “export PATH”
