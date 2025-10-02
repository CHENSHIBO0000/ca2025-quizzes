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
conversion_passed_msg:
    .string " Basic conversions Pass\n"
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

# test_basic_conversions()
    jal     ra, test_basic_conversions
    bne     x0, a0, 1f                    # if (ret != 0) go to failed

1: # failed
    li      a7, 93                        # system call: exit2
    li      a0, 1                         # exit value
    ecall                                 # exit 1


#-------------------------------------------------------------------------------
# test_basic_conversions
#
# Register Usage:
#   s0: i
#   s1: arr_ptr
#   s2: orig
#   s3: bf
#   s4: conv
#   s5: conv_bf16
#   s6: conv_f32
#
#-------------------------------------------------------------------------------
test_basic_conversions:
    addi    sp, sp, -8
    sw      ra, 4(sp)                     # store return addr
    sw      s0, 0(sp)                     # store s0

# for (i = 0; i < NUM_TEST_VALUES; i++)
    li      s0, 0                         # i = 0

    la      s1, orig_f32                  # arr_ptr = &orig_f32[0]
    la      s5, conv_bf16                 # arr_ptr = &conv_bf16[0]
    la      s6, conv_f32                  # arr_ptr = &conv_f32[0]
    li      t0, NUM_TEST_VALUES_CONV
    bge     s0, t0, 3f                    # if (i >= NUM_TEST_VALUES) go to end for
1:
    lw      s2, 0(s1)                     # orig = orig_f32[i]

    mv      a0, s2
    jal     ra f32_to_bf16                # f32_to_bf16(orig)
    mv      s3, a0                        # bf = f32_to_bf16(orig)

    jal     ra bf16_to_f32                # bf16_to_f32(bf)
    mv      s4, a0                        # conv = bf16_to_f32(bf)

# Sign bit check
    snez    t0, s2                        # t0 = (orig != 0.0)
    beq     t0, x0, 2f                    # if (orig == 0.0) go to 2
    slt     t1, s2, x0                    # t1 = orig < 0
    slt     t2, s4, x0                    # t2 = conv < 0
    bne     t1, t2, 4f                    # if (orig < 0) != (conv < 0) go to failed
2:

# bf vs conv_bf16 check
    lw      t0, 0(s5)                     # t0 = conv_bf16[i]
    bne     s3, t0, 4f                    # if (bf != conv_bf16[i]) go to failed

# conv vs conv_f32 check
    lw      t0, 0(s6)                     # t0 = conv_f32[i]
    bne     s4, t0, 4f                    # if (conv != conv_f32[i]) go to failed

# Print orig and conv for debugging

    addi    s0, s0, 1                     # i++
    addi    s1, s1, 4                     # arr_ptr += 4
    addi    s5, s5, 4
    addi    s6, s6, 4

    li      t0, NUM_TEST_VALUES_CONV
    blt     s0, t0, 1b                    # if (i < NUM_TEST_VALUES), back to 1
# end for
3:
    la      a0, conversion_passed_msg
    li      a7, 4
    ecall                                 # Print passed message

    mv      a0, x0                        # a0 = 0
    j       5f                            # go to return
4: # failed
    li      a0, 1                         # a0 = 1
5: # on return
    lw      s0, 0(sp)                     # restore s0
    lw      ra, 4(sp)                     # restore return addr
    addi    sp, sp, 8
    ret


f32_to_bf16:

    mv      t0, a0                        
    srli    t1, t0, 23                   
    andi    t1, t1, 0xFF                 

    li      t2, 0xFF                     
    beq     t1, t2, 1f                    

    srli    t1, t0, 16               
    andi    t1, t1, 1                 
    li      t2, 0x7FFF                 
    add     t3, t1, t2           
    add     t0, t0, t3           
    srli    t0, t0, 16
    j       2f

1:
    srli    t0, t0, 16                    
    li      t1, 0xFFFF
    and     t0, t0, t1                   
2: 
    mv      a0, t0                        
    ret


bf16_to_f32:
    slli    a0, a0, 16
    ret
