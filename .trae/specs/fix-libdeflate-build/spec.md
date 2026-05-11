# 修复 fanchmwrt CI 中 libdeflate 构建失败 Spec

## Why
fanchmwrt CI 在编译 `tools/libdeflate` 时失败，导致 `tools/zstd/compile` 也随之失败。而使用相同源码仓的 daewrt-ci 却能正常编译。需要找出两个 CI 的关键差异并修复 fanchmwrt CI。

## What Changes
- 在 WRT-CORE.yml 中添加 "Free Disk Space" 步骤，释放 GitHub Actions Runner 磁盘空间
- 在 WRT-CORE.yml 的环境初始化步骤中补充安装 `python3-netifaces` 和 `bc` 包
- 将缓存路径从仅缓存 `staging_dir/host*` 和 `staging_dir/tool*` 改为缓存完整的 `staging_dir`
- 移除 `/mnt/build_wrt` 符号链接创建步骤（daewrt-ci 已注释掉该步骤）

## Impact
- Affected specs: WRT-CORE.yml 构建流程
- Affected code: `.github/workflows/WRT-CORE.yml`

## 根因分析

对比 `fisher423/fanchmwrt`（失败）和 `fisher423/daewrt-ci`（成功）的 WRT-CORE.yml，发现以下关键差异：

### 差异 1：磁盘空间管理（最可能的根因）
- **daewrt-ci**：使用 `endersonmenezes/free-disk-space@v2` 释放磁盘空间，移除了 Android SDK、.NET、Haskell、Swift、Miniconda 等大量不需要的软件，可释放约 20-30GB 空间
- **fanchmwrt**：**没有**磁盘空间释放步骤。GitHub Actions Runner 默认只有约 14GB 可用空间，OpenWrt 全量编译需要大量空间，磁盘耗尽会导致 `libdeflate` 等工具编译失败

### 差异 2：依赖包安装
- **daewrt-ci**：额外安装了 `python3-netifaces` 和 `bc`
- **fanchmwrt**：仅安装 `dos2unix libfuse-dev`，缺少 `python3-netifaces`

### 差异 3：缓存策略
- **daewrt-ci**：缓存完整的 `./wrt/staging_dir` 目录
- **fanchmwrt**：仅缓存 `./wrt/staging_dir/host*` 和 `./wrt/staging_dir/tool*`，缓存不完整可能导致增量构建失败

### 差异 4：构建目录
- **daewrt-ci**：不创建 `/mnt/build_wrt` 符号链接（已注释掉）
- **fanchmwrt**：创建 `/mnt/build_wrt` 并符号链接到 `$GITHUB_WORKSPACE/wrt`

### 差异 5：构建环境初始化脚本
- **daewrt-ci**：使用本地脚本 `$GITHUB_WORKSPACE/Scripts/init_build_environment.sh`（内容与 immortalwrt 官方脚本一致，但额外安装了 golang-1.26、gh CLI、upx、padjffs2、po2lmo、modify-firmware 等工具）
- **fanchmwrt**：直接从 `https://build-scripts.immortalwrt.org/init_build_environment.sh` 下载

## ADDED Requirements

### Requirement: 磁盘空间释放
CI 构建流程 SHALL 在环境初始化之前释放 GitHub Actions Runner 的磁盘空间，确保有足够的磁盘空间完成编译。

#### Scenario: 磁盘空间不足导致编译失败
- **WHEN** CI 在默认 GitHub Actions Runner 上运行且没有释放磁盘空间
- **THEN** 编译过程中可能因磁盘空间耗尽导致 `tools/libdeflate` 等工具构建失败

#### Scenario: 释放磁盘空间后编译成功
- **WHEN** CI 在环境初始化前使用 `endersonmenezes/free-disk-space@v2` 释放磁盘空间
- **THEN** 编译过程有足够的磁盘空间，`tools/libdeflate` 可以正常构建

### Requirement: 补充依赖包
CI 构建流程 SHALL 安装 `python3-netifaces` 和 `bc` 依赖包。

#### Scenario: 缺少依赖包
- **WHEN** CI 未安装 `python3-netifaces`
- **THEN** 某些软件包的配置或编译可能失败

### Requirement: 完整缓存 staging_dir
CI 构建流程 SHALL 缓存完整的 `./wrt/staging_dir` 目录，而非仅缓存 `host*` 和 `tool*` 子目录。

#### Scenario: 部分缓存导致增量构建失败
- **WHEN** CI 仅缓存 `staging_dir/host*` 和 `staging_dir/tool*`
- **THEN** 缓存恢复后，`staging_dir` 中其他必要文件缺失，可能导致增量构建失败

## MODIFIED Requirements

### Requirement: WRT-CORE.yml 构建流程
在 "Checkout Projects" 步骤之前添加 "Free Disk Space" 步骤；在 "Initialization Environment" 步骤中补充 `python3-netifaces` 和 `bc` 包；修改缓存路径为完整的 `staging_dir`；移除 `/mnt/build_wrt` 符号链接创建。

## REMOVED Requirements

### Requirement: /mnt/build_wrt 符号链接
**Reason**: daewrt-ci 已验证不使用该符号链接也能正常编译，且该符号链接可能导致路径问题
**Migration**: 直接在 `$GITHUB_WORKSPACE/wrt` 目录下进行编译
