# s0:sign_a
# s1:sign_b
# s2:exp_a
# s3:exp_b
# s4:mant_a
# s5:mant_b
# s6:result_sign
# s7:exp_adjust
# s8:result_mant
# s9:result_exp

.data
input_a:   .half 0x3f40          # A = 1.0 (bf16 bits)
input_b:   .half 0x3e80         # B = 1.0 (bf16 bits)
s_a:       .asciz "A = "
s_b:       .asciz "B = "
s_sum:     .asciz "A * B = "
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
    jal     ra, bf16_mul         # returns a0 = result bits
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




bf16_mul:
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

##if (exp_a == 0xFF)
    li      t0, 0XFF
    bne     s2, t0, CHECK_EXP_B_FF
    bne     s4, x0, RETURN_A
##  if (!exp_b && !mant_b)
    #bne     s3, x0, RETURN_INFINITY
    #bne     s5, x0, RETURN_INFINITY
    or      t0, s3, s5
    beqz    t0, RETURN_NAN
    j       RETURN_INFINITY

CHECK_EXP_B_FF:

##if (exp_b == 0xFF)
    li      t0, 0XFF
    bne     s3, t0, CHECK_ZERO
    bne     s5, x0, RETURN_B
##  if (!exp_b && !mant_b)
    #bne     s2, x0, RETURN_INFINITY
    #bne     s4, x0, RETURN_INFINITY
    or       t0, s2, s4
    beqz     t0, RETURN_NAN
    j       RETURN_INFINITY

CHECK_ZERO:
##if ((!exp_a && !mant_a) || (!exp_b && !mant_b))
    or      t0, s2, s4
    beqz    t0, RETURN_ZERO
    or      t1, s3, s5
    beqz    t1, RETURN_ZERO

##int16_t exp_adjust = 0;
    li      s7, 0

##Check_exp_a
    beqz    s2, A_SUBNORMAL
    ori     s4, s4, 0x80
    j       CHECK_B_SUBNORMAL

A_SUBNORMAL:

WHILE_A:
    andi    t0, s4, 0X80
    bnez    t0, 1f
    slli    s4, s4, 1
    addi    s7, s7, -1
    j       WHILE_A

1:
    li      s2, 1
    j       CHECK_B_SUBNORMAL


##Check_exp_b
CHECK_B_SUBNORMAL:

    beqz    s3, B_SUBNORMAL
    ori     s5, s5, 0x80
    j       MUL

B_SUBNORMAL:

WHILE_B:
    andi    t0, s5, 0X80
    bnez    t0, 2f
    slli    s5, s5, 1
    addi    s7, s7, -1
    j       WHILE_B
2:
    li      s3, 1

MUL:
# s4 = A (16-bit), s5 = B (16-bit) → s8 = A*B (32-bit)
    li    s8, 0
    mv    t0, s4
    mv    t1, s5
    li    t3, 16
1:
    andi  t2, t1, 1
    beqz  t2, 2f
    add   s8, s8, t0
2:
    slli  t0, t0, 1
    srli  t1, t1, 1
    addi  t3, t3, -1
    bnez  t3, 1b

    add   s9, s2, s3        
    li    t0, 127
    sub   s9, s9, t0
    add   s9, s9, s7           # result_exp = exp_a + exp_b - BF16_EXP_BIAS + exp_adjust



##  if (result_mant & 0x8000)
    li      t0,0x8000
    and     t0, s8, t0
    beqz    t0, 3f
    srli    s8, s8, 8         
    andi    s8, s8, 0x7F
    addi    s9, s9, 1
    j       CHECK_OVERFLOW
3:
    srli   s8, s8, 7
    andi   s8, s8, 0x7F
    
##  if (result_exp >= 0xFF)
CHECK_OVERFLOW:

    li      t0, 0XFF
    blt     s9, t0, no_overflow
    slli    t1, s6, 15           
    li      t0, 0x7F80           
    or      a0, t1, t0           
    ret

no_overflow:

    bgt     s9, x0, FINISH_COMBINE_RESULT
    li      t0, -6
    blt     s9, t0, RETURN_ZERO

    li      t0, 1
    sub     t0, t0, s9
    srl     s8, s8, t0
    li      s9, 0


FINISH_COMBINE_RESULT:
    slli    s6, s6, 15
    andi    s9, s9, 0xFF
    slli    s9, s9, 7
    andi    s8, s8, 0x7F
    or      a0, s6, s9
    or      a0, a0, s8

    j       mul_done



##  if (result_exp <= 0)

####  if (result_exp < -6)


RETURN_NAN:

    li      a0, BF16_NAN
    j       mul_done

RETURN_INFINITY:

    slli    a0, s6, 15
    li      t0, 0x7F80
    or      a0, a0, t0
    j       mul_done

RETURN_A:

    j       mul_done

RETURN_B:

    mv      a0, a1
    j       mul_done

RETURN_ZERO:

    mv      a0, s6
    slli    a0, a0, 15
    j       mul_done

mul_done:

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
    

        
    