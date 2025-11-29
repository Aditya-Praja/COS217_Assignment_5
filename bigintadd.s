    .section .text
    .align 2
    .global BigInt_add
    .global BigInt_larger

/* BigInt struct field offsets */
    .equ LLENGTH,   0
    .equ AULDIGITS, 8

/* Stack frame layout (64 bytes)
 *
 *  fp+0   saved x29
 *  fp+8   saved x30
 *  fp-8   ULCARRY
 *  fp-16  LINDEX
 *  fp-24  LSUMLENGTH
 *  fp-32  OSUM
 *  fp-40  OADDEND2
 *  fp-48  OADDEND1
 *  fp-56  ULSUM
 *
 */
    .equ ULCARRY,       -8
    .equ LINDEX,        -16
    .equ LSUMLENGTH,    -24
    .equ OSUM,          -32
    .equ OADDEND2,      -40
    .equ OADDEND1,      -48
    .equ ULSUM,         -56
    .equ FRAME_SIZE,     64

    .equ MAX_DIGITS, 32768

/*********************************************************************
 * long BigInt_larger(long l1, long l2)
 *********************************************************************/
BigInt_larger:
    cmp x0, x1
    bgt 1f
    mov x0, x1
    ret
1:
    ret

/*********************************************************************
 * int BigInt_add(BigInt_T a1, BigInt_T a2, BigInt_T sum)
 *********************************************************************/
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

    /* If sum->lLength > lSumLength, clear sum->digits */
    ldr     x5, [x29, OSUM]
    ldr     x6, [x5, LLENGTH]
    ldr     x7, [x29, LSUMLENGTH]

    cmp     x6, x7
    ble     2f

    add     x0, x5, AULDIGITS
    mov     x1, 0
    lsl     x2, x7, 3
    bl      memset

2:
    /* ulCarry = 0; lIndex = 0 */
    mov     x0, 0
    str     x0, [x29, ULCARRY]
    str     x0, [x29, LINDEX]

/* LOOP: for(lIndex < lSumLength) */
3:
    ldr     x1, [x29, LINDEX]
    ldr     x2, [x29, LSUMLENGTH]
    cmp     x1, x2
    bge     4f

    /* ulSum = ulCarry, ulCarry = 0 */
    ldr     x3, [x29, ULCARRY]
    str     x3, [x29, ULSUM]
    mov     x3, 0
    str     x3, [x29, ULCARRY]

    /* ---- Add a1 digit ---- */
    ldr     x4, [x29, OADDEND1]
    lsl     x5, x1, 3
    add     x4, x4, AULDIGITS
    add     x4, x4, x5
    ldr     x6, [x4]

    ldr     x7, [x29, ULSUM]
    add     x7, x7, x6
    str     x7, [x29, ULSUM]

    cmp     x7, x6
    bhs     5f
    mov     x8, 1
    str     x8, [x29, ULCARRY]
5:

    /* ---- Add a2 digit ---- */
    ldr     x4, [x29, OADDEND2]
    lsl     x5, x1, 3
    add     x4, x4, AULDIGITS
    add     x4, x4, x5
    ldr     x6, [x4]

    ldr     x7, [x29, ULSUM]
    add     x7, x7, x6
    str     x7, [x29, ULSUM]

    cmp     x7, x6
    bhs     6f
    mov     x8, 1
    str     x8, [x29, ULCARRY]
6:

    /* store result digit */
    ldr     x4, [x29, OSUM]
    lsl     x5, x1, 3
    add     x4, x4, AULDIGITS
    add     x4, x4, x5

    ldr     x7, [x29, ULSUM]
    str     x7, [x4]

    /* lIndex++ */
    add     x1, x1, 1
    str     x1, [x29, LINDEX]
    b       3b

/* END LOOP */
4:
    /* If carry out, append extra digit */
    ldr     x0, [x29, ULCARRY]
    cmp     x0, 1
    bne     7f

    ldr     x1, [x29, LSUMLENGTH]
    cmp     x1, MAX_DIGITS
    beq     8f

    ldr     x2, [x29, OSUM]
    lsl     x3, x1, 3
    add     x2, x2, AULDIGITS
    add     x2, x2, x3

    mov     x4, 1
    str     x4, [x2]

    add     x1, x1, 1
    str     x1, [x29, LSUMLENGTH]

7:
    /* sum->lLength = lSumLength */
    ldr     x2, [x29, OSUM]
    ldr     x1, [x29, LSUMLENGTH]
    str     x1, [x2, LLENGTH]

    mov     x0, 1
    b       9f

8:
    mov     x0, 0

9:
    /* EPILOGUE */
    ldp     x29, x30, [sp]
    add     sp, sp, FRAME_SIZE
    ret
