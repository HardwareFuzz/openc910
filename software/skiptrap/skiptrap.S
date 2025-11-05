/*
 * Rich skip-trap demo for C910 smart testbench.
 * Exercises:
 *  - Integer (x) register writes and memory stores of multiple sizes
 *  - Floating (f) register writes (D extension) and memory stores
 *  - Trap skip on illegal instructions (both 32b and 16b)
 */

.section .data
.align 3
buf:
    .space 64

.section .text
.globl __start

.equ SIM_CTRL_ADDR, 0x01fff000
.equ SIM_PASS_VALUE, 0x0000000444333222

__start:
    /* Install trap handler */
    la      t0, trap_handler
    csrw    mtvec, t0

    /* Enable floating-point (set FS=Dirty) and clear FCSR */
    csrr    t0, mstatus
    li      t1, 0x00003000          /* FS field -> Dirty */
    or      t0, t0, t1
    csrw    mstatus, t0
    csrw    fcsr, x0

    j       user_code

user_code:
    /* ------------ Integer GPR writes + memory stores ------------- */
    li      s1, 0x1111111111111111
    li      s2, 0x2222222222222222
    add     s3, s1, s2             /* = 0x3333... */
    la      t0, buf
    sd      s3, 0(t0)              /* store 8B */
    sh      s2, 8(t0)              /* store 2B */
    sb      s1, 10(t0)             /* store 1B */
    sw      s3, 12(t0)             /* store 4B */

    /* ---------------- Floating-point writes + stores -------------- */
    /* f0 = 1.0, f1 = 2.0, f2 = 3.0, f3 = f1*f2 = 6.0 */
    li      t3, 0x3ff0000000000000 /* +1.0 in IEEE754 double */
    fmv.d.x f0, t3
    fadd.d  f1, f0, f0
    li      t3, 0x4008000000000000 /* +3.0 */
    fmv.d.x f2, t3
    fmul.d  f3, f1, f2
    fsd     f1, 16(t0)
    fsd     f3, 24(t0)

    /* ------------------------ Trap skipping ----------------------- */
    li      s0, 0                  /* counter for skipped insns */
    .word   0x00000000             /* illegal 32b insn */
    addi    s0, s0, 1
    .2byte  0x0000                 /* illegal 16b insn */
    addi    s0, s0, 1
    li      t2, 2
    bne     s0, t2, fail

    /* More mixed stores after trap to enrich log */
    li      a0, 0xdeadbeefcafef00d
    sd      a0, 32(t0)
    li      a1, 0x7f
    sb      a1, 40(t0)

    /* ---------------- AMO (simultaneous reg+mem) operations ---------------- */
    /* Prepare targets */
    la      t5, buf
    addi    t5, t5, 48            /* 8B-aligned slot */
    li      t6, 0x10
    sd      t6, 0(t5)
    li      t2, 5
    /* t3 <- old [t5]; [t5] += 5 */
    amoadd.d t3, t2, (t5)
    /* Now swap in 0x1234...; t4 gets old (which was 0x15) */
    li      t6, 0x123456789abcdef0
    amoswap.d t4, t6, (t5)
    /* 32-bit AMO on 4B-aligned addr (t5+8) */
    addi    a2, t5, 8
    li      t1, 0x7
    sw      t1, 0(a2)
    li      t1, 0x3
    amoadd.w s5, t1, (a2)

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
