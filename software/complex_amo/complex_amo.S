.section .text
.globl __start

// Simple helper: write a byte via the tb's mailbox at 0x01ff_fff0 using sw
.macro PUTCHAR ch
    li      t4, 0x01ffffff0       // 0x01ff_fff0 (40-bit phys truncation ok)
    li      t5, \ch
    sw      t5, 0(t4)
.endm

__start:
    // Clear some integer regs and make visible X-WB logs
    li      t0, 0                 // x5
    li      t1, 0x1122334455667788
    li      t2, 5
    add     t3, t1, t2            // x8 = x6 + x7

    // Data buffer in dtcm
    la      t0, buf0              // t0 -> buf0
    sd      t1, 0(t0)             // store 0x1122.. to [buf0]

    // ========== AMO group (cover many ops) ==========
    // Prepare base pointer and source operands
    la      t0, buf0              // t0 -> buf0
    li      s0, -1                // all ones
    li      s1, 5                 // small positive
    li      s2, 0x0123456789abcdef
    li      s3, 0x00ff00ff00ff00ff
    li      s4, -42               // negative for signed min/max
    li      s5, 0x7fffffffffffffff
    li      s6, 16                // 0x10 for unsigned min
    li      s7, -16               // 0xffff...fff0 for unsigned maxu
    li      s8, 17                // 0x11 for .w add/swap
    li      s9, 0x2233445566778899
    li      s10, 0xdeadbeefcafec001

    // 1) amoadd.d: [buf0] += 5, a0 gets old
    amoadd.d a0, s1, (t0)

    // 2) amoand.d: [buf1] &= t4, a1 gets old
    addi    t1, t0, 8
    amoand.d a1, s3, (t1)

    // 3) amoor.d:  [buf2] |= t3, a2 gets old
    addi    t1, t0, 16
    amoor.d  a2, s2, (t1)

    // 4) amoxor.d: [buf3] ^= t4, a3 gets old
    addi    t1, t0, 24
    amoxor.d a3, s3, (t1)

    // 5) amomin.d (signed): [buf4] = min([buf4], t5), a4 gets old
    addi    t1, t0, 32
    amomin.d a4, s4, (t1)

    // 6) amomax.d (signed): [buf5] = max([buf5], t6), a5 gets old
    addi    t1, t0, 40
    amomax.d a5, s5, (t1)

    // 7) amominu.d (unsigned): [buf6] = minu([buf6], t7), a6 gets old
    addi    t1, t0, 48
    amominu.d a6, s6, (t1)

    // 8) amomaxu.d (unsigned): [buf7] = maxu([buf7], t8), a7 gets old
    addi    t1, t0, 56
    amomaxu.d a7, s7, (t1)

    // 9) amoadd.w: 32b add at [buf8], a4 gets old 64b value sign-extended from word
    addi    t1, t0, 64
    amoadd.w a4, s8, (t1)

    // 10) amoswap.w: 32b swap at [buf9], a5 gets old
    addi    t1, t0, 72
    amoswap.w a5, s8, (t1)

    // 11) amoswap.d: 64b swap at [buf10], a6 gets old, [buf10] := t11
    addi    t1, t0, 80
    amoswap.d a6, s10, (t1)

    // Normal store to adjacent location to exercise plain ST
    sd      s1, 88(t0)

    // A few chars to console to exercise MMIO store path
    PUTCHAR 'O'
    PUTCHAR 'K'
    PUTCHAR '\n'

    // Ensure all prior memory operations (incl. AMO/store) are globally visible
    // before we trigger PASS signature, so logs appear before finish.
    fence rw, rw

    // Finish with PASS signature observed by tb on writeback buses
    li      t1, 0x0000000444333222
    // Optionally write to mailbox as well (not required for PASS)
    li      t0, 0x01fff000
    sd      t1, 0(t0)

1:
    wfi
    j       1b

.section .data
.align 3
buf0:
    .dword 0xdeadbeefcafebabe
buf1:
    .dword 0x1122334455667788
buf2:
    .dword 0xf0f0f0f0f0f0f0f0
buf3:
    .dword 0x0f0f0f0f0f0f0f0f
buf4:
    .dword 0xffffffffffff0005     // large positive, test amomin.d with t5=-42
buf5:
    .dword 0x8000000000000001     // small negative, test amomax.d with t6=INT64_MAX
buf6:
    .dword 0x0000000000000020     // > t7, unsigned min should pick t7
buf7:
    .dword 0x000000000000000f     // < t8 (unsigned), maxu should pick t8
buf8:
    .dword 0x00000000fffffff0     // lower word near boundary for amoadd.w
buf9:
    .dword 0x0000000000000000     // amoswap.w target
buf10:
    .dword 0x123456789abcdef0     // amoswap.d target
