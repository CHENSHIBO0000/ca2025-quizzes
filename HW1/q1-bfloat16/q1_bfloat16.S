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

roundingValues: 

    .word 0x3FC00000
    .word 0x3F800347

roundingResults: 

    .word 0x3FC00000
    .word 0x3F800000

result_msg:
    .string " Result "
golden_msg:
    .string " Golden "
conversion_passed_msg:
    .string " Basic conversions Pass\n"
special_values_passed_msg:
    .string " Special values PASS\n"
arithmetic_passed_msg:
    .string " Arithmetic PASS\n"
comparison_passed_msg:
    .string " Comparison PASS\n"
edge_cases_passed_msg:
    .string " Edge cases PASS\n"
rounding_passed_msg:
    .string " Rounding PASS\n"
All_passed_msg:
    .string " Fuck finally PASS\n"


conversion_failed_msg:
    .string " Basic conversions Fail\n"
special_values_failed_msg:
    .string " Special values Fail\n"
arithmetic_failed_msg:
    .string " Arithmetic Fail\n"
comparison_failed_msg:
    .string " Comparison Fail\n"
edge_cases_failed_msg:
    .string " Edge cases Fail\n"
rounding_failed_msg:
    .string " Rounding Fail\n"

failed_msg:
    .string " Failed\n"
endline:
    .string "\n"

    .text


#------------------------------------------------------------------------------#
#                                                                              #
#                                                                              #   
#         main                                                                 #
#                                                                              #
#                                                                              #
#------------------------------------------------------------------------------#

main:
    li      s0, 0                         # failed = 0

    jal     ra, test_basic_conversions
    bne     x0, a0, failed                    # if (ret != 0) go to failed
    
    jal     ra, test_special_values
    bne     x0, a0, failed                    # if (ret != 0) go to failed

    jal     ra, test_arithmetic
    bne     x0, a0, failed                    # if (ret != 0) go to failed
    
    jal     ra, test_comparisons
    bne     x0, a0, failed                    # if (ret != 0) go to failed

    jal     ra, test_edge_cases
    bne     x0, a0, failed                    # if (ret != 0) go to failed

    jal     ra, test_rounding
    bne     x0, a0, failed                    # if (ret != 0) go to failed

    la      a0, All_passed_msg
    li      a7, 4
    ecall                                 # Print All passed message
    
    li      a7, 93                        # system call: exit2
    li      a0, 1                         # exit value
    ecall                                 # exit 1


failed: 
    la      a0, failed_msg
    li      a7, 4
    ecall      
    
    li      a7, 93                        # system call: exit2
    li      a0, 1                         # exit value
    ecall                                 # exit 1



#------------------------------------------------------------------------------#
#                                                                              #
#                                                                              #   
#         test_basic_conversions                                               #
#                                                                              #
#                                                                              #
#------------------------------------------------------------------------------#
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
    li      a0, 0
    j       5f                            # go to return

4: # failed
    la      a0, conversion_failed_msg
    li      a7, 4
    ecall                                 # Print failed message
    li      a0, 1                         # a0 = 1
5: # on return
    lw      s0, 0(sp)                     # restore s0
    lw      ra, 4(sp)                     # restore return addr
    addi    sp, sp, 8
    ret

#------------------------------------------------------------------------------#
#                                                                              #
#                                                                              #   
#         test_special_values                                                  #
#                                                                              #
#                                                                              #
#------------------------------------------------------------------------------#

test_special_values:
    addi    sp, sp, -4
    sw      ra, 0(sp)                     # store return addr

# +Infinity #
    li      a0, BF16_POS_INF
    jal     ra, bf16_isinf
    beq     a0, x0, failed                    

    li      a0, BF16_POS_INF
    jal     ra, bf16_isnan
    bne     a0, x0, failed                    
# -Infinity #
    li      a0, BF16_NEG_INF
    jal     ra, bf16_isinf
    beq     a0, x0, failed   
# NAN #
    li      a0, BF16_NAN
    jal     ra, bf16_isnan
    beq     a0, x0, failed   

    li      a0, BF16_NAN
    jal     ra, bf16_isinf
    bne     a0, x0, failed    

# ZERO #
    li      a0, BF16_ZERO
    jal     ra, bf16_iszero
    beq     a0, x0, failed  

# NEG_ZERO #
    li      a0, BF16_NEG_ZERO
    jal     ra, bf16_iszero
    beq     a0, x0, 1f 

    la      a0, special_values_passed_msg
    li      a7, 4
    ecall                                 # Print passed message

    mv      a0, x0                        # a0 = 0
    j       2f                            # go to return
1: # failed
    la      a0, special_values_failed_msg
    li      a7, 4
    ecall                                 # Print failed message
    li      a0, 1                         # a0 = 1

2: # on return
    lw      ra, 0(sp)                     # restore return addr
    addi    sp, sp, 4

    ret



#------------------------------------------------------------------------------#
#                                                                              #
#                                                                              #   
#         test_comparisons                                                     #
#                                                                              #
#                                                                              #
#------------------------------------------------------------------------------#
# s0 : a
# s1 : b
# s2 : c  
# s3 : nan
test_comparisons:

    addi    sp, sp, -4
    sw      ra, 0(sp)
    li      a0, 0x3F800000
    jal     ra, f32_to_bf16                # f32_to_bf16(1.0f)
    mv      s0, a0
    mv      s2, a0

    li      a0, 0x40000000
    jal     ra, f32_to_bf16                # f32_to_bf16(2.0f)
    mv      s1, a0

    mv      a0, s0
    mv      a1, s2
    jal     ra, bf16_eq
    beq     a0, x0, 1f

    mv      a0, s0
    mv      a1, s1
    jal     ra, bf16_eq
    bne     a0, x0, 1f

    mv      a0, s0
    mv      a1, s1
    jal     ra, bf16_lt
    beq     a0, x0, 1f    

    mv      a0, s1
    mv      a1, s0
    jal     ra, bf16_lt
    bne     a0, x0, 1f        

    mv      a0, s0
    mv      a1, s2
    jal     ra, bf16_lt
    bne     a0, x0, 1f    

    mv      a0, s1
    mv      a1, s0
    jal     ra, bf16_gt
    beq     a0, x0, 1f        

    mv      a0, s0
    mv      a1, s1
    jal     ra, bf16_gt
    bne     a0, x0, 1f        

    li      s3, 0x7FC0

    mv      a0, s3
    mv      a1, s3   
    jal     ra, bf16_eq
    bne     a0, x0, 1f

    mv      a0, s3
    mv      a1, s0   
    jal     ra, bf16_lt
    bne     a0, x0, 1f

    mv      a0, s3
    mv      a1, s0   
    jal     ra, bf16_gt
    bne     a0, x0, 1f

    mv      a0, x0   
    
    la      a0, comparison_passed_msg
    li      a7, 4
    ecall                                 # Print passed message
    li      a0, 0
    j       2f

1: # failed
    la      a0, comparison_failed_msg
    li      a7, 4
    ecall                                 # Print failed message
    li      a0, 1                         # a0 = 1

2: # on return
    lw      ra, 0(sp)
    addi    sp, sp, 4

    ret


#------------------------------------------------------------------------------#
#                                                                              #
#                                                                              #   
#         test_arithmetic                                                      #
#                                                                              #
#                                                                              #
#------------------------------------------------------------------------------#
# s0 : a
# s1 : b
# s2 : c  
# s3 : result
# s4 : golden
test_arithmetic:
    addi    sp, sp, -4
    sw      ra, 0(sp)
    
    li      a0, 0x3F800000
    jal     ra, f32_to_bf16                # f32_to_bf16(orig)
    mv      s0, a0

    li      a0, 0x40000000
    jal     ra, f32_to_bf16 
    mv      s1, a0    

#1.0f + 2.0f
    mv      a0, s0
    mv      a1, s1
 
    jal     ra, bf16_add
    mv      s2, a0

    jal     ra, bf16_to_f32
    mv      s3, a0
    
    li      s4, 0x40400000
    bne     s3, s4 1f
    
#2.0f - 1.0f
    mv      a0, s1    
    mv      a1, s0

    jal     ra, bf16_sub
    mv      s2, a0

    jal     ra, bf16_to_f32
    mv      s3, a0

    li      s4, 0x3F800000
    bne     s3, s4 1f    
    
#3.0f * 4.0f
    li      a0, 0x40400000
    jal     ra, f32_to_bf16                # f32_to_bf16(orig)
    mv      s0, a0

    li      a0, 0x40800000
    jal     ra, f32_to_bf16 
    mv      s1, a0    

    mv      a0, s0    
    mv      a1, s1

    jal     ra, bf16_mul
    mv      s2, a0   

    jal     ra, bf16_to_f32
    mv      s3, a0

    li      s4, 0x41400000
    bne     s3, s4 1f            

#10.0f / 2.0f
    li      a0, 0x41200000
    jal     ra, f32_to_bf16                # f32_to_bf16(orig)
    mv      s0, a0

    li      a0, 0x40000000
    jal     ra, f32_to_bf16 
    mv      s1, a0    

    mv      a0, s0    
    mv      a1, s1  

    jal     ra, bf16_div
    mv      s2, a0    
    jal     ra, bf16_to_f32
    mv      s3, a0

    li      s4, 0x40A00000
    bne     s3, s4 1f           

#4.0f ^ 0.5
    li      a0, 0x40800000
    jal     ra, f32_to_bf16 
    mv      s0, a0    

    jal     ra, bf16_sqrt
    mv      s2, a0    
    jal     ra, bf16_to_f32
    mv      s3, a0

    li      s4, 0x40000000
    bne     s3, s4 1f   

#9.0f ^ 0.5
    li      a0, 0x41100000
    jal     ra, f32_to_bf16 
    mv      s0, a0    

    jal     ra, bf16_sqrt
    mv      s2, a0    
    jal     ra, bf16_to_f32
    mv      s3, a0

    li      s4, 0x40400000
    bne     s3, s4 1f   

#print_pass
    la      a0, arithmetic_passed_msg
    li      a7, 4
    ecall                                 # Print passed message
    li      a0, 0
    j       2f


1: # failed
    la      a0, arithmetic_failed_msg
    li      a7, 4
    ecall                                 # Print failed message
    li      a0, 1                         # a0 = 1

2: # on return
    lw      ra, 0(sp)
    addi    sp, sp, 4

    ret

#------------------------------------------------------------------------------#
#                                                                              #
#                                                                              #   
#         test_edge_cases                                                      #
#                                                                              #
#                                                                              #
#------------------------------------------------------------------------------#
# s0 : tiny
# s1 : bf_tiny
# s2 : tiny_val  
# s3 : huge
# s4 : bf_huge
# s5 : small
# s6 : smaller
# s7 : smaller_val
# s8 : f32_to_bf16(10.0f)

test_edge_cases:
    addi    sp, sp, -4
    sw      ra, 0(sp)
    
#Tiny
    li      s0, 0x00000001
    mv      a0, s0
    jal     ra, f32_to_bf16 
    mv      s1, a0
    jal     ra, bf16_to_f32    
    mv      s2, a0

    mv      a0, s1
    jal     ra, bf16_iszero
    beq     a0, x0, 1f   

#Huge
    li      a0, 0x41200000
    jal     ra, f32_to_bf16
    mv      t0, a0

    li      s3, 0x7E967699
    mv      a0, s3
    jal     ra, f32_to_bf16 
    mv      s4, a0

    mv      a1, t0
    jal     ra, bf16_mul
    jal     ra, bf16_isinf
    beq     a0, x0, 1f
    
#Small
    li      a0, 0x41200000
    jal     ra, f32_to_bf16 
    mv      s8, a0                  #  t0 = f32_to_bf16(10.0f)
    
    li      a0, 0x006CE3EE
    jal     ra, f32_to_bf16   
    mv      a1, s8
    jal     ra, bf16_div
    jal     ra, bf16_iszero

    beq     a0, x0, 1f



#print_pass
    la      a0, edge_cases_passed_msg
    li      a7, 4
    ecall                                 # Print passed message
    li      a0, 0
    j       2f


1: # failed
    la      a0, edge_cases_failed_msg
    li      a7, 4
    ecall                                 # Print failed message
    li      a0, 1                         # a0 = 1

2: # on return
    lw      ra, 0(sp)
    addi    sp, sp, 4

    ret

#------------------------------------------------------------------------------#
#                                                                              #
#                                                                              #   
#         test_rounding                                                        #
#                                                                              #
#                                                                              #
#------------------------------------------------------------------------------#
# s0 : exact
# s1 : bf_exact
# s2 : back_exact 
# s3 : val
# s4 : bf
# s5 : back
#    roundingValues:  .word 0x3FC00000, 0x3F800347
#    roundingResults: .word 0x3FC00000, 0x3F800000
test_rounding:
    addi    sp, sp, -4
    sw      ra, 0(sp)

    li      s0, 0x3FC00000
    mv      a0, s0
    jal     ra, f32_to_bf16 
    mv      s1, a0
    jal     ra, bf16_to_f32    
    mv      s2, a0

    bne     s0, s2, 1f

    li      s3, 0x3F800347
    mv      a0, s3
    jal     ra, f32_to_bf16 
    mv      s4, a0
    jal     ra, bf16_to_f32    
    mv      s5, a0 

    li      t0, 0x3F800000
    bne     s5, t0, 1f   

#print_pass
    la      a0, rounding_passed_msg
    li      a7, 4
    ecall                                 # Print passed message
    li      a0, 0
    j       2f


1: # failed
    la      a0, rounding_failed_msg
    li      a7, 4
    ecall                                 # Print failed message
    li      a0, 1                         # a0 = 1

2: # on return
    lw      ra, 0(sp)
    addi    sp, sp, 4

    ret



#########################################
#                                       #
#                                       #   
#             f32_to_bf16               #
#                                       #
#                                       #
#########################################

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

#########################################
#                                       #
#                                       #   
#              bf16_to_f32              #
#                                       #
#                                       #
#########################################


bf16_to_f32:
    slli    a0, a0, 16
    ret

#########################################
#                                       #
#                                       #   
#            bf16_isnan                 #
#                                       #
#                                       #
#########################################


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

#########################################
#                                       #
#                                       #   
#            bf16_is_inf                #
#                                       #
#                                       #
#########################################

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


#########################################
#                                       #
#                                       #
#            bf16_is_zero               #
#                                       #
#                                       #
#########################################

bf16_iszero:
    li      t0, 0x7FFF
    and     t1, a0, t0           
    beq     t1, x0, bf16_iszero_true 
    li      a0, 0
    ret                  
bf16_iszero_true:
    li      a0, 1            
    ret    


#########################################
#                                       #
#                                       #   
#               bf16_eq                 #
#                                       #
#                                       #
#########################################
#s0:a0
#s1:a1

bf16_eq:

    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      s0, 8(sp)
    sw      s1, 4(sp)
    sw      s2, 0(sp)
  
    mv      s0, a0
    mv      s1, a1
    jal     ra, bf16_isnan
    mv      s2, a0
    mv      a0, s1
    jal     ra, bf16_isnan
    or      s2, s2, a0
    bne     s2, x0, bf16_eq_false

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
    lw      ra, 12(sp)
    lw      s0, 8(sp)
    lw      s1, 4(sp)
    lw      s2, 0(sp)
    addi    sp, sp, 16

    ret

#########################################
#                                       #
#                                       #   
#               bf16_lt                 #
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
    mv      a0, s1
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
#               bf16_gt                 #
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
#               bf16_add                #
#                                       #
#                                       #
#########################################

bf16_add:

    addi    sp, sp, -44
    sw      ra, 40(sp)
    sw      s0, 36(sp)
    sw      s1, 32(sp)
    sw      s2, 28(sp)        
    sw      s3, 24(sp)
    sw      s4, 20(sp)
    sw      s5, 16(sp)
    sw      s6, 12(sp)        
    sw      s7,  8(sp)      
    sw      s8,  4(sp)
    sw      s9,  0(sp)    


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
    mv      a0, x0
    j       add_done

SAME_SIGN:
    mv      s7, s0               # result_sign = sign_a
    add     s9, s4, s5           # result_mant = mant_a + mant_b
    andi    t0, s9, 0x100
    beq     t0, x0, COMBINE_RESULT
    srli    s9, s9, 1            # result_mant >>=1
    addi    s8, s8, 1            # result_exp++
    li      t2, 0xFF
    bge     s8, t2, INFINITY

COMBINE_RESULT:
    mv      a0, s7
    slli    a0, a0, 15
    andi    s8, s8, 0xFF
    slli    s8, s8, 7
    or      a0, a0, s8
    andi    s9, s9, 0x7F
    or      a0, a0, s9
    j       add_done

INFINITY:
    mv      a0, s7
    slli    a0, a0, 15
    li      t0, 0X7F80
    or      a0, a0, t0
    j       add_done

return_a:
    j       add_done

return_b:
    mv      a0, a1
    j       add_done

add_done:

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

#########################################
#                                       #
#                                       # 
#              bf16_sub                 #
#                                       #
#                                       #
#########################################
bf16_sub:
    addi    sp, sp, -4
    sw      ra, 0(sp)
    
    li      t0,0x8000 
    xor     a1, a1, t0     
    jal     ra, bf16_add

    lw      ra, 0(sp)
    addi    sp, sp, 4
    ret

#########################################
#                                       #
#                                       #
#              bf16_mul                 #
#                                       #
#                                       #
#########################################

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
    bne     s4, x0, RETURN_A_MUL
##  if (!exp_b && !mant_b)
    #bne     s3, x0, RETURN_INFINITY_MUL
    #bne     s5, x0, RETURN_INFINITY_MUL
    or      t0, s3, s5
    beqz    t0, RETURN_NAN_MUL
    j       RETURN_INFINITY_MUL

CHECK_EXP_B_FF:

##if (exp_b == 0xFF)
    li      t0, 0XFF
    bne     s3, t0, CHECK_ZERO
    bne     s5, x0, RETURN_B_MUL
##  if (!exp_b && !mant_b)
    #bne     s2, x0, RETURN_INFINITY_MUL
    #bne     s4, x0, RETURN_INFINITY_MUL
    or       t0, s2, s4
    beqz     t0, RETURN_NAN_MUL
    j       RETURN_INFINITY_MUL

CHECK_ZERO:
##if ((!exp_a && !mant_a) || (!exp_b && !mant_b))
    or      t0, s2, s4
    beqz    t0, RETURN_ZERO_MUL
    or      t1, s3, s5
    beqz    t1, RETURN_ZERO_MUL

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
    j       mul_done

no_overflow:

    bgt     s9, x0, FINISH_COMBINE_RESULT_MUL
    li      t0, -6
    blt     s9, t0, RETURN_ZERO_MUL

    li      t0, 1
    sub     t0, t0, s9
    srl     s8, s8, t0
    li      s9, 0


FINISH_COMBINE_RESULT_MUL:
    slli    s6, s6, 15
    andi    s9, s9, 0xFF
    slli    s9, s9, 7
    andi    s8, s8, 0x7F
    or      a0, s6, s9
    or      a0, a0, s8

    j       mul_done



RETURN_NAN_MUL:

    li      a0, BF16_NAN
    j       mul_done

RETURN_INFINITY_MUL:

    slli    a0, s6, 15
    li      t0, 0x7F80
    or      a0, a0, t0
    j       mul_done

RETURN_A_MUL:

    j       mul_done

RETURN_B_MUL:

    mv      a0, a1
    j       mul_done

RETURN_ZERO_MUL:

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


#########################################
#                                       #
#                                       # 
#              bf16_div                 #
#                                       #
#                                       #
#########################################
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
    bne     s5, x0, RETURN_B_DIV
    bne     s2, t0, RETURN_ZERO_DIV
    bne     s4, x0, RETURN_ZERO_DIV
    j       RETURN_NAN_DIV


CHECK_ZERO_B:
##  if (!exp_b && !mant_b)
    or       t0, s3, s5
####  if (!exp_a && !mant_a)    
    or       t1, s2, s4
    or       t2, t0, t1
    beqz     t2, RETURN_NAN_DIV
    beqz     t0, RETURN_INFINITY_DIV

##if (exp_a == 0xFF)
    li      t0, 0XFF
    bne     s2, t0, CHECK_ZERO_A
    bne     s4, x0, RETURN_A_DIV
    j       RETURN_INFINITY_DIV

CHECK_ZERO_A:
##  if (!exp_a && !mant_a)
    or       t0, s2, s4
    beqz     t0, RETURN_ZERO_DIV

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
    j        RETURN_INFINITY_DIV

8:
    blez     s10, RETURN_ZERO_DIV

    j        FINISH_COMBINE_RESULT_DIV



#return result
RETURN_INFINITY_DIV:

    slli    a0, s6, 15
    li      t0, 0x7F80
    or      a0, a0, t0
    j       div_done

RETURN_ZERO_DIV:
    slli    s6, s6, 15
    mv      a0, s6
    j       div_done

RETURN_NAN_DIV:
    li      a0, BF16_NAN
    j       div_done

RETURN_B_DIV:

    mv      a0, a1
    j       div_done


RETURN_A_DIV:

    j       div_done

FINISH_COMBINE_RESULT_DIV:
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
    
#########################################
#                                       #
#                                       # 
#              bf16_sqrt                #
#                                       #
#                                       #
#########################################

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

    bne     s2, x0, RETURN_A_SQRT  
    bne     s0, x0, RETURN_NAN_SQRT
    j       RETURN_A_SQRT

1:  
    or      t0, s1, s2
    beq     t0, x0, RETURN_ZERO_SQRT

    bne     s0, x0, RETURN_NAN_SQRT

    beq     s1, x0, RETURN_ZERO_SQRT

    addi    s8, s1, -127
    ori     s3, s2, 0x80        

    andi    t0, s8, 0x1
    beq     t0, x0, EVEN_EXP
    slli    s3, s3, 1
    addi    s9, s8, -1
    srai    s9, s9, 1 
    addi    s9, s9, 127
    j       BINARY_SEARCH

EVEN_EXP:
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
    bge     s9, t0, RETURN_INFINITY_SQRT 
    ble     s9, x0, RETURN_ZERO_SQRT 
    j       FINISH_COMBINE_RESULT_SQRT 
    


  
#RETURN result
RETURN_A_SQRT:
    j       sqrt_done

RETURN_NAN_SQRT:
    li      a0, BF16_NAN
    j       sqrt_done

RETURN_ZERO_SQRT:
    li      a0, BF16_ZERO
    j       sqrt_done

RETURN_INFINITY_SQRT:
    li      a0, 0x7F80
    j       sqrt_done

FINISH_COMBINE_RESULT_SQRT:
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
    
    