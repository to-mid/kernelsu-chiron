# crDroid chiron KernelSU 构建与打包记录

整理日期：2026-10-05。历史编译完成于 2026-10-02。

## 来源与版本

适配 `crDroidAndroid-15.0-20260805-chiron-v11.17.zip`，
设备为 Xiaomi MIX 2 / chiron / MSM8998，内核为 Linux 4.4.302。
内核源码来自 LineageOS；crDroid 提供本次重打包使用的原始 boot 模板。
本项目不是 crDroid 或 KernelSU 官方发行版。

| 组件 | 上游 | 固定提交 |
| --- | --- | --- |
| 内核 | `LineageOS/android_kernel_xiaomi_msm8998` | `e0a1a7747eb61e1d77ebcdebbcd48af0dc3b6c21` |
| 原版 KernelSU v0.9.5 | `tiann/KernelSU` | `b766b98513b5a7eb33bc1c4a76b5702bf1288f07` |
| Next v3.2.0-legacy | `KernelSU-Next/KernelSU-Next` | `9b08e88862000d5c50fb2e43a5b75123cf472e54` |

原版驱动为 11872，新版 Next 驱动为 33129。历史尝试过标准 Next v3.3.0，
但部分头文件和 API 不适用于本次 Linux 4.4 构建，因此最终使用 legacy
标签，并修复 `kernel/selinux/rules.c` 中的 sched 头文件选择。

## 补丁和快照

- `patches/kernel-host.patch`：宿主机受 Git 跟踪的修改，含 KSU 接入、Clang
  兼容调整，以及 macOS 大小写冲突造成的 netfilter 文件变化。原脚本会将这些
  修改同步到 Linux 卷；本次如实归档。**netfilter 差异并非均为有意的功能修复，
  不应当作经过审计的最佳实现**。
- `patches/kernel-next-built.patch`：实际 Linux 构建卷的修改，含上述改动和
  Next 自动生成的旧内核适配；对应最终 Next 源码快照。
- `patches/kernelsu-next-linux44.patch`：Next 本地 sched 头文件兼容调整。
- `resume-build.patch`：历史续编用的局部补丁，已被完整补丁覆盖，不要重复应用。
- `build/build-kernel.original.sh`：实际使用过的原构建脚本，归档原样。

原版 KernelSU 最终构建时的独立 Linux 源码快照未保留。提供其固定上游源码、
共享宿主补丁和构建方式供复核，但不能宣称旧镜像可逐字节复现。
Next 的完整实际构建源码快照随 Release 提供。

## 构建

需要 Docker Desktop 或 Linux Docker，以及联网拉取固定上游源码的能力。
新版脚本将源码放在大小写敏感的 Docker 卷中，不在 macOS 文件系统克隆完整
内核树；不复用或清理历史的 `kernelsu-chiron-build-workspace` 卷。

```sh
git clone https://github.com/to-mid/kernelsu-chiron.git
cd kernelsu-chiron
bash build-kernel.sh next
# 或构建原版：
bash build-kernel.sh legacy
```

输出在 `artifacts/next/` 或 `artifacts/legacy/`：
`Image.gz-dtb` 和 `kernel.config`。配置来源为 `chiron_defconfig`，
启用 KSU 和 Kprobes。使用 Ubuntu 22.04 软件包工具链、Clang/lld、
aarch64 与 ARM32 交叉工具链，保留 `KCFLAGS=-Wno-error`。
警告不中止构建，但语法和链接错误仍会失败。

为避免覆盖修改，脚本遇到已有的受跟踪源码修改会停止；再次构建需使用新的空卷。
可通过 `KERNEL_BUILD_VOLUME` 环境变量指定新卷名。
新版脚本本次只做语法与补丁应用检查，**未重新执行完整编译**。
基础镜像和软件包未锁定 digest，时间戳也未固定，重建哈希可能不同。
Next 版本号依赖完整 Git 提交计数，不要改用浅克隆。

## 重打包

自行取得匹配底包，提取原始 boot，不使用其他 ROM 的 boot 模板：

```sh
unzip -p crDroidAndroid-15.0-20260805-chiron-v11.17.zip boot.img > original-boot.img
python3 repack_legacy_boot.py \
  original-boot.img artifacts/next/Image.gz-dtb rebuilt-next-boot.img
python3 verify_boot.py rebuilt-next-boot.img \
  --kernel artifacts/next/Image.gz-dtb --original original-boot.img
```

打包脚本只支持 Android boot header v0，保留原 ramdisk、second payload 和
尾部数据，只替换 kernel 并重算 SHA-1 ID。它不会签署新的 AVB 元数据，也不保证
任意带签名的 boot 模板可用。完整 ROM 和原始 boot 不随仓库重新分发。

## 验证边界

两版归档 boot 均检查 header v0 布局与 SHA-1 ID。Next 镜像的内核与归档
`Image.gz-dtb` 一致，两个 boot 的 ramdisk 均与原始 crDroid boot 一致。
原始 crDroid boot 的 ID 与本打包脚本计算规则不同；校验脚本严格检查输出镜像
的 ID，对 `--original` 仅解析布局并比对 payload，不要求原始 ID 同样计算。
现存 `kernel.config` 仅为 Next 的最终配置。SHA-256 清单覆盖 Release
二进制与源码归档。

历史记录证明编译、打包和 Next 镜像启动成功，但不等于所有设备功能或 Root
流程已全面验证。本次发布不连接手机，不执行刷写。
