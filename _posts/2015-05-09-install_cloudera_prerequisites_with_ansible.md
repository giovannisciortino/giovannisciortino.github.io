---
#layout: post
title:  "Install Cloudera prerequisites with Ansible"
tags: [automation, cluster, hadoop, linux]
---

Ansible is an opensource software for configuring and managing a server infrastructures. It allows multi-node software deployment, ad hoc task execution and configuration management.
In this post I show how use ansible to deploy some Cloudera Hadoop 5 prerequisites to a large set of server.

Ansible is a lightweight alternative to other opensource configuration management tools like puppet. It doesn’t need any agent installed on each managed node like puppet. It require only a ssh connection from ansible server to managed servers and the python package installed on them.

In this tutorial two type of ansible configuration files will be used:

- **hosts file:** it allows to define the list of hosts managed by ansible
- **playbook:** it contains a list of configurations that can be deployed to a server or a group of server


Cloudera Hadoop requires for each nodes the following prerequisites :
- The file /etc/hosts of each nodes containing consistent information about hostnames and IP addresses across all hosts
- SELinux disabled
- IPv6 disabled
- vm.swappiness kernel option must be set to a value less or equal to 10
- A password-less ssh connection to root user with a unique private keys must be configured

This configuration must be deployed to each cloudera server. The manual execution of these tasks over a large hadoop infrastructure could be a time-consuming activity.
Ansible can automatize all this operation.

The example showed in this post uses an hostgroup of 4 cloudera server but it can be easily scaled to hundreds of servers.

Each node in my configuration uses Centos 6.5 operating system and python and libselinux-python rpm has been installed.
The libselinux-python rpm package is required also to disable selinux configuration and it could be also installed by ansible.

I install ansible on the first host of my hostgroup.

{% highlight bash %}
[root@cloudera01 ~]# yum install epel-release
[root@cloudera01 ~]# yum install ansible
{% endhighlight %}

I modify the ansible hosts file /etc/ansible/hosts as showed below. This file defines an hostgroup named “cloudera” and its hostnames list (these hostnames should be defined on /etc/hosts or in a DNS server )

{% highlight bash %}
[root@cloudera01 ~]# cat /etc/ansible/hosts
[cloudera]
cloudera01
cloudera02
cloudera03
cloudera04
{% endhighlight %}

I create a playbook in /root/cloudera-prerequisites.yml as showed in the following text box.

Playbooks are text file in YAML format containing a set of orchestration steps.

This playbook defines:
- The group of servers involved in the orchestration
- The remote username used for the ssh connection
-A list of orchestration step(task) that must be executed on each server of cloudera group. Each task define an ansible module and their parameter. You can found more detail about ansible modules on Ansible documentation [http://docs.ansible.com/modules.html](http://docs.ansible.com/modules.html) .

{% highlight bash %}
[root@cloudera01 ~]# cat cloudera-prerequisites.yml
- hosts: cloudera
remote_user: root
tasks:
- selinux: state=disabled
- sysctl: name=net.ipv6.conf.all.disable_ipv6 value=1 state=present
- sysctl: name=net.ipv6.conf.default.disable_ipv6 value=1 state=present
- sysctl: name=vm.swappiness value=10 state=present
- authorized_key: user=root key="{% raw  %}{{ lookup('file', '/root/.ssh/id_rsa.pub') }}{% endraw  %}"
- copy: src=/etc/hosts dest=/etc/hosts owner=root group=root mode=0644
{% endhighlight %}


Now I’m ready to execute my playbook applying cloudera prerequisites on each node of cloudera hostgroup.
I launch the command ansible-playbook using the playbook as arguments and using the flag “-k”.
The flags -k allow to insert the password of all cloudera hosts in interactive way.
Ansible playbook can be also executed in other environment where there is an password-less ssh connection or hosts with different root passwords.

{% highlight bash %}
[root@cloudera01 ~]# ansible-playbook cloudera-prerequisites.yml -k
SSH password: ## Insert root password of all cloudera hosts

PLAY [cloudera] ***************************************************************

GATHERING FACTS ***************************************************************
ok: [cloudera04]
ok: [cloudera01]
ok: [cloudera03]
ok: [cloudera02]

TASK: [selinux state=disabled] ************************************************
changed: [cloudera04]
changed: [cloudera03]
changed: [cloudera01]
changed: [cloudera02]

TASK: [sysctl name=net.ipv6.conf.all.disable_ipv6 value=1 state=present] ******
ok: [cloudera01]
ok: [cloudera04]
ok: [cloudera03]
ok: [cloudera02]

TASK: [sysctl name=net.ipv6.conf.default.disable_ipv6 value=1 state=present] ***
ok: [cloudera04]
ok: [cloudera03]
ok: [cloudera01]
ok: [cloudera02]

TASK: [authorized_key user=root key="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA8aFJa2vXcrt42PmzIT8/9rFc4JQHS7ElV7p11l7KrV3Kq9IqnPaWei+u6zJ0zTW/J1DvOalzzT23tMakAMPpsKm/LEAQnvKA3Ytc0K+vtHH7tJaAB0QJAoq2rBocj7R+RJtnU8VvQxRyCYELDYoTLLjCKBjvyDN7908ojuuqHdb4LpIiTnge5WcofpeD64P1J4PN6sYAu+nTC/ykg4a75iiuyoWuocwfRgS9i1aFdyHHnY40rB8/Er+vzn9bQRbNTYjwo8kEaQt1ZM4ZRjzhM3gUUwM0JUjeSDN3soA+Dq4tW052nxiL5xEWsCcTLcy5cd6fChzEQShPP8xnee8btw== root@cloudera01.example.com"] ***
ok: [cloudera01]
ok: [cloudera03]
ok: [cloudera02]
ok: [cloudera04]

TASK: [copy src=/etc/hosts dest=/etc/hosts owner=root group=root mode=0644] ***
ok: [cloudera02]
ok: [cloudera01]
ok: [cloudera03]
ok: [cloudera04]

PLAY RECAP ********************************************************************
cloudera01 : ok=6 changed=1 unreachable=0 failed=0
cloudera02 : ok=6 changed=1 unreachable=0 failed=0
cloudera03 : ok=6 changed=1 unreachable=0 failed=0
cloudera04 : ok=6 changed=1 unreachable=0 failed=0
{% endhighlight %}

Reboot each system in order to apply selinux configuration

When a playbook is executed, Ansible generate a report containing detailed information about the execution of each tasks.
In this case ansible informs you that a reboot of each node is required in order to apply to reload selinux configuration.

Ansible executes idempotent configuration, it means that the same playbook can be reapplied on an already configured node without modifying any configuration.
This feature can be useful to check configuration changes or when a new host is added in a hostgroup.
