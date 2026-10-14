# P1 - write 10 known words to memory, then sum them back.
# mem[i] = 10*(i+1)  ->  10,20,...,100    sum = 550
# Expect: x10 = 550, x11 = 10
    addi  x1,  x0, 0         # x1 = base byte address
    addi  x2,  x0, 0         # x2 = index
    addi  x3,  x0, 10        # x3 = element count
    addi  x4,  x0, 0         # x4 = running value

fill_loop:
    beq   x2, x3, fill_done
    addi  x4, x4, 10         # value = 10*(i+1)
    slli  x5, x2, 2          # byte offset = i*4
    add   x5, x5, x1
    sw    x4, 0(x5)
    addi  x2, x2, 1
    beq   x0, x0, fill_loop
fill_done:

    addi  x10, x0, 0         # sum
    addi  x11, x0, 0         # count
    addi  x2,  x0, 0         # index
sum_loop:
    beq   x2, x3, sum_done
    slli  x5, x2, 2
    add   x5, x5, x1
    lw    x6, 0(x5)
    add   x10, x10, x6
    addi  x11, x11, 1
    addi  x2,  x2, 1
    beq   x0, x0, sum_loop
sum_done:

done:
    beq   x0, x0, done
