.section .text
.globl __start

__start:
    /* Smart TB mailbox: write PASS signature then halt */
    li      t0, 0x01fff000
    li      t1, 0x0000000444333222
    sd      t1, 0(t0)
    fence

1:
    wfi
    j       1b
