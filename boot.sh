#start npc boot

cp /npc/sensors/* /etc/sensors/ -Rf

if [ -e /patch/lib/mt7601Usta_v2.ko ] ; then
insmod /patch/lib/mt7601Usta_v2.ko
fi
sh /npc/do.sh
sync;sync;sync && echo 3 > /proc/sys/vm/drop_caches

