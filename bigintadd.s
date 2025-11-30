    .section .text
    .align 2

// BigInt struct field offsets
    .equ LLENGTH, 0
    .equ AULDIGITS, 8
    .equ TRUE, 1
    .equ FALSE, 0
    .equ MAX_DIGITS, 32768

// Register aliases (callee-saved)
    OADDEND1   .req x19
    OADDEND2   .req x20
    OSUM       .req x21
    LSUMLENGTH .req x22
    LINDEX     .req x23
    ULCARRY    .req x24
    ULSUM      .req x25
    TMP1       .req x26
    TMP2       .req x27
    TMP3       .req x28

//--------------------------------------------------------------
// long BigInt_larger(long l1, long l2)
//--------------------------------------------------------------
    .global BigInt_larger
BigInt_larger:
    cmp x0, x1
    bgt bigger
    mov x0, x1
    ret
bigger:
    ret

//--------------------------------------------------------------
// int BigInt_add(BigInt_T a1, BigInt_T a2, BigInt_T sum)
//--------------------------------------------------------------
    .global BigInt_add
BigInt_add:

    //----------------------------------------------------------
    // PROLOGUE — save all callee-saved regs x19–x30
    //----------------------------------------------------------
    sub   sp, sp, 16*6        // 96 bytes
    stp   x29, x30, [sp]
    stp   x19, x20, [sp,16]
    stp   x21, x22, [sp,32]
    stp   x23, x24, [sp,48]
    stp   x25, x26, [sp,64]
    stp   x27, x28, [sp,80]
    mov   x29, sp

    //----------------------------------------------------------
    // Move parameters into our callee-saved registers
    //----------------------------------------------------------
    mov OADDEND1, x0
    mov OADDEND2, x1
    mov OSUM,     x2

    //----------------------------------------------------------
    // lSumLength = BigInt_larger(a1->lLength, a2->lLength)
    //----------------------------------------------------------
    ldr x0, [OADDEND1, #LLENGTH]
    ldr x1, [OADDEND2, #LLENGTH]
    bl BigInt_larger
    mov LSUMLENGTH, x0

    //----------------------------------------------------------
    // Clear digits if oSum->lLength > lSumLength
    //----------------------------------------------------------
    ldr TMP1, [OSUM, #LLENGTH]
    cmp TMP1, LSUMLENGTH
    ble no_clear

    add x0, OSUM, #AULDIGITS
    mov x1, 0
    movz x2, #(MAX_DIGITS & 0xFFFF)
    lsl x2, x2, 3
    bl memset

no_clear:

    mov ULCARRY, 0
    mov LINDEX, 0

//--------------------------------------------------------------
// LOOP
//--------------------------------------------------------------
loop:
    cmp LINDEX, LSUMLENGTH
    bge endloop

    mov ULSUM, ULCARRY
    mov ULCARRY, 0

    //----------------------------------------------------------
    // Add digit from a1
    //----------------------------------------------------------
    lsl TMP1, LINDEX, 3
    add TMP2, OADDEND1, #AULDIGITS
    add TMP2, TMP2, TMP1
    ldr TMP3, [TMP2]

    add ULSUM, ULSUM, TMP3
    cmp ULSUM, TMP3
    bhs no_over1
    mov ULCARRY, 1

no_over1:

    //----------------------------------------------------------
    // Add digit from a2
    //----------------------------------------------------------
    add TMP2, OADDEND2, #AULDIGITS
    add TMP2, TMP2, TMP1
    ldr TMP3, [TMP2]

    add ULSUM, ULSUM, TMP3
    cmp ULSUM, TMP3
    bhs no_over2
    mov ULCARRY, 1

no_over2:

    //----------------------------------------------------------
    // Store digit
    //----------------------------------------------------------
    add TMP2, OSUM, #AULDIGITS
    add TMP2, TMP2, TMP1
    str ULSUM, [TMP2]

    add LINDEX, LINDEX, 1
    b loop

//--------------------------------------------------------------
endloop:
    cmp ULCARRY, 1
    bne store_length

    movz TMP3, #(MAX_DIGITS & 0xFFFF)
    cmp LSUMLENGTH, TMP3
    beq return_false

    lsl TMP1, LSUMLENGTH, 3
    add TMP2, OSUM, #AULDIGITS
    add TMP2, TMP2, TMP1
    mov TMP3, 1
    str TMP3, [TMP2]
    add LSUMLENGTH, LSUMLENGTH, 1

//--------------------------------------------------------------
store_length:
    str LSUMLENGTH, [OSUM, #LLENGTH]
    mov x0, TRUE
    b finish

//--------------------------------------------------------------
return_false:
    mov x0, FALSE

//--------------------------------------------------------------
finish:
    //----------------------------------------------------------
    // EPILOGUE — restore x19–x30
    //----------------------------------------------------------
    ldp x27, x28, [sp,80]
    ldp x25, x26, [sp,64]
    ldp x23, x24, [sp,48]
    ldp x21, x22, [sp,32]
    ldp x19, x20, [sp,16]
    ldp x29, x30, [sp]
    add sp, sp, 16*6
    ret
