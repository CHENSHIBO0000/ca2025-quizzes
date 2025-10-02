# s0:sign_a
# s1:sign_b
# s2:exp_a
# s3:exp_b
# s4:mant_a
# s5:mant_b
# s6:result_sign
# s7:dividend
# s8:divisor
# s9:quotient
# s10:result_exp

    .data
#input_a:   .half 0x3f40          # A = 1.0 (bf16 bits)
#input_b:   .half 0x3e80         # B = 1.0 (bf16 bits)
input_a:   .half 0x3e40          # A = 1.0 (bf16 bits)
input_b:   .half 0x3e80         # B = 1.0 (bf16 bits)
s_a:       .asciz "A = "
s_b:       .asciz "B = "
s_sum:     .asciz "A / B = "
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
    addi    sp, sp, -16
    sw      ra, 12(sp)

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

    # ------- print B -------
    la      a0, s_b
    li      a7, 4
    ecall
    la      t1, input_b
    lhu     a0, 0(t1)            # a0 = B bits
    li      a7, 34
    ecall
    la      a0, nl
    li      a7, 4
    ecall

    # ------- call bf16_add(A, B) -------
    lhu     a0, 0(t0)            # a0 = A bits (arg0)
    lhu     a1, 0(t1)            # a1 = B bits (arg1)
    jal     ra, bf16_div         # returns a0 = result bits
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




bf16_div:
    addi    sp, sp, -48
    sw      s10, 44(sp)
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

    srli    s0, a0, 15        # Extract sign of a
    srli    s1, a1, 15        # Extract sign of b
    andi    s0, s0, 0x1
    andi    s1, s1, 0x1

    srli    s2, a0, 7         # Extract exponent of a
    srli    s3, a1, 7         # Extract exponent of b
    andi    s2, s2, 0xFF
    andi    s3, s3, 0xFF

    andi    s4, a0, 0x7F      # Extract mantissa of a
    andi    s5, a1, 0x7F      # Extract mantissa of b

    xor     s6, s0, s1        # Compute result sign


##if (exp_b == 0xFF)
    li      t0, 0XFF
    bne     s3, t0, CHECK_ZERO_B
    bne     s5, x0, RETURN_B
    bne     s2, t0, RETURN_ZERO
    bne     s4, x0, RETURN_ZERO
    j       RETURN_NAN


CHECK_ZERO_B:
##  if (!exp_b && !mant_b)
    or       t0, s3, s5
####  if (!exp_a && !mant_a)    
    or       t1, s2, s4
    or       t2, t0, t1
    beqz     t2, RETURN_NAN
    beqz     t0, RETURN_INFINITY

##if (exp_a == 0xFF)
    li      t0, 0XFF
    bne     s2, t0, CHECK_ZERO_A
    bne     s4, x0, RETURN_A
    j       RETURN_INFINITY

CHECK_ZERO_A:
##  if (!exp_a && !mant_a)
    or       t0, s2, s4
    beqz     t0, RETURN_ZERO

    beq      s2, x0, 1f
    ori      s4, s4, 0x80        
1:
    beq      s3, x0, 2f
    ori      s5, s5, 0x80 
2:


    slli     s7, s4, 15
    mv       s8, s5
    li       s9, 0

#t0:16
#t1:i
#t2:15
#t3:15-i
#t4:divisor << (15 - i)

    li       t0, 16
    li       t1, 0
    li       t2, 15
for:
    slli     s9, s9, 1
    sub      t3, t2, t1
    sll      t4, s8, t3
    bltu     s7, t4, 3f
    sub      s7, s7, t4
    ori      s9, s9, 1

3:
    addi     t1, t1, 1
    bne      t1, t0, for

#result_exp
    sub      s10, s2, s3
    addi     s10, s10, 127

    bne      s2, x0,  4f
    addi     s10, s10, -1
4:
    bne      s3, x0,  5f
    addi     s10, s10, 1

5:
#t1:1
#t2:0x8000
    li       t1, 1
    li       t2, 0x8000
    and      t0, s9, t2
    beqz     t0, 6f
    srli     s9, s9, 8
    j        7f
6:
#t0:quotient & 0x8000
#result_exp > 1

while_loop:
    and      t0, s9, t2
    bnez     t0, end_while
    ble      s10, t1, end_while
    slli     s9, s9, 1
    addi     s10, s10, -1
    j        while_loop

end_while:
    srli     s9, s9, 8

7:
    andi     s9, s9, 0x7F

    li       t0, 0xFF
    blt      s10, t0, 8f
    j        RETURN_INFINITY

8:
    blez     s10, RETURN_ZERO

    j        FINISH_COMBINE_RESULT

#########################################
#                                       #
#                                       #   
#              return result            #
#                                       #
#                                       #
#########################################
RETURN_INFINITY:

    slli    a0, s6, 15
    li      t0, 0x7F80
    or      a0, a0, t0
    j       div_done

RETURN_ZERO:
    slli    s6, s6, 15
    mv      a0, s6
    j       div_done

RETURN_NAN:
    li      a0, BF16_NAN
    j       div_done

RETURN_B:

    mv      a0, a1
    j       div_done


RETURN_A:

    j       div_done

FINISH_COMBINE_RESULT:
    slli    s6, s6, 15
    andi    s10, s10, 0xFF
    slli    s10, s10, 7
    andi    s9, s9, 0x7F
    or      a0, s6, s10
    or      a0, a0, s9
    j       div_done

div_done:

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
    lw      s10, 44(sp)
    addi    sp, sp, 48
    
    ret
    

        
    