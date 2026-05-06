# fanchmwrt 编译脚本注入 re-ss-01 设备支持实施计划

## 摘要

本计划旨在修改 fanchmwrt/fanchmwrt 仓库的编译脚本，使其能够在编译过程中动态注入对京东云 re-ss-01 设备的支持。re-ss-01 是一款基于 Qualcomm IPQ6000 (IPQ60xx) 芯片的路由器，原生 fanchmwrt 仓库不支持该设备。

## 当前状态分析

### fanchmwrt 仓库现状
- **主分支**: `fanchmwrt-25.12.2`
- **内核版本**: 待确认（参考仓库使用 6.12）
- **支持的设备**: GL-iNet AXT-1800, JDC-AX6600, GL-MT5000, GL-MT3600BE, TR-3000
- **目标平台**: 主要支持 MediaTek (filogic) 和部分 Qualcomm (ipq60xx 仅有 AXT1800/JDC-AX6600)
- **缺失**: `target/linux/qualcommax/ipq60xx` 子目标目录

### 参考仓库 (fisher423/Openwrt_Builder) 提供的解决方案
1. **`sh/inject-device-support.sh`**: 从 ImmortalWrt 克隆设备支持文件
2. **`sh/scripts-part1.sh`**: 包含 `jdcloud_re-ss-01` 设备检测和初始化逻辑
3. **`.github/workflows/Build-jdcloud_re-ss-01.yml`**: 完整的编译工作流
4. **`config/jdcloud_re-ss-01.config`**: 设备配置模板

## 实施计划

### 步骤 1: 创建设备支持注入脚本

**文件**: `sh/inject-device-support.sh`

**来源**: 从参考仓库 fisher423/Openwrt_Builder 复制

**功能**:
- 从 ImmortalWrt master 分支克隆 `target/linux/qualcommax/` 目录
- 复制 ipq60xx 子目标、DTS 文件、image 配置
- 自动检测并添加 `jdcloud_re-ss-01` 设备定义到 `ipq60xx.mk`
- 确保必要的 target.mk 和 config-default 文件存在

**关键配置**:
```bash
IMMORTALWRT_URL="https://github.com/immortalwrt/immortalwrt.git"
IMMORTALWRT_BRANCH="master"
```

### 步骤 2: 修改 scripts-part1.sh 添加设备检测逻辑

**文件**: `sh/scripts-part1.sh`

**修改内容**: 添加新的逻辑块处理 `jdcloud_re-ss-01` 设备

```bash
# --- 逻辑块 6: 处理 jdcloud_re-ss-01 ---
elif [[ "$WORKFLOW_NAME" == "jdcloud_re-ss-01" ]]; then
    echo ">>> 检测到设备: $WORKFLOW_NAME。开始执行 jdcloud_re-ss-01 的特定修改"

    # 修改默认 IP 地址为 192.168.31.1
    sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate
    echo "jdcloud_re-ss-01 IP 修改为 192.168.31.1"

    # 调用设备支持注入脚本
    echo ">>> 开始从 ImmortalWrt 注入 jdcloud_re-ss-01 设备支持..."
    chmod +x $GITHUB_WORKSPACE/sh/inject-device-support.sh
    $GITHUB_WORKSPACE/sh/inject-device-support.sh
    echo ">>> jdcloud_re-ss-01 设备支持注入完成"
fi
```

### 步骤 3: 创建设备配置文件

**文件**: `config/jdcloud_re-ss-01.config`

**来源**: 从参考仓库 fisher423/Openwrt_Builder 复制并适配

**内容要点**:
- Target 架构: `CONFIG_TARGET_qualcommax=y`
- 子目标: `CONFIG_TARGET_qualcommax_ipq60xx=y`
- 设备 Profile: `CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_jdcloud_re-ss-01=y`
- 设备专属包: `CONFIG_PACKAGE_ipq-wifi-jdcloud_re-ss-01=y`
- 基础网络和 LuCI 配置

### 步骤 4: 创建 GitHub Actions Workflow

**文件**: `.github/workflows/build-jdcloud-re-ss-01.yml`

**来源**: 从参考仓库 fisher423/Openwrt_Builder 复制并修改源码仓库地址

**关键配置**:
```yaml
env:
  WORKFLOW_NAME: jdcloud_re-ss-01

jobs:
  build:
    name: Build jdcloud_re-ss-01
    runs-on: ubuntu-22.04
    strategy:
      matrix:
        include:
          - device: jdcloud_re-ss-01
            repo_url: 'https://github.com/fanchmwrt/fanchmwrt.git'
            repo_branch: 'fanchmwrt-25.12.2'
            config_file: './config/jdcloud_re-ss-01.config'
```

## 文件变更清单

| 操作 | 文件路径 | 说明 |
|------|----------|------|
| 新增 | `sh/inject-device-support.sh` | 设备支持注入脚本 |
| 修改 | `sh/scripts-part1.sh` | 添加 jdcloud_re-ss-01 设备处理逻辑 |
| 新增 | `config/jdcloud_re-ss-01.config` | 设备编译配置文件 |
| 新增 | `.github/workflows/build-jdcloud-re-ss-01.yml` | GitHub Actions 编译工作流 |

## 编译后的固件信息

- **默认 IP**: 192.168.31.1
- **默认密码**: 无
- **SoC**: Qualcomm IPQ6000 (IPQ60xx)
- **架构**: ARM Cortex-A53 (arm64)
- **无线驱动**: ath11k

## 验证步骤

1. **脚本语法检查**: 运行 `bash -n sh/inject-device-support.sh` 和 `bash -n sh/scripts-part1.sh`
2. **Workflow 语法检查**: 使用 GitHub Actions 的 YAML 验证
3. **功能测试**: Fork 仓库后在 GitHub Actions 中手动触发编译
4. **固件验证**: 下载编译产物，检查以下内容:
   - `bin/targets/qualcommax/ipq60xx/` 目录存在
   - 包含 `*-jdcloud_re-ss-01-*` 命名的固件文件
   - 固件可以正常启动

## 潜在问题和解决方案

### 问题 1: 内核版本兼容
- **描述**: ImmortalWrt master 分支可能使用不同版本的内核
- **解决**: inject-device-support.sh 脚本会下载对应的 vermagic 并在 scripts-part1.sh 中处理

### 问题 2: 无线驱动缺失
- **描述**: re-ss-01 需要 `ipq-wifi-jdcloud_re-ss-01` 无线固件包
- **解决**: 确保配置文件中包含 `CONFIG_PACKAGE_ipq-wifi-jdcloud_re-ss-01=y`

### 问题 3: 编译时间较长
- **描述**: 首次编译需要下载和编译整个工具链
- **解决**: GitHub Actions 工作流配置了 ccache 缓存

## 实施顺序

1. 创建 `sh/inject-device-support.sh` 脚本
2. 修改 `sh/scripts-part1.sh` 添加设备检测逻辑
3. 创建 `config/jdcloud_re-ss-01.config` 配置文件
4. 创建 `.github/workflows/build-jdcloud-re-ss-01.yml` 工作流
5. 提交到 fanchmwrt fork 仓库并触发测试编译
