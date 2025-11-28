    .section .text
    .align 2
    .global BigInt_add
    .global BigInt_larger

    .equ LLENGTH, 0      
    .equ AULDIGITS, 8
    .equ OADDEND1, 16
    .equ OADDEND2, 24
    .equ OSUM,  32

    .equ ULCARRY,     -8
    .equ ULSUM,      -16
    .equ LINDEX,     -24
    .equ LSUMLENGTH, -32
    .equ MAX_DIGITS, 32768
    .equ MAX_BYTES, MAX_DIGITS * 8

BigInt_larger:
    cmp x0, x1
    bgt first_larger
    mov x0, x1
    ret
first_larger:
    ret

BigInt_add:
    sub sp, sp, 48
    str x30, [sp]
    str x29, [sp, 8]
    add x29, sp, 0

    ldr x0, [x29, OADDEND1]
    ldr x0, [x0, LLENGTH]
    ldr x1, [x29, OADDEND2]
    ldr x1, [x1, LLENGTH]
    bl BigInt_larger
    str x0, [x29, LSUMLENGTH]
    ldr x3, [x29, OSUM]
    ldr x4, [x3, LLENGTH]
    ldr x5, [x29, LSUMLENGTH]
    cmp x4, x5
    ble skip_memset
    add x0, x3, ADIGITS
    mov x1, 0
    mov x2, MAX_BYTES    
    bl memset
skip_memset:
    mov x0, 0
    str x0, [x29, ULCARRY]
    mov x0, 0
    str x0, [x29, LINDEX]
loop_start:
    ldr x1, [x29,LINDEX]
    ldr x2, [x29,LSUMLENGTH]
    cmp x1, x2
    bge loop_end
    ldr x3, [x29, ULCARRY]
    str x3, [x29, ULSUM]
    mov x3, 0
    str x3, [x29, ULCARRY]

    ldr x4, [x29, OADDEND1]
    ldr x5, [x29, LINDEX]
    lsl x5, x5, 3 
    add x4, x4, AULDIGITS
    add x4, x4, x5
    ldr x6, [x4]
    ldr x7, [x29, ULSUM]
    add x7, x7, x6
    str x7, [x29, ULSUM]
    cmp x7, x6
    bhs no_overflow1
    mov x8, 1
    str x8, [x29, ULCARRY]
no_overflow1:

    ldr x4, [x29, OADDEND2]
    ldr x5, [x29, LINDEX]
    lsl x5, x5, 3 
    add x4, x4, AULDIGITS
    add x4, x4, x5
    ldr x6, [x4]
    ldr x7, [x29, ULSUM]
    add x7, x7, x6
    str x7, [x29, ULSUM]
    cmp x7, x6
    bhs no_overflow2
    mov x8, 1
    str x8, [x29, ULCARRY]
no_overflow2:

    ldr x4, [x29, OSUM]
    ldr x5, [x29, LINDEX]
    lsl x5, x5, 3     
    add x4, x4, ADIGITS        
    add x4, x4, x5 
    ldr x7, [x29, ULSUM]
    str x7, [x4]

    ldr x1, [x29, LINDEX]    
    add x1, x1, 1            
    str x1, [x29, LINDEX]   
    b loop_start

loop_end:

    ldr x0, [x29, ULCARRY]  
    cmp x0, 1
    bne no_carry
    ldr x1, [x29, LSUMLENGTH]  
    cmp x1, MAX_DIGITS
    beq max_digits_surpassed
    ldr x2, [x29, OSUM]
    ldr x1, [x29, LSUMLENGTH]
    lsl x1, x1, 3
    add x2, x2, ADIGITS       
    add x2, x2, x1
    mov x3, 1
    str x3, [x2]
    ldr x1, [x29, LSUMLENGTH]
    add x1, x1, 1
    str x1, [x29, LSUMLENGTH]
no_carry:
    ldr x2, [x29, OSUM]
    ldr x1, [x29, LSUMLENGTH]
    str x1, [x2, LLENGTH]
    mov x0, TRUE
    b finish
max_digits_surpassed:
    move x0, 0
finish: 
    ldr x30, [sp]
    ldr x29, [sp, 8]
    add sp, sp, 48
    ret