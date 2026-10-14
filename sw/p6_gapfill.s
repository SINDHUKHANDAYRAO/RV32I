# P6 - closes the six instructions the other five programs never execute:
#      SLTI, SLTIU, XORI, SLL, SRL, SRA  (register-operand shifts)
    addi  x1, x0, -3         # x1 = 0xFFFFFFFD
    addi  x2, x0, 4          # x2 = shift amount
    slti  x3, x1, 1          # -3 < 1 signed        -> 1
    sltiu x4, x1, 1          # 4294967293 < 1 unsig -> 0
    xori  x5, x1, 255        # 0xFFFFFFFD ^ 0xFF    -> 0xFFFFFF02
    sll   x6, x1, x2         # 0xFFFFFFFD << 4      -> 0xFFFFFFD0
    srl   x7, x1, x2         # logical  >> 4        -> 0x0FFFFFFF
    sra   x8, x1, x2         # arith   >>> 4        -> 0xFFFFFFFF
    addi  x9, x0, 36         # shift amount 36 -> uses only low 5 bits (=4)
    sll   x10, x1, x9        # must equal x6
done:
    beq   x0, x0, done
