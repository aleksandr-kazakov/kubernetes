# Kubernetes Setup Using Ansible and Vagrant on WSL
Vagrantfile has been taken from https://github.com/LocusInnovations/k8s-vagrant-virtualbox and slightly modified.

## Prerequisites:
- Virtualbox installed on Windows directly "VirtualBox-6.0.24-139119-Win.exe" (supported by Vagrant 2.2.19) 
- Install Ubuntu 18.04 from Microsoft Store. When you will be prompted to create user - create it with the same name as your windows user. Use this user during installation in WSL. This is important because of this error:
```
root@computer:/mnt/c/folder# vagrant status
The VirtualBox VM was created with a user that doesn't match the
current user running Vagrant. VirtualBox requires that the same user
be used to manage the VM that was created. Please re-run Vagrant with
that user. This is not a Vagrant issue.

The UID used to create the VM was: 1000
Your UID is: 0
```  
- Inside WSL Install Vagrant from https://www.vagrantup.com/downloads.html
```
wget -c https://releases.hashicorp.com/vagrant/2.2.4/vagrant_2.2.19_x86_64.deb
sudo dpkg -i vagrant_2.2.19_x86_64.deb
```
- install vagrant disksize plugin  
```
vagrant plugin install vagrant-disksize
```
- Clone this repository to the folder on your C: drive, for example c:\k8s-vagrant-virtualbox

# Issues with vagrant in WSL and fixes
- vagrant can't use Virtualbox
```
user@/mnt/c/k8s-vagrant-virtualbox$ vagrant status
The provider 'virtualbox' that was requested to back the machine
'kubemaster' is reporting that it isn't usable on this system. The
reason is shown below:

Vagrant could not detect VirtualBox! Make sure VirtualBox is properly installed.
Vagrant uses the `VBoxManage` binary that ships with VirtualBox, and requires
this to be available on the PATH. If VirtualBox is installed, please find the
`VBoxManage` binary and add it to the PATH environmental variable.
```
Fix (https://www.vagrantup.com/docs/other/wsl): 
```
export ls -l PATH=$PATH:"/mnt/c/Program Files/Oracle/VirtualBox:/mnt/c/Windows/System32:/mnt/c/Windows/System32/WindowsPowerShell/v1.0/"
```
- VBoxManage.exe: error: Could not create the directory ..... (VERR_INVALID_NAME)
```
user@/mnt/c/k8s-vagrant-virtualbox$ vagrant up master

There was an error while executing `VBoxManage`, a CLI used by Vagrant
for controlling VirtualBox. The command and stderr is shown below.

Command: ["clonemedium", "C:\\Users\\User\\VirtualBox VMs\\ubuntu-bionic-18.04-cloudimg-20220131\\ubuntu-bionic-18.04-cloudimg.vmdk", "./C:\\Users\\User\\VirtualBox VMs\\ubuntu-bionic-18.04-cloudimg-20220131\\ubuntu-bionic-18.04-cloudimg.vdi", "--format", "VDI"]

Stderr: 0%...
Progress state: VBOX_E_IPRT_ERROR
VBoxManage.exe: error: Failed to clone medium
VBoxManage.exe: error: Could not create the directory 'C:\k8s-vagrant-virtualbox\C:\Users\User\VirtualBox VMs\ubuntu-bionic-18.04-cloudimg-20220131' (VERR_INVALID_NAME)VBoxManage.exe: error: Details: code VBOX_E_IPRT_ERROR (0x80bb0005), component VirtualBoxWrap, interface IVirtualBox
VBoxManage.exe: error: Context: "enum RTEXITCODE __cdecl handleCloneMedium(struct HandlerArg *)" at line 1023 of file VBoxManageDisk.cpp
```
Fix (https://github.com/miikkij/vagrant-disksize/commit/c8dc1180a81cb9df1d8072221ad50c2e42cb69fa):
```
vi /home/user/.vagrant.d/gems/2.7.4/gems/vagrant-disksize-0.1.3/lib/vagrant/disksize/actions.rb

        def generate_resizable_disk(disk)
          src = disk[:file]
          src.gsub!(/\\+/, '/')       <----- fix
          src_extn = File.extname(src)
          src_path = File.dirname(src)
          src_base = File.basename(src, src_extn)
```
- RawFile#0 failed to create the raw output file ..... (VERR_PATH_NOT_FOUND)
```
user@/mnt/c/k8s-vagrant-virtualbox$ vagrant up master
There was an error while executing `VBoxManage`, a CLI used by Vagrant
for controlling VirtualBox. The command and stderr is shown below.

Command: ["startvm", "36c82309-488d-46e6-8d67-cd79933171c3", "--type", "headless"]

Stderr: VBoxManage.exe: error: RawFile#0 failed to create the raw output file /mnt/c/k8s-vagrant-virtualbox/ubuntu-bionic-18.04-cloudimg-console.log (VERR_PATH_NOT_FOUND)
VBoxManage.exe: error: Details: code E_FAIL (0x80004005), component ConsoleWrap, interface IConsole
```
Fix (https://github.com/joelhandwell/ubuntu_vagrant_boxes/issues/1):
```
config.vm.provider "virtualbox" do |v|
    v.memory = 4096
    v.cpus = 4
    v.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]      <----- Fix
end
```
- Permission denied (publickey) when you try launch instance like  "vagrant up master"
Fix:
export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="/mnt/c/k8s-vagrant-virtualbox"
or
export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="$(pwd)"
- Permission denied (publickey) when you trying ssh to the instance like vagrant ssh master. SSH key reside on windows disk and has 777 permissions.
```
user@computer:/mnt/c/k8s-vagrant-virtualbox$ vagrant ssh master
vagrant@127.0.0.1: Permission denied (publickey).
```
try to debug:    vagrant ssh master --debug
try other way:   ssh vagrant@127.0.0.1 -p 2200 -i /mnt/c/k8s-vagrant-virtualbox/.vagrant/machines/master/virtualbox/private_key
last one shows the cause of the isssue - key permissions

Workaround:
```
cp /mnt/c/k8s-vagrant-virtualbox/.vagrant/machines/master/virtualbox/private_key ~/.ssh/
chmod 600 ~/.ssh/private_key
ssh vagrant@127.0.0.1 -p 2200 -i ~/.ssh/private_key     # <----- works

mv /mnt/c/k8s-vagrant-virtualbox/.vagrant/machines/master/virtualbox/private_key /mnt/c/k8s-vagrant-virtualbox/.vagrant/machines/master/virtualbox/private_key-backup
ln -s ~/.ssh/private_key /mnt/c/k8s-vagrant-virtualbox/.vagrant/machines/master/virtualbox/private_key
vagrant ssh master                                      # <--- works
```
or you can try script ./ssh_key_copy.sh, which will do the same. Script accept 1 parameter - node name, ex. "ssh_key_copy.sh master"

