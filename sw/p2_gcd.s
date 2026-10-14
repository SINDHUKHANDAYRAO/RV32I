# P2 - gcd(1071, 462) by repeated subtraction. Expect x10 = 21.
    addi  x1, x0, 1071      # a
    addi  x2, x0, 462       # b
gcd_loop:
    beq   x1, x2, gcd_done
    blt   x1, x2, b_bigger
    sub   x1, x1, x2        # a > b
    beq   x0, x0, gcd_loop
b_bigger:
    sub   x2, x2, x1        # b > a
    beq   x0, x0, gcd_loop
gcd_done:
    add   x10, x1, x0
done:
    beq   x0, x0, done
