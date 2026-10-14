# Assignment 2 Q6 - R-type and I-type only, no branches, no memory
    addi  x1,  x0, 15        # x1 = 15
    addi  x2,  x0, -3        # x2 = -3
    add   x3,  x1, x2        # x3 = 12
    sub   x4,  x1, x2        # x4 = 18
    and   x5,  x1, x2        # x5 = 13
    or    x6,  x1, x2        # x6 = -1
    xor   x7,  x1, x2        # x7 = 0xFFFFFFF2
    slt   x8,  x2, x1        # x8 = 1
    sltu  x9,  x2, x1        # x9 = 0
    slli  x10, x1, 4         # x10 = 240
    srli  x11, x2, 4         # x11 = 0x0FFFFFFF
    srai  x12, x2, 4         # x12 = -1
    andi  x13, x1, 7         # x13 = 7
    addi  x0,  x0, 99        # x0 stays 0
