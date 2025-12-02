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
    ULSUM .req x25    // unsigned long
    OFFSET .req x8

    .equ TRUE, 1
    .equ FALSE, 0
    .equ MAX_DIGITS, 32768

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
    str x25, [sp, 56]
    str x26, [sp, 64]
    str x27, [sp, 72]
    str x28, [sp, 80]
    add x29, sp, 0

    // putting the parameters into the stack 
    mov OADDEND1, x0
    mov OADDEND2, x1
    mov OSUM,     x2

    // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength)
    ldr x0, [OADDEND1, LLENGTH]
    ldr x1, [OADDEND2, LLENGTH]
    cmp x0, x1
    ble second_larger
    mov LSUMLENGTH, x0
    b after_larger

second_larger:
    mov LSUMLENGTH, x1

after_larger:
    // clear array if necessary, conditonal first 
    ldr x9, [OSUM, LLENGTH]
    cmp x9, LSUMLENGTH
    ble no_clear

    // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long))
    add x0, OSUM, AULDIGITS      // pointer to aulDigits 
    mov x1, 0
    mov x2, MAX_DIGITS
    lsl x2, x2, 3              // MAX_DIGITS * 8
    bl memset

no_clear:

    // lIndex = 0 
    mov LINDEX, 0
    adds xzr, xzr, xzr  // clear carry flag

loop:
    sub x9, LSUMLENGTH, LINDEX
    cbz x9, endloop

    lsl OFFSET, LINDEX, 3 

    // add a1 digits
    add x11, OADDEND1, AULDIGITS
    add x11, x11, OFFSET
    ldr x11, [x11]
    
    // add a2 digits
    add x10, OADDEND2, AULDIGITS
    add x10, x10, OFFSET
    ldr x10, [x10]

    // add with carry
    adcs ULSUM, x11, x10

    // storing in sum
    add x9, OSUM, AULDIGITS
    add x9, x9, OFFSET
    str ULSUM, [x9]
    add LINDEX, LINDEX, 1
    b loop

endloop:
    // after loop
    bcc store_length

    mov x11, MAX_DIGITS
    cmp LSUMLENGTH, x11
    beq return_false

    lsl x9, LSUMLENGTH, 3
    add x10, OSUM, AULDIGITS
    add x10, x10, x9
    mov x11, 1
    str x11, [x10]
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
    ldr x25, [sp, 56]
    ldr x26, [sp, 64]
    ldr x27, [sp, 72]
    ldr x28, [sp, 80]
    add sp, sp, 96
    ret
    