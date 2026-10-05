# crDroid chiron KernelSU 双版本归档

适配 Xiaomi MIX 2（chiron）的
`crDroidAndroid-15.0-20260805-chiron-v11.17` 底包，非官方发行。
内核基线来自 LineageOS MSM8998 Linux 4.4.302，boot 以 crDroid 原始镜像为模板，
保留 ramdisk，集成 KernelSU 后替换内核。

- Next：`v3.2.0-legacy`，驱动 `33129`，附配套 Next 管理器 APK。
- 原版：KernelSU `v0.9.5`，驱动 `11872`，作为历史镜像保留；未附旧版管理器。
- `Image.gz-dtb` 与 `kernel.config` 只对应 Next。
- 附 SHA-256 清单、Next 实际构建源码快照、内核基线与原版 KernelSU 源码。
- 原版最终构建树未单独保留，源码与补丁说明见仓库 `BUILD.md`。

两版 boot 均通过 header v0 / SHA-1 检查，Next 内核 payload 匹配归档内核，
ramdisk 与指定 crDroid boot 一致。历史记录证明 Next 镜像启动成功，但没有
配套 Next APK 安装后 Root 授权验证的完整记录。

仅限指定设备与底包。请先备份原 boot 并准备恢复方式；其他 ROM 不保证兼容。
本次归档没有重新刷写手机，也未执行完整重编译。
