# 任务列表：fanchmwrt 添加 jdcloud_re-ss-01 设备支持

## 任务

- [x] Task 1: 创建 Scripts/inject-device-support.sh 设备支持注入脚本
  - 从 ImmortalWrt master 分支克隆 target/linux/qualcommax 目录
  - 复制 ipq60xx 子目标、DTS 文件、image 配置
  - 自动检测并添加 jdcloud_re-ss-01 设备定义

- [x] Task 2: 修改 Scripts/Settings.sh 添加设备检测和注入调用逻辑
  - 添加 WORKFLOW_NAME 或 WRT_NAME 环境变量检测
  - 当检测到 jdcloud_re-ss-01 设备时调用注入脚本
  - 确保不影响现有设备的编译流程

- [x] Task 3: 修改 Config/IPQ60XX-WIFI-YES.txt 添加无线驱动包配置
  - 添加 CONFIG_PACKAGE_ipq-wifi-jdcloud_re-ss-01=y
  - 确保设备编译时包含正确的无线固件

- [x] Task 4: 验证脚本语法
  - bash -n 验证 inject-device-support.sh
  - bash -n 验证 Settings.sh
  - 确保修改后的脚本可正常执行

## 任务依赖
- Task 2 依赖于 Task 1（注入脚本需要先创建）
- Task 3、Task 4 无依赖，可并行执行
