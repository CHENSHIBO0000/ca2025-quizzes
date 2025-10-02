.data

message:
    .string "All tests passed.\n"

.text
main:

    jal     ra, Test
    beq     a1, x0, exit

    li      a7, 4
    la      a0, message
    ecall
    li      a7, 10                # halt
    ecall


exit:
    li      a7, 93                # system call: exit2
    li      a0, 1                 # exit value
    ecall                         # exit 1

# Test 
#
# s0: previous_value
# s1: bool_passed
# s2: i
# s3: fl
# s4: value
# s5: fl2

Test:
    addi    sp, sp, -4
    sw      ra, 0(sp)

    li      s0, -1
    li      s1, 1

    li      s2, 0

test_for_loop:
    mv      s3, s2 #f1 = i
    mv      a0, s3 # 
    jal     ra, uf8_decode
    mv      s4, a0
    jal     ra, uf8_encode
    mv      s5, a0

    beq     s3, s5, 1f
    li      s1, 0

1:
    bgt     s4, s0, 2f
    li      s1, 0

2: #previous_value
    mv      s0, s4
    addi    s2, s2, 1
    li      t0, 256
    blt     s2, t0, test_for_loop           # if (i < 256), to 1
    

done:
    lw      ra 0(sp)              # restore return addr
    addi    sp, sp, 4

    mv      a1, s1                # return passed
    ret


uf8_decode:

    addi    sp, sp, -4
    sw      ra, 0(sp)

    andi t0, a0, 0x0f #t0 = mantissa
    srli t1, a0, 4    #t1 = exponent
    
    # offset = ((1 << exponent) - 1) << 4
    addi t2, zero, 1
    sll t2, t2, t1
    addi t2, t2, -1
    slli t2, t2, 4 #t2 = offset
    
    sll a0,t0, t1
    add a0, a0 t2

    lw      ra 0(sp)              # restore return addr
    addi    sp, sp, 4

    ret



uf8_encode:
    
    # if(value<16)
    li   t0,  16
    slt  t0, a0 ,t0
    bne  t0, zero, return_value
    
    addi  sp, sp, -28
    sw    s0, 24(sp)
    sw    s1, 20(sp)
    sw    s2, 16(sp)
    sw    s3, 12(sp)
    sw    s4, 8(sp)
    sw    s5, 4(sp)
    sw    ra, 0(sp)


    
    add  s0, a0, zero #s0 = value
    
    #Find appropriate exponent using CLZ hint
    jal  ra, clz
    add  s1, a0, x0  #s1 = lz
    li   t0, 31
    sub  s2, t0, s1    #s2 = msb
    
    
    add s3, zero, zero #s3 = exponent
    add s4, zero, zero #s4 = overflow

#if(msb >= 5)
    li  t0, 5
    blt t0, s2, 1f

    addi s3, s2, -4
    #if(exponent > 15)
    li  t0, 15
    ble s3, t0, 2f
    li  s3, 15

# Calculate overflow for estimated exponent
2:
    li  s5, 0
3:
    bge  s5, s3, 4f
    slli s4, s4, 1
    addi s4, s4, 16
    addi s5, s5, 1
    j    3b

# Adjust if estimate was off 
4:
    slt t0, x0, s3
    slt t1, s0, s4
    and t0, t0, t1

    beq t0, x0, 1f

    addi  s4, s4, -16
    srli, s4, s4, 1
    addi  s3, s3, -1

    j     4b 


#Find exact exponent
1:
    addi t0, x0, 15

    bge  s3, t0, encode_done
    slli s6, s4, 1
    addi s6, s6, 16

    blt  s0, s6, encode_done
    mv   s4, s6
    addi s3, s3, 1
    j    1b

encode_done:
    sub  s7, s0, s4
    srl  s7, s7, s3

    slli  a0, s3, 4
    or   a0, a0, s7
    
    lw    ra, 0(sp)
    lw    s5, 4(sp)
    lw    s4, 8(sp)
    lw    s3, 12(sp)
    lw    s2, 16(sp)
    lw    s1, 20(sp)
    lw    s0, 24(sp)
    addi  sp, sp, 28
    
return_value:
    
    ret

    
    

clz:
    addi t0, zero, 32 #t0 = n
    addi t1, zero, 16 #t1 = c
    add t3, a0, zero #t3 = x
    
clz_Loop:
    srl t2, t3, t1 #t2 = y
    beq t2, zero, clz_y_0
    sub t0, t0, t1
    add t3, t2, zero #t3 = x
    
clz_y_0:
    srli t1,t1,1 # c >> 1
    
    bne  t1, x0, clz_Loop
    sub  a0,t0,t3
    ret
    