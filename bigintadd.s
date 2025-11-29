    .section .text
    .align 2
    .global BigInt_add
    .global BigInt_larger

/* BigInt struct offsets */
    .equ LLENGTH,   0
    .equ AULDIGITS, 8

/* Stack layout (FRAME_SIZE = 80) */

    .equ ULCARRY,       -8
    .equ LINDEX,        -16
    .equ LSUMLENGTH,    -24
    .equ OSUM,          -32
    .equ OADDEND2,      -40
    .equ OADDEND1,      -48

    .equ ULSUM,         -64      /* safe 8-byte local for partial sum */
    .equ FRAME_SIZE,     80

    .equ MAX_DIGITS,  32768

/*********************************************************************
 * BigInt_larger
 *********************************************************************/
BigInt_larger:
    cmp x0, x1
    bgt 1f
    mov x0, x1
    ret
1:
    ret

/*********************************************************************
 * BigInt_add(addend1, addend2, sum)
 *********************************************************************/
BigInt_add:

    /* PROLOGUE */
    sub     sp, sp, FRAME_SIZE
    stp     x29, x30, [sp]
    add     x29, sp, 0

    /* Save parameters into frame */
    str     x0, [x29, OADDEND1]
    str     x1, [x29, OADDEND2]
    str     x2, [x29, OSUM]

    /* Compute max length = BigInt_larger(a1->len, a2->len) */
    ldr     x3, [x29, OADDEND1]
    ldr     x0, [x3, LLENGTH]

    ldr     x4, [x29, OADDEND2]
    ldr     x1, [x4, LLENGTH]

    bl      BigInt_larger
    str     x0, [x29, LSUMLENGTH]

    /* If sum->length < needed length, zero sum digits */
    ldr     x5, [x29, OSUM]
    ldr     x6, [x5, LLENGTH]
    ldr     x7, [x29, LSUMLENGTH]

    cmp     x6, x7
    ble     2f

    add     x0, x5, AULDIGITS    /* x0 = sum->digits */
    mov     x1, 0
    lsl     x2, x7, 3            /* bytes = newLength * 8 */
    bl      memset

2:
    /* carry = 0, index = 0 */
    mov     x0, 0
    str     x0, [x29, ULCARRY]
    str     x0, [x29, LINDEX]

/* LOOP: for(i < LSUMLENGTH) */
3:
    ldr     x1, [x29, LINDEX]
    ldr     x2, [x29, LSUMLENGTH]
    cmp     x1, x2
    bge     4f

    /* ULSUM = carry; carry = 0 */
    ldr     x3, [x29, ULCARRY]
    str     x3, [x29, ULSUM]
    mov     x3, 0
    str     x3, [x29, ULCARRY]

    /* ---- Add digit from addend1 ---- */
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

    /* ---- Add digit from addend2 ---- */
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

    /* i++ */
    add     x1, x1, 1
    str     x1, [x29, LINDEX]
    b       3b

/* END LOOP */
4:
    /* Final carry */
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
    /* Store ulLength */
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
