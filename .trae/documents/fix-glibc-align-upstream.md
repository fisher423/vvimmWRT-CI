# 修复 GLIBC_2.38 编译错误 — 对齐上游编译脚本

## 问题概述

WRT-CORE.yml 在 GitHub Actions 上编译时遇到 GLIBC_2.38 兼容性错误。多次尝试修复（手动降级包、直接下载 .deb、apt-mark hold 等）均失败。根本原因是我们的环境初始化方式与上游成功方案不一致。

## 当前状态分析

### 当前 WRT-CORE.yml 的问题
1. **缺少磁盘清理步骤**：没有使用 `hugoalh/disk-space-optimizer-ghaction` 清理预装软件
2. **没有使用 `init_build_environment.sh`**：改为手动安装依赖，但导致 GLIBC 版本不兼容
3. **直接下载 .deb 降级失败**：`coreutils_8.32-4.1ubuntu1.2_amd64.deb` 下载到的是 404 HTML 页面而非真正的 deb 文件
4. **`apt-mark hold` 无效**：因为 coreutils deb 文件已损坏

### 上游成功方案（m0eak/Openwrt_Builder + fisher423/Openwrt_Builder）
```yaml
# 步骤1: 磁盘清理 Action
- uses: hugoalh/disk-space-optimizer-ghaction@v0.8.1

# 步骤2: 手动磁盘清理2
- run: sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc ...

# 步骤3: 初始化环境（关键！）
- run: |
    sudo rm -rf /etc/apt/sources.list.d/*
    sudo -E apt-get -yqq update
    sudo -E apt-get -yqq purge azure-cli* ghc* zulu* ...
    sudo bash -c 'bash <(curl -s https://build-scripts.immortalwrt.org/init_build_environment.sh)'
    sudo -E apt-get -yqq autoremove --purge
    sudo -E apt-get -yqq clean
```

**关键洞察**：上游使用 `init_build_environment.sh`（包含 `apt full-upgrade`）且能正常工作，是因为磁盘清理 Action 先清理了预装的不兼容软件包，确保 `apt full-upgrade` 只升级到 Ubuntu 22.04 (jammy) 仓库中的版本，而不会引入 24.04 (noble) 的包。

### 其他发现
1. **inject-device-support.sh 缺少 wifi board 文件复制**：fisher423 版本会复制 `package/firmware/ipq-wifi/board-*jdcloud*` 文件，我们的版本没有
2. **Settings.sh 中 jdcloud 检测路径错误**：`./Config/$WRT_CONFIG.txt` 在 `cd ./wrt/` 后找不到配置文件

## 修改计划

### 文件1: `.github/workflows/WRT-CORE.yml`

**修改内容**：重写环境初始化部分，对齐上游成功方案

具体变更：
1. **删除** "Check Runner OS" 步骤（调试用，不需要）
2. **新增** "磁盘清理" 步骤：使用 `hugoalh/disk-space-optimizer-ghaction@v0.8.1`
3. **新增** "磁盘清理2" 步骤：手动删除 dotnet, android, ghc, swift, CodeQL 等
4. **重写** "Initialization Environment" 步骤：
   - 保留 `sudo rm -rf /etc/apt/sources.list.d/*`
   - 保留 `sudo -E apt-get -yqq update`
   - 保留 `sudo -E apt-get -yqq purge ...`
   - **替换**手动依赖安装和 .deb 降级为 `sudo bash -c 'bash <(curl -s https://build-scripts.immortalwrt.org/init_build_environment.sh)'`
   - 保留 `sudo -E apt-get -yqq autoremove --purge` 和 `clean`
   - 保留时区设置
   - 保留 `/mnt/build_wrt` 和 `/workdir` 创建
   - **删除**所有 GLIBC 修复代码（.deb 下载、apt-mark hold、验证步骤）
5. **保留** "Install local Automake 1.17" 步骤（fanchmwrt 需要）
6. **保留** "Inject Device Support" 步骤
7. 其余步骤不变

### 文件2: `Scripts/inject-device-support.sh`

**修改内容**：添加 wifi board 文件复制，对齐 fisher423 版本

在步骤 [2/4] 中添加：
```bash
# 复制 wifi board 文件
WIFI_BOARD_DIR="$OPENWRT_DIR/package/firmware/ipq-wifi"
mkdir -p "$WIFI_BOARD_DIR"
for board_file in "$TEMP_DIR/immortalwrt-temp/package/firmware/ipq-wifi/board-"*jdcloud*; do
    if [ -f "$board_file" ]; then
        cp -f "$board_file" "$WIFI_BOARD_DIR/"
        echo -e "${GREEN}  Copied wifi board: $(basename $board_file)${NC}"
    fi
done
```

### 文件3: `Scripts/Settings.sh`

**修改内容**：修复 jdcloud 检测路径

第78行：
```bash
# 修改前
if [[ "${WRT_NAME,,}" == *"jdcloud"* ]] || grep -q "jdcloud_re-ss-01" ./Config/$WRT_CONFIG.txt 2>/dev/null; then

# 修改后
if [[ "${WRT_NAME,,}" == *"jdcloud"* ]] || grep -q "jdcloud_re-ss-01" $GITHUB_WORKSPACE/Config/$WRT_CONFIG.txt 2>/dev/null; then
```

## 不修改的文件
- `QCA-ALL.yml` — 已正确配置，无需修改
- `Config/IPQ60XX-WIFI-NO.txt` — 已正确配置，无需修改

## 验证步骤
1. 提交修改后，手动触发 QCA-ALL workflow
2. 检查 "Initialization Environment" 步骤是否成功完成
3. 检查 "Inject Device Support" 步骤是否正确注入设备支持
4. 检查编译是否成功通过（不再出现 GLIBC_2.38 错误）
