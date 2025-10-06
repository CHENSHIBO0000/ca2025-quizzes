.equ    NUM_TEST_VALUES, 25

.data
orig_X:
    .word 0x00000000   #1
    .word 0x00000001   #2
    .word 0x80000000   #3
    .word 0xFFFFFFFF   #4
    .word 0xAAAAAAAA   #5
    .word 0xF0F0F0F0   #6
    .word 0x12345678   #7
    .word 0x12345678   #8
    .word 0x0000FFFF   #9
    .word 0x00000000   #10
    .word 0x7FFFFFFF   #11
    .word 0x7FFFFFFF   #12
    .word 0x00010000   #13
    .word 0x00F00000   #14
    .word 0x00F00000   #15
    .word 0xDEADBEEF   #16
    .word 0xCAFEBABE   #17
    .word 0x01010101   #18
    .word 0xAAAAAAAA   #19
    .word 0x00000003   #20
    .word 0x0000000F   #21
    .word 0x00000008   #22
    .word 0x40000000   #23
    .word 0x80000001   #24
    .word 0x00000002   #25

orig_Y:
    .word 0x00000000   #1
    .word 0x00000000   #2
    .word 0x00000000   #3
    .word 0x00000000   #4
    .word 0x55555555   #5
    .word 0x0F0F0F0F   #6
    .word 0x12345678   #7
    .word 0x12345670   #8
    .word 0xFFFF0000   #9
    .word 0xFFFFFFFF   #10
    .word 0xFFFFFFFF   #11
    .word 0x80000000   #12
    .word 0x00000001   #13
    .word 0x00000000   #14
    .word 0x0000F000   #15
    .word 0xFEEDFACE   #16
    .word 0x8BADF00D   #17
    .word 0x10101010   #18
    .word 0xAAAAAAAA   #19
    .word 0x00000001   #20
    .word 0x000000F0   #21
    .word 0x00000010   #22
    .word 0x80000000   #23
    .word 0x00000001   #24
    .word 0x00000001   #25

golden:
    .word 0    #1  identical
    .word 1    #2  one LSB differs
    .word 1    #3  one MSB differs
    .word 32   #4  all bits differ
    .word 32   #5  alternating 1010 vs 0101
    .word 32   #6  nibble-wise alternation
    .word 0    #7  identical random value
    .word 1    #8  single-bit delta
    .word 32   #9  lower/upper 16 bits swapped
    .word 32   #10 all-zero vs all-one
    .word 1    #11 only MSB differs
    .word 32   #12 +max vs min-int
    .word 2    #13 two distant ones
    .word 4    #14 four consecutive ones
    .word 8    #15 two groups of four ones
    .word 6    #16 random pair
    .word 14   #17 random pair
    .word 8    #18 0x01 pattern vs 0x10 pattern
    .word 0    #19 identical alternating
    .word 1    #20 adjacent low bits
    .word 8    #21 eight consecutive bits differ
    .word 2    #22 two adjacent bits
    .word 2    #23 top two bits differ
    .word 1    #24 only MSB differs
    .word 2    #25 LSB and next bit differ  
           
Passed_msg:
    .string "All test PASS :)\n"
Failed_msg:
    .string "Failed :(\n"
endline:
    .string "\n"

    .text

# s0 : i
# s1 : arr_ptr = &orig_X[0]
# s2 : arr_ptr = &orig_Y[0]
# s3 : arr_ptr = &golden[0]
# s4 : golden
# s5 : output
# s6 : NUM_TEST_VALUES
#########################################
#                                       #
#                                       #
#                main                   #
#                                       #
#                                       #
#########################################
main:
# for (i = 0; i < NUM_TEST_VALUES; i++)
    li      s0, 0

    la      s1, orig_X
    la      s2, orig_Y
    la      s3, golden

    li      s6, NUM_TEST_VALUES
    bge     s0, s6, Passed                    # if (i >= NUM_TEST_VALUES) go to end for
1:
    lw      a0, 0(s1)                     # t0 = orig_X
    lw      a1, 0(s2)                     # t1 = orig_Y
    lw      s4, 0(s3)

    jal     ra hammingDistance
    mv      s5, a0

    bne     s4, s5, 2f

    addi    s0, s0, 1
    addi    s1, s1, 4
    addi    s2, s2, 4
    addi    s3, s3, 4

    blt     s0, s6, 1b      
Passed: 
    la      a0, Passed_msg
    li      a7, 4
    ecall                                 # Print passed message
    li      a0, 0
    j       done                            # go to return

#failed
2:
    la      a0, Failed_msg
    li      a7, 4
    ecall                                 # Print passed message

    j       done                            # go to return

done:
    li      a7, 93                        # system call: exit2
    li      a0, 1                         # exit value
    ecall                                 # exit 1


# s0 : x
# s1 : y
# s2 : diff
# s3 : hamming_count
# s4 : leading_zero 
# t0 : i
# t1 : 32
# t2 : diff & 0x80000000
# t3 : 0x80000000

#########################################
#                                       #
#                                       #   
#           HammingDistance             #
#                                       #
#                                       #
#########################################
hammingDistance:

    addi    sp, sp -24
    sw      ra, 20(sp)
    sw      s0, 16(sp)
    sw      s1,  12(sp)
    sw      s2,  8(sp)
    sw      s3,  4(sp)
    sw      s4,  0(sp)

    mv      s0, a0
    mv      s1, a1

    xor     s2, s1, s0
    li      s3, 0

    beq     s2, x0, RETURN_ZERO

    li      t0, 0
    li      t1, 32
    li      t3, 0x80000000
for:
    and     t2, s2, t3
    beq     t2, x0, ZERO
    addi    s3, s3, 1
ZERO:
    beq     s2, x0, RETURN_DIS
    addi    t0, t0, 1
    slli    s2, s2, 1
    blt     t0, t1, for
    j       RETURN_DIS

RETURN_ZERO:
    li      a0, 0
    j       RETURN


RETURN_DIS:
    mv      a0, s3
    j       RETURN

RETURN:
    lw      s4,  0(sp)
    lw      s3,  4(sp)
    lw      s2,  8(sp)
    lw      s1, 12(sp)
    lw      s0, 16(sp)            
    lw      ra, 20(sp)
    addi    sp, sp, 24
    ret

