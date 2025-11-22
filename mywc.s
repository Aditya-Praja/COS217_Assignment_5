    .section .rodata

formatStr: .asciz "%7ld %7ld %7ld\n"

    .section .data

lLineCount:  .quad 0      // long
lWordCount:  .quad 0      // long
lCharCount:  .quad 0      // long
iInWord:     .word 0      // int

    .section .bss

iChar:       .skip 4      // int

    .section .text

    .global main

main: 

    b loopWhile

loopStart:

    adr x0, lCharCount
    ldr x3, [x0]
    add x3, x3, 1          // lCharCount++
    str x3, [x0]

    // if (! isspace(iChar)) goto elseSpace;
    adr x0, iChar
    ldr w5, [x0]
    // start ispace call
    mov w0, w5
    bl isspace
    cbnz w0, spaceChar
    b elseSpace

spaceChar:
    // if (! iInWord) goto elseInWord;
    adr x0, iInWord
    ldr w4, [x0]
    cbz w4, endif_InWord1

    //lWordCount++;
    adr x0, lWordCount
    ldr x2, [x0]
    add x2, x2, 1
    str x2, [x0]
    // iInWord = 0 (false);
    adr x0, iInWord
    mov w4, 0
    str w4, [x0]

endif_InWord1:
    b endif_Space

elseSpace:
    // if (iInWord) goto endif_InWord2;
    adr x0, iInWord
    ldr w4, [x0]
    cbnz w4, endif_InWord2

    // iInWord = 1 (true);
    mov w4, 1
    adr x0, iInWord
    str w4, [x0]

endif_InWord2: 
    b endif_Space

endif_Space:
    // if (iChar != '\n') goto endif_newline
    adr x0, iChar
    ldr w5, [x0]
    cmp w5, 10   
    bne endif_newline

    // lLineCount++;
    adr x0, lLineCount
    ldr x2, [x0]
    add x2, x2, 1
    str x2, [x0]

endif_newline:

loopWhile:
    // iChar = getchar();
    bl getchar
    mov w5, w0
    adr x0, iChar
    str w5, [x0]

    // while (iChar != EOF) loopStart;
    cmp w5, -1
    bne loopStart

    // if (! iInWord) goto loopPrint;
    adr x0, iInWord
    ldr w4, [x0]
    cbz w4, loopPrint

    // lWordCount++;
    adr x0, lWordCount
    ldr x2, [x0]
    add x2, x2, 1
    str x2, [x0]

loopPrint:
    // printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
    adr x0, formatStr
    adr x1, lLineCount
    ldr x1, [x1]
    adr x2, lWordCount
    ldr x2, [x2]
    adr x3, lCharCount
    ldr x3, [x3]

    bl printf

    // return 0;
    mov x0, 0
    ret
        

