/* bcd.h -- the 8086's packed BCD arithmetic, as the assembly uses it.
 *
 * The 6502 original did decimal arithmetic with SED/ADC/SBC; the 8086 port does it with
 *     clc / adc al, x / daa          (add)
 *     stc / cmc / sbb al, x / das    (subtract; stc+cmc just clears the carry)
 * so every "count += 1" in the game is this, and it WRAPS: 99 + 1 = 00 and 00 - 1 = 99 (the
 * carry out is thrown away). These are literal models of ADC+DAA and SUB+DAS, so they give the
 * same answer as the real instructions even when an operand is not valid BCD (a hand-edited save).
 *
 * Some code chains additions WITHOUT clearing the carry in between (CmdOffer's attribute gift):
 * then a decimal overflow leaks one extra into the next addition. bcd_adc is for that. Subtractions
 * of multi-byte numbers (food, hit points) chain the borrow on purpose: bcd_sbb.
 */
#ifndef U2_BCD_H
#define U2_BCD_H

#include <stdint.h>

/* adc al, b / daa   with *cf the carry flag, in and out; returns AL */
static inline uint8_t bcd_adc(uint8_t a, uint8_t b, int *cf)
{
    unsigned sum = (unsigned)a + b + (unsigned)(*cf != 0);
    uint8_t al = (uint8_t)sum;
    int cf_adc = sum > 0xFF;                                  /* CF after ADC */
    int af = ((a & 15) + (b & 15) + (*cf != 0)) > 15;         /* AF after ADC */
    uint8_t old_al = al;
    int out_cf = 0;

    /* DAA, as Intel's manual defines it */
    if ((al & 15) > 9 || af) {
        out_cf = cf_adc || ((unsigned)al + 6 > 0xFF);
        al = (uint8_t)(al + 6);
    }
    if (old_al > 0x99 || cf_adc) {
        al = (uint8_t)(al + 0x60);
        out_cf = 1;
    }
    *cf = out_cf;
    return al;
}

/* clc / adc al, b / daa   (the carry out is dropped) */
static inline uint8_t bcd_add(uint8_t a, uint8_t b)
{
    int cf = 0;
    return bcd_adc(a, b, &cf);
}

/* sbb al, b / das   with *borrow the carry flag, in and out; returns AL. For a plain subtract the
 * borrow comes in as 0 (the assembly's stc / cmc). Chained subtractions of a multi-byte BCD number
 * (the food, the hit points) pass the borrow on from byte to byte. */
static inline uint8_t bcd_sbb(uint8_t a, uint8_t b, int *borrow)
{
    int bin = (*borrow != 0);
    uint8_t al = (uint8_t)(a - b - bin);
    int cf_sub = (unsigned)a < (unsigned)b + bin;             /* CF after SBB */
    int af = (a & 15) < (b & 15) + bin;                       /* AF after SBB */
    uint8_t old_al = al;
    int out_cf = 0;

    /* DAS, as Intel's manual defines it */
    if ((al & 15) > 9 || af) {
        out_cf = cf_sub || (al < 6);
        al = (uint8_t)(al - 6);
    }
    if (old_al > 0x99 || cf_sub) {
        al = (uint8_t)(al - 0x60);
        out_cf = 1;
    }
    *borrow = out_cf;
    return al;
}

/* stc / cmc / sbb al, b / das   =   sub al, b / das   (the borrow out is dropped) */
static inline uint8_t bcd_sub(uint8_t a, uint8_t b)
{
    int borrow = 0;
    return bcd_sbb(a, b, &borrow);
}

#endif
