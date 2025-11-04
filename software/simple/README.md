# simple 裸机示例

`asm_exit.S` 展示了如何在 C910 smart testbench 中安全结束仿真：程序向 `0x01FFF000` 写入 PASS 签名 (`0x0000000444333222`) 后进入 `wfi` 循环，等待外部仿真器检测到写入并触发 `$finish`。

## 构建

```bash
cd /home/canxin/openc910/software/simple
export TOOL_EXTENSION=/opt/riscv/bin   # 按需调整到本地 RISC-V 工具链
make clean
make
```

生成物包括 `asm_exit.elf/.hex/.pat` 等文件；如需构建不同文件，可使用 `make FILE=<target>` 覆盖默认值。

## 配合 Verilator 仿真

确保已经在 `smart_run` 中构建出支持 `--elf` 参数的 Verilator 可执行文件（参考 `doc/verilator_build.md`），并提前设置好 `SREC2VMEM` 指向转换工具，例如：

```bash
export SREC2VMEM=/home/canxin/openc910/smart_run/tests/bin/Srec2vmem
```

然后：

```bash
cd /home/canxin/openc910/smart_run/work
KEEP_C910_TEMP=1 obj_dir/Vtop --elf /home/canxin/openc910/software/simple/asm_exit.elf
```

仿真运行后应打印 PASS banner 并调用 `$finish`。
