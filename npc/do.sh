#!/bin/sh

rdate -s time.fu-berlin.de
ln -s /npc/Europe/Berlin /etc/localtime

cd /npc/
# TODO add your $password-hash here. replace the default password hash $1$GCcN0wVC$CJ9NVUwHpDDAjP2aArAss/ - (pass: toor)
sed -i -e 's/root::10933:0:99999:7:::/root:$1$GCcN0wVC$CJ9NVUwHpDDAjP2aArAss\/:10933:0:99999:7:::/g' /etc/shadow
sed -i -e 's/root:x:0:0:root:\/root:\/bin\/sh/root:x:0:0:root:\/npc\/root-home:\/bin\/sh/g' /etc/passwd
mkdir -p /etc/dropbear
cp /npc/dropbear_ecdsa_host_key /etc/dropbear/

./dropbearmulti dropbear

