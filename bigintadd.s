    .section .text
    .align 2
    .global BigInt_add
    .global BigInt_larger

/* Offsets in the BigInt struct */
    .equ LLENGTH,   0          // offset of ulLength
    .equ AULDIGITS, 8          // offset of aulDigits[] (first digit)

/* FP-relative argument offsets */
    .equ OADDEND1,  16
    .equ OADDEND2,  24
    .equ OSUM,      32

/* FP-relative locals (negative offsets) */
    .equ ULCARRY,     -8
    .equ ULSUM,      -16
    .equ LINDEX,     -24
    .equ LSUMLENGTH, -32

/*********************************************************************
 * int BigInt_larger(ulA, ulB)
 *********************************************************************/
BigInt_larger:
    cmp x0, x1
    bgt 1f
    mov x0, x1
    ret
1:
    ret

/*********************************************************************
 * int BigInt_add(addend1, addend2, sum)
 *********************************************************************/
BigInt_add:
    /* PROLOGUE (COS 217 slide style) */
    sub  sp, sp, 48
    str  x29, [sp]        /* save FP */
    str  x30, [sp, 8]     /* save LR */
    add  x29, sp, 0       /* FP = SP */

    /* Load ulLengths of both addends */
    ldr x0, [x29, OADDEND1]
    ldr x0, [x0, LLENGTH]

    ldr x1, [x29, OADDEND2]
    ldr x1, [x1, LLENGTH]

    /* Compute larger length */
    bl BigInt_larger
    str x0, [x29, LSUMLENGTH]

    /* Zero sum digits only when needed */
    ldr x3, [x29, OSUM]
    ldr x4, [x3, LLENGTH]       /* old sum length */
    ldr x5, [x29, LSUMLENGTH]   /* new needed length */

    cmp x4, x5
    ble 2f                      /* skip memset if old >= new */

    /* memset(sum->digits, 0, newLength*8) */
    add x0, x3, AULDIGITS       /* x0 = start of digits[] */
    mov x1, 0                   /* memset fill byte */
    ldr x2, [x29, LSUMLENGTH]
    lsl x2, x2, 3               /* bytes = length * 8 */
    bl memset
2:

    /* init carry and index */
    mov x0, 0
    str x0, [x29, ULCARRY]

    mov x0, 0
    str x0, [x29, LINDEX]

/* ------------------------------------------------------------ */
/* LOOP: for (i = 0; i < sumLength; i++) */
/* ------------------------------------------------------------ */
3:
    ldr x1, [x29, LINDEX]
    ldr x2, [x29, LSUMLENGTH]
    cmp x1, x2
    bge 4f

    /* ULSUM = carry */
    ldr x3, [x29, ULCARRY]
    str x3, [x29, ULSUM]

    /* clear carry */
    mov x3, 0
    str x3, [x29, ULCARRY]

    /* ---------- Add addend1 digit ---------- */
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
    bhs 5f
    mov x8, 1
    str x8, [x29, ULCARRY]
5:

    /* ---------- Add addend2 digit ---------- */
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
    bhs 6f
    mov x8, 1
    str x8, [x29, ULCARRY]
6:

    /* store sum digit */
    ldr x4, [x29, OSUM]
    ldr x5, [x29, LINDEX]
    lsl x5, x5, 3
    add x4, x4, AULDIGITS
    add x4, x4, x5
    ldr x7, [x29, ULSUM]
    str x7, [x4]

    /* i++ */
    ldr x1, [x29, LINDEX]
    add x1, x1, 1
    str x1, [x29, LINDEX]
    b 3b

/* END LOOP */
4:
    /* Handle final carry */
    ldr x0, [x29, ULCARRY]
    cmp x0, 1
    bne 7f

    ldr x1, [x29, LSUMLENGTH]
    cmp x1, 32768          /* MAX_DIGITS */
    beq 8f

    ldr x2, [x29, OSUM]
    lsl x3, x1, 3
    add x2, x2, AULDIGITS
    add x2, x2, x3
    mov x4, 1
    str x4, [x2]

    add x1, x1, 1
    str x1, [x29, LSUMLENGTH]
7:

    /* store new length into sum->ulLength */
    ldr x2, [x29, OSUM]
    ldr x1, [x29, LSUMLENGTH]
    str x1, [x2, LLENGTH]

    mov x0, 1         /* return TRUE */
    b 9f

8:
    mov x0, 0         /* overflow → return FALSE */

9:
    /* EPILOGUE */
    ldr x29, [sp]
    ldr x30, [sp, 8]
    add sp, sp, 48
    ret
