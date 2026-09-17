
### 主机硬件

- 主板：华擎B550M-ITXac
- CPU：AMD R5600G
- 内存：32GB
- 硬盘：986GB

### 操作系统

- Ubuntu Server 26.04 Minimal

cpw@ubuntupc:~$ uname -r
7.0.0-29-generic
cpw@ubuntupc:~$ uname -m
x86_64
cpw@ubuntupc:~$ uname -a
Linux ubuntupc 7.0.0-29-generic #29-Ubuntu SMP PREEMPT_DYNAMIC Fri Jul 17 20:52:35 UTC 2026 x86_64 GNU/Linux
cpw@ubuntupc:~$ cat /etc/os-release
PRETTY_NAME="Ubuntu 26.04 LTS"
NAME="Ubuntu"
VERSION_ID="26.04"
VERSION="26.04 (Resolute Raccoon)"
VERSION_CODENAME=resolute
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=resolute
LOGO=ubuntu-logo
cpw@ubuntupc:~$ hostnamectl
 Static hostname: ubuntupc
       Icon name: computer-desktop
         Chassis: desktop 🖥️
      Machine ID: d9131cc719254c93a3047259145040df
         Boot ID: 2fcedb32c4a4478daedd4fb9dfe19178
Operating System: Ubuntu 26.04 LTS
          Kernel: Linux 7.0.0-29-generic
    Architecture: x86-64
 Hardware Vendor: ASRock
  Hardware Model: B550M-ITX/ac
Firmware Version: P3.90
   Firmware Date: Wed 2025-10-01
    Firmware Age: 10month 2w 5d
cpw@ubuntupc:~$ free -m
               total        used        free      shared  buff/cache   available
Mem:           30943         741       29908           1         660       30202
Swap:           8191           0        8191
cpw@ubuntupc:~$ df -m
Filesystem             1M-blocks  Used Available Use% Mounted on
tmpfs                       6189     2      6188   1% /run
/dev/mapper/vg-lv_root    200502 11048    179199   6% /
tmpfs                      15472     0     15472   0% /dev/shm
efivarfs                       1     1         1   9% /sys/firmware/efi/efivars
none                           1     0         1   0% /run/credentials/systemd-journald.service
none                           1     0         1   0% /run/credentials/systemd-resolved.service
none                           1     0         1   0% /run/credentials/systemd-networkd.service
tmpfs                      15472     0     15472   0% /tmp
/dev/nvme0n1p2              1946   130      1698   8% /boot
/dev/mapper/vg-lv_home    200502     3    190244   1% /home
/dev/mapper/vg-lv_data    531551     3    504476   1% /data
/dev/nvme0n1p1              1073     7      1067   1% /boot/efi
none                           1     0         1   0% /run/credentials/getty@tty1.service
tmpfs                       3095     1      3095   1% /run/user/1000
cpw@ubuntupc:~$ lsblk
NAME           MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
nvme0n1        259:0    0 931.5G  0 disk
|-nvme0n1p1    259:1    0     1G  0 part /boot/efi
|-nvme0n1p2    259:2    0     2G  0 part /boot
`-nvme0n1p3    259:3    0 928.5G  0 part
  |-vg-lv_root 252:0    0   200G  0 lvm  /
  |-vg-lv_home 252:1    0   200G  0 lvm  /home
  `-vg-lv_data 252:2    0 528.5G  0 lvm  /data
[root@L14Centos ~]# blkid
/dev/sda1: UUID="81dc82f2-3a11-4564-ad18-152ce84c6c34" TYPE="xfs"
/dev/sda2: UUID="HpF2BA-cXtg-FVV8-l2Ef-eo0U-Fpkw-S75Hhn" TYPE="LVM2_member"
/dev/mapper/centos-root: UUID="fb30f048-828e-46fc-9306-87b8643930d6" TYPE="xfs"
