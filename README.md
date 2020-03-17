## REMARKS
- Prepared for Ubuntu-based Clonezilla Live (alternative stable)
- Tested only on one machine with one WiFi adapter
- Feel free to fork and modify to your liking

## HOW-TO

1. Put ocs_prerun.sh in root drive of the USB

2. Create/modify GRUB menu to enable ocs_prerun

```bash
menuentry "Clonezilla live WiFi (Default settings, KMS with large font)"{
  search --set -f /live/vmlinuz
  linux /live/vmlinuz boot=live union=overlay username=user hostname=eoan config quiet components noswap edd=on enforcing=0 locales=en_US.UTF-8 keyboard-layouts=keep ocs_prerun="bash /lib/live/mount/medium/ocs_prerun.sh" ocs_live_run="ocs-live-general" ocs_live_extra_param="" ocs_live_batch="no" vga=791 ip= net.ifnames=0  splash live_console_font_size=16x32
  initrd /live/initrd.img
}
```

