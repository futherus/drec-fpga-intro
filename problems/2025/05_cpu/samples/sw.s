.text
.globl _start
.globl _finish

_start:
    li      t0, 3
    addi    t0, t0, 5
    addi    t0, t0, 7
    addi    t0, t0, 9
    addi    t0, t0, 11
    addi    t0, t0, 13
    sw      t0, 0x20(zero)

    li      t0, 0x1000
    li      t1, 0x1234C6C8
    sw      t1, 0x00(t0)
    sh      t1, 0x20(t0)
    sb      t1, 0x40(t0)
    lw      t1, 0x00(t0)
    lh      t1, 0x20(t0)
    lb      t1, 0x40(t0)

_finish:
    beq     zero, zero, _finish 

