# 源码归档

完整源码以 `.tar.gz` 附件保存在 Release，不纳入 Git 历史。

| 附件 | 内容 |
| --- | --- |
| `KernelSU-Next-33129-built-source.tar.gz` | 实际构建 Linux 卷中的 `kernel/` 与 `KernelSU-Next/`，含本地修改及上游许可文件；排除 `.git` 与 `out` |
| `kernel-base-e0a1a774.tar.gz` | 固定 LineageOS 内核提交的完整基线，保留仅大小写不同的文件 |
| `KernelSU-v0.9.5-b766b985.tar.gz` | 固定原版 KernelSU 提交的完整源码 |

在 Linux 大小写敏感文件系统或 Docker 卷中解压，不要直接解压到默认 macOS
文件系统。Next 快照中的 `kernel/drivers/kernelsu` 是指向
`../../KernelSU-Next/kernel` 的软链接，两个目录须保留在同一父目录。

归档不含 Git 历史。Next 的版本计算需要 Git 提交计数，所以从归档重建时须恢复
对应完整 Git 历史，或使用仓库构建脚本克隆固定提交。快照适合检查实际源码，
不应直接假定去掉 `.git` 后仍能生成相同驱动版本。

原版源码重建使用内核基线与 `patches/kernel-host.patch`，
但没有旧版最终构建树的独立快照。完整构建方式与限制见 `BUILD.md`。
