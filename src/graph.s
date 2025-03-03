	.title	HIOCS PLUS (graph.s)

*****************************************************************
*	HIOCS version 1.10
*		< GRAPH.HAS >
*	$Id: GRAPH.HA_ 1.1 92/09/14 01:17:30 YuNK Exp $
*
*		Copyright 1990,91,92  SHARP / Y.Nakamura
*****************************************************************


* Include Files ----------------------- *

	.include	iocscall.mac
	.include	hiocs.equ


* Text Section ------------------------ *

	.text

*****************************************
*	IOCS $d3	_TXXLINE	*
*****************************************

txxline::
	movem.l	d1-d7/a1-a3,-(sp)
	lea	_CRTC21,a2
	lea	$0004(a2),a3		*CRTC R23(ビットマスクレジスタ)
	moveq	#0,d0
	move	(a1)+,d0		*描画プレーン番号
	move	(a1)+,d1		*Ｘ座標
	move	(a1)+,d3		*Ｙ座標
	move	(a1)+,d2		*水平線の長さ
	beq	txxline9
	bpl	txxline1
	addq.w	#1,d2
	bra	txxline2
txxline1:
	subq.w	#1,d2
txxline2:
	add.w	d1,d2			*終点のＸ座標
	move	(a1)+,d6		*ラインスタイル
	lea	$e00000,a1
	tst	d0
	bmi	L00173e
	btst.b	#$00,(a2)
	bne	L00174a			*テキスト同時アクセスモード
	and.w	#$0003,d0
	add.w	d0,d0
	swap	d0
	adda.l	d0,a1			*描画プレーンのＶＲＡＭアドレス
	move	#$0200,d0
L001730:
	move	(a2),d7
	move	d0,(a2)			*テキストビットマスクＯＮ
	bsr	txxlpset
	move	d7,(a2)
txxline9:
	movem.l	(sp)+,d1-d7/a1-a3
	rts

L00173e:				*描画プレーン指定が負の場合
	and.w	#$000f,d0		*下位４ビットで描画プレーンを指定
	lsl	#4,d0
	or.w	#$0300,d0		*同時アクセス/ビットマスクＯＮ
	bra	L001730

L00174a:				*描画前に同時アクセスモードだった場合
	move	(a2),d0			*プレーン指定を無視して現在のモードで描画
	or.w	#$0300,d0
	bra	L001730

*	水平描画の実処理

L001772:
	lea	(@f,pc),a0
@@:	rts
txxlxor:				*xorモードで描画
	movea.w	#-1,a0
	bra	L00177c
txxlpset:				*psetモードで描画
	suba.l	a0,a0
L00177c:
	movem.l	TXXMIN.w,d4-d5
	cmp.w	d4,d3
	blt	L001772			*Ｙ座標が範囲外 (小さい)
	cmp.w	d5,d3
	bge	L001772			*		(大きい)
	swap	d4
	swap	d5
	cmp.w	d1,d2
	bge	L001794			*d1.w<=d2.w
	exg.l	d1,d2
L001794:
	cmp.w	d4,d1
	bge	L00179a
	move	d4,d1			*Ｘ始点をクリッピング
L00179a:
	cmp.w	d5,d2
	blt	L0017a2
	move	d5,d2			*Ｘ終点をクリッピング
	subq.w	#1,d2
L0017a2:
	move.b	d6,-(sp)		;move.b	d6,d0	*ラインスタイル
	move	(sp),d6			;lsl	#8,d6
	move.b	(sp)+,d6		;move.b	d0,d6
	move	d6,d0
	swap	d6
	move	d0,d6
	move	TXLLEN.w,d0		*１ラインのバイト数
	mulu.w	d3,d0
	adda.l	d0,a1			*水平線を引く行のＶＲＡＭアドレス
	moveq	#-1,d3
	moveq	#-1,d4
	addq.w	#1,d2			*終点＋１
	move	d1,d3
	move	d2,d4
	and.w	#$000f,d3
	and.w	#$000f,d4
	add.w	d3,d3
	add.w	d4,d4
	move	L001752(pc,d3.w),d3	*始点・終点付近のマスクパターンを得る
	move	L001752(pc,d4.w),d4
	lsr	#5,d1			*1/32
	bcs	L0017e2			*longwordの下位に始点がある
	swap	d3			*	   上位に始点がある
	clr.w	d3
L0017e2:
	lsr	#5,d2			*1/32
	bcs	L0017ee			*longwordの下位に終点がある
	swap	d4			*	   上位に終点がある
	clr.w	d4
L0017ee:
	not.l	d4
	swap	d3			*(上位のマスクパターンを下位にする)
	swap	d4
	move	d2,d5
	sub.w	d1,d5
	beq	txxlword		*始点・終点が同じlongword内にある場合
	bcs	L001772			*始点・終点とも範囲外
	subq.w	#1,d5
	add.w	d1,d1
	add.w	d1,d1
	add.w	d2,d2
	add.w	d2,d2
	cmp.w	TXLLEN.w,d2
	bne	L00180c
	subq.w	#4,d2			*終点が画面の端になる場合
	moveq	#-1,d4			*(終点付近のパターンは描かない)
L00180c:
	move	a0,d0
	bne	L00184c
L001810:				*psetモードで描画
	move.l	a1,-(sp)
	move	sr,d0
	ori.w	#$0700,sr		*割り込み禁止
	move	d4,(a3)			*ビットマスク
	move	d6,(a1,d2.w)		*終点付近のパターン書き込み
	swap	d4
	move	d4,(a3)
	move	d6,2(a1,d2.w)
	swap	d4
	adda.w	d1,a1			*始点のＶＲＡＭアドレス
	move	d3,(a3)
	move	d6,(a1)+		*始点付近のパターン書き込み
	swap	d3
	move	d3,(a3)
	move	d6,(a1)+
	swap	d3
	clr.w	(a3)
	move	d0,sr			*割り込み禁止解除
	move	d5,d0
	beq	L001844			*すでに直線が全て描かれている
	bsr	txxldopset
L001844:
	movea.l	(sp)+,a1
	lea	L001810(pc),a0
	rts

L001752:				*端点付近のマスクパターン
	.dc.w	$0000,$8000,$c000,$e000,$f000,$f800,$fc00,$fe00
	.dc.w	$ff00,$ff80,$ffc0,$ffe0,$fff0,$fff8,$fffc,$fffe

L00184c:				*xorモードで描画
	move.l	a1,-(sp)
	move	sr,d0
	ori.w	#$0700,sr		*割り込み禁止
	move	d4,(a3)			*ビットマスク
	not.w	(a1,d2.w)		*終点付近の反転
	swap	d4
	move	d4,(a3)
	not.w	2(a1,d2.w)
	swap	d4
	adda.w	d1,a1			*始点のＶＲＡＭアドレス
	move	d3,(a3)
	not.w	(a1)+			*始点付近の反転
	swap	d3
	move	d3,(a3)
	not.w	(a1)+
	swap	d3
	clr.w	(a3)
	move	d0,sr			*割り込み禁止解除
	move	d5,d0
	beq	L001880			*すでに直線が全て描かれている
	bsr	txxldoxor
L001880:
	movea.l	(sp)+,a1
	lea	L00184c(pc),a0
	rts

txxlword:				*始点・終点が1longword内にある場合
	add.w	d1,d1
	add.w	d1,d1
	or.l	d4,d3			*マスクパターンを合成
	move	a0,d0
	bne	L0018b6
L001892:				*psetモードで描画
	move	sr,d0
	ori.w	#$0700,sr		*割り込み禁止
	move	d3,(a3)
	move	d6,(a1,d1.w)
	swap	d3
	move	d3,(a3)
	move	d6,2(a1,d1.w)
	swap	d3
	clr.w	(a3)
	move	d0,sr			*割り込み禁止解除
	lea	L001892(pc),a0
	rts
L0018b6:				*xorモードで描画
	move	sr,d0
	ori.w	#$0700,sr		*割り込み禁止
	move	d3,(a3)
	not.w	(a1,d1.w)
	swap	d3
	move	d3,(a3)
	not.w	2(a1,d1.w)
	swap	d3
	clr.w	(a3)
	move	d0,sr			*割り込み禁止解除
	lea	L0018b6(pc),a0
	rts

txxldopset:				*水平線を引く(psetモード)
	lea	(L0018e0,pc),a0
	add	d0,d0
L0018e0:
	subi	#$0020,d0
	bgt	L0018f0			*64バイト(512ドット)描画
L0018e8:
	neg.w	d0
	movea.l	(sp)+,a0
	jmp	L0018f0(pc,d0.w)
L0018f0:
	.rept	16
	move.l	d6,(a1)+
	.endm
	jmp	(a0)

txxldoxor:				*水平線を引く(xorモード)
	lea	(L001918,pc),a0
	add	d0,d0
L001918:
	subi	#$0020,d0
	bgt	L001928			*64バイト(512ドット)描画
L001920:
	neg.w	d0
	movea.l	(sp)+,a0
	jmp	L001928(pc,d0.w)
L001928:
	.rept	16
	not.l	(a1)+
	.endm
	jmp	(a0)

*****************************************
*	IOCS $d4	_TXYLINE	*
*****************************************

txyline::
	movem.l	d1-d7/a1-a3,-(sp)
	lea	_CRTC21,a2
	lea	$0004(a2),a3		*CRTC R23(ビットマスクレジスタ)
	moveq	#0,d0
	move	(a1)+,d0		*描画プレーン番号
	move	(a1)+,d1		*Ｘ座標
	move	(a1)+,d2		*Ｙ座標
	move	(a1)+,d3		*垂直線の長さ
	beq	txyline9
	bpl	txyline1
	addq.w	#1,d3
	bra	txyline2
txyline1:
	subq.w	#1,d3
txyline2:
	add.w	d2,d3			*終点のＹ座標
	move	(a1)+,d6		*ラインスタイル
	lea	$e00000,a1
	tst	d0
	bmi	L001992
	btst.b	#$00,(a2)
	bne	L00199e			*テキスト同時アクセスモード
	and.w	#$0003,d0
	add.w	d0,d0
	swap	d0
	adda.l	d0,a1			*描画プレーンのＶＲＡＭアドレス
	move	#$0200,d0
L001984:
	move	(a2),d7
	move	d0,(a2)			*テキストビットマスクＯＮ
	bsr	txylpset
	move	d7,(a2)
txyline9:
	movem.l	(sp)+,d1-d7/a1-a3
L0019a6:
	rts

L001992:				*描画プレーン指定が負の場合
	and.w	#$000f,d0		*下位４ビットで描画プレーンを指定
	lsl	#4,d0
	or.w	#$0300,d0
	bra	L001984

L00199e:				*描画前に同時アクセスモードだった場合
	move	(a2),d0			*プレーン指定を無視して現在のモードで描画
	or.w	#$0300,d0
	bra	L001984

*	垂直描画の実処理

txylpset:
	cmp.w	TXXMIN.w,d1
	blt.s	L0019a6			*Ｘ座標が範囲外 (小さい)
	cmp.w	TXXMAX.w,d1
	bge.s	L0019a6			*		(大きい)
	movem.l	TXXMIN.w,d4-d5
	cmp.w	d2,d3
	bge	L0019c0			*d2.w<=d3.w
	exg.l	d2,d3
L0019c0:
	cmp.w	d4,d2
	bge	L0019c6
	move	d4,d2			*Ｙ始点をクリッピング
L0019c6:
	cmp.w	d5,d3
	blt	L0019ce
	move	d5,d3			*Ｙ終点をクリッピング
	subq.w	#1,d3
L0019ce:
	sub.w	d2,d3
	bcs.s	L0019a6			*始点・終点とも範囲外
	addq.w	#1,d3			*垂直線の長さ
	move	TXLLEN.w,d4
	mulu.w	d4,d2
	adda.l	d2,a1			*始点のある行のＶＲＡＭアドレス
	move	d1,d0
	lsr	#4,d0
	add.w	d0,d0
	adda.w	d0,a1			*始点のある1wordのＶＲＡＭアドレス
	and.w	#$000f,d1
	move	#$7fff,d0
	ror.w	d1,d0
	move	sr,-(sp)
	ori.w	#$0700,sr		*割り込み禁止
	move	d0,(a3)			*マスクパターン
	moveq	#$ff,d0			*ラインスタイル	%11111111
	cmp.b	d0,d6
	beq	L001a02
	tst.b	d6
	bne	txylpat
	moveq	#0,d0			*		%00000000
L001a02:
	lsl	#4,d4			*16ライン
	move	d3,d1			*垂直線の長さ
	lsr	#4,d1
	lea	L001a12(pc),a0
	bra	L001a14
	.quad
L001a10:				*16ライン描画
	i:=$80*15
	.rept	15
	move	d0,(i.w,a1)
	i:=i-$80
	.endm
	move	d0,(a1)			*合わせて2.wにする
	jmp	(a0)			*
L001a6a:
	jmp	(a0)
L001a12:
	adda.w	d4,a1
L001a14:
	dbra	d1,L001a10
L001a18:
	andi	#$000f,d3		*端数の0～15ライン描画
	lea	(L001a6c,pc),a0
	neg	d3
.if CPU>=68020
	jmp	(L001a6a,pc,d3.w*4)
.else
	add	d3,d3
	add	d3,d3
	jmp	(L001a6a,pc,d3.w)
.endif

*	ラインパターン指定の描画

txylpat:
	moveq	#0,d1
	bra	txylpat_start
txylpat_loop:
	rol.b	#1,d6
	bcc	txylpat_clr

	move	d0,(a1)
	adda	d4,a1
	dbra	d3,txylpat_loop
	bra	L001a6c
txylpat_clr:
	move	d1,(a1)
	adda	d4,a1
txylpat_start:
	dbra	d3,txylpat_loop
L001a6c:
	clr.w	(a3)
txyline_rte::
	move	(sp)+,sr		*割り込み禁止解除
	rts

*****************************************
*	IOCS $d6	_TXBOX		*
*****************************************

txbox::
	movem.l	d1-d7/a1-a4,-(sp)
	lea	_CRTC21,a2
	lea	$0004(a2),a3		*CRTC R23(ビットマスクレジスタ)
	moveq	#0,d4
	move	(a1)+,d4		*描画プレーン番号
	move	(a1)+,d0		*Ｘ座標
	move	(a1)+,d1		*Ｙ座標
	move	(a1)+,d2		*Ｘ方向長さ
	beq	txbox9
	bpl	txbox1
	addq.w	#1,d2
	bra	txbox2
txbox1:
	subq.w	#1,d2
txbox2:
	add.w	d0,d2			*終点のＸ座標
	move	(a1)+,d3		*Ｙ方向長さ
	beq	txbox9
	bpl	txbox3
	addq.w	#1,d3
	bra	txbox4
txbox3:
	subq.w	#1,d3
txbox4:
	add.w	d1,d3			*終点のＹ座標
	move	(a1)+,d6		*ラインスタイル
	lea	$e00000,a1
	tst	d4
	bmi	L001c0e
	btst.b	#$00,(a2)
	bne	L001c1a			*テキスト同時アクセスモード
	and.w	#$0003,d4
	add.w	d4,d4
	swap	d4
	adda.l	d4,a1			*描画プレーンのＶＲＡＭアドレス
	move	#$0200,d4
L001c00:
	move	(a2),d7
	move	d4,(a2)			*テキストビットマスクＯＮ
	bsr	L001c24
	move	d7,(a2)
txbox9:
	movem.l	(sp)+,d1-d7/a1-a4
	rts

L001c0e:				*描画プレーン指定が負の場合
	and.w	#$000f,d4		*下位４ビットで描画プレーンを指定
	lsl	#4,d4
	or.w	#$0300,d4
	bra	L001c00

L001c1a:				*描画前に同時アクセスモードだった場合
	move	(a2),d4			*プレーン指定を無視して現在のモードで描画
	or.w	#$0300,d4
	bra	L001c00

*	ボックス描画の実処理

L001c24:
	cmp.w	d0,d2
	bge	L001c2c			*d0.w<=d2.w
	exg.l	d0,d2
L001c2c:
	cmp.w	d1,d3
	bge	L001c34			*d1.w<=d3.w
	exg.l	d1,d3
L001c34:
	movea.l	a1,a4
	movem.w	d0-d3,-(sp)
	exg.l	d1,d3
	exg.l	d0,d1			*(x0,y0)-(x1,y0)
	bsr	txxlpset		*(d1.w,d3.w)-(d2.w,d3.w)
	movea.l	a4,a1
	movem.w	(sp),d0-d3
	exg.l	d0,d1			*(x0,y1)-(x1,y1)
	bsr	txxlpset
	movea.l	a4,a1
	movem.w	(sp),d0-d3
	exg.l	d0,d1
	exg.l	d0,d2			*(x0,y0)-(x0,y1)
	bsr	txylpset		*(d1.w,d2.w)-(d1.w,d3.w)
	movea.l	a4,a1
	movem.w	(sp)+,d0-d3
	exg.l	d1,d2			*(x1,y0)-(x1,y1)
	bra	txylpset

*****************************************
*	IOCS $d7	_TXFILL		*
*****************************************

txfill::
	movem.l	d1-d7/a1-a4/a6,-(sp)
	lea	_CRTC21,a2
	lea	$0004(a2),a3		*CRTC R23(ビットマスクレジスタ)
	moveq	#0,d4
	move	(a1)+,d4		*描画プレーン番号
	move	(a1)+,d0		*Ｘ座標
	move	(a1)+,d1		*Ｙ座標
	move	(a1)+,d2		*Ｘ方向長さ
	beq	txfill9
	bpl	txfill1
	addq.w	#1,d2
	bra	txfill2
txfill1:
	subq.w	#1,d2
txfill2:
	add.w	d0,d2			*終点のＸ座標
	move	(a1)+,d3		*Ｙ方向長さ
	beq	txfill9
	bpl	txfill3
	addq.w	#1,d3
	bra	txfill4
txfill3:
	subq.w	#1,d3
txfill4:
	add.w	d1,d3			*終点のＹ座標
	move	(a1)+,d6		*ペイントスタイル
	lea	$e00000,a1
	tst	d4
	bmi	L001cd2
	btst.b	#$00,(a2)
	bne	L001cde			*テキスト同時アクセスモード
	and.w	#$0003,d4
	add.w	d4,d4
	swap	d4
	adda.l	d4,a1			*描画プレーンのＶＲＡＭアドレス
	move	#$0200,d4
L001cac:
	move	(a2),-(sp)
	move	d4,(a2)			*テキストビットマスクＯＮ

*	d6.bはtxxlpsetでd6.lの各バイトにコピーされる(偶数ライン目用)
*	一度txxlpsetを呼ぶとa0.lが事前処理を省いたアドレスに書き換わるので
*	ここでd6.hbをa6.lの各バイトにコピーする(奇数ライン目用)
	move	d6,-(sp)
	move	d6,d5
	move.b	(sp)+,d5
	move	d5,d4
	swap	d5
	move	d4,d5
	movea.l	d5,a6

	lea	(txxlpset,pc),a0
	bsr	L001ce8
	move	(sp)+,(a2)
txfill9:
	movem.l	(sp)+,d1-d7/a1-a4/a6
L001ce6:
	rts

L001cd2:				*描画プレーン指定が負の場合
	and.w	#$000f,d4		*下位４ビットで描画プレーンを指定
	lsl	#4,d4
	or.w	#$0300,d4
	bra	L001cac

L001cde:				*描画前に同時アクセスモードだった場合
	move	(a2),d4			*プレーン指定を無視して現在のモードで描画
	or.w	#$0300,d4
	bra	L001cac

*	ボックスフィル/リバース描画の実処理

L001ce8:
	cmp.w	d0,d2
	bge	L001cf0			*d0.w<=d2.w
	exg.l	d0,d2
L001cf0:
	cmp.w	d1,d3
	bge	L001cf8			*d1.w<=d3.w
	exg.l	d1,d3
L001cf8:
	movem.l	TXXMIN.w,d4-d5
	cmp.w	d4,d3
	blt.s	L001ce6			*Ｙ座標が範囲外 (小さい)
	cmp.w	d5,d1
	bge.s	L001ce6			*		(大きい)
	cmp.w	d4,d1
	bge	L001d10
	move	d4,d1			*Ｙ始点をクリッピング
L001d10:
	cmp.w	d5,d3
	blt	L001d18
	move	d5,d3			*Ｙ終点をクリッピング
	subq.w	#1,d3
L001d18:
	move	d3,d7
	sub.w	d1,d7
	exg.l	d0,d1
	exg.l	d0,d3
	movea.w	TXLLEN.w,a4
L001d24:
	jsr	(a0)			*水平線描画
	exg.l	d6,a6			*次のペイントスタイル
	adda.l	a4,a1
	dbra	d7,L001d24
	rts

*****************************************
*	IOCS $d8	_TXREV		*
*****************************************

txrev::
	movem.l	d1-d7/a1-a4/a6,-(sp)
	lea	_CRTC21,a2
	lea	$0004(a2),a3		*CRTC R23(ビットマスクレジスタ)
	moveq	#0,d4
	move	(a1)+,d4		*描画プレーン番号
	move	(a1)+,d0		*Ｘ座標
	move	(a1)+,d1		*Ｙ座標
	move	(a1)+,d2		*Ｘ方向長さ
	beq	txrev9
	bpl	txrev1
	addq.w	#1,d2
	bra	txrev2
txrev1:
	subq.w	#1,d2
txrev2:
	add.w	d0,d2			*終点のＸ座標
	move	(a1)+,d3		*Ｙ方向長さ
	beq	txrev9
	bpl	txrev3
	addq.w	#1,d3
	bra	txrev4
txrev3:
	subq.w	#1,d3
txrev4:
	add.w	d1,d3			*終点のＹ座標
	lea	$e00000,a1
	btst.b	#$00,(a2)
	bne	L001d7c			*テキスト同時アクセスモード
	and.w	#$0003,d4
	add.w	d4,d4
	swap	d4
	adda.l	d4,a1			*描画プレーンのＶＲＡＭアドレス
	move	#$0200,d4
L001d68:
	move	(a2),-(sp)
	move	d4,(a2)			*テキストビットマスクＯＮ
	lea	txxlxor(pc),a0
	bsr	L001ce8
	move	(sp)+,(a2)
txrev9:
	movem.l	(sp)+,d1-d7/a1-a4/a6
	rts

L001d7c:				*描画前に同時アクセスモードだった場合
	move	(a2),d4			*プレーン指定を無視して現在のモードで描画
	or.w	#$0300,d4
	bra	L001d68


*****************************************
*	IOCS $d5	_TXLINE		*
*****************************************

txline::
	movem.l	d1-d7/a1-a4,-(sp)
	lea	_CRTC21,a2
	lea	$0004(a2),a3		*CRTC R23(ビットマスクレジスタ)
	moveq	#0,d4
	move	(a1)+,d4		*描画プレーン番号
	move	(a1)+,d0		*始点Ｘ座標
	move	(a1)+,d1		*始点Ｙ座標
	move	(a1)+,d2		*Ｘ方向長さ
	beq	L001aa4
	bpl	L001aa2
	addq.w	#1,d2
	bra	L001aa4
L001aa2:
	subq.w	#1,d2
L001aa4:
	move	(a1)+,d3		*Ｙ方向長さ
	beq	L001ab0
	bpl	L001aae
	addq.w	#1,d3
	bra	L001ab0
L001aae:
	subq.w	#1,d3
L001ab0:
	add.w	d0,d2			*終点Ｘ座標
	add.w	d1,d3			*終点Ｙ座標
	move	(a1)+,d6		*ラインスタイル
	lea	$e00000,a1
	tst	d4
	bmi	L001ae2
	btst.b	#$00,(a2)
	bne	L001aee			*テキスト同時アクセスモード
	and.w	#$0003,d4
	add.w	d4,d4
	swap	d4
	adda.l	d4,a1			*描画プレーンのＶＲＡＭアドレス
	move	#$0200,d4
L001ad4:
	move	(a2),d7
	move	d4,(a2)			*テキストビットマスクＯＮ
	bsr	L001b06
	move	d7,(a2)
	movem.l	(sp)+,d1-d7/a1-a4
L001b04:
	rts

L001ae2:				*描画プレーン指定が負の場合
	and.w	#$000f,d4		*下位４ビットで描画プレーンを指定
	lsl	#4,d4
	or.w	#$0300,d4		*同時アクセス/ビットマスクＯＮ
	bra	L001ad4

L001aee:				*描画前に同時アクセスモードだった場合
	move	(a2),d4			*プレーン指定を無視して現在のモードで描画
	or.w	#$0300,d4
	bra	L001ad4

L001af6:				*水平線の場合
	exg.l	d1,d4
	bra	txxlpset

L001afc:				*垂直線の場合
	exg.l	d1,d2
	exg.l	d2,d5
	bra	txylpset

*	直線描画の実処理

L001b06:
	bsr	txlclip			*座標のクリッピングを行なう
	bcs.s	L001b04			*線分は不可視
	exg.l	d0,d4
	exg.l	d1,d5
	cmp.w	d3,d5
	beq	L001af6			*水平線の場合
	cmp.w	d2,d4
	beq	L001afc			*垂直線の場合
	bgt	L001b1e			*d2.w<d4.w
	exg.l	d2,d4
	exg.l	d3,d5
L001b1e:
	move	TXLLEN.w,d1
	move	d3,d0
	mulu.w	d1,d0
	adda.l	d0,a1
	move	d2,d0
	lsr	#4,d0
	add.w	d0,d0
	adda.w	d0,a1			*始点のＶＲＡＭアドレス
	sub.w	d2,d4			*dx
	sub.w	d3,d5			*dy
	bcc	L001b3a			*dy>=0
	neg.w	d5
	neg.w	d1
L001b3a:
	movea.w	d1,a0
	move	d2,d0
	and.w	#$000f,d0
	sub.w	#$000f,d0
	neg.w	d0
	moveq	#$ff,d1
	bchg.l	d0,d1			*始点のビット位置
	move	d5,d3
	lea	L001b64(pc),a4
	cmp.w	d4,d3
	bcs	L001b5c			*dx>dy
	lea	L001b96(pc),a4
	exg.l	d3,d4
L001b5c:
	move	d4,d2
	lsr	#1,d2			*e = dx(dy) / 2
	move	d4,d0
	jmp	(a4)

*	dx>dyの直線を描く

L001b64:
	move	sr,-(sp)
	ori.w	#$0700,sr		*割り込み禁止
L001b6a:
	move	d1,(a3)			*ビットマスク
	rol.b	#1,d6			*ラインスタイル
	bcc	L001b8a
	move	#$ffff,(a1)
L001b74:
	ror.w	#1,d1			*Ｘ座標を増す
	bmi	L001b7a
	addq.l	#2,a1			*アドレスが増える
L001b7a:
	subq.w	#1,d0
	bmi	L001b90			*描画が終わった
	add.w	d3,d2			*e += dy
	cmp.w	d4,d2
	bcs	L001b6a			*dx > e
	sub.w	d4,d2			*e -= dx
	adda.l	a0,a1			*Ｙ座標を増す(減らす)
	bra	L001b6a
L001b8a:
	clr.w	(a1)
	bra	L001b74
L001b90:
	clr.w	(a3)
txline_rte::
	move	(sp)+,sr		*割り込み禁止解除
	rts

*	dx<=dyの直線を描く

L001b96:
	move	sr,-(sp)
	ori.w	#$0700,sr		*割り込み禁止
L001b9c:
	move	d1,(a3)			*ビットマスク
	rol.b	#1,d6			*ラインスタイル
	bcc	L001bbc
	move	#$ffff,(a1)
L001ba6:
	adda.l	a0,a1			*Ｙ座標を増す(減らす)
	subq.w	#1,d0
	bmi	L001b90			*描画が終わった
	add.w	d3,d2			*e += dx
	cmp.w	d4,d2
	bcs	L001b9c			*dy > e
	sub.w	d4,d2			*e -= dy
	ror.w	#1,d1			*Ｘ座標を増す
	bmi	L001b9c
	addq.l	#2,a1			*アドレスが増える
	bra	L001b9c
L001bbc:
	clr.w	(a1)
	bra	L001ba6



*****************************************
*	IOCS $b0	_DRAWMODE	*
*****************************************

drawmode::
	move	(DRAWMODE),d0
	cmpi	#-1,d1
	beq	L001d92

	move	d1,(DRAWMODE)
L001d92:
	rts

*****************************************
*	IOCS $b9	_BOX		*
*****************************************

box::
	move	GRCOLMAX.w,d0
	beq	L001e0e			*グラフィックは使用不可
	cmp.w	$0008(a1),d0
	bcs	L001e12			*パレットコードが範囲外
	movem.l	d1-d7/a1-a4,-(sp)
	move	(a1)+,d0		*始点Ｘ座標
	move	(a1)+,d1		*　　Ｙ座標
	move	(a1)+,d2		*終点Ｘ座標
	move	(a1)+,d3		*　　Ｙ座標
	move	(a1)+,d7		*パレットコード
	move	(a1),d6			*ラインスタイル
	bsr	L002876
	movem.l	(sp)+,d1-d7/a1-a4
	moveq	#0,d0
	rts

*****************************************
*	IOCS $b8	_LINE		*
*****************************************

line::
	move	GRCOLMAX.w,d0
	beq	L001e0e			*グラフィックは使用不可
	cmp.w	$0008(a1),d0
	bcs	L001e12			*パレットコードが範囲外
	movem.l	d1-d7/a1-a4,-(sp)
	move	(a1)+,d0		*始点Ｘ座標
	move	(a1)+,d1		*　　Ｙ座標
	move	(a1)+,d2		*終点Ｘ座標
	move	(a1)+,d3		*　　Ｙ座標
	move	(a1)+,d7		*パレットコード
	move	(a1),d6			*ラインスタイル
	bsr	L0028dc
	movem.l	(sp)+,d1-d7/a1-a4
	moveq	#0,d0
	rts

*****************************************
*	IOCS $bb	_CIRCLE		*
*****************************************

circle::
	move	GRCOLMAX.w,d0
	beq	L001e0e			*グラフィックは使用不可
	cmp.w	$0006(a1),d0
	bcs	L001e12			*パレットコードが範囲外
	movem.l	d1-d7/a1-a5,-(sp)
	move	(a1)+,d4		*中心Ｘ座標
	move	(a1)+,d5		*　　Ｙ座標
	move	(a1)+,d1		*半径
	move	(a1)+,d7		*パレットコード
	move	(a1)+,d2		*円弧開始角度
	move	(a1)+,d3		*　　終了角度
	move	(a1),d6			*比率
	bsr	L002468
	movem.l	(sp)+,d1-d7/a1-a5
	moveq	#0,d0
	rts

*	グラフィックは使用不可なのでエラー

L001e0e:
	moveq	#-1,d0
	rts

*	パレットコードが範囲外なのでエラー

L001e12:
	moveq	#-2,d0
	rts

*****************************************
*	IOCS $ba	_FILL		*
*****************************************

fill::
	move	GRCOLMAX.w,d0
	beq	L001e0e			*グラフィックは使用不可
	cmp.w	$0008(a1),d0
	bcs	L001e12			*パレットコードが範囲外
	movem.l	d1-d7/a1-a4,-(sp)
	move	(a1)+,d0		*始点Ｘ座標
	move	(a1)+,d1		*　　Ｙ座標
	move	(a1)+,d2		*終点Ｘ座標
	move	(a1)+,d3		*　　Ｙ座標
	move	(a1),d7			*パレットコード
	bsr	L002b74
	movem.l	(sp)+,d1-d7/a1-a4
	moveq	#0,d0
	rts

*****************************************
*	IOCS $bc	_PAINT		*
*****************************************

paint::
	move	GRCOLMAX.w,d0
	beq	L001e0e			*グラフィックは使用不可
	cmp.w	$0004(a1),d0
	bcs	L001e12			*パレットコードが範囲外
	movem.l	d1-d7/a1-a5,-(sp)
	move	(a1)+,d4		*始点Ｘ座標
	move	(a1)+,d5		*　　Ｙ座標
	move	(a1)+,d7		*パレットコード
	move.l	(a1)+,d0		*作業領域先頭アドレス
	move.l	(a1),d1			*	 終了アドレス
	bsr	L002288
	movem.l	(sp)+,d1-d7/a1-a5
	moveq	#0,d0
	rts

*****************************************
*	IOCS $b7	_POINT		*
*****************************************

point::
	tst	GRCOLMAX.w
	beq	L001e0e			*グラフィックは使用不可
	movem.l	d1-d7/a1-a6,-(sp)
	move.l	a1,-(sp)
	move	(a1)+,d4		*Ｘ座標
	move	(a1)+,d5		*Ｙ座標
	bsr	L001f3c			*グラフィックＶＲＡＭアドレスを求める
	bcs	L001e88			*画面の範囲外
	move	(a0),d0
L001e7a:
	movea.l	(sp)+,a1
	move	d0,$0004(a1)
	movem.l	(sp)+,d1-d7/a1-a6
	moveq	#0,d0
	rts

L001e88:
	clr.w	d0
	bra	L001e7a

*****************************************
*	IOCS $b6	_PSET		*
*****************************************

pset::
	move	GRCOLMAX.w,d0
	beq	L001ede			*グラフィックは使用不可
	cmp.w	$0004(a1),d0
	bcs	L001ee2			*パレットコードが範囲外
	movem.l	d1-d7/a1-a6,-(sp)
	move	(a1)+,d4		*Ｘ座標
	move	(a1)+,d5		*Ｙ座標
	move	(a1),d7			*描画パレットコード
	bsr	L001f3c			*グラフィックＶＲＡＭアドレスを求める
	bcs	L001eaa			*画面の範囲外
	move	d7,(a0)
L001eaa:
	movem.l	(sp)+,d1-d7/a1-a6
	moveq	#0,d0
	rts

*****************************************
*	IOCS $bd	_SYMBOL		*
*****************************************

symbol::
	move	GRCOLMAX.w,d0
	beq	L001ede			*グラフィックは使用不可
	cmp.w	$000a(a1),d0
	bcs	L001ee2			*パレットコードが範囲外
	movem.l	d1-d7/a1-a5,-(sp)
	move	(a1)+,d4		*Ｘ座標
	move	(a1)+,d5		*Ｙ座標
	movea.l	(a1)+,a0		*文字列データアドレス
	move.b	(a1)+,d2		*横倍率
	move.b	(a1)+,d3		*縦倍率
	move	(a1)+,d7		*パレットコード
	move.b	(a1)+,d1		*フォントタイプ
	move.b	(a1),d6			*角度指定
	bsr	L001f7e
	movem.l	(sp)+,d1-d7/a1-a5
	moveq	#0,d0
	rts

L001ede:				*グラフィックは使用不可
	bra	L001e0e

L001ee2:				*パレットコードが範囲外
	bra	L001e12

*****************************************
*	IOCS $b5	_WIPE		*
*****************************************

wipe::
	tst	GRCOLMAX.w
	beq	L001ede			*グラフィックは使用不可
	movem.l	d1-d7/a1-a4,-(sp)
	bsr	L002bca
	movem.l	(sp)+,d1-d7/a1-a4
	moveq	#0,d0
	rts

*****************************************
*	IOCS $be	_GETGRM		*
*****************************************

getgrm::
	tst	GRCOLMAX.w
	beq	L001ede			*グラフィックは使用不可
	movem.l	d1-d7/a1-a4,-(sp)
	move	(a1)+,d0		*始点Ｘ座標
	move	(a1)+,d1		*　　Ｙ座標
	move	(a1)+,d2		*終点Ｘ座標
	move	(a1)+,d3		*　　Ｙ座標
	movea.l	(a1)+,a2		*バッファ先頭アドレス
	movea.l	(a1),a3			*	 終了アドレス
	bsr	L0020c6
	movem.l	(sp)+,d1-d7/a1-a4
	rts

*****************************************
*	IOCS $bf	_PUTGRM		*
*****************************************

putgrm::
	tst	GRCOLMAX.w
	beq	L001ede			*グラフィックは使用不可
	movem.l	d1-d7/a1-a4,-(sp)
	move	(a1)+,d0		*始点Ｘ座標
	move	(a1)+,d1		*　　Ｙ座標
	move	(a1)+,d2		*終点Ｘ座標
	move	(a1)+,d3		*　　Ｙ座標
	movea.l	(a1)+,a2		*バッファ先頭アドレス
	movea.l	(a1),a3			*	 終了アドレス
	bsr	L0020ca
	movem.l	(sp)+,d1-d7/a1-a4
	rts



*	グラフィックＶＲＡＭアドレスを求める

L001f3c:
	cmp.w	GRXMIN.w,d4
	blt	L001f74			*Ｘ座標が範囲外 (小さい)
	cmp.w	GRXMAX.w,d4
	bgt	L001f74			*		(大きい)
	cmp.w	GRYMIN.w,d5
	blt	L001f74			*Ｙ座標が範囲外 (小さい)
	cmp.w	GRYMAX.w,d5
	bgt	L001f74			*		(大きい)
	moveq	#0,d0
	move	d5,d0
	swap	d0
	lsr.l	#6,d0			*1024倍(512×512)
	btst.b	#$02,GRLLEN+2.w
	bne	L001f66
	add.l	d0,d0			*2048倍(1024×1024)
L001f66:
	movea.l	GRADR.w,a0		*グラフィックＶＲＡＭ先頭アドレス
	adda.l	d0,a0
	adda.w	d4,a0
	adda.w	d4,a0
	tst	d0
	rts
L001f74:
	ori.b	#$01,ccr		*座標が画面の範囲外
	rts



L001f7a:	.dc.b	6,8,12
	.even

*	シンボル描画の実処理

L001f7e:
	link	a6,#-106
	move.l	GRXMIN.w,-$0066(a6)
	move.l	GRXMAX.w,-$0062(a6)
	clr.l	-$006a(a6)
	cmp.b	#$03,d1			*フォントタイプ
	bcs	L001f9a
	moveq	#$02,d1			*24×24
L001f9a:
	and.w	#$00ff,d1
	move.b	L001f7a(pc,d1.w),d1	*フォントタイプ→サイズ
	move	d1,-$0012(a6)
	lea	-$0008(a6),a4
	lea	-$0010(a6),a5
	move	d4,(a4)			*Ｘ座標
	move	d5,(a5)			*Ｙ座標
	and.w	#$00ff,d2		*横倍率
	bne	L001fba
	moveq	#$01,d2
L001fba:
	and.w	#$00ff,d3		*縦倍率
	bne	L001fc2
	moveq	#$01,d3
L001fc2:
	move	d2,d0
	move	d3,d1
	subq.w	#1,d0
	subq.w	#1,d1
	bsr	L002096
	move	d2,-$0002(a6)		*横倍率
	move	d3,-$000a(a6)		*縦倍率
	move	d0,-$0004(a6)
	move	d1,-$000c(a6)
	lea	-$005e(a6),a1		*フォントデータ用バッファ
L001fe2:
	move	-$0012(a6),d1		*フォントサイズ
	swap	d1
	clr.w	d1
	move.b	(a0)+,d1		*文字列データを得る
	beq	L002092
		bpl	L00200a		;ASCII
	cmp.b	#$a0,d1
	bcs	L002002
	cmp.b	#$e0,d1
	bcs	L00200a
L002002:				*２バイト文字の場合
	move.b	d1,-(sp)		;lsl	#8,d1
	move	(sp)+,d1		;
	move.b	(a0),d1
	beq	L00200a
	addq.l	#1,a0
L00200a:
	movem.l	a0/a5,-(sp)
	movea.l	-$006a(a6),a5		*(=0)
	movea.l	_FNTGET*4+$000400.w,a0
	jsr	(a0)			*フォントパターンを得る
	movem.l	(sp)+,a0/a5
	move	(a1),d6			*Ｘ方向ドット数
	subq.w	#1,d6
	lsr	#3,d6
	addq.w	#1,d6			*Ｘ方向バイト数
	move	(a4),$0002(a4)		*横座標
	move	(a1),d4			*Ｘ方向ドット数
L002028:
	move	(a5),$0002(a5)		*縦座標
	move	$0002(a1),d5		*Ｙ方向ドット数
	lea	$0004(a1),a2		*フォントパターン
L002034:
	lea	$00(a2,d6.w),a3		*次ラインのデータアドレス
	move.l	a3,-(sp)
L00203a:				*フォント１ライン分を左シフトする
	move.b	-(a3),d0
	roxl.b	#1,d0
	move.b	d0,(a3)
	cmpa.l	a2,a3
	bne	L00203a
	roxr.b	#1,d0			*左端の１ドットを調べる
	bpl	L00206c			*ドットがないので描画しない
	move	-$0006(a6),d0		*Ｘ座標
	move	-$000e(a6),d1		*Ｙ座標
	move	d0,d2
	move	d1,d3
	add.w	$0004(a4),d2		*Ｘ倍率－１
	add.w	$0004(a5),d3		*Ｙ倍率－１
	movem.l	d4-d6/a0-a1/a5,-(sp)
	movea.l	-$006a(a6),a5		*(=0)
	bsr	L002b74			*(d0.w,d1.w)-(d2.w,d3.w)のボックスフィル描画
	movem.l	(sp)+,d4-d6/a0-a1/a5
L00206c:
	move	-$000a(a6),d0		*縦倍率
	add.w	d0,$0002(a5)
	movea.l	(sp)+,a2
	subq.w	#1,d5
	bne	L002034			*次ラインへ
	move	-$0002(a6),d0		*横倍率
	add.w	d0,$0002(a4)
	subq.w	#1,d4
	bne	L002028			*次ドットへ
	move	-$0002(a6),d0
	muls.w	(a1),d0			*フォントの横サイズ
	add.w	d0,(a4)
	bra	L001fe2
L002092:
	unlk	a6
	rts

L002096:
	subq.b	#1,d6			*角度指定
	bcs	L0020a6
	beq	L0020a8
	subq.b	#1,d6
	beq	L0020b0
	exg.l	a4,a5			*270度回転
	neg.w	d1
	neg.w	d3
L0020a6:				*回転しない
	rts
L0020a8:				*90度回転
	exg.l	a4,a5
	neg.w	d0
	neg.w	d2
	rts
L0020b0:				*180度回転
	neg.w	d0
	neg.w	d2
	neg.w	d1
	neg.w	d3
	rts



*	グラフィックは使用不可なのでエラー

L0020ba:
	moveq	#-1,d0
	rts

*	座標が範囲外なのでエラー

L0020be:
	moveq	#-2,d0
	rts

*	バッファが不足しているのでエラー

L0020c2:
	moveq	#-3,d0
	rts

*	グラフィック読み込み(GETGRM)実処理

L0020c6:
	moveq	#0,d7
	bra	L0020cc

*	グラフィック書き込み(PUTGRM)実処理

L0020ca:
	moveq	#$ff,d7
L0020cc:
	tst	GRCOLMAX.w
	beq	L0020ba			*グラフィックは使用不可
	cmp.w	d0,d2
	bge	L0020d8			*d2.w>=d0.w
	exg.l	d0,d2
L0020d8:
	cmp.w	d1,d3
	bge	L0020de			*d3.w>=d1.w
	exg.l	d1,d3
L0020de:
	cmp.w	GRXMIN.w,d0
	blt	L0020be			*Ｘ始点が範囲外
	cmp.w	GRXMAX.w,d2
	bgt	L0020be			*Ｘ終点が範囲外
	cmp.w	GRYMIN.w,d1
	blt	L0020be			*Ｙ始点が範囲外
	cmp.w	GRYMAX.w,d3
	bgt	L0020be			*Ｙ終点が範囲外
	sub.w	d0,d2
	sub.w	d1,d3
	move	d0,d4
	move	d1,d5
	bsr	L002132
	move	d2,d0
	addq.w	#1,d0			*Ｘ方向長さ
	move	d3,d1
	addq.w	#1,d1			*Ｙ方向長さ
	mulu.w	d1,d0			*描画エリアの大きさ
	jsr	(a1)			*必要なバッファサイズを求める
	subq.l	#1,d0
	add.l	a2,d0
	cmp.l	a3,d0
	bhi	L0020c2			*バッファが不足している
	moveq	#0,d0
	move	d5,d0
	swap	d0
	lsr.l	#6,d0			*1024倍(512×512)
	btst.b	#$02,GRLLEN+2.w
	bne	L002126
	add.l	d0,d0			*2048倍(1024×1024)
L002126:
	movea.l	GRADR.w,a0
	adda.l	d0,a0
	adda.w	d4,a0
	adda.w	d4,a0			*処理開始ＶＲＡＭアドレス
	jmp	(a4)			*読み込み/書き込み処理へ

L002132:
	moveq	#$04,d1			*65536色モード
	move	GRCOLMAX.w,d0
	bmi	L002142
	moveq	#$02,d1			*256色モード
	tst.b	d0
	bmi	L002142
	moveq	#0,d1			*16色モード
L002142:
	lea	L00215a(pc),a1
	adda.w	L00215a(pc,d1.w),a1
	tst	d7
	bne	L002150
	addq.w	#6,d1			*読み込みの場合
L002150:
	lea	L002160(pc),a4
	adda.w	L002160(pc,d1.w),a4
	rts

L00215a:
	.dc.w	L00216c-L00215a
	.dc.w	L002174-L00215a
	.dc.w	L002172-L00215a

L002160:
	.dc.w	L0021fe-L002160		*PUTGRM
	.dc.w	L002256-L002160
	.dc.w	L00226e-L002160
	.dc.w	L002176-L002160		*GETGRM
	.dc.w	L0021d0-L002160
	.dc.w	L0021e8-L002160

*	描画サイズから必要なバッファサイズを求める

L00216c:				*16色
	addq.l	#1,d0
	lsr.l	#1,d0
	rts

L002172:				*65536色
	lsl.l	#1,d0
L002174:				*256色
	rts

*	グラフィックＶＲＡＭ読み込み処理

L002176:				*16色
	btst.l	#$00,d2
	beq	L00219e
	lsr	#1,d2			*Ｘドット数が偶数
L00217e:
	movea.l	a0,a1
	move	d2,d1
L002182:
	move.l	(a1)+,d0		*２ドット読み込み
	move.l	d0,d4
	swap	d4
	lsl.b	#4,d4
	or.b	d4,d0			*１バイトにパックする
	move.b	d0,(a2)+
	dbra	d1,L002182
	adda.l	GRLLEN.w,a0
	dbra	d3,L00217e
	moveq	#0,d0
	rts

L00219e:				*Ｘドット数が奇数
	movea.l	a0,a1
	move	d2,d1
L0021a2:
	move	(a1)+,d0
	lsl.b	#4,d0
	subq.w	#1,d1
	bcs	L0021be			*右端の１ドットの場合
L0021aa:
	or.w	(a1)+,d0
	move.b	d0,(a2)+
	dbra	d1,L0021a2
	adda.l	GRLLEN.w,a0
	dbra	d3,L00219e
	moveq	#0,d0
	rts
L0021be:				*次の行のドットとパックする
	adda.l	GRLLEN.w,a0
	movea.l	a0,a1
	move	d2,d1
	dbra	d3,L0021aa
L0021ca:				*奇数ドットで終わった場合
	move.b	d0,(a2)+
	moveq	#0,d0
	rts

L0021d0:				*256色
	movea.l	a0,a1
	move	d2,d1
L0021d4:
	move	(a1)+,d0
	move.b	d0,(a2)+
	dbra	d1,L0021d4
	adda.l	GRLLEN.w,a0
L0021e0:
	dbra	d3,L0021d0
	moveq	#0,d0
	rts

L0021e8:				*65536色
	movea.l	a0,a1
	move	d2,d1
L0021ec:
	move	(a1)+,(a2)+
	dbra	d1,L0021ec
	adda.l	GRLLEN.w,a0
L0021f6:
	dbra	d3,L0021e8
	moveq	#0,d0
	rts

*	グラフィックＶＲＡＭ書き込み処理

L0021fe:				*16色
	btst.l	#$00,d2
	beq	L002224
	lsr	#1,d2			*Ｘドット数が偶数
L002206:
	movea.l	a0,a1
	move	d2,d1
L00220a:
	move.b	(a2)+,d0
	move.b	d0,d4			*パックデータを分離する
	lsr.b	#4,d0
	move	d0,(a1)+
	move	d4,(a1)+
	dbra	d1,L00220a
	adda.l	GRLLEN.w,a0
	dbra	d3,L002206
	moveq	#0,d0
	rts

L002224:				*Ｘドット数が奇数
	movea.l	a0,a1
	move	d2,d1
L002228:
	move.b	(a2)+,d0
	move.b	d0,d4
	ror.b	#4,d0
	move	d0,(a1)+
	subq.w	#1,d1
	bcs	L002246			*右端の１ドットの場合
L002234:
	move	d4,(a1)+
	dbra	d1,L002228
	adda.l	GRLLEN.w,a0
	dbra	d3,L002224
	moveq	#0,d0
	rts
L002246:				*分離したデータを次の行に持ち越す
	adda.l	GRLLEN.w,a0
	movea.l	a0,a1
	move	d2,d1
L00224e:
	dbra	d3,L002234
	moveq	#0,d0
	rts

L002256:				*256色
	movea.l	a0,a1
	move	d2,d1
L00225a:
	move.b	(a2)+,d0
	move	d0,(a1)+
	dbra	d1,L00225a
	adda.l	GRLLEN.w,a0
L002266:
	dbra	d3,L002256
	moveq	#0,d0
	rts

L00226e:				*65536色
	movea.l	a0,a1
	move	d2,d1
L002272:
	move	(a2)+,(a1)+
	dbra	d1,L002272
	adda.l	GRLLEN.w,a0
	dbra	d3,L00226e
	moveq	#0,d0
	rts



L002284:
	unlk	a6
	rts

*	ペイントの実処理

L002288:
	link	a6,#-64
	move.l	GRXMIN.w,-$0040(a6)
	move.l	GRXMAX.w,-$003c(a6)
	move.l	GRLLEN.w,-$0038(a6)
	cmp.l	d0,d1
	bcs	L002284			*作業領域がない
	move.l	d0,-$002c(a6)		*作業領域先頭アドレス
	sub.l	#$0000001f,d1
	move.l	d1,-$0028(a6)		*作業領域終了アドレス
	move.l	d0,-$0034(a6)
	move.l	d0,-$0030(a6)
	move	d4,d1
	movea.w	d5,a4
	bsr	L001f3c			*グラフィックＶＲＡＭアドレスを求める
	bcs	L002284			*画面の範囲外
	cmp.w	(a0),d7
	beq	L002284			*すでにペイントされている
	move	d7,d0			*パレットコード
	swap	d7
	move	d0,d7
	move	(a0),d6			*ペイント領域色
	move	-$0040(a6),d4		*GRXMIN
	move	-$003c(a6),d5		*GRXMAX
	bsr	L00232a			*ペイント開始位置から左右の境界を検索
	move.l	-$0024(a6),-$0018(a6)	*-$24:領域左端の座標 / -$22:ＶＲＡＭアドレス
	move.l	-$0020(a6),-$0014(a6)	*-$1e:領域右端の座標 / -$1c:ＶＲＡＭアドレス
	move.l	-$001c(a6),-$0010(a6)
	bsr	L0023d8			*開始ラインから上下へ走査を行なう
L0022ee:
	movea.l	-$0030(a6),a1		*バッファ読み出しポインタ
	cmpa.l	-$0034(a6),a1		*	 書き込みポインタ
	beq	L002284			*バッファが空になったのでペイント終了
	lea	$0020(a1),a1		*ポインタを先に進める
	cmpa.l	-$0028(a6),a1
	bls	L002306
	movea.l	-$002c(a6),a1		*リングバッファが１周した
L002306:
	move.l	a1,-$0030(a6)
	movea.w	(a1)+,a2		*ペイント方向
	movea.w	(a1)+,a4		*Ｙ座標
	move.l	(a1)+,-$0018(a6)	*現在ラインについて
	move.l	(a1)+,-$0014(a6)	*領域左端の座標/ＶＲＡＭアドレス
	move.l	(a1)+,-$0010(a6)	*領域右端の座標/ＶＲＡＭアドレス
	move.l	(a1)+,-$000c(a6)	*親ラインについて
	move.l	(a1)+,-$0008(a6)	*領域左端の座標/ＶＲＡＭアドレス
	move.l	(a1)+,-$0004(a6)	*領域右端の座標/ＶＲＡＭアドレス
	bsr	L002388			*上下ラインの走査を行なう
	bra	L0022ee

*	開始位置から左右の境界を検索する

L00232a:
	move	d7,(a0)			*１ドット描画
	move.l	a0,-(sp)
	move	d1,-(sp)
	sub.w	d4,d1
	subq.w	#1,d1			*開始位置から左端までのドット数－２
	bcc	L00233e
L002336:				*ペイントで画面左端に達した
	move	d7,(a0)
	move	d4,d1
	bra	L00234c
L00233c:
	move	d7,(a0)			*１ドット描画
L00233e:				*左にペイントしながら境界を検索する
	cmp.w	-(a0),d6
	dbne	d1,L00233c
	beq	L002336			*左端までペイント領域になる場合
	addq.l	#2,a0
	addq.w	#1,d1
	add.w	d4,d1			*領域左端の座標
L00234c:
	move	d1,-$0024(a6)
	move.l	a0,-$0022(a6)
	move	d5,d1
	sub.w	(sp)+,d1
	subq.w	#1,d1			*開始位置から右端までのドット数－２
	bcs	L002362
	movea.l	(sp)+,a0
	addq.l	#2,a0
	bra	L00236c
L002362:
	movea.l	(sp)+,a0
L002364:				*ペイントで画面右端に達した
	move	d7,(a0)
	move	d5,d1
	bra	L00237c
L00236a:
	move	d7,(a0)+		*１ドット描画
L00236c:				*右にペイントしながら境界を検索する
	cmp.w	(a0),d6
	dbne	d1,L00236a
	beq	L002364			*右端までペイント領域になる場合
	subq.l	#2,a0
	addq.w	#1,d1
	sub.w	d5,d1
	neg.w	d1			*領域右端の座標
L00237c:
	move	d1,-$001e(a6)
	move.l	a0,-$001c(a6)
L002386:
L0023d6:
	rts

*	現在ラインから上下へ走査を行なう

L002388:
	cmpa.w	-$003e(a6),a4		*GRYMIN
	beq	L002396			*画面の最上行の場合
	lea	-$0001(a4),a5
	moveq	#0,d0
	bsr	L0023a2			*１ライン上の走査を行なう
L002396:
	cmpa.w	-$003a(a6),a4		*GRYMAX
	beq	L002386			*画面の最下行の場合
	lea	$0001(a4),a5
	moveq	#$ff,d0
L0023a2:				*上下ラインの走査を行なう
	movea.w	d0,a3			*ペイント方向
	move	a2,d1
	eor.w	d0,d1
	beq	L0023f4			*親ラインのペイント方向と同方向の場合
	move	-$000c(a6),d1		*親ラインの領域左端の座標
	cmp.w	d4,d1			*GRXMIN
	beq	L0023c0
	subq.w	#1,d1
	move	d1,d3
	move	-$0018(a6),d1		*現在ラインの領域左端の座標
	movea.l	-$0016(a6),a0		*		　　　 ＶＲＡＭアドレス
	bsr	L002400			*次の走査を行なう(左側)
L0023c0:
	move	-$0006(a6),d1		*親ラインの領域右端の座標
	cmp.w	d5,d1			*GRTXMAX
	beq	L002386
	movea.l	-$0004(a6),a0		*親ラインの領域右端のＶＲＡＭアドレス
	move	-$0012(a6),d3		*現在ラインの領域右端の座標
	addq.l	#2,a0
	addq.w	#1,d1
	bra	L002410			*次の走査を行なう(右側)

*	開始ラインから上下へ走査を行なう

L0023d8:
	cmpa.w	-$003e(a6),a4		*GRYMIN
	beq	L0023e6			*画面の最上行の場合
	lea	-$0001(a4),a5
	moveq	#0,d0
	bsr	L0023f2			*１ライン上の走査を行なう
L0023e6:
	cmpa.w	-$003a(a6),a4		*GRYMAX
	beq.s	L0023d6			*画面の最下行の場合
	lea	$0001(a4),a5
	moveq	#$ff,d0
L0023f2:				*上下ラインの走査を行なう
	movea.w	d0,a3
L0023f4:				*親ラインについて
	move	-$0012(a6),d3		*領域右端の座標
	movea.l	-$0016(a6),a0		*領域左端のＶＲＡＭアドレス
	move	-$0018(a6),d1		*領域左端の座標
L002400:
	move	-$0036(a6),d0		*GRLLEN
	move	a3,d2
	bne	L00240a			*走査ラインは下
	neg.w	d0			*	　　 上
L00240a:
	adda.w	d0,a0			*走査開始ＶＲＡＭアドレス
	bra	L002410
L00240e:
	addq.w	#1,d1
L002410:
	cmp.w	d3,d1
	bhi	L002466			*走査が終了した
	cmp.w	(a0)+,d6		*境界を検索する
	bne	L00240e
	subq.l	#2,a0			*境界を発見した
	bsr	L002422
	addq.l	#2,a0
	addq.w	#1,d1
	bra	L002410

*	ペイントした領域の情報をバッファに入れる

L002422:
	bsr	L00232a			*ペイントしながら左右の境界を検索
	movea.l	-$0034(a6),a1		*バッファ書き込みポインタ
	lea	$0020(a1),a1		*ポインタを先に進める
	cmpa.l	-$0028(a6),a1
	bls	L002438
	movea.l	-$002c(a6),a1		*リングバッファが１周した
L002438:
	cmpa.l	-$0030(a6),a1
	beq	L002466			*バッファが一杯なのでなにもしない
	move.l	a1,-$0034(a6)
	move	a3,(a1)+		*ペイント方向 0:上/-1:下
	move	a5,(a1)+		*Ｙ座標
	move.l	-$0024(a6),(a1)+	*現在ラインについて
	move.l	-$0020(a6),(a1)+	*領域左端の座標/ＶＲＡＭアドレス
	move.l	-$001c(a6),(a1)+	*領域右端の座標/ＶＲＡＭアドレス
	move.l	-$0018(a6),(a1)+	*親ラインについて
	move.l	-$0014(a6),(a1)+	*領域左端の座標/ＶＲＡＭアドレス
	move.l	-$0010(a6),(a1)+	*領域右端の座標/ＶＲＡＭアドレス
	move	-$001e(a6),d1		*領域右端の座標
	movea.l	-$001c(a6),a0		*ＶＲＡＭアドレス
L002466:
	rts



*	円描画の実処理

L002468:
	link	a6,#-82
	move.l	GRXMIN.w,-$004e(a6)
	move.l	GRXMAX.w,-$004a(a6)
	clr.l	-$0052(a6)
	move	d4,-$0004(a6)		*中心Ｘ座標
	move	d5,-$0002(a6)		*中心Ｙ座標
	move	d6,-$0046(a6)		*比率
	clr.w	-$0012(a6)
	clr.w	-$0010(a6)
	clr.w	-$0014(a6)
	moveq	#$ff,d0
	tst	d2			*円弧開始角度
	bpl	L0024a0
	neg.w	d2			*扇型を描く
	move	d0,-$0012(a6)
L0024a0:
	tst	d3			*円弧終了角度
	bpl	L0024aa
	neg.w	d3			*扇型を描く
	move	d0,-$0010(a6)
L0024aa:
	cmp.w	d2,d3
	bcc	L0024b2
	move	d0,-$0014(a6)		*円を描く向き
L0024b2:
	tst	d1			*半径
	bpl	L0024ba
	move	#$7fff,d1
L0024ba:
	move	d1,-$0008(a6)
	move	d1,-$000a(a6)
	clr.w	-$0006(a6)
	bsr	L0024d0
	bsr	L0025c4
	unlk	a6
L0024ce:
	rts


L0024d0:
	lea	-$0024(a6),a0
	moveq	#8-1,d1
	move.b	#%10010110,d0
L0024da:
	clr.w	(a0)+
	lsl.b	#1,d0
	bcc	L0024e6
	move.b	#$01,-$0001(a0)
L0024e6:
	dbra	d1,L0024da
	move	d3,d0			*終了角度
	bsr	L002522
	move	d1,-$000c(a6)
	move.b	#$20,(a0)
	move	d2,d0			*開始角度
	bsr	L002522
	move	d1,-$000e(a6)
	bset.b	#$06,(a0)
	btst.b	#$05,(a0)
	beq	L00250e
	tst	-$0014(a6)
	beq	L0024ce			*完全に描かれる1/8円はない
L00250e:				*1/8円が完全に描かれる範囲を調べる
	addq.w	#1,d6
	and.w	#$0007,d6
	bsr	L00255a
	btst.b	#$05,(a0)
	bne	L0024ce
	bset.b	#$07,(a0)
	bra	L00250e


L002522:
	move	#45,d6
	moveq	#0,d1
	cmpi.w	#360,d0
	bls	L002532
	move	#360,d0
L002532:
	sub.w	d6,d0
	bls	L00253a
	addq.w	#1,d1
	bra	L002532
L00253a:
	add.w	d6,d0
	move	d1,-(sp)
	lsr	#1,d1
	bcc	L002546
	sub.w	d6,d0
	neg.w	d0
L002546:
	moveq	#-1,d1
	cmp.w	d6,d0
	beq	L002558			*45ﾟ,135ﾟ,225ﾟ,315ﾟの場合
	moveq	#0,d1
	move.b	L002566(pc,d0.w),d1
	mulu.w	-$0008(a6),d1		*半径
	lsr.l	#8,d1			*0ﾟ～44ﾟの場合	:r*sin(d0.w)
L002558:				*46ﾟ～90ﾟの場合	:r*cos(d0.w)
	move	(sp)+,d6
L00255a:
	moveq	#0,d0
	move.b	L002594(pc,d6.w),d0
	lea	-$24(a6,d0.w),a0
	rts

L002566:
	.dc.b	$00,$04,$09,$0d,$12,$16,$1b,$1f
	.dc.b	$24,$28,$2c,$31,$35,$3a,$3e,$42
	.dc.b	$47,$4b,$4f,$53,$58,$5c,$60,$64
	.dc.b	$68,$6c,$70,$74,$78,$7c,$80,$84
	.dc.b	$88,$8b,$8f,$93,$96,$9a,$9e,$a1
	.dc.b	$a5,$a8,$ab,$af,$b2,$b5

L002594:
	.dc.b	$0e,$0a,$02,$06,$04,$00,$08,$0c

L00259c:
	bsr	L0025ea
	addq.w	#1,-$0006(a6)
	move	-$0006(a6),d0
	add.w	d0,d0
	move	-$000a(a6),d1
	sub.w	d0,d1
	addq.w	#1,d1
	bpl	L0025c0
	subq.w	#1,-$0008(a6)
	move	-$0008(a6),d0
	add.w	d0,d0
	add.w	d0,d1
	addq.w	#1,d1
L0025c0:
	move	d1,-$000a(a6)
L0025c4:
	move	-$0008(a6),d0
	sub.w	-$0006(a6),d0
	beq	L0025d2
	subq.w	#1,d0
	bne	L00259c
L0025d2:				*45ﾟに達した
	move	-$0006(a6),d0
	cmp.w	-$000e(a6),d0		*開始角長さ(45ﾟなら-1)
	bcc	L0025e0
	move	d0,-$000e(a6)
L0025e0:
	cmp.w	-$000c(a6),d0		*終了角長さ
	bcc	L0025ea
	move	d0,-$000c(a6)
L0025ea:				*1/8円に１ドットずつ描画
	bsr	L0026d6			*比率からＸ，Ｙ座標を計算する
	lea	-$0044(a6),a4
	moveq	#$07,d6
L0025f4:
	movem.l	d6/a4,-(sp)
	move.b	$0020(a4),d2
	beq	L002692			*1/8円は描かない
	bmi	L00264e			*1/8円を全て描く
	move	-$0006(a6),d1
	lsl.b	#2,d2
	bcc	L002638
	move	-$000e(a6),d0		*開始角長さ
	cmp.w	d1,d0
	beq	L00269e			*現在開始角である
	btst.b	#$00,$0021(a4)
	bne	L002620
	bcs	L00262e			*角度増加方向
	bra	L002622
L002620:				*角度減少方向
	bcc	L00262e
L002622:				*開始角に達していない
	tst.b	d2
	bpl	L002692			*終了角はその1/8円内にない
	tst	-$0014(a6)
	beq	L002692
	bra	L002638
L00262e:				*開始角に達した
	tst.b	d2
	bpl	L00264e			*終了角はその1/8円内にない
	tst	-$0014(a6)
	bne	L00264e
L002638:
	move	-$000c(a6),d0		*終了角長さ
	cmp.w	d1,d0
	beq	L0026a4			*現在終了角である
	btst.b	#$00,$0021(a4)
	beq	L00264c
	bcs	L00264e			*角度減少方向
	bra	L002692
L00264c:				*角度増加方向
	bcs	L002692
L00264e:				*終了角に達していない
	move	(a4),d4			*Ｘ
	move	$0010(a4),d5		*Ｙ
	cmp.w	-$004e(a6),d4		*GRXMIN
	blt	L002692
	cmp.w	-$004a(a6),d4		*GRXMAX
	bgt	L002692
	cmp.w	-$004c(a6),d5		*GRYMIN
	blt	L002692
	cmp.w	-$0048(a6),d5		*GRYMAX
	bgt	L002692

	moveq	#0,d0
	move	d5,d0
	swap	d0
	lsr.l	#6,d0
	btst	#2,(GRLLEN+2)
	bne	L002684
	add.l	d0,d0
L002684:
	movea.l	(GRADR),a0
	adda.l	d0,a0
	adda	d4,a0
	adda	d4,a0			*ＧＶＲＡＭアドレス
	move	d7,(a0)			*１ドット描画
L002692:
	movem.l	(sp)+,d6/a4
	addq.l	#2,a4
	dbra	d6,L0025f4
	rts

L00269e:				*開始角
	tst	-$0012(a6)
	bra	L0026a8
L0026a4:				*終了角
	tst	-$0010(a6)
L0026a8:
	beq	L00264e			*扇は描かない
	move	(a4),d0			*Ｘ
	move	$0010(a4),d1		*Ｙ
	move	-$0004(a6),d2		*中心Ｘ
	move	-$0002(a6),d3		*中心Ｙ
	moveq	#$ff,d6			*ラインスタイル
	move.l	a5,-(sp)
	movea.l	-$0052(a6),a5		*(=0)
	move	(DRAWMODE),-(sp)
	clr	(DRAWMODE)
	bsr	L0028dc			*ライン描画
	move	(sp)+,(DRAWMODE)
	movea.l	(sp)+,a5
	bra	L002692
L0026d6:
	lea	-$0044(a6),a4
	lea	-$0034(a6),a5
	move	-$0008(a6),d0		*半径
	bsr	L0026e8
	move	-$0006(a6),d0
L0026e8:
	bsr	L00271e
	move	-$0004(a6),d0		*中心Ｘ
	add.w	d5,d0
	move	d0,$000c(a4)
	move	d0,$000e(a4)
	move	-$0004(a6),d0
	sub.w	d5,d0
	move	d0,$0004(a4)
	move	d0,$0006(a4)
	subq.l	#4,a4
	move	-$0002(a6),d0		*中心Ｙ
	add.w	d4,d0
	bsr	L002716
	move	-$0002(a6),d0
	sub.w	d4,d0
L002716:
	move	d0,$0008(a5)
	move	d0,(a5)+
	rts

L00271e:
	move	d0,d4			*縦長さ
	move	d0,d5			*横長さ
	move	-$0046(a6),d0		*比率
	cmp.w	#$0100,d0
	beq	L002756			*真円の場合
	bcc	L002734
	mulu.w	d0,d4			*横長の円
	lsr.l	#8,d4			*ｒ×比率／256
	rts

L002734:
	moveq	#0,d1			*縦長の円
	move	d0,d1
	moveq	#0,d0
	move	d5,d0
	lsl.l	#8,d0
	moveq	#0,d2
	moveq	#$1f,d3
L002742:				*ｒ×256／比率
	add.l	d0,d0
	roxl.l	#1,d2
	cmp.l	d1,d2
	bcs	L002750
	bset.l	#$00,d0
	sub.l	d1,d2
L002750:
	dbra	d3,L002742
	move	d0,d5
L002756:
	rts



*	テキスト画面のラインのクリッピングを行なう

txlclip:
	link	a6,#-8
	move.l	TXXMIN.w,-$0008(a6)
	move.l	TXXMAX.w,-$0004(a6)
	subi.l	#$00010001,-$0004(a6)
	bra	L002782

*	グラフィック画面のラインのクリッピングを行なう

L002772:
	link	a6,#-8
	move.l	GRXMIN.w,-$0008(a6)
	move.l	GRXMAX.w,-$0004(a6)
L002782:
	movem.l	d4-d7/a0-a3,-(sp)
	moveq	#0,d6
	exg.l	d0,d2
	exg.l	d1,d3
	bsr	chkclipdot		*端点コードを求める
	exg.l	d0,d2
	exg.l	d1,d3
	move	d4,d5			*終点の端点コード
L002796:
	bsr	chkclipdot
	move	d4,d7			*始点の端点コード
	or.w	d5,d7
	bne	L0027b0			*始点・終点のいずれかがクリップ範囲外
	tst	d6
	beq	L0027a8			*始点・終点の交換が行なわれていない
	exg.l	d0,d2
	exg.l	d1,d3
L0027a8:
	movem.l	(sp)+,d4-d7/a0-a3
	unlk	a6
	rts

L0027b0:
	move	d4,d7
	and.w	d5,d7
	bne	L0027c6			*線分は完全不可視
	tst	d4
	bne	L0027c2			*始点がクリップ範囲外
	exg.l	d0,d2
	exg.l	d1,d3
	exg.l	d4,d5
	not.w	d6
L0027c2:
	bsr	clipdot
	bra	L002796

*	線分が完全不可視だった

L0027c6:
	ori.b	#$01,ccr		*C=1
	bra	L0027a8

*	片方の端点(d0.w,d1.w)をクリッピングする

clipdot:
	move	d4,ccr
	bcs	L0027ec			*左辺にクリップ
	bvs	L0027f2			*右辺
	beq	L0027da			*上辺
					*下辺

	move	-$0002(a6),d7		*ymax
	bra	L0027de
L0027da:
	move	-$0006(a6),d7		*ymin
L0027de:
	movea.w	d1,a0
	movea.w	d0,a1
	movea.w	d3,a2
	movea.w	d2,a3
	bsr	L0027fe
	exg.l	d0,d1
	rts

L0027ec:
	move	-$0008(a6),d7		*xmin
	bra	L0027f6
L0027f2:
	move	-$0004(a6),d7		*xmax
L0027f6:
	movea.w	d0,a0
	movea.w	d1,a1
	movea.w	d2,a2
	movea.w	d3,a3

L0027fe:				*a0～a2間で中点分割を行なう
	adda.w	#$8000,a0
	adda.w	#$8000,a1
	adda.w	#$8000,a2
	adda.w	#$8000,a3
	add.w	#$8000,d7
	cmpa.w	a0,a2
	bcc	L00281a			*a0.w<=a2.w
	exg.l	a0,a2
	exg.l	a1,a3
L00281a:
	cmp.w	a0,d7
	beq	L002844			*中点分割の必要なし
	cmp.w	a2,d7
	beq	L002840			*中点分割の必要なし
L002822:
	move	a1,d1
	add.w	a3,d1
	roxr.w	#1,d1			*d1.w=(a1+a3)/2
	move	a0,d0
	add.w	a2,d0
	roxr.w	#1,d0			*d0.w=(a0+a2)/2
	cmp.w	d7,d0
	beq	L002848			*中点分割が終わった
	bcs	L00283a			*d7.w>d0.w
	movea.w	d0,a2
	movea.w	d1,a3
	bra	L002822
L00283a:
	movea.w	d0,a0
	movea.w	d1,a1
	bra	L002822
L002840:
	exg.l	a0,a2
	exg.l	a1,a3
L002844:
	move	a0,d0
	move	a1,d1
L002848:
	sub.w	#$8000,d0
	sub.w	#$8000,d1
	rts

*	端点とクリップウィンドウとの関係を調べる

chkclipdot:
	clr.w	d4
	cmp.w	-$0008(a6),d0		*xmin
	bge	L00285c
	addq.w	#1,d4
L00285c:
	cmp.w	-$0004(a6),d0		*xmax
	ble	L002864
	addq.w	#2,d4
L002864:
	cmp.w	-$0006(a6),d1		*ymin
	bge	L00286c
	addq.w	#4,d4
L00286c:
	cmp.w	-$0002(a6),d1		*ymax
	ble	L002874
	addq.w	#8,d4
L002874:
L0028da:				*完全不可視なので何もしない
	rts


*	ボックス描画の実処理

L002876:
	cmp.w	d1,d3
	beq	L0028c6			*y0==y1の場合
	cmp.w	d0,d2
	beq	L0028d0			*x0==x1の場合
	movem.w	d0-d3,-(sp)
	move	(0,sp),d4
	move	(2,sp),d5
	move	(4,sp),d1
	bsr	L002980			*(x0,y0)-(x1,y0)
	move	(4,sp),d4
	move	(2,sp),d5
	move	(6,sp),d1
	bsr	L002a5a			*(x1,y0)-(x1,y1)
	move	(4,sp),d4
	move	(6,sp),d5
	move	(0,sp),d1
	bsr	L002980			*(x1,y1)-(x0,y1)
	move	(sp)+,d4
	move	(sp)+,d1
	move.l	(sp)+,d5		*(4,sp)|(6,sp):下位のみ使用
	bra	L002a5a			*(x0,y1)-(x0,y0)

L0028c6:				*水平線描画
	move	d0,d4
	move	d1,d5
	move	d2,d1
	bra	L00298a

L0028d0:				*垂直線描画
	move	d0,d4
	move	d1,d5
	move	d3,d1
	bra	L002a64

*	ライン描画の実処理

L0028dc:
	bsr	L002772			*クリッピングを行なう
	bcs.s	L0028da			*完全不可視の場合
	cmp.w	d1,d3
	beq	L0028c6			*水平線
	cmp.w	d0,d2
	beq	L0028d0			*垂直線
	move.l	d0,d4
	move.l	d1,d5
	moveq	#0,d1
	moveq	#2,d0			*Ｘ方向増分
	sub.w	d4,d2			*Ｘ方向長さ－１
	bcc	L0028fc			*x2>=x1
	st.b	d1
	neg.w	d2
	moveq	#-2,d0
L0028fc:
	movea.l	d0,a1
	move	GRLLEN+2.w,d0		*Ｙ方向増分
	sub.w	d5,d3			*Ｙ方向長さ－１
	bcc	L00290e			*y2>=y1
	bset.l	#16,d1
	neg.w	d3
	neg.w	d0
L00290e:
	movea.w	d0,a2
	cmp.w	d3,d2
	bcc	L00291a			*dx>=dy
	swap	d1
	exg.l	d2,d3
	exg.l	a1,a2
L00291a:
	move	d1,d0
	move	d2,d1
	lsr	#1,d1			*e = dx(dy)/2
	bcs	L002928
	tst.b	d0
	beq	L002928
	subq.w	#1,d1
L002928:
	moveq	#0,d0
	move	d5,d0
	swap	d0
	lsr.l	#6,d0			*1024倍(512×512)
	btst.b	#$02,GRLLEN+2.w
	bne	L00293a
	add.l	d0,d0			*2048倍(1024×1024)
L00293a:
	movea.l	GRADR.w,a0
	adda.l	d0,a0
	adda	d4,a0
	adda	d4,a0			*描画開始ＶＲＡＭアドレス
	tst	(DRAWMODE)
	bne	L002966
	move	d2,d0			*psetモードの場合
L00294c:
	rol.w	#1,d6			*ラインスタイル
	bcc	L002952
	move	d7,(a0)			*１ドット描画
L002952:
	subq.w	#1,d0
	bmi.s	L002964
	adda.w	a1,a0
	add.w	d3,d1			*e += dy(dx)
	cmp.w	d2,d1
	bcs	L00294c
	sub.w	d2,d1			*e -= dx(dy)
	adda.w	a2,a0
	bra	L00294c

L002966:				*xorモードの場合
	move	d2,d0
L002968:
	rol.w	#1,d6			*ラインスタイル
	bcc	L00296e
	not.w	(a0)			*１ドット描画
L00296e:
	subq.w	#1,d0
	bmi.s	L002964
	adda.w	a1,a0
	add.w	d3,d1			*e += dy(dx)
	cmp.w	d2,d1
	bcs	L002968
	sub.w	d2,d1			*e -= dx(dy)
	adda.w	a2,a0
	bra	L002968

*	水平線描画処理

L002980:
	cmp.w	d4,d1
	bcc	L002988
	addq.w	#1,d1
	bra	L00298a
L002988:
	subq.w	#1,d1
L00298a:
	bsr	L002afc			*クリッピングを行なう
	bcs	L0029cc			*完全不可視の場合
	cmp.w	#$ffff,d6		*ラインスタイル
	beq	L002a1c
	moveq	#0,d0			*点線の場合
	move	d5,d0
	swap	d0
	lsr.l	#6,d0			*1024倍(512×512)
	btst.b	#$02,GRLLEN+2.w
	bne	L0029aa
	add.l	d0,d0			*2048倍(1024×1024)
L0029aa:
	movea.l	GRADR.w,a0
	adda.l	d0,a0
	adda.w	d4,a0
	adda.w	d4,a0			*描画開始ＶＲＡＭアドレス
	sub.w	d4,d1			*長さ－１
	bcc	L0029ee			*x1>=x0
	tst	(DRAWMODE)		*右から左へ描画
	bne	L0029d6
	addq.l	#2,a0			*psetモードの場合
	neg.w	d1
L0029c2:
	rol.w	#1,d6
	bcc	L0029ce
	move	d7,-(a0)		*１ドット描画
	dbra	d1,L0029c2
L0029cc:
L002964:
	rts
L0029ce:
	subq.l	#2,a0
	dbra	d1,L0029c2
	rts

L0029d6:				*xorモードの場合
	addq.l	#2,a0
	neg.w	d1
L0029da:
	rol.w	#1,d6
	bcc	L0029e6
	not.w	-(a0)			*１ドット描画
	dbra	d1,L0029da
	rts
L0029e6:
	subq.l	#2,a0
	dbra	d1,L0029da
	rts

L0029ee:				*左から右へ描画
	tst	(DRAWMODE)
	bne	L002a08
L0029f4:
	rol.w	#1,d6			*psetモードの場合
	bcc	L002a00
	move	d7,(a0)+		*１ドット描画
	dbra	d1,L0029f4		*!!
	rts
L002a00:
	addq.l	#2,a0
	dbra	d1,L0029f4		*!!
	rts

L002a08:				*xorモードの場合
	rol.w	#1,d6
	bcc	L002a14
	not.w	(a0)+			*１ドット描画
	dbra	d1,L002a08
	rts
L002a14:
	addq.l	#2,a0
	dbra	d1,L002a08
	rts

L002a1c:				*実線の場合
	cmp.w	d4,d1
	bcc	L002a22
	exg.l	d1,d4
L002a22:
	sub.w	d4,d1			*長さ－１
	moveq	#0,d0
	move	d5,d0
	swap	d0
	lsr.l	#6,d0			*1024倍(512×512)
	btst.b	#$02,GRLLEN+2.w
	bne	L002a36
	add.l	d0,d0			*2048倍(1024×1024)
L002a36:
	movea.l	GRADR.w,a1
	adda.l	d0,a1
	adda.w	d4,a1
	adda.w	d4,a1			*描画開始ＶＲＡＭアドレス
	addq.w	#1,d1
	swap	d1
	clr.w	d1
	swap	d1
	move	d7,d0
	swap	d7
	move	d0,d7
	tst	(DRAWMODE)
	beq	L002c1c			*水平線を引く(psetモード)
	bra	L002c80			*	     (xorモード)

*	垂直線描画処理

L002a5a:
	cmp.w	d5,d1
	bcc	L002a62
	addq.w	#1,d1
	bra	L002a64
L002a62:
	subq.w	#1,d1
L002a64:
	bsr	L002b3a			*クリッピングを行なう
	bcs	L002aac			*完全不可視の場合
	cmp.w	#$ffff,d6		*ラインスタイル
	beq	L002abc
	moveq	#0,d0			*点線の場合
	move	d5,d0
	swap	d0
	lsr.l	#6,d0			*1024倍(512×512)
	btst.b	#$02,GRLLEN+2.w
	bne	L002a82
	add.l	d0,d0			*2048倍(1024×1024)
L002a82:
	movea.l	GRADR.w,a0
	adda.l	d0,a0
	adda.w	d4,a0
	adda.w	d4,a0			*描画開始ＶＲＡＭアドレス
	moveq	#0,d0
	move	GRLLEN+2.w,d0
	sub.w	d5,d1			*長さ－１
	bcc	L002a9a
	neg.w	d0
	neg.w	d1
L002a9a:
	tst	(DRAWMODE)
	bne	L002aae
L002aa0:				*psetモードの場合
	rol.w	#1,d6
	bcc	L002aa6
	move	d7,(a0)			*１ドット描画
L002aa6:
	adda.w	d0,a0
	dbra	d1,L002aa0
L002aac:
	rts

L002aae:				*xorモードの場合
	rol.w	#1,d6
	bcc	L002ab4
	not.w	(a0)
L002ab4:
	adda.w	d0,a0
	dbra	d1,L002aae
	rts

L002abc:				*実線の場合
	cmp.w	d5,d1
	bcc	L002ac2
	exg.l	d1,d5
L002ac2:
	sub.w	d5,d1			*長さ－１
	moveq	#0,d0
	move	d5,d0
	swap	d0
	lsr.l	#6,d0			*1024倍(512×512)
	btst.b	#$02,GRLLEN+2.w
	bne	L002ad6
	add.l	d0,d0			*2048倍(1024×1024)
L002ad6:
	movea.l	GRADR.w,a1
	adda.l	d0,a1
	adda.w	d4,a1
	adda.w	d4,a1			*描画開始ＶＲＡＭアドレス
	addq.w	#1,d1
	swap	d1
	clr.w	d1
	swap	d1
	btst.b	#$03,GRLLEN+2.w
	sne.b	d0
	tst	(DRAWMODE)
	beq	L002cfa			*垂直線を引く(psetモード)
	bra	L002ce4			*	     (xorモード)


L002afc:				*水平線のクリッピングを行なう
	move.l	GRXMIN.w,d2
	move.l	GRXMAX.w,d3
	cmp.w	d2,d5
	blt	L002b34			*Ｙ座標が範囲外 (小さい)
	cmp.w	d3,d5
	bgt	L002b34			*		(大きい)
	swap	d2
	swap	d3
	cmp.w	d4,d1
	bge	L002b1c			*d1.w>=d4.w
	exg.l	d4,d1
	bsr	L002b1c
	exg.l	d4,d1
	rts
L002b1c:
	cmp.w	d2,d1
	blt	L002b34			*描画範囲の左外
	cmp.w	d3,d4
	bgt	L002b34			*描画範囲の右外
	cmp.w	d2,d4
	bge	L002b2a
	move	d2,d4			*x0 = GRXMIN
L002b2a:
	cmp.w	d3,d1
	ble	L002b30
	move	d3,d1			*x1 = GRXMAX
L002b30:
	tst	d0
	rts
L002b34:
	ori.b	#$01,ccr
	rts

L002b3a:				*垂直線のクリッピングを行なう
	cmp.w	GRXMIN.w,d4
	blt	L002b34			*Ｘ座標が範囲外 (小さい)
	cmp.w	GRXMAX.w,d4
	bgt	L002b34			*		(大きい)
	move	GRYMIN.w,d2
	move	GRYMAX.w,d3
	cmp.w	d5,d1
	bge	L002b5a			*d1.w>=d5.w
	exg.l	d5,d1
	bsr	L002b5a
	exg.l	d5,d1
	rts
L002b5a:
	cmp.w	d2,d1
	blt	L002b34			*描画範囲の上外
	cmp.w	d3,d5
	bgt	L002b34			*描画範囲の下外
	cmp.w	d2,d5
	bge	L002b68
	move	d2,d5			*y0 = GRYMIN
L002b68:
	cmp.w	d3,d1
	ble	L002b6e
	move	d3,d1			*y1 = GRYMAX
L002b6e:
	tst	d0
L002b72:
	rts

*	ボックスフィルの実処理

L002b74:
	cmp.w	d0,d2
	bge	L002b7a			*d2.w>=d0.w
	exg.l	d0,d2
L002b7a:
	cmp.w	d1,d3
	bge	L002b80			*d3.w>=d0.w
	exg.l	d1,d3
L002b80:
	move.l	GRXMIN.w,d4
	move.l	GRXMAX.w,d5
	cmp.w	d4,d3
	blt	L002b72
	cmp.w	d5,d1
	bgt	L002b72
	swap	d4
	swap	d5
	cmp.w	d4,d2
	blt	L002b72
	cmp.w	d5,d0
	bgt	L002b72
	cmp.w	d4,d0
	bge	L002ba2
	move	d4,d0
L002ba2:
	cmp.w	d5,d2
	ble	L002ba8
	move	d5,d2
L002ba8:
	swap	d4
	swap	d5
	cmp.w	d4,d1
	bge	L002bb2
	move	d4,d1
L002bb2:
	cmp.w	d5,d3
	ble	L002bb8
	move	d5,d3
L002bb8:
	move	d7,d6
	swap	d7
	move	d6,d7
	tst	(DRAWMODE)
	beq	L002bda
	lea	L002c80(pc),a3
	bra	L002bde

*	画面消去の実処理

L002bca:
	movem.l	GRXMIN.w,d0/d2
	move	d0,d1
	move	d2,d3
	swap	d0
	swap	d2			*(d0.w,d1.w)-(d2.w,d3.w)
	moveq	#0,d7
L002bda:
	lea	L002c1c(pc),a3
L002bde:
	sub.w	d0,d2
	addq.w	#1,d2			*Ｘ方向ドット数
	sub.w	d1,d3
	move	d0,d4
	moveq	#0,d0
	move	d1,d0
	swap	d0
	lsr.l	#6,d0			*1024倍(512×512)
	btst.b	#$02,GRLLEN+2.w
	bne	L002bf8
	add.l	d0,d0			*2048倍(1024×1024)
L002bf8:
	movea.l	GRADR.w,a2
	adda.l	d0,a2
	adda.w	d4,a2
	adda.w	d4,a2			*左上のＶＲＡＭアドレス
	moveq	#0,d4
	move	GRLLEN+2.w,d4
	swap	d2
	clr.w	d2
	swap	d2
L002c0e:
	movea.l	a2,a1
	move.l	d2,d1
	jsr	(a3)
	adda.l	d4,a2
	dbra	d3,L002c0e
	rts

*	水平線を引く(psetモード)

L002c1c:
	ror.l	#6,d1
	lea	(L002c28,pc),a0
L002c28:
	dbra	d1,L002c3e
L002c2c:
	clr	d1
	rol.l	#5,d1
	bpl	L002c34
	move	d7,(a1)+
L002c34:
	add	d1,d1
	neg	d1
	movea.l	(sp)+,a0
	jmp	(L002c7e,pc,d1.w)
L002c3e:
	.rept	32
	move.l	d7,(a1)+
	.endm
L002c7e:
	jmp	(a0)

*	水平線を引く(xorモード)

L002c80:
	ror.l	#6,d1
	lea	(L002c8c,pc),a0
L002c8c:
	dbra	d1,L002ca2
L002c90:
	clr	d1
	rol.l	#5,d1
	bpl	L002c98
	not	(a1)+
L002c98:
	add	d1,d1
	neg	d1
	movea.l	(sp)+,a0
	jmp	(L002ce2,pc,d1.w)
L002ca2:
	.rept	32
	not.l	(a1)+
	.endm
L002ce2:
	jmp	(a0)

*	垂直線を引く(xorモード)

L002ce4:
	lea	$00004000,a3		*(512×512)
	lea	L002db4(pc),a2
	tst.b	d0
	beq	L002d0e
	adda.l	a3,a3			*(1024×1024)
	lea	L002df6(pc),a2
	bra	L002d0e

*	垂直線を引く(psetモード)

L002cfa:
	lea	$00004000,a3		*(512×512)
	lea	L002d30(pc),a2
	tst.b	d0
	beq	L002d0e
	adda.l	a3,a3			*(1024×1024)
	lea	L002d72(pc),a2
L002d0e:
	ror.l	#4,d1
	subq.w	#1,d1
	bmi	L002d20
	lea	L002d1a(pc),a0
L002d18:
	jmp	(a2)
L002d1a:
	adda.l	a3,a1
	dbra	d1,L002d18
L002d20:
	clr.w	d1
	rol.l	#4,d1
	add.w	d1,d1
	add.w	d1,d1
	neg.w	d1
	movea.l	(sp)+,a0
	jmp	$40(a2,d1.w)

L002d30:				*512×512 psetモード
	move	d7,($3c00,a1)
	move	d7,($3800,a1)
	move	d7,($3400,a1)
	move	d7,($3000,a1)
	move	d7,($2c00,a1)
	move	d7,($2800,a1)
	move	d7,($2400,a1)
	move	d7,($2000,a1)
	move	d7,($1c00,a1)
	move	d7,($1800,a1)
	move	d7,($1400,a1)
	move	d7,($1000,a1)
	move	d7,($0c00,a1)
	move	d7,($0800,a1)
	move	d7,($0400,a1)
	move	d7,(a1)
	jmp	(a0)
	jmp	(a0)

L002d72:				*1024×1024 psetモード
	move	d7,($7800,a1)
	move	d7,($7000,a1)
	move	d7,($6800,a1)
	move	d7,($6000,a1)
	move	d7,($5800,a1)
	move	d7,($5000,a1)
	move	d7,($4800,a1)
	move	d7,($4000,a1)
	move	d7,($3800,a1)
	move	d7,($3000,a1)
	move	d7,($2800,a1)
	move	d7,($2000,a1)
	move	d7,($1800,a1)
	move	d7,($1000,a1)
	move	d7,($0800,a1)
	move	d7,(a1)
	jmp	(a0)
	jmp	(a0)

L002db4:				*512×512 xorモード
	not	($3c00,a1)
	not	($3800,a1)
	not	($3400,a1)
	not	($3000,a1)
	not	($2c00,a1)
	not	($2800,a1)
	not	($2400,a1)
	not	($2000,a1)
	not	($1c00,a1)
	not	($1800,a1)
	not	($1400,a1)
	not	($1000,a1)
	not	($0c00,a1)
	not	($0800,a1)
	not	($0400,a1)
	not	(a1)
	jmp	(a0)
	jmp	(a0)

L002df6:				*1024×1024 xorモード
	not	($7800,a1)
	not	($7000,a1)
	not	($6800,a1)
	not	($6000,a1)
	not	($5800,a1)
	not	($5000,a1)
	not	($4800,a1)
	not	($4000,a1)
	not	($3800,a1)
	not	($3000,a1)
	not	($2800,a1)
	not	($2000,a1)
	not	($1800,a1)
	not	($1000,a1)
	not	($0800,a1)
	not	(a1)
	jmp	(a0)
	jmp	(a0)

	.end
