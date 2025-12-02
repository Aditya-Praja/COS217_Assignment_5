    .section .text

// BigInt struct field offsets
    .equ LLENGTH, 0 // long 
    .equ AULDIGITS, 8 // unsigned long []

// Stored information 
    OADDEND1 .req x19 // BigInt_T
    OADDEND2 .req x20     // BigInt_T
    OSUM .req x21  // BigInt_T
    LSUMLENGTH .req x22     // long 
    LINDEX .req x23     // long 
    ULCARRY .req x24    // unsigned long 
    ULSUM .req x25    // unsigned long

    .equ TRUE, 1
    .equ FALSE, 0
    .equ MAX_DIGITS, 32768

// long BigInt_larger(long lLength1, long lLength2)

    .global BigInt_larger
BigInt_larger:
    cmp x0, x1
    bgt first_larger
    mov x0, x1
    ret
first_larger:
    ret

// int BigInt_add(BigInt_T oAddend1, BigInt_T oAddend2, BigInt_T oSum)
    .global BigInt_add
BigInt_add:

    // prolog 
    sub sp, sp, 96
    str x29, [sp]
    str x30, [sp, 8]
    str x19, [sp, 16]
    str x20, [sp, 24]
    str x21, [sp, 32]
    str x22, [sp, 40]
    str x23, [sp, 48]
    str x24, [sp, 56]
    str x25, [sp, 64]
    str x26, [sp, 72]
    str x27, [sp, 80]
    str x28, [sp, 88]
    add x29, sp, 0

    // putting the parameters into the stack 
    mov OADDEND1, x0
    mov OADDEND2, x1
    mov OSUM,     x2

    // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength)
    ldr x0, [OADDEND1, LLENGTH]
    ldr x1, [OADDEND2, LLENGTH]
    bl  BigInt_larger
    mov LSUMLENGTH, x0

    // clear array if necessary, conditonal first 
    ldr x8, [OSUM, LLENGTH]
    cmp x8, LSUMLENGTH
    ble not_cleared

    // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long))
    add x0, OSUM, AULDIGITS      // pointer to aulDigits 
    mov x1, 0
    mov x2, MAX_DIGITS
    lsl x2, x2, 3              // MAX_DIGITS * 8
    bl memset

not_cleared:

    // ulCarry = 0 and lIndex = 0 
    mov ULCARRY, 0
    mov LINDEX, 0

// for loop lIndex < lSumLength 
loop:
    cmp LINDEX, LSUMLENGTH
    bge endloop

    // ulSum = ulCarry; ulCarry = 0 
    mov ULSUM, ULCARRY
    mov ULCARRY, 0

    // Add digit from a1
    lsl x8, LINDEX, 3
    add x9, OADDEND1, AULDIGITS
    add x9, x9, x8
    ldr x10, [x9]

    add ULSUM, ULSUM, x10
    cmp ULSUM, x10
    bhs no_overflow1
    mov ULCARRY, 1

no_overflow1:

    // Add digit from a2
    add x9, OADDEND2, AULDIGITS
    add x9, x9, x8
    ldr x10, [x9]

    add ULSUM, ULSUM, x10
    cmp ULSUM, x10
    bhs no_overflow2
    mov ULCARRY, 1
    
no_overflow2:

    // storing in sum
    add x9, OSUM, AULDIGITS
    add x9, x9, x8
    str ULSUM, [x9]
    add LINDEX, LINDEX, 1

    b loop

endloop:
    // after loop
    cmp ULCARRY, 1
    bne store_length

    mov x10, MAX_DIGITS
    cmp LSUMLENGTH, x10
    beq return_false

    lsl x8, LSUMLENGTH, 3
    add x9, OSUM, AULDIGITS
    add x9, x9, x8
    mov x10, 1
    str x10, [x9]
    add LSUMLENGTH, LSUMLENGTH, 1

store_length:
    // oSum->lLength = lSumLength 
    str LSUMLENGTH, [OSUM, LLENGTH]

    mov x0, TRUE
    b finish

return_false:
    mov x0, FALSE

finish:
    // epilog
    ldr x29, [sp]
    ldr x30, [sp, 8]
    ldr x19, [sp, 16]
    ldr x20, [sp, 24]
    ldr x21, [sp, 32]
    ldr x22, [sp, 40]
    ldr x23, [sp, 48]
    ldr x24, [sp, 56]
    ldr x25, [sp, 64]
    ldr x26, [sp, 72]
    ldr x27, [sp, 80]
    ldr x28, [sp, 88]
    add sp, sp, 96
    ret

