# DIGOO DG-M1X hacks

This is a log of simple hacks for the cheap, linux driven, Digoo DG-M1X. For now, this is only about to bring wifi up without using the app, setting the correct time(-zone) and installing an ssh server in place for the shipped telnetd. The api of the pan-tilt-zoom service could also be reverse engineered.

Out of the box, this cam "features":
- open telnet access as root (at least on this firmware `Linux goke 3.4.43-gk #56 PREEMPT Fri Sep 29 00:24:56 PDT 2006 armv6l GNU/Linux`)
- ONVIF should be accessible at port 5000. Due to the android app tinyCam Monitor, it is supposed to use ONVIF `Profile S` (but as well as a lot of other people, I couldn't get it to work in other software). 
- rtsp access with `user: admin`, `pw: 20160404` at `port: 554` and `path: /onvif1` (respectively `/onvif2` with lower quality), e.g. `vlc rtsp://admin:20160404@<your-cams-ip>/onvif1`

Using these rtsp parameters, I could get it to setup manually in every software I tried so far, except out of the box PTZ (e.g. [Synology Surveillance Station](https://www.synology.com/de-de/surveillance), [Shinobi](https://github.com/ShinobiCCTV/Shinobi) or [Home Assistant](https://home-assistant.io/)).

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

To replace telnet with ssh, copy all files of `npc` to `/npc` on your cam (TODO, please have a closer look on what you are doing here, this is not failsafe atm). You can do this e.g. using wget
(the wget embedded in busybox is not capable of https/tls) or by inserting a sd card (not tested).
Thx thomas (https://github.com/ant-thomas/zsgx1hacks) for pre-compiling dropbearmulti!

Generate your own password hash with `openssl passwd -1` (follow the prompt) and add it to `do.sh`
For a public key authentication to work, add your public key(s) in `npc/root-home/.ssh/authorized_keys`
Then execute `do.sh` and everything should be setup. To make this persistent, add `sh /npc/do.sh` to `/npc/boot.sh` (skip this if you already copied the file to the cam). You should however always make sure that your script is working. Otherwise the cam could get inaccessible from the network.


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


## PTZ

I do not assume this cam is following the official ONVIF standard as most ONVIF clients are not working with it (although I do not have any clue about the ONVIF standard).
Using the android app [tinyCam Monitor](https://play.google.com/store/apps/details?id=com.alexvas.dvr&hl=de) and [packet capture](https://play.google.com/store/apps/details?id=app.greyshirts.sslcapture&hl=de)), I could monitor all pan and tilt actions and quickly reverse engineered the appropriate commands. ~~Please note that so far I didn't have a closer look into how the password and nonce is managed~~ , authentication is not done at all…, see the example request.
For pan and tilt, send a SOAP request with the following body to port 5000 on path `/onvif/device_service`, e.g. for moving to the left (see [ptz_request.xml](ptz_request.xml) or listing below):

`curl -H "Content-Type: application/soap+xml" -X POST -d "@ptz_request.xml" http://$your-cams-ip:5000/onvif/device_service`

And the plain xml body:
```
<v:Envelope 
    xmlns:i="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:d="http://www.w3.org/2001/XMLSchema" 
    xmlns:c="http://www.w3.org/2003/05/soap-encoding" 
    xmlns:v="http://www.w3.org/2003/05/soap-envelope">
    <v:Header>
        <Security v:mustUnderstand="1" 
            xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
            <UsernameToken 
                xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
                <Username>admin</Username>
                <Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">tada_your_non_exisisting_password=</Password>
                <Nonce>non_existing_nonce</Nonce>
                <Created 
                    xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">2018-01-16T11:43:32Z
                </Created>
            </UsernameToken>
        </Security>
    </v:Header>
    <v:Body>
        <ContinuousMove 
            xmlns="http://www.onvif.org/ver20/ptz/wsdl">
            <ProfileToken>IPCProfilesToken0</ProfileToken>
            <Velocity>
                <PanTilt 
                    xmlns="http://www.onvif.org/ver10/schema" x="-1.0" y="0.0"/>
            </Velocity>
        </ContinuousMove>
    </v:Body>
</v:Envelope>

```
Specification: https://www.onvif.org/ver20/ptz/wsdl/ptz.wsdl

Table of possible movements (see [PanTilt tag](ptz_request.xml#L26))

| x    | y    | Action            |
|------|------|-------------------|
| 0.0  | -1.0 | move down         |
| 0.0  | 1.0  | move up           |
| 1.0  | 0.0  | move to the right |
| -1.0 | 0.0  | move to the left  |


## Software

The Digoo DG-M1Q inspected by e.g, [kfowlks]](https://github.com/kfowlks/DG-M1Q) and [yuvadm](https://github.com/yuvadm/DG-M1Q) _seems_ to run a similar (if not the same) software than the m1x. Find dmesg, pictures, serial logs, etc. there.


## TODO 
  - scp: link scp from dropbearmulti to $PATH?
  - disable internet access using hosts file?
  - remove telnetd

