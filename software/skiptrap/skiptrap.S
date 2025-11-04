.section .text
.globl __start

/* Skip-trap demo for C910 smart testbench.
 * An illegal instruction is injected on purpose; the trap handler
 * advances MEPC past the faulting instruction and execution continues.
 */

.equ SIM_CTRL_ADDR, 0x01fff000
.equ SIM_PASS_VALUE, 0x0000000444333222

__start:
    la      t0, trap_handler
    csrw    mtvec, t0

    /* Allow floating-point ops in case user payload touches FP regs */
    csrr    t0, mstatus
    li      t1, 0x00003000          /* FS field -> Dirty */
    or      t0, t0, t1
    csrw    mstatus, t0
    csrw    fcsr, x0

    j       user_code

user_code:
    li      s0, 0

    /* Deliberate illegal 32-bit instruction */
    .word   0x00000000
    addi    s0, s0, 1

    /* Another illegal opcode emitted via mtval (c.unimp style) */
    .2byte  0x0000
    addi    s0, s0, 1

    /* Confirm we actually skipped both faulting instructions */
    li      t2, 2
    bne     s0, t2, fail

    j       exit

fail:
    j       fail

exit:
    /* Notify smart TB and park */
    li      t0, SIM_CTRL_ADDR
    li      t1, SIM_PASS_VALUE
    sd      t1, 0(t0)
    fence
1:
    wfi
    j       1b

.align 2
trap_handler:
    csrr    t0, mepc            /* faulting PC */
    csrr    t1, mcause
    csrr    t4, mtval

    slli    t5, t1, 1           /* clear interrupt bit */
    srli    t1, t5, 1

    li      t2, 2               /* default len = 2 bytes */

    li      t3, 2               /* illegal instruction */
    beq     t1, t3, decode_length
    li      t3, 1               /* instruction access fault */
    beq     t1, t3, update_mepc
    li      t3, 12              /* instruction page fault */
    beq     t1, t3, update_mepc

    lhu     t4, 0(t0)           /* fetch encoding if mtval not useful */

decode_length:
    andi    t4, t4, 3
    li      t3, 3
    bne     t4, t3, compressed_len
    li      t2, 4               /* standard 32-bit instruction */
    j       update_mepc

compressed_len:
    li      t2, 2               /* compressed instruction */

update_mepc:
    add     t0, t0, t2
    csrw    mepc, t0
    csrw    mcause, x0
    csrw    mtval, x0
    mret
