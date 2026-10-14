# P3 - first 15 Fibonacci numbers stored as words from 0x40. Count in x10.
    addi  x1, x0, 64        # x1 = 0x40 destination pointer
    addi  x2, x0, 0         # fib(n-2)
    addi  x3, x0, 1         # fib(n-1)
    addi  x4, x0, 0         # counter
    addi  x5, x0, 15        # limit
fib_loop:
    beq   x4, x5, fib_done
    sw    x2, 0(x1)         # store current
    add   x6, x2, x3        # next = a + b
    add   x2, x3, x0        # a = b
    add   x3, x6, x0        # b = next
    addi  x1, x1, 4
    addi  x4, x4, 1
    beq   x0, x0, fib_loop
fib_done:
    add   x10, x4, x0       # x10 = 15
done:
    beq   x0, x0, done
