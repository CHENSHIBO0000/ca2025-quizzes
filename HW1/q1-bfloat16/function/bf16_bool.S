    .data

    .equ    BF16_SIGN_MASK, 0x8000
    .equ    BF16_EXP_MASK, 0x7F80
    .equ    BF16_MANT_MASK, 0x007F
    .equ    BF16_EXP_BIAS, 127
    .equ    NUM_TEST_VALUES_CONV, 9
    .equ    NUM_TEST_VALUES_ARITH, 11

    .equ    BF16_POS_INF, 0x7F80
    .equ    BF16_NEG_INF, 0xFF80
    .equ    BF16_NAN, 0x7FC0
    .equ    BF16_ZERO, 0x0000
    .equ    BF16_NEG_ZERO, 0x8000

orig_f32:
    .word   0x00000000                    # 0.0
    .word   0x3f800000                    # 1.0
    .word   0xbf800000                    # -1.0
    .word   0x3f000000                    # 0.5
    .word   0xbf000000                    # -0.5
    .word   0x40490fd0                    # 3.14159
    .word   0xc0490fd0                    # -3.14159
    .word   0x501502f9                    # 1e10
    .word   0xd01502f9                    # -1e10

conv_bf16:
    .word   0x0000                        # 0.0
    .word   0x3f80                        # 1.0
    .word   0xbf80                        # -1.0
    .word   0x3f00                        # 0.5
    .word   0xbf00                        # -0.5
    .word   0x4049                        # 3.140625
    .word   0xc049                        # -3.140625
    .word   0x5015                        # 1e10
    .word   0xd015                        # -1e10

conv_f32:
    .word   0x00000000                    # 0.0
    .word   0x3f800000                    # 1.0
    .word   0xbf800000                    # -1.0
    .word   0x3f000000                    # 0.5
    .word   0xbf000000                    # -0.5
    .word   0x40490000                    # 3.140625
    .word   0xc0490000                    # -3.140625
    .word   0x50150000                    # 1e10
    .word   0xd0150000                    # -1e10

bf16_add_input:
    .word   0x3f80, 0x4000                # 1.0 + 2.0
    .word   0x4049, 0x402e                # 3.140625 + 2.71875
    .word   0x3f80, 0xffffc000            # 1.0 + -2.0
    .word   0xffffc000, 0x3f80            # -2.0 + 1.0
    .word   0x0000, 0x3f80                # 0.0 + 1.0
    .word   0x3f80, 0x0000                # 1.0 + 0.0
    .word   0x7f80, 0x3f80                # +Inf + 1.0
    .word   0x3f80, 0x7f80                # 1.0 + +Inf
    .word   0xffff80, 0x3f80              # -inf + 1.0
    .word   0x3f80, 0xffff80              # 1.0 + -inf
    .word   0x7f62, 0x7f62                # 3e38 + 3e38 (f32 to bf16)

bf16_add_output:
    .word   0x4040                        # 3.0
    .word   0x40bb                        # 5.84375
    .word   0xbf80                        # -1.0
    .word   0xbf80                        # -1.0
    .word   0x3f80                        # 1.0
    .word   0x3f80                        # 1.0
    .word   0x7f80                        # +Inf
    .word   0x7f80                        # +Inf
    .word   0xffff80                      # -Inf
    .word   0xffff80                      # -Inf
    .word   0x7f80                        # +Inf

result_msg:
    .string " Result "
golden_msg:
    .string " Golden "

special_values_passed_msg:
    .string " Special values PASS\n"

endline:
    .string "\n"

    .text


#-------------------------------------------------------------------------------
# main
#-------------------------------------------------------------------------------
main:
    li      s0, 0                         # failed = 0

# test_special_values()
    jal     ra, test_special_values
    bne     x0, a0, 1f                    # if (ret != 0) g

#-------------------------------------------------------------------------------
# test_special_values
#-------------------------------------------------------------------------------
test_special_values:
    addi    sp, sp, -4
    sw      ra, 0(sp)                     # store return addr

    li      a0, BF16_POS_INF
    jal     ra, bf16_isinf
    beq     x0, a0, 1f                    # if (ret == 0) go to failed

    li      a0, BF16_POS_INF
    jal     ra, bf16_isnan
    bne     x0, a0, 1f                    # if (ret != 0) go to failed

    li      a0, BF16_NEG_INF
    jal     ra, bf16_isinf
    beq     x0, a0, 1f                    # if (ret == 0) go to failed

    li      a0, BF16_NAN
    jal     ra, bf16_isnan
    beq     x0, a0, 1f                    # if (ret == 0) go to failed

    li      a0, BF16_NAN
    jal     ra, bf16_isinf
    bne     x0, a0, 1f                    # if (ret != 0) go to failed

    li      a0, BF16_ZERO
    jal     ra, bf16_iszero
    beq     x0, a0, 1f                    # if (ret == 0) go to failed

    li      a0, BF16_NEG_ZERO
    jal     ra, bf16_iszero
    beq     x0, a0, 1f                    # if (ret == 0) go to failed

    li      a7, 4
    la      a0, special_values_passed_msg
    ecall                                 # Print passed message

    li      a0, 0
    j       2f                            # go to return
1: # failed
    li      a0, 1
2: # on return
    lw      ra, 0(sp)                     # restore return addr
    addi    sp, sp, 4
    ret

bf16_isnan:
    mv      t0, a0              
    li      t1, BF16_EXP_MASK
    and     t2, t0, t1        

    li      t3, BF16_MANT_MASK
    and     t4, t0, t3          

    bne     t2, t1, bf16_isnan_false  
    beq     t4, x0, bf16_isnan_false   

    li      a0, 1               
    ret

bf16_isnan_false:

    li      a0, 0             
    ret

bf16_isinf:

    mv      t0, a0              
    li      t1, BF16_EXP_MASK
    and     t2, t0, t1        

    li      t3, BF16_MANT_MASK
    and     t4, t0, t3          

    bne     t2, t1, bf16_isinf_false 
    bne     t4, x0, bf16_isinf_false   

    li      a0, 1             
    ret
    
bf16_isinf_false:

    li      a0, 0                
    ret


bf16_iszero:
    li      t0, 0x7FFF
    and     t1, a0, t0           
    beq     t1, x0, bf16_iszero_true 
    li      a0, 0
    ret                  
bf16_iszero_true:
    li      a0, 1            
    ret    

