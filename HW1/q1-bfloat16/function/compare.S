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

    # ------- call bf16_eq(A, B) -------
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

        # ------- call bf16_lt(A, B) -------
    lhu     a0, 0(t0)            # a0 = A bits (arg0)
    lhu     a1, 0(t1)            # a1 = B bits (arg1)
    jal     ra, bf16_lt         # returns a0 = result bits
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

    # ------- call bf16_gt(A, B) -------
    lhu     a0, 0(t0)            # a0 = A bits (arg0)
    lhu     a1, 0(t1)            # a1 = B bits (arg1)
    jal     ra, bf16_gt         # returns a0 = result bits
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


#########################################
#                                       #
#                                       #   
#                 eq                    #
#                                       #
#                                       #
#########################################
#s0:a0
#s1:a1

bf16_eq:

    addi    sp, sp, -12
    sw      ra, 8(sp)
    sw      s0, 4(sp)
    sw      s1, 0(sp)

    mv      s0, a0
    mv      s1, a1
    jal     ra, bf16_isnan
    mv      s3, a0
    mv      a0, s1
    jal     ra, bf16_isnan
    or      s3, s3, a0
    bne     s3, x0, bf16_eq_false

    mv      a0, s0
    jal     ra, bf16_iszero
    beq     a0, x0, bf16_eq_check
    mv      a0, s1
    jal     ra, bf16_iszero
    beq     a0, x0, bf16_eq_check

bf16_eq_true:
    li      a0, 1
    j       bf16_eq_end


bf16_eq_check:
    beq     s0, s1, bf16_eq_true

bf16_eq_false:
    li      a0, 0
    j       bf16_eq_end

bf16_eq_end:
    lw      ra, 8(sp)
    lw      s0, 4(sp)
    lw      s1, 0(sp)
    addi    sp, sp, 12

    ret

#########################################
#                                       #
#                                       #   
#                 lt                    #
#                                       #
#                                       #
#########################################
#s0:a0
#s1:a1
#s2:sign_a
#s3:sign_b
#s4:temp
bf16_lt:
    addi    sp, sp, -24
    sw      ra, 20(sp)
    sw      s0, 16(sp)
    sw      s1, 12(sp)
    sw      s2, 8(sp)
    sw      s3, 4(sp)
    sw      s4, 0(sp)

    mv      s0, a0
    mv      s1, a1
    jal     ra, bf16_isnan
    mv      s4, a0
    mv      a0, t1
    jal     ra, bf16_isnan
    or      s4, s4, a0
    bne     s4, x0, bf16_lt_false

    mv      a0, s0
    jal     ra, bf16_iszero
    beq     a0, x0, bf16_lt_check_sign
    mv      a0, s1
    jal     ra, bf16_iszero
    beq     a0, x0, bf16_lt_check_sign

bf16_lt_false:

    li      a0, 0
    j       bf16_lt_end

bf16_lt_check_sign:
    srli    s2, s0, 15          # sign_a
    srli    s3, s1, 15          # sign_b
    andi    s2, s2, 1
    andi    s3, s3, 1

    bne     s2, s3, bf16_lt_sign_diff

    bgtz    s2, 1f 
    blt     s0, s1, bf16_lt_true
    j       bf16_lt_false

1:
    blt     s0, s1, bf16_lt_false
    j       bf16_lt_true

bf16_lt_true:
    li      a0, 1
    j       bf16_lt_end

bf16_lt_end:
    lw      ra, 20(sp)
    lw      s0, 16(sp)
    lw      s1, 12(sp)
    lw      s2, 8(sp)
    lw      s3, 4(sp)
    lw      s4, 0(sp)
    addi    sp, sp, 24

    ret

bf16_lt_sign_diff:

    blt     s2, s3, bf16_lt_false
    j       bf16_lt_true

#########################################
#                                       #
#                                       #   
#                 gt                    #
#                                       #
#                                       #
#########################################
bf16_gt:
    addi    sp, sp, -4
    sw      ra, 0(sp)

    mv      t0, a0
    mv      a0, a1
    mv      a1, t0
    jal     ra, bf16_lt

    lw      ra, 0(sp)
    addi    sp, sp, 4

    ret


#########################################
#                                       #
#                                       #   
#                 nan                   #
#                                       #
#                                       #
#########################################
bf16_isnan:

    addi    sp, sp, -4
    sw      ra, 0(sp)  

    mv      t0, a0              
    li      t1, BF16_EXP_MASK
    and     t2, t0, t1        

    li      t3, BF16_MANT_MASK
    and     t4, t0, t3          

    bne     t2, t1, bf16_isnan_false  
    beq     t4, x0, bf16_isnan_false   

    li      a0, 1      
    j       bf16_isnan_end

bf16_isnan_false:

    li      a0, 0           
    j       bf16_isnan_end

bf16_isnan_end:

    lw      ra, 0(sp)                     
    addi    sp, sp, 4
    ret

#########################################
#                                       #
#                                       #   
#                 zero                  #
#                                       #
#                                       #
#########################################
bf16_iszero:

    addi    sp, sp, -4
    sw      ra, 0(sp)

    li      t0, 0x7FFF
    and     t1, a0, t0           
    beq     t1, x0, bf16_iszero_true 
    li      a0, 0
    j       bf16_iszero_end

bf16_iszero_true:
    li      a0, 1  
    j       bf16_iszero_end   
  
bf16_iszero_end:

    lw      ra, 0(sp)                  
    addi    sp, sp, 4       

    ret  
