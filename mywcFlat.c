/*--------------------------------------------------------------------*/
/* mywc.c                                                             */
/* Author: Adi Prajapati                                              */
/*--------------------------------------------------------------------*/

#include <stdio.h>
#include <ctype.h>

/*--------------------------------------------------------------------*/

/* In lieu of a boolean data type. */
enum {FALSE, TRUE};

/*--------------------------------------------------------------------*/

static long lLineCount = 0;      /* Bad style. */
static long lWordCount = 0;      /* Bad style. */
static long lCharCount = 0;      /* Bad style. */
static int iChar;                /* Bad style. */
static int iInWord = FALSE;      /* Bad style. */

/*--------------------------------------------------------------------*/

/* Write to stdout counts of how many lines, words, and characters
   are in stdin. A word is a sequence of non-whitespace characters.
   Whitespace is defined by the isspace() function. Return 0. */

int main(void)
{

    goto loopWhile;

    loopStart:
        lCharCount++;
        
        if (! isspace(iChar)) goto elseSpace;

            if (! iInWord) goto endif_InWord1;
                lWordCount++;
                iInWord = FALSE;
        endif_InWord1:
        goto endif_Space;

        elseSpace:
            if (iInWord) goto endif_InWord2;
                iInWord = TRUE;
        
        endif_InWord2:
        goto endif_Space;

        endif_Space:
        if (iChar != '\n') goto endif_newLine;
            lLineCount++;
        
        endif_newLine:
        goto loopWhile;

    loopWhile:
        iChar = getchar();
        if (iChar != EOF) goto loopStart;

        if (! iInWord) goto loopPrint;
            lWordCount++;
    
    loopPrint:
        printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
        return 0;

}

