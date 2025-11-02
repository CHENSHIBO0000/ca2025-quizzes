.data
str1:       .string  "Move Disk "
str2:       .string  " from "
str3:       .string  " to "
strA:       .string  "A"
strB:       .string  "B"
strC:       .string  "C"
str:        .string  "\n"


.text

.globl  hanoi_asm
.type   hanoi_asm, @function

hanoi_asm:
    addi    x2, x2, -36
    sw      x8, 0(x2)
    sw      x9, 4(x2)
    sw      x18, 8(x2)
    sw      x19, 12(x2)
    sw      x20, 16(x2)
    sw      ra, 32(x2)   

    li      x5, 0x15
    sw      x5, 20(x2)
    sw      x5, 24(x2)
    sw      x5, 28(x2)

    # Fix disk positions (BLANK 1-3: neutralize x5 effect)
    # BLANK 1: Fix position at x2+20
    sw      x0, 20(x2)

    # BLANK 2: Fix position at x2+24
    sw      x0, 24(x2)

    # BLANK 3: Fix position at x2+28
    sw      x0, 28(x2)

    addi    x8, x0, 1
game_loop:
    # BLANK 4: Check loop termination (2^3 moves)
    addi    x5, x0, 8
    beq     x8, x5, finish_game

    # Gray code formula: gray(n) = n XOR (n >> k)
    # BLANK 5: What is k for Gray code?
    srli    x5, x8, 1

    # BLANK 6: Complete Gray(n) calculation
    xor     x6, x8, x5

    # BLANK 7-8: Calculate previous value and its shift
    addi    x7, x8, -1
    srli    x28, x7, 1

    # BLANK 9: Generate Gray(n-1)
    xor     x7, x7, x28

    # BLANK 10: Which bits changed?
    xor     x5, x6, x7

    # Initialize disk number
    addi    x9, x0, 0

    # BLANK 11: Mask for testing LSB
    andi    x6, x5, 1

    # BLANK 12: Branch if disk 0 moves
    bne     x6, x0, disk_found

    # BLANK 13: Set disk 1
    addi    x9, x0, 1

    # BLANK 14: Test second bit with proper mask
    andi    x6, x5, 2
    bne     x6, x0, disk_found

    # BLANK 15: Last disk number
    addi    x9, x0, 2

disk_found:
    # BLANK 16: Check impossible pattern (multiple bits)
    andi    x30, x5, 5
    addi    x31, x0, 5
    beq     x30, x31, pattern_match
    jal     x0, continue_move

pattern_match:
continue_move:

    # BLANK 17: Word-align disk index (multiply by what?)
    slli    x5, x9, 2

    # BLANK 18: Base offset for disk array
    addi    x5, x5, 20
    add     x5, x2, x5
    lw      x18, 0(x5)

    bne     x9, x0, handle_large

    # BLANK 19: Small disk moves by how many positions?
    addi    x19, x18, 2

    # BLANK 20: Number of pegs
    addi    x6, x0, 3
    blt     x19, x6, display_move
    sub     x19, x19, x6
    jal     x0, display_move

handle_large:
    # BLANK 21: Load reference disk position
    lw      x6, 20(x2)

    # BLANK 22: Sum of all peg indices (0+1+2)
    addi    x19, x0, 3
    sub     x19, x19, x18
    sub     x19, x19, x6

display_move:

    # print "Move Disk "
    la   a0, str1
    call puts

    # # print disk number (1..3) as one char
    addi a0, x9, 1
    call print_dec

    # print " from "
    la   a0, str2
    call puts

    addi t0, x18, 65
    mv   a0, t0
    call print_char



print_to:
    # print " to "
    la   a0, str3
    call puts

    addi t0, x19, 65
    mv   a0, t0
    call print_char


next_move:

    la   a0, str
    call puts

    slli    x5, x9, 2
    addi    x5, x5, 20
    add     x5, x2, x5

    sw      x19, 0(x5)

    addi    x8, x8, 1
    jal     x0, game_loop

finish_game:
    lw      x8, 0(x2)
    lw      x9, 4(x2)
    lw      x18, 8(x2)
    lw      x19, 12(x2)
    lw      x20, 16(x2)
    lw      x1,  32(x2)
    addi    x2, x2, 36

    ret    

# print
puts:
    add   t0, a0, x0       
    add   t1, a0, x0       
1:  lbu   t2, 0(t1)
    beq   t2, x0, 2f
    addi  t1, t1, 1
    j     1b
2:  sub   a2, t1, t0      
    mv    a1, t0           
    li    a0, 1            
    li    a7, 64           
    ecall
    ret