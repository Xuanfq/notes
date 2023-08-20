1.  Update apt-get: `sudo apt-get update`.
2.  Install ssh service: `sudo apt-get install openssh-server` and `sudo apt-get install openssh-client`(ssh client usually doesn't need because ). Or `apt-get install ssh`.
3.  Startup ssh service: `sudo /etc/init.d/ssh start`.
4.  Modify the ssh configuration file: `sudo vim /etc/ssh/sshd_config`. Find the `PermitRootLogin without-password` item and change as `PermitRootLogin yes`.
5.  Reboot ssh service: `service ssh restart`.

