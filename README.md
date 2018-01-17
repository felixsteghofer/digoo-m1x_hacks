# DIGOO DG-M1X hacks

This is a log of simple hacks for the cheap m1x. For now, this is only about to bring wifi up without using the app, setting the correct time(-zone) and installing an ssh server in place for the shipped telnetd.

Out of the box, this cam features:
- open telnet access as root (at least on this firmware `Linux goke 3.4.43-gk #56 PREEMPT Fri Sep 29 00:24:56 PDT 2006 armv6l GNU/Linux`)
- rtsp access with user `admin`, pw `20160404` at port `554` and path `/onvif1` (respectively `/onvif2` with lower quality), e.g. `vlc rtsp://admin:20160404@<your-cams-ip>/onvif1`
- ONVIF should be accessible at port 5000. Due to the android app tinycam, it is supposed  to use ONVIF `Profile S` (but as well as a lot of other people, I couldn't get it to work in other software). I have dumped some network traffic between tinycam and the cam but didn't had the time to investigate that so far.

Of course: Everything at your own risk here…


## Setup

First of all, make sure to disable internet access for the cam! (e.g. using your fritzbox parental controls or iptables of your router)

To setup the wifi of your m1x, you may simply telnet to the cam as root (no password) and edit `/rom/wpa_supplicant0.conf`:

```
ctrl_interface=/etc/Wireless  
 network={ 
     ssid="$SSID"   
     psk="$yourpw"
  }
```

Reboot and the cam should be connected to your network.

To replace telnet with ssh, copy all files of `npc` to `/npc` on your cam. You can do this e.g. using wget
(the wget embedded in busybox is not capable of https/tls) or by inserting a sd card (not tested).
Thx thomas (https://github.com/ant-thomas/zsgx1hacks) for pre-compiling dropbearmulti.

Generate your own password hash with `openssl passwd -1` (follow the prompt) and add it to `do.sh`
For a public key authentication to work, add your public key(s) in `npc/root-home/.ssh/authorized_keys`


## Persistency

```
# cat /proc/mounts 

rootfs / rootfs rw 0 0
/dev/root / squashfs ro,relatime 0 0
proc /proc proc rw,relatime 0 0
tmpfs /dev tmpfs rw,relatime 0 0
tmpfs /tmp tmpfs rw,relatime 0 0
sysfs /sys sysfs rw,relatime 0 0
devpts /dev/pts devpts rw,relatime,mode=600,ptmxmode=000 0 0
/dev/ram0 /mnt/ramdisk tmpfs rw,relatime 0 0
/dev/ram0 /etc tmpfs rw,relatime 0 0
/dev/ram0 /tmp tmpfs rw,relatime 0 0
/dev/mtdblock4 /rom jffs2 rw,relatime 0 0
/dev/mtdblock5 /npc jffs2 rw,relatime 0 0

```

To store files persistently use `/rom` or `/npc`. Here, `/rom` is used for setting up wifi in `/rom/wpa_supplicant0.conf` and `/npc` is used for all other stuff. `/npc/boot.sh` can be used to trigger commands in the boot process, e.g. our own init script (`sh /npc/do.sh`).



## Sync time

The busybox in this cam does not ship any ntp binaries but uses `rdate` to let you sync time with remote servers (it also appears to not have a hardware clock)
```
# hwclock -r

Thu Jan  1 00:00:00 1970  0.000000 seconds
```

As rdate is very uncommon these days, you have to find a sync server that supports rdate clients (e.g. `time.fu-berlin.de` or `time-a-g.nist.gov`).

For the correct time to show up, add your corresponding timezone file inside a persistent folder (e.g. `/npc/zoneinfo`). You will find those files on most linux systems in `/usr/share/zoneinfo/`. It is important to not only copy the actual binary timezone file, but also to create the folder it is residing in and symlink that to `/etc/localtime`, for example for Berlin `ln -s /npc/zoneinfo/Europe/Berlin /etc/localtime`.


## TODO 
  - scp: link scp from dropbearmulti to $PATH?
  - disable internet access using hosts file?
  - remove telnetd

