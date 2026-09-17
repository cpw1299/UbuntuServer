# 个人主机软硬件配置说明书

## 一、 硬件配置概览

| 硬件组件         | 规格型号                                          |
| :--------------- | :------------------------------------------------ |
| **主板**         | 华擎 AMD B550M-ITXac                              |
| **处理器 (CPU)** | AMD Ryzen 5 5600G (6核12线程，带核显)             |
| **内存 (RAM)**   | 32GB DDR4                                         |
| **硬盘 (SSD)**   | WD Blue SN570 1TB NVMe SSD (实际可用容量约 986GB) |

---

## 二、 主板接口详解 (华擎 AMD B550M-ITXac)

### 2.1 后置 I/O 接口
- **视频输出**：1 x HDMI 接口, 1 x DisplayPort 1.4 接口
- **USB 接口**：
  - 4 x USB 3.2 Gen1 Type-A 接口 (5Gbps)
  - 2 x USB 2.0 Type-A 接口 (包含 1 个 BIOS 闪回专用接口)
- **网络接口**：1 x RJ-45 千兆网卡接口 (Intel I219-V)
- **无线模块**：1 x Wi-Fi 5 (802.11ac) + 蓝牙 4.2 天线接口 (Intel 3168)
- **音频接口**：3 x HD 音频插孔 (支持 5.1 声道，Realtek ALC892 编解码器)
- **其他**：1 x PS/2 键鼠通用接口

### 2.2 内部接口与插槽
- **扩展插槽**：1 x PCIe 3.0 x16 插槽 (由于使用 5600G，带宽运行在 PCIe 3.0)
- **存储接口**：
  - 1 x M.2 插槽 (位于正面，PCIe 4.0 x4，由于 5600G 限制实际运行在 PCIe 3.0 x4)
  - 1 x M.2 插槽 (位于背面，PCIe 3.0 x2，用于芯片组通道)
  - 4 x SATA3 6Gbps 数据接口 (支持 RAID 0/1/10)
- **内存插槽**：2 x DDR4 DIMM 插槽 (支持双通道，最高频率视CPU内存控制器而定)
- **风扇接口**：1 x 4-pin CPU 风扇接口, 2 x 4-pin 机箱/系统风扇接口
- **前置面板接口**：
  - 1 x USB 3.2 Gen1 接针 (支持 2 个额外 USB 3.2 Gen1 接口)
  - 2 x USB 2.0 接针 (支持 4 个额外 USB 2.0 接口)
  - 前置音频接针
  - 机箱开机/重启/指示灯接针
- **供电接口**：24-pin ATX 主供电接口, 8-pin CPU 供电接口

---

## 三、 软件与存储配置

### 3.1 操作系统
- **系统名称**：Ubuntu Server 26.04 Minimal
- **分区方式**：手动分区 (GPT 分区表)

### 3.2 磁盘整体信息
- **设备路径**：`/dev/nvme0n1`
- **磁盘型号**：WD Blue SN570 1TB SSD
- **总容量**：1000GB (逻辑/物理扇区大小：512B/512B)
- **分区表类型**：GPT
- **磁盘标志**：无

### 3.3 系统信息

以下为系统当前运行状态输出：

```console
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

cpw@ubuntupc:~$ lscpu
Architecture:                x86_64
  CPU op-mode(s):            32-bit, 64-bit
  Address sizes:             48 bits physical, 48 bits virtual
  Byte Order:                Little Endian
CPU(s):                      12
  On-line CPU(s) list:       0-11
Vendor ID:                   AuthenticAMD
  Model name:                AMD Ryzen 5 5600G with Radeon Graphics
    CPU family:              25
    Model:                   80
    Thread(s) per core:      2
    Core(s) per socket:      6
    Socket(s):               1
    Stepping:                0
    Frequency boost:         enabled
    CPU(s) scaling MHz:      65%
    CPU max MHz:             4465.9731
    CPU min MHz:             403.5520
    BogoMIPS:                7785.54
    Flags:                   fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl xtopo
                             logy nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 x2apic movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic
                              cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb st
                             ibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_
                             local user_shstk clzero irperf xsaveerptr rdpru wbnoinvd cppc arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsav
                             e_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm debug_swap
Virtualization features:
  Virtualization:            AMD-V
Caches (sum of all):
  L1d:                       192 KiB (6 instances)
  L1i:                       192 KiB (6 instances)
  L2:                        3 MiB (6 instances)
  L3:                        16 MiB (1 instance)
NUMA:
  NUMA node(s):              1
  NUMA node0 CPU(s):         0-11
Vulnerabilities:
  Gather data sampling:      Not affected
  Ghostwrite:                Not affected
  Indirect target selection: Not affected
  Itlb multihit:             Not affected
  L1tf:                      Not affected
  Mds:                       Not affected
  Meltdown:                  Not affected
  Mmio stale data:           Not affected
  Old microcode:             Not affected
  Reg file data sampling:    Not affected
  Retbleed:                  Not affected
  Spec rstack overflow:      Mitigation; Safe RET
  Spec store bypass:         Mitigation; Speculative Store Bypass disabled via prctl
  Spectre v1:                Mitigation; usercopy/swapgs barriers and __user pointer sanitization
  Spectre v2:                Mitigation; Retpolines; IBPB conditional; IBRS_FW; STIBP always-on; RSB filling; PBRSB-eIBRS Not affected; BHI Not affected
  Srbds:                     Not affected
  Tsa:                       Mitigation; Clear CPU buffers
  Tsx async abort:           Not affected
  Vmscape:                   Mitigation; IBPB before exit to userspace
```

### 3.4 内存与存储使用情况

```console
cpw@ubuntupc:~$ free -m
               total        used        free      shared  buff/cache   available
Mem:           30943         741       29908           1         660       30202
Swap:           8191           0        8191
```

```console
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
```

```console
cpw@ubuntupc:~$ lsblk
NAME           MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
nvme0n1        259:0    0 931.5G  0 disk
|-nvme0n1p1    259:1    0     1G  0 part /boot/efi
|-nvme0n1p2    259:2    0     2G  0 part /boot
`-nvme0n1p3    259:3    0 928.5G  0 part
  |-vg-lv_root 252:0    0   200G  0 lvm  /
  |-vg-lv_home 252:1    0   200G  0 lvm  /home
  `-vg-lv_data 252:2    0 528.5G  0 lvm  /data
```

```console
cpw@ubuntupc:~$ blkid
/dev/mapper/vg-lv_root: UUID="c2ba74c3-044a-4b78-a50d-7ba327eeb33f" BLOCK_SIZE="4096" TYPE="ext4"
```


















