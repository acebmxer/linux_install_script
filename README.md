# linux_setup_script
Script to run after fresh linux install

This script will provide a prompt.  Choose to fully update a bare metal system or XCP-NG VM.  Seperatly choose to install XCP-NG tools or upgrade tools.  Install Docker or just run updates on the system.

To begin select 1 of 6 options.
1.  To fully update and upgrade bare metal.
2.  To fully update and upgrade xcp-ng vm.
3.  To install or update xen-guest-utilities.
4.  To update your system
5.  To install docker.
6.  To make no changes and Exit.

Enter choice [1-6]:


### Clone the repo and run setup.sh
```
git clone "https://github.com/acebmxer/linux_setup_script.git"
cd linux_setup_script && chmod +x * && bash setup.sh
```
