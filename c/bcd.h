/* bcd.h -- the 8086's packed BCD add, as the assembly uses it.
 *
 * The 6502 original did decimal arithmetic with SED/ADC; the 8086 port does it with
 *     clc / adc al, x / daa
 * so every "count += 1" in the game is this operation, and it WRAPS: 99 + 1 = 00 (the carry
 * out is thrown away). This is a literal model of ADC + DAA, so it also gives the same answer as
 * the real instructions when an operand is not valid BCD (a hand-edited save, say).
 */
#ifndef U2_BCD_H
#define U2_BCD_H

#include <stdint.h>

/* clc; mov al, a; adc al, b; daa   (returns AL; the carry out is dropped) */
static inline uint8_t bcd_add(uint8_t a, uint8_t b)
{
    unsigned sum = (unsigned)a + b;
    uint8_t al = (uint8_t)sum;
    int cf = sum > 0xFF;                       /* CF after ADC */
    int af = ((a & 15) + (b & 15)) > 15;       /* AF after ADC */
    uint8_t old_al = al;
    int old_cf = cf;

    /* DAA, as Intel's manual defines it */
    if ((al & 15) > 9 || af)
        al = (uint8_t)(al + 6);
    if (old_al > 0x99 || old_cf)
        al = (uint8_t)(al + 0x60);
    return al;
}

#endif
