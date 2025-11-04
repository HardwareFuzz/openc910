# skiptrap 裸机示例

该示例展示如何在 C910 上通过自定义 trap handler 跳过会触发异常的指令，让程序继续向前推进。核心思路是在 `trap_handler` 中解析 `mcause/mtval` 以判断 fault 指令长度，然后将 `mepc` 前移并 `mret` 回用户代码。

## 触发逻辑
- `user_code` 中手工插入一个 32 位非法指令 (`.word 0x00000000`) 和一个 16 位非法指令 (`.2byte 0x0000`)。
- 每成功跨过一次异常，计数寄存器 `s0` 加 1；若最终 `s0 != 2` 则陷入 `fail`。
- 正常路径会向 smart testbench 的邮箱 (`0x01FFF000`) 写入 PASS 签名 `0x0000000444333222`，随后 `wfi`。

## 构建
```bash
cd /home/canxin/openc910/software/skiptrap
export TOOL_EXTENSION=/opt/riscv/bin   # 根据实际工具链调整
make clean
make
```

生成物包含 `skiptrap.elf/.hex/.pat` 等文件，可直接交给 smart_run Verilator 仿真运行；如需构建其他目标，可通过 `make FILE=<target>` 覆盖默认值。

## 在 Verilator 中运行
确保已按 `doc/verilator_build.md` 构建 `smart_run/work/obj_dir/Vtop`，并设置好 `SREC2VMEM` 环境变量指向转换工具，例如：
```bash
export SREC2VMEM=/home/canxin/openc910/smart_run/tests/bin/Srec2vmem
```
然后：
```bash
cd /home/canxin/openc910/smart_run/work
KEEP_C910_TEMP=1 obj_dir/Vtop --elf /home/canxin/openc910/software/skiptrap/skiptrap.elf
```
仿真应在两条非法指令都被跳过后打印 PASS banner 并 `$finish`。
