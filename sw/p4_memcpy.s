# P4 - byte-wise memcpy of 13 bytes from 0x00 to 0x100, then LB/LBU re-read.
# Source words are written first with SW so the pattern is known.
    lui   x1, 0xDEADB       # x1 = 0xDEADB000
    addi  x1, x1, 0x6F      # x1 = 0xDEADB06F
    sw    x1, 0(x0)         # mem[0x00] = 0xDEADB06F
    lui   x2, 0xC0FFE
    addi  x2, x2, 0x11
    sw    x2, 4(x0)         # mem[0x04] = 0xC0FFE011
    lui   x3, 0x12345
    addi  x3, x3, 0x678
    sw    x3, 8(x0)         # mem[0x08] = 0x12345678
    lui   x4, 0xABCDE
    addi  x4, x4, 0x7F
    sw    x4, 12(x0)        # mem[0x0C] = 0xABCDE07F

    addi  x5, x0, 0         # src pointer
    addi  x6, x0, 256       # dst pointer 0x100
    addi  x7, x0, 0         # i
    addi  x8, x0, 13        # n
cpy_loop:
    beq   x7, x8, cpy_done
    add   x9,  x5, x7
    lbu   x20, 0(x9)        # read one byte
    add   x9,  x6, x7
    sb    x20, 0(x9)        # write one byte
    addi  x7, x7, 1
    beq   x0, x0, cpy_loop
cpy_done:
    lb    x11, 256(x0)      # signed re-read of byte 0 (0x6F -> +111)
    lbu   x12, 259(x0)      # unsigned re-read of byte 3 (0xDE -> 222)
    lb    x13, 259(x0)      # signed re-read of byte 3 (0xDE -> -34)
    addi  x10, x0, 13       # bytes copied
done:
    beq   x0, x0, done
