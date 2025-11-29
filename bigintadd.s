    .section .text
    .global BigInt_add
    .global BigInt_larger

/* BigInt struct field offsets */
    .equ LLENGTH,   0
    .equ AULDIGITS, 8

/* Stack frame layout (64 bytes) */
    .equ ULCARRY,       -8
    .equ LINDEX,        -16
    .equ LSUMLENGTH,    -24
    .equ OSUM,          -32
    .equ OADDEND2,      -40
    .equ OADDEND1,      -48
    .equ ULSUM,         -56
    .equ FRAME_SIZE,    64

    .equ MAX_DIGITS, 32768

/*
    long BigInt_larger(long lLength1, long lLength2)
*/
BigInt_larger:
    cmp x0, x1
    bgt first_larger
    mov x0, x1
    ret
first_larger:
    ret

/*
 int BigInt_add(BigInt_T oAddend1, BigInt_T oAddend2, BigInt_T oSum)
*/
BigInt_add:

    /* PROLOGUE */
    sub     sp, sp, FRAME_SIZE
    stp     x29, x30, [sp]
    add     x29, sp, 0

    /* Spill parameters to stack */
    str     x0, [x29, OADDEND1]
    str     x1, [x29, OADDEND2]
    str     x2, [x29, OSUM]

    /* Compute lSumLength = max(a1->len, a2->len) */
    ldr     x3, [x29, OADDEND1]
    ldr     x0, [x3, LLENGTH]

    ldr     x4, [x29, OADDEND2]
    ldr     x1, [x4, LLENGTH]

    bl      BigInt_larger
    str     x0, [x29, LSUMLENGTH]

    /* Clear all digits if needed (C clears ALL MAX_DIGITS) */
    ldr     x5, [x29, OSUM]
    ldr     x6, [x5, LLENGTH]      /* old length */
    ldr     x7, [x29, LSUMLENGTH]  /* new needed length */
    cmp     x6, x7
    ble     no_clear

    /* memset(oSum->aulDigits, 0, MAX_DIGITS * 8) */
    add     x0, x5, AULDIGITS      /* pointer to aulDigits */
    mov     x1, 0
    mov     x2, MAX_DIGITS
    lsl     x2, x2, 3              /* bytes = MAX_DIGITS * 8 */
    bl      memset

no_clear:

    /* ulCarry = 0, lIndex = 0 */
    mov     x0, 0
    str     x0, [x29, ULCARRY]
    str     x0, [x29, LINDEX]

/* LOOP: lIndex < lSumLength */
loop:
    ldr     x1, [x29, LINDEX]
    ldr     x2, [x29, LSUMLENGTH]
    cmp     x1, x2
    bge     endloop

    /* ulSum = ulCarry; ulCarry = 0 */
    ldr     x3, [x29, ULCARRY]
    str     x3, [x29, ULSUM]
    mov     x3, 0
    str     x3, [x29, ULCARRY]

    /* Add digit from a1 */
    ldr     x4, [x29, OADDEND1]
    lsl     x5, x1, 3
    add     x4, x4, AULDIGITS
    add     x4, x4, x5
    ldr     x6, [x4]

    ldr     x7, [x29, ULSUM]
    add     x7, x7, x6
    str     x7, [x29, ULSUM]

    cmp     x7, x6
    bhs     no_over1
    mov     x8, 1
    str     x8, [x29, ULCARRY]
no_over1:

    /* Add digit from a2 */
    ldr     x4, [x29, OADDEND2]
    lsl     x5, x1, 3
    add     x4, x4, AULDIGITS
    add     x4, x4, x5
    ldr     x6, [x4]

    ldr     x7, [x29, ULSUM]
    add     x7, x7, x6
    str     x7, [x29, ULSUM]

    cmp     x7, x6
    bhs     no_over2
    mov     x8, 1
    str     x8, [x29, ULCARRY]
no_over2:

    /* Store digit to sum */
    ldr     x4, [x29, OSUM]
    lsl     x5, x1, 3
    add     x4, x4, AULDIGITS
    add     x4, x4, x5

    ldr     x7, [x29, ULSUM]
    str     x7, [x4]

    /* lIndex++ */
    add     x1, x1, 1
    str     x1, [x29, LINDEX]

    b       loop

endloop:

    /* Final carry */
    ldr     x0, [x29, ULCARRY]
    cmp     x0, 1
    bne     store_length

    ldr     x1, [x29, LSUMLENGTH]
    cmp     x1, MAX_DIGITS
    beq     overflow

    /* oSum->aulDigits[lSumLength] = 1 */
    ldr     x2, [x29, OSUM]
    lsl     x3, x1, 3
    add     x2, x2, AULDIGITS
    add     x2, x2, x3
    mov     x4, 1
    str     x4, [x2]

    add     x1, x1, 1
    str     x1, [x29, LSUMLENGTH]

store_length:
    /* oSum->lLength = lSumLength */
    ldr     x2, [x29, OSUM]
    ldr     x1, [x29, LSUMLENGTH]
    str     x1, [x2, LLENGTH]

    mov     x0, 1
    b       done

overflow:
    mov     x0, 0

done:
    ldp     x29, x30, [sp]
    add     sp, sp, FRAME_SIZE
    ret
