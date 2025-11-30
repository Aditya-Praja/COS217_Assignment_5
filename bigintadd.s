    .section .text

// BigInt struct field offsets
    .equ LLENGTH, 0
    .equ AULDIGITS, 8
    .equ TRUE, 1
    .equ FALSE, 0

// Stack frame 
    OADDENT1 .req x19
    OADDEND2 .req x20     
    OSUM .req x21 
    LSUMLENGTH .req x22     
    LINDEX .req x23     
    ULCARRY .req x24     
    ULSUM .req x25    
    TMP1 .req x26
    TMP2 .req x27
    TMP3 .req x28

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
    sub sp, sp, 16
    str x29, [sp]
    str x30, [sp, 8]
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
    ldr TMP1, [OSUM, LLENGTH]
    cmp TMP1, LSUMLENGTH
    ble no_clear

    // memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long))
    add x0, OSUM, AULDIGITS      // pointer to aulDigits 
    mov x1, 0
    mov x2, MAX_DIGITS
    lsl x2, x2, 3              // MAX_DIGITS * 8
    bl memset

no_clear:

    // ulCarry = 0 and lIndex = 0 
    mov ULCARRY, 0
    mov LINDEX,0

// for loop lIndex < lSumLength 
loop:
    cmp LINDEX, LSUMLENGTH
    bge endloop

    // ulSum = ulCarry; ulCarry = 0 
    mov ULSUM, ULCARRY
    mov ULCARRY, 0

    // Add digit from a1
    lsl TMP1, LINDEX, 3
    add TMP2, OADDEND1, AULDIGITS
    add TMP2, TMP2, TMP1
    ldr TMP3, [TMP2]

    add ULSUM, ULSUM, TMP3
    cmp ULSUM, TMP3
    bhs no_over1
    mov ULCARRY, 1

no_over1:

    // Add digit from a2
    add TMP2, OADDEND2, AULDIGITS
    add TMP2, TMP2, TMP1
    ldr TMP3, [TMP2]

    add ULSUM, ULSUM, TMP3
    cmp ULSUM, TMP3
    bhs no_over2
    mov ULCARRY, 1
no_over2:

    // storing in sum
    add TMP2, OSUM, AULDIGITS
    add TMP2, TMP2, TMP1
    str ULSUM, [TMP2]
    add LINDEX, LINDEX, 1

    b loop

endloop:
    // after loop
    cmp ULCARRY, 1
    bne store_length

    mov TMP3, MAX_DIGITS
    cmp LSUMLENGTH, TMP3
    beq return_false

    lsl TMP1, LSUMLENGTH, 3
    add TMP2, OSUM, AULDIGITS
    add TMP2, TMP2, TMP1
    mov TMP3, 1
    str TMP3, [TMP2]
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
    add sp, sp, 16
    ret
