# Tasks

- [x] Task 1: 在 WRT-CORE.yml 中添加 "Free Disk Space" 步骤
  - [x] SubTask 1.1: 在 "Checkout Projects" 步骤之前添加 `endersonmenezes/free-disk-space@v2` action
  - [x] SubTask 1.2: 配置 action 参数，移除 Android SDK、.NET、Haskell、Swift、Miniconda 等不需要的软件

- [x] Task 2: 在 WRT-CORE.yml 的 "Initialization Environment" 步骤中补充依赖包
  - [x] SubTask 2.1: 在 `apt install` 命令中添加 `python3-netifaces` 和 `bc`

- [x] Task 3: 修改 WRT-CORE.yml 的缓存策略
  - [x] SubTask 3.1: 将缓存路径从 `./wrt/staging_dir/host*` 和 `./wrt/staging_dir/tool*` 改为 `./wrt/staging_dir`

- [x] Task 4: 移除 /mnt/build_wrt 符号链接相关步骤
  - [x] SubTask 4.1: 删除 "Initialization Environment" 中创建 `/mnt/build_wrt` 和符号链接的命令

# Task Dependencies
- Task 1, Task 2, Task 3, Task 4 之间无依赖关系，可以并行执行
