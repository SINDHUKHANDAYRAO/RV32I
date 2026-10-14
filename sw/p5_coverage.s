# P5 - coverage closer: all six branch conditions, all five load types,
# all three store widths, LUI, AUIPC, JAL, JALR.
# Each branch sets a bit in x10 if it behaves correctly. Expect x10 = 0x3F.
    addi  x10, x0, 0

    addi  x1, x0, 5
    addi  x2, x0, 5
    bne   x1, x2, skip1
    ori   x10, x10, 1        # BEQ path: equal, so bne not taken -> set bit 0
skip1:
    addi  x2, x0, 7
    beq   x1, x2, skip2
    ori   x10, x10, 2        # BNE path
skip2:
    addi  x3, x0, -1
    addi  x4, x0, 1
    bge   x3, x4, skip3
    ori   x10, x10, 4        # BLT: -1 < 1 signed
skip3:
    blt   x4, x3, skip4
    ori   x10, x10, 8        # BGE: 1 >= -1 signed
skip4:
    bgeu  x3, x4, take5      # unsigned: 0xFFFFFFFF >= 1 -> taken
    beq   x0, x0, skip5
take5:
    ori   x10, x10, 16       # BGEU
skip5:
    bltu  x4, x3, take6      # unsigned: 1 < 0xFFFFFFFF -> taken
    beq   x0, x0, skip6
take6:
    ori   x10, x10, 32       # BLTU
skip6:

    # ---- LUI / AUIPC ----
    lui   x11, 0x12345       # x11 = 0x12345000
    auipc x12, 0             # x12 = address of this instruction

    # ---- stores and loads of every width ----
    lui   x13, 0x89ABC
    addi  x13, x13, 0x0DE    # x13 = 0x89ABC0DE
    sw    x13, 512(x0)       # mem[0x200] = 0x89ABC0DE
    lw    x14, 512(x0)       # 0x89ABC0DE
    lb    x15, 512(x0)       # byte 0 = 0xDE -> -34
    lbu   x16, 512(x0)       # 222
    lh    x17, 512(x0)       # half 0 = 0xC0DE -> -16162
    lhu   x18, 512(x0)       # 49374
    addi  x19, x0, 0x55
    sb    x19, 516(x0)       # mem[0x204] byte 0 = 0x55
    addi  x20, x0, 0x66
    sb    x20, 519(x0)       # mem[0x204] byte 3 = 0x66
    lui   x21, 0x00007
    addi  x21, x21, 0x777
    sh    x21, 522(x0)       # mem[0x208] upper half = 0x7777
    lw    x22, 516(x0)       # expect 0x66000055
    lw    x23, 520(x0)       # expect 0x77770000

    # ---- JAL / JALR ----
    jal   x24, subroutine    # x24 = return address
    beq   x0, x0, after_sub
subroutine:
    addi  x25, x0, 42
    jalr  x0, 0(x24)         # return
after_sub:

done:
    beq   x0, x0, done
