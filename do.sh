#!/bin/sh

cd /npc/
# TODO add your $password-hash here
sed -i -e 's/root::10933:0:99999:7:::/root:$password-hash:10933:0:99999:7:::/g' /etc/shadow
mkdir -p /etc/dropbear
cp /npc/dropbear_ecdsa_host_key /etc/dropbear/

./dropbearmulti dropbear

