# KernelSU / KernelSU-Next for crDroid on Xiaomi MIX 2

这是基于 **crDroid Android 15 的 Xiaomi MIX 2（chiron）底包**进行内核替换、
KernelSU 集成与 boot 镜像重打包的非官方项目。保留旧版 KernelSU 和
KernelSU-Next 两套产物。

适配底包：`crDroidAndroid-15.0-20260805-chiron-v11.17.zip`。
**不要将这些 boot 镜像用于其他机型、ROM 或版本。**

准确的来源关系：内核源码底座来自 LineageOS
`android_kernel_xiaomi_msm8998`，Linux `4.4.302`；boot 镜像以
上述 crDroid 底包的 `boot.img` 为模板，保留原 ramdisk、启动参数和页面布局，
替换内核并重新计算 Android boot header v0 的 SHA-1 ID。
这不是 crDroid 或 KernelSU 官方发行版。

## 下载

编译产物和完整源码归档在本仓库 **Releases** 中；校验清单位于
[`artifacts/SHA256SUMS`](artifacts/SHA256SUMS)。

| 版本 | boot 镜像 | 管理器 |
| --- | --- | --- |
| KernelSU-Next `v3.2.0-legacy` / 驱动 `33129` | `KernelSU-Next-33129-chiron-crDroidAndroid-15.0-20260805-boot.img` | `KernelSU_Next_v3.2.0_33129-release.apk` |
| 原版 KernelSU `v0.9.5` / 驱动 `11872` | `KernelSU-chiron-crDroidAndroid-15.0-20260805-boot.img` | 需要对应旧版管理器，本次未归档 APK |

`Image.gz-dtb` 和 `kernel.config` **仅对应 Next 版本**，不能当作旧版内核或配置。
Next APK 是上游配套发行包，不是本仓库重新编译的应用。

旧版 KernelSU 镜像仅作历史保留，不适配此次使用的新版管理器。
历史会话记录了 Next 镜像刷入后设备正常启动，但最初使用的官方 KernelSU
管理器仍提示非 GKI 不支持；随后下载了配套 Next 管理器。
**没有记录证明配套 APK 安装后的 Root 授权已经通过实机验证。**

## 源码与构建

参见 [`BUILD.md`](BUILD.md) 和 [`sources/README.md`](sources/README.md)。
本仓库提供固定上游提交、实际修改补丁、Dockerfile、构建脚本和 boot 打包脚本。
Release 同时保存 Next 实际构建源码快照、原版 KernelSU 源码和内核基线源码。
不上传完整 ROM、编译缓存、Docker 虚拟磁盘或私人文件。

## 使用与风险

刷写前自行备份原始 boot 镜像，并准备可用的恢复方式。需要解锁 bootloader，
刷写错误可能导致无法启动；不要擦除数据或关闭安全机制来绕过版本不匹配。
本仓库不提供自动刷机脚本。

在确认设备为 chiron、底包版本完全一致且已完成备份后，手动执行：

```sh
adb reboot bootloader
fastboot flash boot KernelSU-Next-33129-chiron-crDroidAndroid-15.0-20260805-boot.img
fastboot reboot
```

原版镜像需替换上述文件名，并使用与旧版驱动匹配的管理器。
两版镜像二选一，不要连续刷写两版后误以为同时生效。

## 许可与致谢

内核、KernelSU 和 KernelSU-Next 的版权与许可属于各自上游作者；源码归档保留
上游许可文件。补丁中的第三方代码继续遵循其原有许可，不因本仓库重新许可。
本仓库新增的构建与校验脚本、文档采用 GPL-2.0-only。

感谢 LineageOS、crDroid、tiann/KernelSU 和 KernelSU-Next 项目。
