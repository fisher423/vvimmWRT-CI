# fanchmwrt 添加 jdcloud_re-ss-01 设备支持规格

## 为什么
fanchmwrt/fanchmwrt 仓库的 `fanchmwrt-25.12.2` 分支原生支持 `jdcloud_re-ss-01` 设备（已在 IPQ60XX-WIFI-YES.txt 中配置），但需要参考 [fisher423/Openwrt_Builder](https://github.com/fisher423/Openwrt_Builder) 的做法，在编译过程中注入设备支持文件，确保编译的固件包含正确的 DTS 设备树和无线驱动配置。

## 需求分析

### 现有环境
- **Config/IPQ60XX-WIFI-YES.txt** 已包含 `CONFIG_TARGET_DEVICE_qualcommax_ipq60xx_DEVICE_jdcloud_re-ss-01=y`
- **Scripts/Settings.sh** 包含高通平台通用设置逻辑
- **Scripts/Handles.sh** 包含插件调整逻辑

### 参考仓库 (fisher423/Openwrt_Builder) 提供的注入方案
1. **inject-device-support.sh**: 从 ImmortalWrt 克隆 `target/linux/qualcommax/` 目录
2. **scripts-part1.sh**: 检测设备名称，调用注入脚本
3. **Build-jdcloud_re-ss-01.yml**: 设置 WORKFLOW_NAME 环境变量

## 修改内容

### 新增文件
- **Scripts/inject-device-support.sh**: 设备支持注入脚本

### 修改文件
- **Scripts/Settings.sh**: 添加 jdcloud_re-ss-01 设备检测和注入调用逻辑
- **Config/IPQ60XX-WIFI-YES.txt**: 添加 jdcloud_re-ss-01 设备专属包配置（如需要）

## 影响范围

### 受影响的文件
| 文件 | 操作 | 说明 |
|------|------|------|
| Scripts/inject-device-support.sh | 新增 | 从 ImmortalWrt 注入设备支持 |
| Scripts/Settings.sh | 修改 | 添加设备检测和调用注入脚本 |
| Config/IPQ60XX-WIFI-YES.txt | 修改 | 添加无线驱动包配置 |

### 不修改的文件
- QCA-ALL.yml（保持原有 workflow 名称）
- WRT-CORE.yml（保持通用编译核心）
- Handles.sh（保持原有插件处理逻辑）
- 其他 Config/*.txt（保持原有配置）

## 实现细节

### 1. inject-device-support.sh 功能
- 从 ImmortalWrt master 分支克隆 `target/linux/qualcommax/` 目录
- 复制 ipq60xx 子目标、DTS 文件、image 配置到源码目录
- 自动检测并添加 `jdcloud_re-ss-01` 设备定义到 `ipq60xx.mk`
- 确保必要的 target.mk 和 config-default 文件存在

### 2. Settings.sh 修改逻辑
```bash
# 当 WRT_NAME 包含 "jdcloud" 或设备名称时，调用注入脚本
if [[ "${WRT_NAME,,}" == *"jdcloud"* ]]; then
    echo ">>> Injecting jdcloud device support..."
    chmod +x $GITHUB_WORKSPACE/Scripts/inject-device-support.sh
    $GITHUB_WORKSPACE/Scripts/inject-device-support.sh
fi
```

### 3. 编译后固件信息
- **默认 IP**: 继承 WRT_IP 环境变量（QCA-ALL.yml 中为 192.168.10.1）
- **默认密码**: 无
- **SoC**: Qualcomm IPQ6000 (IPQ60xx)
- **架构**: ARM Cortex-A53 (arm64)

## 约束条件
1. 不改变原有 workflow 文件名称和结构
2. 不创建新的 workflow 文件
3. 注入逻辑仅在检测到特定设备名称时执行
4. 向后兼容：不影响现有设备的编译流程
