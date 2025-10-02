# s0:sign_a
# s1:sign_b
# s2:exp_a
# s3:exp_b
# s4:mant_a
# s5:mant_b
# s6:exp_diff
# s7:result_sign
# s8:result_exp
# s9:result_mant

    .data
input_a:   .half 0x3F80          # A = 1.0 (bf16 bits)
input_b:   .half 0x3F80          # B = 1.0 (bf16 bits)
s_a:       .asciz "A = 0x"
s_b:       .asciz "B = 0x"
s_sum:     .asciz "A + B = 0x"
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
    jal     ra, bf16_sub         # returns a0 = result bits
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


bf16_sub:
    addi    sp, sp, -4
    sw      ra, 0(sp)

    xori     a1, a1, 0x8000      
    jal     ra, bf16_add
        
    lw      ra, 0(sp)
    addi    sp, sp, 4
    ret

bf16_add:
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

##if (exp_a == 0xFF)
    li      t0, 0XFF
    bne     s2, t0, EXP_A_NOT_EQUAL_255
    beq     s4, x0, 1f
    j       return_a
    
1:
    bne     s3, t0, return_a
    bnez    s5, return_b
    beq     s0, s1, return_b
    li      a0, BF16_NAN
    j       add_done



EXP_A_NOT_EQUAL_255:
##if (exp_b == 0xFF)
    bne     s3, t0, EXP_B_NOT_EQUAL_255
    j       return_b

EXP_B_NOT_EQUAL_255:

##if(!exp_a && !mant_a)
    bne     s2, x0, CHECK_B_ZERO
    beq     s4, x0, return_b

CHECK_B_ZERO:
##if(!exp_b && !mant_b)
    bne     s3, x0, CHECK_A_EXPONENTS
    beq     s5, x0, return_a

CHECK_A_EXPONENTS:
##if (exp_a == 0)
    beq     s2, x0, CHECK_B_EXPONENTS
    ori     s4, s4, 0x80

CHECK_B_EXPONENTS:
##if (exp_b == 0)
    beq     s3, x0, RESULT_EXP 
    ori     s5, s5, 0x80

    

#result_exp  
RESULT_EXP:
    sub    s6, s2, s3           # exp_diff = exp_a - exp_b

##if (exp_diff > 0)
    blt    x0, s6, EXP_DIFF_POS
    blt    s6, x0, EXP_DIFF_NEG
#result_exp = exp_a;
    mv     s8, s2               # result_exp = exp_a
    j      BOTH_SIGN_CHECK

EXP_DIFF_POS:
    mv     s8, s2               # result_exp = exp_a
    li     t0, 8
    blt    t0, s6, return_a
    srl    s5, s5, s6           # mant_b >>= exp_diff
    j      BOTH_SIGN_CHECK
    
EXP_DIFF_NEG:
    mv     s8, s3               # result_exp = exp_b
    li     t0, -8
    blt    s6, t0, return_b 
    neg    t0, s6
    srl    s4, s4, t0           # mant_a >>= -exp_diff
    j      BOTH_SIGN_CHECK



BOTH_SIGN_CHECK:
    beq    s0, s1, SAME_SIGN
    bgeu   s4, s5, L_ge         # if (mant_a >= mant_b) goto L_ge;
    mv     s7, s1               # result_sign = sign_b
    sub    s9, s5, s4           # result_mant = mant_b - mant_a
    j      WHILE_LOOP
L_ge:
    mv     s7, s0               # result_sign = sign_a
    sub    s9, s4, s5           # result_mant = mant_a - mant_b

WHILE_LOOP:
## if (!result_mant) return 0
    beqz    s9, return_zero

normalize_loop:
    andi    t0, s9, 0x80
    bnez    t0, COMBINE_RESULT        
    slli    s9, s9, 1            # result_mant <<= 1
    addi    s8, s8, -1           # --result_exp
    bge     x0, s8, return_zero  # if (result_exp <= 0) → 下溢，回 0
    j       normalize_loop

return_zero:
    mv     a0, x0
    j      add_done

SAME_SIGN:
    mv     s7, s0               # result_sign = sign_a
    add    s9, s4, s5           # result_mant = mant_a + mant_b
    andi   t0, s9, 0x100
    beq    t0, x0, COMBINE_RESULT
    srli   s9, s9, 1            # result_mant >>=1
    addi   s8, s8, 1            # result_exp++
    li     t2, 0xFF
    bge    s8, t2, INFINITY

COMBINE_RESULT:
    mv     a0, s7
    slli   a0, a0, 15
    andi   s8, s8, 0xFF
    slli   s8, s8, 7
    or     a0, a0, s8
    andi   s9, s9, 0x7F
    or     a0, a0, s9
    j      add_done

INFINITY:
    mv     a0, s7
    slli   a0, a0, 15
    li     t0, 0X7F80
    or     a0, a0, t0
    j      add_done

return_a:
    j       add_done

return_b:
    mv      a0, a1
    j       add_done

add_done:

    ret
    

        
    