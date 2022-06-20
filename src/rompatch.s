	.title	HIOCS PLUS (rompatch.s)

*****************************************************************
*	HIOCS version 1.10
*		< ROMPATCH.HAS >
*	$Id: ROMPATCH.HA_ 1.1 92/09/14 01:15:56 YuNK Exp $
*
*		Copyright 1990,91,92  SHARP / Y.Nakamura
*****************************************************************


* Include Files ----------------------- *

	.include	hiocs.equ

* Fixed Numbers ----------------------- *

DMAMODE:	.equ	$000c34		*b ＤＭＡ処理実行中のＩＯＣＳ番号
DMAERROR:	.equ	$000c35		*b ＤＭＡのエラーコード

_DMA_CSR2:	.equ	$e84080		*チャンネルステータスレジスタ
_DMA_CER2:	.equ	$e84081		*チャンネルエラーレジスタ
_DMA_DCR2:	.equ	$e84084		*デバイスコントロールレジスタ
_DMA_OCR2:	.equ	$e84085		*オペレーションコントロールレジスタ
_DMA_SCR2:	.equ	$e84086		*シーケンスコントロールレジスタ
_DMA_CCR2:	.equ	$e84087		*チャンネルコントロールレジスタ
_DMA_MTC2:	.equ	$e8408a		*メモリトランスファカウンタ
_DMA_MAR2:	.equ	$e8408c		*メモリアドレスレジスタ
_DMA_DAR2:	.equ	$e84094		*デバイスアドレスレジスタ
_DMA_BTC2:	.equ	$e8409a		*ベーストランスファカウンタ
_DMA_BAR2:	.equ	$e8409c		*ベースアドレスレジスタ

* Text Section ------------------------ *

	.text

patchbegin::
	.dc.b	'HIOCS bug patch for ROM IOCS',0
	.even


*****************************************
*	IOCS $94	_GPALET		*	(全ＲＯＭ)
*****************************************

gpalet::
	lea	_GRAPHPAL,a0
	move	GRCOLMAX,d0
	beq	gpalet2			*グラフィックは使用不可
	addq	#1,d0
	beq	gpalet3			*65536色モード
	moveq	#0,d0
	move	d1,d0
	cmp.w	GRCOLMAX,d0
	bhi	gpalet2			*色コードが不正
	add.w	d0,d0
	adda.l	d0,a0
	cmp.l	#-1,d2
	beq	gpalet1
	move	d2,(a0)			*パレットを設定する
	moveq	#0,d0
	rts
gpalet1:				*現在のパレットを調べる
	move	(a0),d0
	rts

gpalet2:				*エラー
	moveq.l	#-1,d0
	rts

gpalet3:				*65536色モードでのパレット設定
	moveq	#0,d0
	move.l	d3,-(a7)
	moveq	#0,d3
	move.b	d1,d0
	ror.l	#1,d0
	asl.w	#1,d0
	rol.l	#1,d0
	cmp.l	#-1,d2
	beq	gpalet4
	move.b	d2,(a0,d0.w)		*下位８ビットのパレットを設定する
	bra	gpalet5
gpalet4:
	move.b	(a0,d0.w),d3		*下位８ビットのパレットを調べる
	rol.w	#8,d3
gpalet5:
	move	d1,d0
	lsr.w	#8,d0
	ror.l	#1,d0
	asl.w	#1,d0
	rol.l	#1,d0
	ror.w	#8,d2
	cmp.l	#-1,d2
	beq	gpalet6
	move.b	d2,2(a0,d0.w)		*上位８ビットのパレットを設定する
	bra	gpalet7
gpalet6:				*上位８ビットのパレットを調べる
	move.b	2(a0,d0.w),d3		*!!(ROMでは move.b (a0,d0.w),d3 だった)
	ror.w	#8,d3
gpalet7:
	rol.w	#8,d2
	move.l	d3,d0
	move.l	(a7)+,d3
	rts


*****************************************
*	IOCS $8a	_DMAMOVE	*	v1.0(87/03/18,87/05/07)
*****************************************

dmamove::
	cmp.l	#$0000ff00,d2
	bcs	dmamove1		*$ff00バイト以下
	move.l	d2,-(a7)
	move.l	#$0000ff00,d2
	bsr	dmamove1		*$ff00バイト転送
	btst.l	#$0000,d1
	beq	dmamove01
	adda.l	d2,a2			*a2増加
dmamove01:
	btst.l	#$0001,d1
	beq	dmamove02
	suba.l	d2,a2			*a2減少
dmamove02:
	btst.l	#$0002,d1
	beq	dmamove03
	adda.l	d2,a1			*a1増加
dmamove03:
	btst.l	#$0003,d1
	beq	dmamove04
	suba.l	d2,a1			*a1減少
dmamove04:
	move.l	d2,d0
	move.l	(a7)+,d2
	sub.l	d0,d2
	bne	dmamove			*まだデータが残っている
	rts

dmamove1:
	tst.b	DMAMODE
	bne	dmamove1		*前の転送が終了するまで待つ
	move.b	#$8a,DMAMODE		*_DMAMOVE実行中
	move.b	d1,d0
	and.b	#$80,d0			*転送方向
	or.b	#$01,d0			*オートリクエスト/バイト転送
	move.b	d0,_DMA_OCR2
	move.l	a1,_DMA_MAR2
	move.b	d1,d0
	and.b	#$7f,d0			*カウンタ増減
	move.b	d0,_DMA_SCR2
	move.l	a2,_DMA_DAR2
	st	_DMA_CSR2		*ステータスをクリア
	move	d2,_DMA_MTC2		*転送サイズ
	move.b	#$88,_DMA_CCR2		*動作開始
	rts


*****************************************
*	IOCS $7a	_MS_PATST	*	v1.1(91/01/11)
*****************************************

ms_patst::
	move.l	a5,-(sp)
	movem.l	d1-d7/a0-a4,-(sp)
	movea	#$0a7a,a5
	movem.l	d1-d2/a1,$006a(a5)
	st.b	$0064(a5)
	move	$006c(a5),d1
	cmpi	#$000f,d1
	bhi	ms_patst2
	tst.b	$0028(a5)
	beq	ms_patst1
	jsr	$ffa890
	move	$006c(a5),d1		*!!(ROMでは破壊されたd1.wを復帰していなかった)
ms_patst1:
	jmp	$ffa606

ms_patst2:
	jmp	$ffa61e


patchend::

	.end

* End of File ------------------------- *

*	$Log:	ROMPATCH.HA_ $
* Revision 1.1  92/09/14  01:15:56  YuNK
* Initial revision
* 
