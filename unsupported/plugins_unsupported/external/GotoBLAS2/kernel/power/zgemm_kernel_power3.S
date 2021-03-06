/*********************************************************************/
/*                                                                   */
/*             Optimized BLAS libraries                              */
/*                     By Kazushige Goto <kgoto@tacc.utexas.edu>     */
/*                                                                   */
/* Copyright (c) The University of Texas, 2009. All rights reserved. */
/* UNIVERSITY EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES CONCERNING  */
/* THIS SOFTWARE AND DOCUMENTATION, INCLUDING ANY WARRANTIES OF      */
/* MERCHANTABILITY, FITNESS FOR ANY PARTICULAR PURPOSE,              */
/* NON-INFRINGEMENT AND WARRANTIES OF PERFORMANCE, AND ANY WARRANTY  */
/* THAT MIGHT OTHERWISE ARISE FROM COURSE OF DEALING OR USAGE OF     */
/* TRADE. NO WARRANTY IS EITHER EXPRESS OR IMPLIED WITH RESPECT TO   */
/* THE USE OF THE SOFTWARE OR DOCUMENTATION.                         */
/* Under no circumstances shall University be liable for incidental, */
/* special, indirect, direct or consequential damages or loss of     */
/* profits, interruption of business, or related expenses which may  */
/* arise from use of Software or Documentation, including but not    */
/* limited to those resulting from defects in Software and/or        */
/* Documentation, or loss or inaccuracy of data of any kind.         */
/*********************************************************************/

#define ASSEMBLER
#include "common.h"
		
#ifndef __64BIT__
#define LOAD	lwz
#else
#define LOAD	ld
#endif

#ifdef __64BIT__
#define STACKSIZE 320
#define ALPHA_R 296(SP)
#define ALPHA_I 304(SP)
#define FZERO	312(SP)
#else
#define STACKSIZE 256
#define ALPHA_R 224(SP)
#define ALPHA_I 232(SP)
#define FZERO	240(SP)
#endif

#define	M	r3
#define	N	r4
#define	K	r5

#ifdef linux
#ifndef __64BIT__
#define A	r6
#define	B	r7
#define	C	r8
#define	LDC	r9
#else
#define A	r8
#define	B	r9
#define	C	r10
#define	LDC	r6
#endif
#endif

#if defined(_AIX) || defined(__APPLE__)
#if !defined(__64BIT__) && defined(DOUBLE)
#define A	r10
#define	B	r6
#define	C	r7
#define	LDC	r8
#else
#define A	r8
#define	B	r9
#define	C	r10
#define	LDC	r6
#endif
#endif

#define	I	r24
#define J	r25
#define AO	r26
#define	BO	r27
#define	CO1	r28
#define CO2	r29

#define PREA	r30
#define PREC	r31
#define PREB	PREA
	
#ifndef NEEDPARAM

#ifndef DOUBLE
#include "../cparam.h"
#else
#include "../zparam.h"
#endif

	PROLOGUE
	PROFCODE

	addi	SP, SP, -STACKSIZE
	li	r0, 0

	stfd	f14,    0(SP)
	stfd	f15,    8(SP)
	stfd	f16,   16(SP)
	stfd	f17,   24(SP)

	stfd	f18,   32(SP)
	stfd	f19,   40(SP)
	stfd	f20,   48(SP)
	stfd	f21,   56(SP)

	stfd	f22,   64(SP)
	stfd	f23,   72(SP)
	stfd	f24,   80(SP)
	stfd	f25,   88(SP)

	stfd	f26,   96(SP)
	stfd	f27,  104(SP)
	stfd	f28,  112(SP)
	stfd	f29,  120(SP)

	stfd	f30,  128(SP)
	stfd	f31,  136(SP)

#ifdef __64BIT__
	std	r31,  144(SP)
	std	r30,  152(SP)
	std	r29,  160(SP)
	std	r28,  168(SP)
	std	r27,  176(SP)
	std	r26,  184(SP)
	std	r25,  192(SP)
	std	r24,  200(SP)
#else
	stw	r31,  144(SP)
	stw	r30,  148(SP)
	stw	r29,  152(SP)
	stw	r28,  156(SP)
	stw	r27,  160(SP)
	stw	r26,  164(SP)
	stw	r25,  168(SP)
	stw	r24,  172(SP)
#endif

	stfd	f1,  ALPHA_R
	stfd	f2,  ALPHA_I
	stw	r0,  FZERO

#ifdef linux
#ifdef __64BIT__
	ld	LDC,    112 + STACKSIZE(SP)
#endif
#endif

#if defined(_AIX) || defined(__APPLE__)
#ifdef __64BIT__
	ld	LDC,    112 + STACKSIZE(SP)
#else
#ifdef DOUBLE
	lwz	B,       56 + STACKSIZE(SP)
	lwz	C,       60 + STACKSIZE(SP)
	lwz	LDC,     64 + STACKSIZE(SP)
#else
	lwz	LDC,     56 + STACKSIZE(SP)
#endif
#endif
#endif

	slwi	LDC, LDC, ZBASE_SHIFT

	cmpwi	cr0, M, 0
	ble	LL(999)
	cmpwi	cr0, N, 0
	ble	LL(999)
	cmpwi	cr0, K, 0
	ble	LL(999)

#ifndef PREFETCHTEST
#ifdef PPC970
	li	PREC,   4 * SIZE
#endif
#ifdef POWER4
	li	PREC,   4 * SIZE   /* is 12 best? */
#endif
#ifdef POWER5
	li	PREC,   4 * SIZE   /* is 12 best? */
#endif
#else

#ifdef linux
#ifndef __64BIT__
	lwz	PREA,   16 + STACKSIZE(SP)
	lwz	PREC,   20 + STACKSIZE(SP)
#else
	ld	PREA,  136 + STACKSIZE(SP)
	ld	PREC,  144 + STACKSIZE(SP)
#endif
#endif

#if defined(_AIX) || defined(__APPLE__)
#ifdef __64BIT__
	ld	PREA,  136 + STACKSIZE(SP)
	ld	PREC,  144 + STACKSIZE(SP)
#else
#ifdef DOUBLE
	lwz	PREA,   72 + STACKSIZE(SP)
	lwz	PREC,   76 + STACKSIZE(SP)
#else
	lwz	PREA,   68 + STACKSIZE(SP)
	lwz	PREC,   72 + STACKSIZE(SP)
#endif
#endif
#endif

#endif

#ifndef PREFETCHTEST
#ifdef PPC970
#ifdef ALLOC_HUGETLB
	li	PREA,   (16 *  5 * SIZE + 16)
#else
	li	PREA,   (16 *  9 * SIZE + 16)
#endif
#endif
#ifdef POWER4
#ifdef ALLOC_HUGETLB
	li	PREA,   (16 *  1 * SIZE + 16)
#else
	li	PREA,   (16 *  2 * SIZE + 16)
#endif
#endif
#ifdef POWER5
	li	PREA,   16 *  9 * SIZE
#endif
#endif

	lfs	f0, FZERO

	srawi.	J, N,  1
	ble	LL(KERNEL_N_AND_3_HEAD)
	.align 4

LL(KERNEL_MainHead):
 	fmr	f1,  f0
	fmr	f2,  f0
	fmr	f3,  f0
	fmr	f4,  f0
	fmr	f5,  f0
	fmr	f6,  f0
	fmr	f7,  f0
	fmr	f8,  f0
	fmr	f9,  f0
	fmr	f10, f0
	fmr	f11, f0
	fmr	f12, f0
	fmr	f13, f0
	fmr	f14, f0
	fmr	f15, f0

	mr	CO1, C
	add	CO2, C,  LDC
	add	C,  CO2, LDC

	srawi.	I, M,  1
	mr	AO, A
	ble	LL(KERNEL_M_AND_3)
	.align 4

LL(KERNEL_MainSubHead):
	LFD	f16,  0 * SIZE(AO)
	LFD	f17,  1 * SIZE(AO)
	LFD	f18,  2 * SIZE(AO)
	LFD	f19,  3 * SIZE(AO)

	LFD	f20,  0 * SIZE(B)
	LFD	f21,  1 * SIZE(B)
	LFD	f22,  2 * SIZE(B)
	LFD	f23,  3 * SIZE(B)
 
	LFD	f24,  4 * SIZE(AO)
	LFD	f25,  5 * SIZE(AO)
	LFD	f26,  6 * SIZE(AO)
	LFD	f27,  7 * SIZE(AO)

	srawi.	r0,  K,  2
	mr	BO,  B
	mtspr	CTR, r0
	ble	LL(KERNEL_K_AND_7)
	.align 4

LL(KERNEL_MainLoop):
	fmadd	f0,  f16, f20, f0
	fmadd	f4,  f16, f21, f4
	LFD	f28,  4 * SIZE(BO)
	fmadd	f8,  f16, f22, f8
	fmadd	f12, f16, f23, f12
	LFD	f16,  8 * SIZE(AO)

	fmadd	f1,  f17, f20, f1
	fmadd	f5,  f17, f21, f5
	LFD	f29,  5 * SIZE(BO)
	fmadd	f9,  f17, f22, f9
	fmadd	f13, f17, f23, f13
	LFD	f17,  9 * SIZE(AO)

	fmadd	f2,  f18, f20, f2
	fmadd	f6,  f18, f21, f6
	LFD	f30,  6 * SIZE(BO)
	fmadd	f10, f18, f22, f10
	fmadd	f14, f18, f23, f14
	LFD	f18, 10 * SIZE(AO)

	fmadd	f3,  f19, f20, f3
	fmadd	f7,  f19, f21, f7
	LFD	f31,  7 * SIZE(BO)
	fmadd	f11, f19, f22, f11
	fmadd	f15, f19, f23, f15
	LFD	f19, 11 * SIZE(AO)

	fmadd	f0,  f24, f28, f0
	fmadd	f4,  f24, f29, f4
	LFD	f20,  8 * SIZE(BO)
	fmadd	f8,  f24, f30, f8
	fmadd	f12, f24, f31, f12
	LFD	f24, 12 * SIZE(AO)

	fmadd	f1,  f25, f28, f1
	fmadd	f5,  f25, f29, f5
	LFD	f21,  9 * SIZE(BO)
	fmadd	f9,  f25, f30, f9
	fmadd	f13, f25, f31, f13
	LFD	f25, 13 * SIZE(AO)

	fmadd	f2,  f26, f28, f2
	fmadd	f6,  f26, f29, f6
	LFD	f22, 10 * SIZE(BO)
	fmadd	f10, f26, f30, f10
	fmadd	f14, f26, f31, f14
	LFD	f26, 14 * SIZE(AO)

	fmadd	f3,  f27, f28, f3
	fmadd	f7,  f27, f29, f7
	LFD	f23, 11 * SIZE(BO)
	fmadd	f11, f27, f30, f11
	fmadd	f15, f27, f31, f15
	LFD	f27, 15 * SIZE(AO)

	fmadd	f0,  f16, f20, f0
	fmadd	f4,  f16, f21, f4
	LFD	f28, 12 * SIZE(BO)
	fmadd	f8,  f16, f22, f8
	fmadd	f12, f16, f23, f12
	LFDU	f16, 16 * SIZE(AO)

	fmadd	f1,  f17, f20, f1
	fmadd	f5,  f17, f21, f5
	LFD	f29, 13 * SIZE(BO)
	fmadd	f9,  f17, f22, f9
	fmadd	f13, f17, f23, f13
	LFD	f17,  1 * SIZE(AO)

	fmadd	f2,  f18, f20, f2
	fmadd	f6,  f18, f21, f6
	LFD	f30, 14 * SIZE(BO)
	fmadd	f10, f18, f22, f10
	fmadd	f14, f18, f23, f14
	LFD	f18,  2 * SIZE(AO)

	fmadd	f3,  f19, f20, f3
	fmadd	f7,  f19, f21, f7
	LFD	f31, 15 * SIZE(BO)
	fmadd	f11, f19, f22, f11
	fmadd	f15, f19, f23, f15
	LFD	f19,  3 * SIZE(AO)

	fmadd	f0,  f24, f28, f0
	fmadd	f4,  f24, f29, f4
	LFDU	f20, 16 * SIZE(BO)
	fmadd	f8,  f24, f30, f8
	fmadd	f12, f24, f31, f12
	LFD	f24,  4 * SIZE(AO)

	fmadd	f1,  f25, f28, f1
	fmadd	f5,  f25, f29, f5
	LFD	f21,  1 * SIZE(BO)
	fmadd	f9,  f25, f30, f9
	fmadd	f13, f25, f31, f13
	LFD	f25,  5 * SIZE(AO)

	fmadd	f2,  f26, f28, f2
	fmadd	f6,  f26, f29, f6
	LFD	f22,  2 * SIZE(BO)
	fmadd	f10, f26, f30, f10
	fmadd	f14, f26, f31, f14
	LFD	f26,  6 * SIZE(AO)

	fmadd	f3,  f27, f28, f3
	fmadd	f7,  f27, f29, f7
	LFD	f23,  3 * SIZE(BO)

	fmadd	f11, f27, f30, f11
	fmadd	f15, f27, f31, f15
	LFD	f27,  7 * SIZE(AO)
	bdnz	LL(KERNEL_MainLoop)
	.align 4

LL(KERNEL_K_AND_7):
	andi.	r0,  K,  3
	lfd	f30,  ALPHA_R
	lfd	f31,  ALPHA_I
	mtspr	CTR, r0
	ble	LL(KERNEL_MainFinish)
	.align 4

LL(KERNEL_SubLoop):
	fmadd	f0,  f16, f20, f0
	fmadd	f4,  f16, f21, f4
	fmadd	f8,  f16, f22, f8
	fmadd	f12, f16, f23, f12
	LFD	f16,  4 * SIZE(AO)

	fmadd	f1,  f17, f20, f1
	fmadd	f5,  f17, f21, f5
	fmadd	f9,  f17, f22, f9
	fmadd	f13, f17, f23, f13
	LFD	f17,  5 * SIZE(AO)

	fmadd	f2,  f18, f20, f2
	fmadd	f6,  f18, f21, f6
	fmadd	f10, f18, f22, f10
	fmadd	f14, f18, f23, f14
	LFD	f18,  6 * SIZE(AO)

	fmadd	f3,  f19, f20, f3
	LFD	f20,  4 * SIZE(BO)
	fmadd	f7,  f19, f21, f7
	LFD	f21,  5 * SIZE(BO)
	fmadd	f11, f19, f22, f11
	LFD	f22,  6 * SIZE(BO)
	fmadd	f15, f19, f23, f15
	LFD	f19,  7 * SIZE(AO)

	LFD	f23,  7 * SIZE(BO)
	addi	BO, BO,  4 * SIZE
	addi	AO, AO,  4 * SIZE
	bdnz	LL(KERNEL_SubLoop)
	.align 4

LL(KERNEL_MainFinish):
	LFD	f16, 0 * SIZE(CO1)
	LFD	f17, 1 * SIZE(CO1)
	LFD	f18, 2 * SIZE(CO1)
	LFD	f19, 3 * SIZE(CO1)

#if   defined(NN) || defined(NT) || defined(TN) || defined(TT) || \
      defined(CC) || defined(CR) || defined(RC) || defined(RR)

	FSUB	  f0,  f0,  f5
	FADD	  f1,  f1,  f4
	FSUB	  f2,  f2,  f7
	FADD	  f3,  f3,  f6

	LFD	f20, 0 * SIZE(CO2)
	LFD	f21, 1 * SIZE(CO2)
	LFD	f22, 2 * SIZE(CO2)
	LFD	f23, 3 * SIZE(CO2)

	FSUB	  f8,  f8,  f13
	FADD	  f9,  f9,  f12
	FSUB	  f10, f10, f15
	FADD	  f11, f11, f14

#elif defined(CN) || defined(CT) || defined(RN) || defined(RT)

	FADD	  f0,  f0,  f5
	FSUB	  f1,  f1,  f4
	FADD	  f2,  f2,  f7
	FSUB	  f3,  f3,  f6

	LFD	f20, 0 * SIZE(CO2)
	LFD	f21, 1 * SIZE(CO2)
	LFD	f22, 2 * SIZE(CO2)
	LFD	f23, 3 * SIZE(CO2)

	FADD	  f8,  f8,  f13
	FSUB	  f9,  f9,  f12
	FADD	  f10, f10, f15
	FSUB	  f11, f11, f14

#else /* defined(NC) || defined(TC) || defined(NR) || defined(TR) */

	FADD	  f0,  f0,  f5
	FSUB	  f1,  f4,  f1
	FADD	  f2,  f2,  f7
	FSUB	  f3,  f6,  f3

	LFD	f20, 0 * SIZE(CO2)
	LFD	f21, 1 * SIZE(CO2)
	LFD	f22, 2 * SIZE(CO2)
	LFD	f23, 3 * SIZE(CO2)

	FADD	  f8,  f8,  f13
	FSUB	  f9,  f12, f9
	FADD	  f10, f10, f15
	FSUB	  f11, f14, f11

#endif

#if   defined(NN) || defined(NT) || defined(TN) || defined(TT)

	FMADD	f16, f30, f0,  f16
	FMADD	f17, f30, f1,  f17
	FMADD	f18, f30, f2,  f18
	FMADD	f19, f30, f3,  f19

	FMADD	f20, f30, f8,  f20
	FMADD	f21, f30, f9,  f21
	FMADD	f22, f30, f10, f22
	FMADD	f23, f30, f11, f23

	FNMSUB	f16, f31, f1,  f16
	FMADD	f17, f31, f0,  f17
	FNMSUB	f18, f31, f3,  f18
	FMADD	f19, f31, f2,  f19

	FNMSUB	f20, f31, f9,  f20
	FMADD	f21, f31, f8,  f21
	FNMSUB	f22, f31, f11, f22
	FMADD	f23, f31, f10, f23

#else /* defined(CN)||defined(CT)||defined(NC)||defined(TC)||defined(CC) */
      /* defined(RN)||defined(RT)||defined(NR)||defined(TR)||defined(CR) */
      /* defined(RC)|| defined(RR) */

	FMADD	f16, f30, f0,  f16
	FNMSUB	f17, f30, f1,  f17
	FMADD	f18, f30, f2,  f18
	FNMSUB	f19, f30, f3,  f19

	FMADD	f20, f30, f8,  f20
	FNMSUB	f21, f30, f9,  f21
	FMADD	f22, f30, f10, f22
	FNMSUB	f23, f30, f11, f23

	FMADD	f16, f31, f1,  f16
	FMADD	f17, f31, f0,  f17
	FMADD	f18, f31, f3,  f18
	FMADD	f19, f31, f2,  f19

	FMADD	f20, f31, f9,  f20
	FMADD	f21, f31, f8,  f21
	FMADD	f22, f31, f11, f22
	FMADD	f23, f31, f10, f23

#endif

	STFD	f16,  0 * SIZE(CO1)
	STFD	f17,  1 * SIZE(CO1)
	STFD	f18,  2 * SIZE(CO1)
	STFD	f19,  3 * SIZE(CO1)

	lfs	f0,  FZERO
 	fmr	f1,  f0
	fmr	f2,  f0
	fmr	f3,  f0

	STFD	f20,  0 * SIZE(CO2)
	STFD	f21,  1 * SIZE(CO2)
	STFD	f22,  2 * SIZE(CO2)
	STFD	f23,  3 * SIZE(CO2)

	fmr	f4,  f0
	fmr	f5,  f0
	fmr	f6,  f0
	fmr	f7,  f0

	fmr	f8,  f0
	fmr	f9,  f0
	fmr	f10, f0
	fmr	f11, f0

	fmr	f12, f0
	fmr	f13, f0
	fmr	f14, f0
	fmr	f15, f0

	addi	CO1, CO1, 4 * SIZE
	addi	CO2, CO2, 4 * SIZE
	
	addic.	I, I, -1
	bgt	LL(KERNEL_MainSubHead)
	.align 4

LL(KERNEL_M_AND_3):
	andi.	I,  M,  1
	ble	LL(KERNEL_MainTail)
	.align 4

LL(KERNEL_M_AND_3_SubHead):
	LFD	f16,  0 * SIZE(AO)
	LFD	f17,  1 * SIZE(AO)
	LFD	f18,  2 * SIZE(AO)
	LFD	f19,  3 * SIZE(AO)

	LFD	f20,  0 * SIZE(B)
	LFD	f21,  1 * SIZE(B)
	LFD	f22,  2 * SIZE(B)
	LFD	f23,  3 * SIZE(B)

	LFD	f24,  4 * SIZE(B)
	LFD	f25,  5 * SIZE(B)
	LFD	f26,  6 * SIZE(B)
	LFD	f27,  7 * SIZE(B)

	lfs	f0, FZERO
	fmr	f1, f0
	fmr	f2, f0
	fmr	f3, f0
	fmr	f4, f0
	fmr	f5, f0
	fmr	f6, f0
	fmr	f7, f0

	srawi.	r0,  K,  2
	mr	BO,  B
	mtspr	CTR, r0
	ble	LL(KERNEL_M_AND_3_K_AND_3)
	.align 4

LL(KERNEL_M_AND_3_MainLoop):
	fmadd	f0,  f16, f20, f0
	fmadd	f1,  f16, f21, f1
	fmadd	f2,  f16, f22, f2
	fmadd	f3,  f16, f23, f3

	fmadd	f4,  f17, f20, f4
	fmadd	f5,  f17, f21, f5
	fmadd	f6,  f17, f22, f6
	fmadd	f7,  f17, f23, f7

 	LFD	f20,  8 * SIZE(BO)
	LFD	f21,  9 * SIZE(BO)
	LFD	f22, 10 * SIZE(BO)
	LFD	f23, 11 * SIZE(BO)

	fmadd	f0,  f18, f24, f0
	fmadd	f1,  f18, f25, f1
	fmadd	f2,  f18, f26, f2
	fmadd	f3,  f18, f27, f3

	fmadd	f4,  f19, f24, f4
	fmadd	f5,  f19, f25, f5
	fmadd	f6,  f19, f26, f6
	fmadd	f7,  f19, f27, f7

 	LFD	f24, 12 * SIZE(BO)
	LFD	f25, 13 * SIZE(BO)
	LFD	f26, 14 * SIZE(BO)
	LFD	f27, 15 * SIZE(BO)

	LFD	f16,  4 * SIZE(AO)
	LFD	f17,  5 * SIZE(AO)
	LFD	f18,  6 * SIZE(AO)
	LFD	f19,  7 * SIZE(AO)

	fmadd	f0,  f16, f20, f0
	fmadd	f1,  f16, f21, f1
	fmadd	f2,  f16, f22, f2
	fmadd	f3,  f16, f23, f3

	fmadd	f4,  f17, f20, f4
	fmadd	f5,  f17, f21, f5
	fmadd	f6,  f17, f22, f6
	fmadd	f7,  f17, f23, f7

 	LFD	f20, 16 * SIZE(BO)
	LFD	f21, 17 * SIZE(BO)
	LFD	f22, 18 * SIZE(BO)
	LFD	f23, 19 * SIZE(BO)

	fmadd	f0,  f18, f24, f0
	fmadd	f1,  f18, f25, f1
	fmadd	f2,  f18, f26, f2
	fmadd	f3,  f18, f27, f3

	fmadd	f4,  f19, f24, f4
	fmadd	f5,  f19, f25, f5
	fmadd	f6,  f19, f26, f6
	fmadd	f7,  f19, f27, f7

	LFD	f16,  8 * SIZE(AO)
	LFD	f17,  9 * SIZE(AO)
	LFD	f18, 10 * SIZE(AO)
	LFD	f19, 11 * SIZE(AO)

 	LFD	f24, 20 * SIZE(BO)
	LFD	f25, 21 * SIZE(BO)
	LFD	f26, 22 * SIZE(BO)
	LFD	f27, 23 * SIZE(BO)

	addi	BO,  BO, 16 * SIZE
	addi	AO,  AO,  8 * SIZE
	bdnz	LL(KERNEL_M_AND_3_MainLoop)
	.align 4

LL(KERNEL_M_AND_3_K_AND_3):
	andi.	r0,  K,  3
	lfd	f30, ALPHA_R
	lfd	f31, ALPHA_I
	mtspr	CTR, r0
	ble	LL(KERNEL_M_AND3_Finish)
	.align 4

LL(KERNEL_M_AND_3_SubLoop):
	fmadd	f0,  f16, f20, f0
	fmadd	f1,  f16, f21, f1
	fmadd	f2,  f16, f22, f2
	fmadd	f3,  f16, f23, f3

	fmadd	f4,  f17, f20, f4
	fmadd	f5,  f17, f21, f5
	fmadd	f6,  f17, f22, f6
	fmadd	f7,  f17, f23, f7

 	LFD	f20,  4 * SIZE(BO)
	LFD	f21,  5 * SIZE(BO)
	LFD	f22,  6 * SIZE(BO)
	LFD	f23,  7 * SIZE(BO)

	LFD	f16,  2 * SIZE(AO)
	LFD	f17,  3 * SIZE(AO)
	addi	AO, AO,  2 * SIZE
	addi	BO, BO,  4 * SIZE
	bdnz	LL(KERNEL_M_AND_3_SubLoop)
	.align 4

LL(KERNEL_M_AND3_Finish):
#if   defined(NN) || defined(NT) || defined(TN) || defined(TT) || \
      defined(CC) || defined(CR) || defined(RC) || defined(RR)

	FSUB	  f0,  f0,  f5
	FADD	  f1,  f1,  f4
	FSUB	  f2,  f2,  f7
	FADD	  f3,  f3,  f6

#elif defined(CN) || defined(CT) || defined(RN) || defined(RT)

	FADD	  f0,  f0,  f5
	FSUB	  f1,  f4,  f1
	FADD	  f2,  f2,  f7
	FSUB	  f3,  f6,  f3

#else /* defined(NC) || defined(TC) || defined(NR) || defined(TR) */

	FADD	  f0,  f0,  f5
	FSUB	  f1,  f1,  f4
	FADD	  f2,  f2,  f7
	FSUB	  f3,  f3,  f6

#endif

	LFD	f16, 0 * SIZE(CO1)
	LFD	f17, 1 * SIZE(CO1)

	LFD	f18, 0 * SIZE(CO2)
	LFD	f19, 1 * SIZE(CO2)


#if   defined(NN) || defined(NT) || defined(TN) || defined(TT)

	FMADD	f16, f30, f0,  f16
	FMADD	f17, f30, f1,  f17
	FMADD	f18, f30, f2,  f18
	FMADD	f19, f30, f3,  f19
	FNMSUB	f16, f31, f1,  f16
	FMADD	f17, f31, f0,  f17
	FNMSUB	f18, f31, f3,  f18
	FMADD	f19, f31, f2,  f19

#else /* defined(CN)||defined(CT)||defined(NC)||defined(TC)||defined(CC) */
      /* defined(RN)||defined(RT)||defined(NR)||defined(TR)||defined(CR) */
      /* defined(RC)|| defined(RR) */

	FMADD	f16, f30, f0,  f16
	FNMSUB	f17, f30, f1,  f17
	FMADD	f18, f30, f2,  f18
	FNMSUB	f19, f30, f3,  f19

	FMADD	f16, f31, f1,  f16
	FMADD	f17, f31, f0,  f17
	FMADD	f18, f31, f3,  f18
	FMADD	f19, f31, f2,  f19
#endif

	STFD	f16, 0 * SIZE(CO1)
	STFD	f17, 1 * SIZE(CO1)
	STFD	f18, 0 * SIZE(CO2)
	STFD	f19, 1 * SIZE(CO2)

	addi	CO1, CO1, 2 * SIZE
	addi	CO2, CO2, 2 * SIZE

	addic.	I, I, -1
	bgt	LL(KERNEL_M_AND_3_SubHead)
	.align 4

LL(KERNEL_MainTail):
	mr	B,  BO
	addic.	J, J, -1
	lfs	f0, FZERO
	bgt	LL(KERNEL_MainHead)
	.align 4

LL(KERNEL_N_AND_3_HEAD):
	andi.	J, N,  1
	ble	LL(999)
	.align 4

LL(KERNEL_N_AND_3_MainHead):
	srawi.	I,  M,  1
	mr	CO1, C
	add	C, C, LDC
	mr	AO, A

	ble	LL(KERNEL_MN_AND_3_Head)
	.align 4

LL(KERNEL_N_AND_3_SubHead):
	LFD	f20,  0 * SIZE(AO)
	LFD	f21,  1 * SIZE(AO)
	LFD	f22,  2 * SIZE(AO)
	LFD	f23,  3 * SIZE(AO)

	LFD	f24,  4 * SIZE(AO)
	LFD	f25,  5 * SIZE(AO)
	LFD	f26,  6 * SIZE(AO)
	LFD	f27,  7 * SIZE(AO)

	LFD	f16, 0 * SIZE(B)
	LFD	f17, 1 * SIZE(B)
	LFD	f18, 2 * SIZE(B)
	LFD	f19, 3 * SIZE(B)

	lfs	f0, FZERO
	fmr	f1, f0
	fmr	f2, f0
	fmr	f3, f0
	fmr	f4, f0
	fmr	f5, f0
	fmr	f6, f0
	fmr	f7, f0

	srawi.	r0,  K,  2
	mr	BO, B
	mtspr	CTR, r0
	ble	LL(KERNEL_N_AND_3_K_AND_3)
	.align 4

LL(KERNEL_N_AND_3_MainLoop):
	fmadd	f0,  f16, f20, f0
	fmadd	f1,  f16, f21, f1
	fmadd	f2,  f16, f22, f2
	fmadd	f3,  f16, f23, f3

	fmadd	f4,  f17, f20, f4
	fmadd	f5,  f17, f21, f5
	fmadd	f6,  f17, f22, f6
	fmadd	f7,  f17, f23, f7

	LFD	f20,  8 * SIZE(AO)
	LFD	f21,  9 * SIZE(AO)
	LFD	f22, 10 * SIZE(AO)
	LFD	f23, 11 * SIZE(AO)

	fmadd	f0,  f18, f24, f0
	fmadd	f1,  f18, f25, f1
	fmadd	f2,  f18, f26, f2
	fmadd	f3,  f18, f27, f3

	fmadd	f4,  f19, f24, f4
	fmadd	f5,  f19, f25, f5
	fmadd	f6,  f19, f26, f6
	fmadd	f7,  f19, f27, f7

	LFD	f24, 12 * SIZE(AO)
	LFD	f25, 13 * SIZE(AO)
	LFD	f26, 14 * SIZE(AO)
	LFD	f27, 15 * SIZE(AO)

	LFD	f16,  4 * SIZE(BO)
	LFD	f17,  5 * SIZE(BO)
	LFD	f18,  6 * SIZE(BO)
	LFD	f19,  7 * SIZE(BO)

	fmadd	f0,  f16, f20, f0
	fmadd	f1,  f16, f21, f1
	fmadd	f2,  f16, f22, f2
	fmadd	f3,  f16, f23, f3

	fmadd	f4,  f17, f20, f4
	fmadd	f5,  f17, f21, f5
	fmadd	f6,  f17, f22, f6
	fmadd	f7,  f17, f23, f7

	LFD	f20, 16 * SIZE(AO)
	LFD	f21, 17 * SIZE(AO)
	LFD	f22, 18 * SIZE(AO)
	LFD	f23, 19 * SIZE(AO)

	fmadd	f0,  f18, f24, f0
	fmadd	f1,  f18, f25, f1
	fmadd	f2,  f18, f26, f2
	fmadd	f3,  f18, f27, f3

	fmadd	f4,  f19, f24, f4
	fmadd	f5,  f19, f25, f5
	fmadd	f6,  f19, f26, f6
	fmadd	f7,  f19, f27, f7

	LFD	f24, 20 * SIZE(AO)
	LFD	f25, 21 * SIZE(AO)
	LFD	f26, 22 * SIZE(AO)
	LFD	f27, 23 * SIZE(AO)

	LFD	f16,  8 * SIZE(BO)
	LFD	f17,  9 * SIZE(BO)
	LFD	f18, 10 * SIZE(BO)
	LFD	f19, 11 * SIZE(BO)

	addi	AO, AO, 16 * SIZE
	addi	BO, BO,  8 * SIZE
 	dcbt	PREA, AO
 	dcbt	PREA, BO
	bdnz	LL(KERNEL_N_AND_3_MainLoop)
	.align 4

LL(KERNEL_N_AND_3_K_AND_3):
	andi.	r0,  K,  3
	lfd	f30, ALPHA_R
	lfd	f31, ALPHA_I
	mtspr	CTR, r0
	ble	LL(KERNEL_N_AND_3_Finish)
	.align 4

LL(KERNEL_N_AND_3_SubLoop):
	fmadd	f0,  f16, f20, f0
	fmadd	f1,  f16, f21, f1
	fmadd	f2,  f16, f22, f2
	fmadd	f3,  f16, f23, f3

	fmadd	f4,  f17, f20, f4
	fmadd	f5,  f17, f21, f5
	fmadd	f6,  f17, f22, f6
	fmadd	f7,  f17, f23, f7

	LFD	f20, 4 * SIZE(AO)
	LFD	f21, 5 * SIZE(AO)
	LFD	f22, 6 * SIZE(AO)
	LFD	f23, 7 * SIZE(AO)

	LFD	f16, 2 * SIZE(BO)
	LFD	f17, 3 * SIZE(BO)

	addi	BO,  BO, 2 * SIZE
	addi	AO,  AO, 4 * SIZE
	bdnz	LL(KERNEL_N_AND_3_SubLoop)
	.align 4

LL(KERNEL_N_AND_3_Finish):
#if   defined(NN) || defined(NT) || defined(TN) || defined(TT) || \
      defined(CC) || defined(CR) || defined(RC) || defined(RR)

	FSUB	  f0,  f0,  f5
	FADD	  f1,  f1,  f4
	FSUB	  f2,  f2,  f7
	FADD	  f3,  f3,  f6

#elif defined(CN) || defined(CT) || defined(RN) || defined(RT)

	FADD	  f0,  f0,  f5
	FSUB	  f1,  f1,  f4
	FADD	  f2,  f2,  f7
	FSUB	  f3,  f3,  f6

#else /* defined(NC) || defined(TC) || defined(NR) || defined(TR) */

	FADD	  f0,  f0,  f5
	FSUB	  f1,  f4,  f1
	FADD	  f2,  f2,  f7
	FSUB	  f3,  f6,  f3

#endif

	LFD	f16, 0 * SIZE(CO1)
	LFD	f17, 1 * SIZE(CO1)
	LFD	f18, 2 * SIZE(CO1)
	LFD	f19, 3 * SIZE(CO1)

#if   defined(NN) || defined(NT) || defined(TN) || defined(TT)

	FMADD	f16, f30, f0,  f16
	FMADD	f17, f30, f1,  f17
	FMADD	f18, f30, f2,  f18
	FMADD	f19, f30, f3,  f19
	FNMSUB	f16, f31, f1,  f16
	FMADD	f17, f31, f0,  f17
	FNMSUB	f18, f31, f3,  f18
	FMADD	f19, f31, f2,  f19

#else /* defined(CN)||defined(CT)||defined(NC)||defined(TC)||defined(CC) */
      /* defined(RN)||defined(RT)||defined(NR)||defined(TR)||defined(CR) */
      /* defined(RC)|| defined(RR) */

	FMADD	f16, f30, f0,  f16
	FNMSUB	f17, f30, f1,  f17
	FMADD	f18, f30, f2,  f18
	FNMSUB	f19, f30, f3,  f19

	FMADD	f16, f31, f1,  f16
	FMADD	f17, f31, f0,  f17
	FMADD	f18, f31, f3,  f18
	FMADD	f19, f31, f2,  f19
#endif

	STFD	f16, 0 * SIZE(CO1)
	STFD	f17, 1 * SIZE(CO1)
	STFD	f18, 2 * SIZE(CO1)
	STFD	f19, 3 * SIZE(CO1)

	addi	CO1, CO1, 4 * SIZE

	addic.	I, I, -1
	bgt	LL(KERNEL_N_AND_3_SubHead)
	.align 4

LL(KERNEL_MN_AND_3_Head):
	andi.	I,  M,  1
	ble	LL(KERNEL_SubEnd)
	.align 4

LL(KERNEL_MN_AND_3_SubHead):
	LFD	f16, 0 * SIZE(AO)
	LFD	f17, 1 * SIZE(AO)
	LFD	f18, 2 * SIZE(AO)
	LFD	f19, 3 * SIZE(AO)

	LFD	f20, 0 * SIZE(B)
	LFD	f21, 1 * SIZE(B)
	LFD	f22, 2 * SIZE(B)
	LFD	f23, 3 * SIZE(B)

	lfs	f0, FZERO
	fmr	f1, f0
	fmr	f2, f0
	fmr	f3, f0
	fmr	f4, f0
	fmr	f5, f0
	fmr	f6, f0
	fmr	f7, f0

	srawi.	r0,  K,  2
	mr	BO, B
	mtspr	CTR, r0
	ble	LL(KERNEL_MN_AND_3_K_AND_3)
	.align 4

LL(KERNEL_MN_AND_3_MainLoop):
	fmadd	f0,  f16,  f20,  f0
	fmadd	f1,  f17,  f21,  f1
	fmadd	f2,  f17,  f20,  f2
	fmadd	f3,  f16,  f21,  f3

	LFD	f16,  4 * SIZE(AO)
	LFD	f17,  5 * SIZE(AO)
	LFD	f20,  4 * SIZE(BO)
	LFD	f21,  5 * SIZE(BO)

	fmadd	f4,  f18,  f22,  f4
	fmadd	f5,  f19,  f23,  f5
	fmadd	f6,  f19,  f22,  f6
	fmadd	f7,  f18,  f23,  f7

	LFD	f18,  6 * SIZE(AO)
	LFD	f19,  7 * SIZE(AO)
	LFD	f22,  6 * SIZE(BO)
	LFD	f23,  7 * SIZE(BO)

	fmadd	f0,  f16,  f20,  f0
	fmadd	f1,  f17,  f21,  f1
	fmadd	f2,  f17,  f20,  f2
	fmadd	f3,  f16,  f21,  f3

	LFD	f16,  8 * SIZE(AO)
	LFD	f17,  9 * SIZE(AO)
	LFD	f20,  8 * SIZE(BO)
	LFD	f21,  9 * SIZE(BO)

	fmadd	f4,  f18,  f22,  f4
	fmadd	f5,  f19,  f23,  f5
	fmadd	f6,  f19,  f22,  f6
	fmadd	f7,  f18,  f23,  f7

	LFD	f18, 10 * SIZE(AO)
	LFD	f19, 11 * SIZE(AO)
	LFD	f22, 10 * SIZE(BO)
	LFD	f23, 11 * SIZE(BO)

	addi	AO, AO,  8 * SIZE
	addi	BO, BO,  8 * SIZE
	bdnz	LL(KERNEL_MN_AND_3_MainLoop)
	.align 4

LL(KERNEL_MN_AND_3_K_AND_3):
	fadd	f0, f0, f4
	fadd	f1, f1, f5
	fadd	f2, f2, f6
	fadd	f3, f3, f7

	andi.	r0,  K,  3
	lfd	f30, ALPHA_R
	lfd	f31, ALPHA_I
	mtspr	CTR,r0
	ble	LL(KERNEL_MN_AND_3_Finish)
	.align 4

LL(KERNEL_MN_AND_3_SubLoop):
	fmadd	f0,  f16,  f20,  f0
	fmadd	f1,  f17,  f21,  f1
	fmadd	f2,  f17,  f20,  f2
	fmadd	f3,  f16,  f21,  f3

	LFD	f16, 2 * SIZE(AO)
	LFD	f17, 3 * SIZE(AO)
	LFD	f20, 2 * SIZE(BO)
	LFD	f21, 3 * SIZE(BO)

	addi	AO, AO, 2 * SIZE
	addi	BO, BO, 2 * SIZE

	bdnz	LL(KERNEL_MN_AND_3_SubLoop)
	.align 4

LL(KERNEL_MN_AND_3_Finish):
#if   defined(NN) || defined(NT) || defined(TN) || defined(TT) || \
      defined(CC) || defined(CR) || defined(RC) || defined(RR)
	fsub	f0, f0, f1
	fadd	f2, f2, f3
#elif defined(CN) || defined(CT) || defined(RN) || defined(RT)
	fadd	f0, f0, f1
	fsub	f2, f2, f3
#else
	fadd	f0, f0, f1
	fsub	f2, f3, f2
#endif

	LFD	f16,  0 * SIZE(CO1)
	LFD	f17,  1 * SIZE(CO1)

#if   defined(NN) || defined(NT) || defined(TN) || defined(TT)

	FMADD	f16, f30, f0, f16
	FMADD	f17, f30, f2, f17

	FNMSUB	f16, f31, f2, f16
	FMADD	f17, f31, f0, f17

#else /* defined(CN)||defined(CT)||defined(NC)||defined(TC)||defined(CC) */
      /* defined(RN)||defined(RT)||defined(NR)||defined(TR)||defined(CR) */
      /* defined(RC) || defined(RR) */

	FMADD	f16, f30, f0, f16
	FNMSUB	f17, f30, f2, f17

	FMADD	f16, f31, f2, f16
	FMADD	f17, f31, f0, f17

#endif


	STFD	f16,  0 * SIZE(CO1)
	STFD	f17,  1 * SIZE(CO1)

	addi	CO1, CO1, 2 * SIZE
	addic.	I, I, -1
	bgt	LL(KERNEL_MN_AND_3_SubHead)
	.align 4

LL(KERNEL_SubEnd):
	mr	B,  BO
	addic.	J, J, -1
	bgt	LL(KERNEL_N_AND_3_MainHead)
	.align 4

LL(999):
	addi	r3, 0, 0

	lfd	f14,    0(SP)
	lfd	f15,    8(SP)
	lfd	f16,   16(SP)
	lfd	f17,   24(SP)

	lfd	f18,   32(SP)
	lfd	f19,   40(SP)
	lfd	f20,   48(SP)
	lfd	f21,   56(SP)

	lfd	f22,   64(SP)
	lfd	f23,   72(SP)
	lfd	f24,   80(SP)
	lfd	f25,   88(SP)

	lfd	f26,   96(SP)
	lfd	f27,  104(SP)
	lfd	f28,  112(SP)
	lfd	f29,  120(SP)

	lfd	f30,  128(SP)
	lfd	f31,  136(SP)

#ifdef __64BIT__
	ld	r31,  144(SP)
	ld	r30,  152(SP)
	ld	r29,  160(SP)
	ld	r28,  168(SP)
	ld	r27,  176(SP)
	ld	r26,  184(SP)
	ld	r25,  192(SP)
	ld	r24,  200(SP)
#else
	lwz	r31,  144(SP)
	lwz	r30,  148(SP)
	lwz	r29,  152(SP)
	lwz	r28,  156(SP)
	lwz	r27,  160(SP)
	lwz	r26,  164(SP)
	lwz	r25,  168(SP)
	lwz	r24,  172(SP)
#endif

	addi	SP, SP, STACKSIZE

	blr

	EPILOGUE
#endif
