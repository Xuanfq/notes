
# Linux系统诊断

## dmesg 

Command **dmesg**
```sh
aiden@Xuanooo:~/kernel/module$ dmesg | tail
[   16.521567] systemd-journald[36]: File /var/log/journal/6032589e7118408aad929e78fed09226/system.journal corrupted or uncleanly shut down, renaming and replacing.
[   20.087987] WSL (2): Creating login session for aiden
[   20.335765] systemd-journald[36]: File /var/log/journal/6032589e7118408aad929e78fed09226/user-1000.journal corrupted or uncleanly shut down, renaming and replacing.
[   49.297547] hello: disagrees about version of symbol module_layout
[   49.591882] hv_balloon: Max. dynamic memory size: 8118 MB
[  732.817203] hello: disagrees about version of symbol module_layout
[  823.716038] nf_conntrack: default automatic helper assignment has been turned off for security reasons and CT-based firewall rule not found. Use the iptables CT target to attach helpers instead.
[  964.585417] hello: disagrees about version of symbol module_layout
[ 1182.709346] hello: disagrees about version of symbol module_layout
[ 1646.063379] hello: disagrees about version of symbol module_layout
```






















