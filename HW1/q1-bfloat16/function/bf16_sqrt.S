# s0:sign
# s1:exp
# s2:mant
# s3:m
# s4:low
# s5:high
# s6:result
# s7:new_mant
# s8:e
# s9:new_exp


.data
input_a:   .half 0x3e40          # A = 1.0 (bf16 bits)
input_b:   .half 0x3e80         # B = 1.0 (bf16 bits)
s_a:       .asciz "A = "
s_sum:     .asciz "sqrt a = "
nl:        .asciz "\n"
.equ    BF16_SIGN_MASK, 0x8000
.equ    BF16_EXP_MASK,  0x7F80
.equ    BF16_MANT_MASK, 0x007F
.equ    BF16_EXP_BIAS,  127
.equ    BF16_NAN,       0x7FC0
.equ    BF16_ZERO,      0x0000
    .text
    .globl main
main:

    # ------- print A -------
    la      a0, s_a
    li      a7, 4
    ecall
    la      t0, input_a
    lhu     a0, 0(t0)            # a0 = A bits (u16 → zero-extend)
    li      a7, 34               # print int in hex (RARS)
    ecall
    la      a0, nl
    li      a7, 4
    ecall


    # ------- call bf16_add(A, B) -------
    lhu     a0, 0(t0)            # a0 = A bits (arg0)
    lhu     a1, 0(t1)            # a1 = B bits (arg1)
    jal     ra, bf16_sqrt         # RETURNs a0 = result bits
    mv      s0, a0               # save result

    # ------- print result -------
    la      a0, s_sum
    li      a7, 4
    ecall
    mv      a0, s0               # a0 = result bits
    li      a7, 34               # (use 1 if no hex syscall)
    ecall
    la      a0, nl
    li      a7, 4
    ecall

    # ------- exit -------
    lw      ra, 12(sp)
    addi    sp, sp, 16
    li      a7, 10
    ecall




bf16_sqrt:
    addi    sp, sp, -44
    sw      ra, 40(sp)
    sw      s0, 36(sp)
    sw      s1, 32(sp)
    sw      s2, 28(sp)
    sw      s3, 24(sp)
    sw      s4, 20(sp)
    sw      s5, 16(sp)
    sw      s6, 12(sp)
    sw      s7, 8(sp)
    sw      s8, 4(sp)
    sw      s9, 0(sp)  


    srli    s0, a0, 15        # Extract sign 
    andi    s0, s0, 0x1


    srli    s1, a0, 7         # Extract exponent
    andi    s1, s1, 0xFF

    andi    s2, a0, 0x7F      # Extract mantissa 

## Handle special cases
    li      t0, 0XFF
    bne     s1, t0, 1f

    bne     s2, x0, RETURN_a  
    bne     s0, x0, RETURN_NAN
    j       RETURN_a

1:  
    or      t0, s1, s2
    beq     t0, x0, RETURN_ZERO

    bne     s0, x0, RETURN_NAN

    beq     s1, x0, RETURN_ZERO

    addi    s8, s1, -127
    ori     s3, s2, 0x80        

    andi    t0, s8, 0x1
    beq     t0, x0, even_exp
    slli    s3, s3, 1
    addi    s9, s8, -1
    srai    s9, s9, 1 
    addi    s9, s9, 127
    j       BINARY_SEARCH

even_exp:
    srai    s9, s8, 1
    addi    s9, s9, 127
    j       BINARY_SEARCH

BINARY_SEARCH:
    li      s4, 90               # low = 90
    li      s5, 256              # high = 256
    li      s6, 128              # result = 128
    
##  t0: mid
##  t1: sq
BINARY_SEARCH_LOOP:
    bgt     s4, s5, NORMALIZE
    add     t0, s4, s5
    srli    t0, t0, 1            # mid = (low + high) >> 1

    li      t1, 0
    mv      t2, t0

BINARY_SEARCH_LOOP_MUL:
    add     t1, t1, t0
    addi    t2, t2, -1
    bne     t2, x0, BINARY_SEARCH_LOOP_MUL
    srli    t1, t1, 7            # sq = (mid * mid) >> 7

    bgtu    t1, s3, 2f
    mv      s6, t0
    addi    s4, t0, 1
    j       BINARY_SEARCH_LOOP
2:
    addi    s5, t0, -1
    j       BINARY_SEARCH_LOOP


NORMALIZE:
    li      t0, 256
    blt     s6, t0, CHECK_LOWER_BOUND
    srli    s6, s6, 1
    addi    s9, s9, 1
    j       CHECK_OVER_UNDER_FLOW  
    
CHECK_LOWER_BOUND:
    li      t0, 128
    bge     s6, t0, CHECK_OVER_UNDER_FLOW

    li      t1, 1
NORMALIZE_LOOP:
    bge     s6, t0, CHECK_OVER_UNDER_FLOW
    ble     s9, t1 , CHECK_OVER_UNDER_FLOW
    slli    s6, s6, 1
    addi    s9, s9, -1
    j       NORMALIZE_LOOP


CHECK_OVER_UNDER_FLOW:

    andi    s7, s6, 0x7F

    li      t0, 0xFF
    bge     s9, t0, RETURN_INFINITY 
    ble     s9, x0, RETURN_ZERO
    j       FINISH_COMBINE_RESULT
    


#########################################
#                                       #
#                                       #   
#              RETURN result            #
#                                       #
#                                       #
#########################################

RETURN_a:
    j       sqrt_done

RETURN_NAN:
    li      a0, BF16_NAN
    j       sqrt_done

RETURN_ZERO:
    li      a0, BF16_ZERO
    j       sqrt_done

RETURN_INFINITY:
    li      a0, 0x7F80
    j       sqrt_done

FINISH_COMBINE_RESULT:
    andi    a0, s9, 0XFF
    slli    a0, a0, 7
    or      a0, a0, s7
    j       sqrt_done

sqrt_done:

    lw      s9, 0(sp)
    lw      s8, 4(sp)
    lw      s7, 8(sp)       
    lw      s6, 12(sp)
    lw      s5, 16(sp)
    lw      s4, 20(sp)
    lw      s3, 24(sp)
    lw      s2, 28(sp)
    lw      s1, 32(sp)
    lw      s0, 36(sp)
    lw      ra, 40(sp)
    addi    sp, sp, 44
    
    ret
    

        
    