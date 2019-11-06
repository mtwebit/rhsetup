sed -i ... /etc/ssh/sshd_config
semanage port -a -t ssh_port_t -p tcp 10222
firewall-cmd --permanent --zone=public --add-port=
firewall-cmd --reload
