	.title	HIOCS PLUS (console.s)

*****************************************************************
*	HIOCS version 1.10
*		< CONSOLE.HAS >
*	$Id: CONSOLE.HA_ 1.5 93/04/03 22:49:06 YuNK Exp $
*
*		Copyright 1990,91,92  SHARP / Y.Nakamura
*****************************************************************


* Include Files ----------------------- *

	.include	doscall.mac
	.include	iocscall.mac
	.include	hiocs.equ


* Global Symbols ---------------------- *

	.xref	old_defchr,old_akconv
	.xref	CHRSELFLG,VBELLFLG
	.xref	CSRPAT0,CSRPAT1,CSRSAVE0,CSRSAVE1,CSRPATC,CSRPATSW
	.xref	EXCHRVECT
	.xref	FIRSTFLG,FIRSTFNT
	.xref	FONTANK12,FONTANK6,FONTANK8
	.xref	FONTKNJ16A,FONTKNJ16B,FONTKNJ16C,FONTKNJ24,FONTSML12
	.xref	LOGBUFVECT,CONDFLAG,CONESCFLG,CONDSYSCALL
	.xref	UNDEFCHR,UNDEFJIS,UNDEFPTR
	.xref	USRKNJ2FLG,USRKNJFLG


* Macros ------------------------------ *

	.offset	0
~jobadr:  .dc	0
~fntadr:  .dc.l	0
~knjflag: .dc.b	0
~jisflag: .dc.b	0
sizeof_CHRTABLE:

LEA_CHRTABLE: .macro firstbyte,member,areg
	lea	(chrtable+(sizeof_CHRTABLE*firstbyte)+member,pc),areg
	.endm

SHIFT_HALF_HIRA: .macro	dn
	cmpi.b	#'ｦ',dn
	bcs	@skip
	cmpi.b	#'ﾝ',dn
	bhi	@skip
	eori.b	#$20,dn
@skip:
	.endm

LSL_2:	.macro	dn
	.sizem	sz
.if CPU>=68020
	lsl&sz	#2,dn
.else
	add&sz	dn,dn
	add&sz	dn,dn
.endif
	.endm


* Text Section ------------------------ *

	.text

*****************************************
*	IOCS $2f	_B_PUTMES	*
*****************************************

b_putmes::				*<+03
	movem.l	d1/d3/d5-d6/a2-a4/a6,-(sp)
	cmpi	#63,d3
	bhi	b_putmes99		*Ｙ座標が大きすぎる
	moveq	#127,d0
	sub	d2,d0
	bcs	b_putmes99		*Ｘ座標が大きすぎる
	move	d2,d5
	cmp	d0,d4
	bcs	b_putmes1
	move	d0,d4
b_putmes1:
	ext.l	d3
	swap	d3
	lsr.l	#5,d3			*128×16倍
	add	d5,d3
	add.l	(TXADR),d3		*ＶＲＡＭアドレス
	movea.l	d3,a3
	lea	(_CRTC21),a2
	lea	(chrtable,pc),a4
	andi	#$000f,d1		*色コード
	add	d1,d1
	move	d1,d6
	cmpi.l	#fntadr,(_FNTADR*4+$400)	*IOCS _FNTADRは内部ルーチンか？
	bne	b_putmes50

b_putmes2:
	moveq	#0,d1
	move.b	(a1)+,d1
	beq	b_putmes3		*表示文字列が終了した
	cmpi.b	#$fe,d1			*$fe→$20
	bne	b_putmes5
	bra	b_putmes4
b_putmes3:
	subq.l	#1,a1
b_putmes4:
	moveq	#' ',d1
b_putmes5:
	lsl	#3,d1
	movea.l	(~fntadr,a4,d1.w),a0
	move.b	(~jisflag,a4,d1.w),d0
	ble	b_putmes10		*mi or eq(半角文字)
	moveq	#0,d1
	move.b	(a1)+,d1		*下位バイト
	beq	b_putmes3		*上位バイトで文字列が終わってしまった
	cmpi.b	#$04,d0
	bcs	putmes_kanji		*		全角漢字/非漢字
	beq	putmes_hira		*$80xx		半角ひらがな
	cmpi.b	#$08,d0
	beq	putmes_knj88		*$88xx		拡張外字/漢字 境界
	bcs	putmes_uskA		*$85xx～$87xx	外字Ａ/拡張用
	cmpi.b	#$0a,d0
	beq	putmes_uskB		*$ecxx～$efxx	外字Ｂ/未定義
	bcs	putmes_knjeb		*$ebxx		漢字/外字Ｂ 境界
	cmpi.b	#$0d,d0
	bhi	putmes_small		*$f0xx～$f3xx	1/4角文字 / $85xx,$86xx 半角非漢字
	bcs	putmes_knjAB		*$88xx,$98xx	非漢字/第１水準/第２水準 境界
	adda.l	(USKFONT2),a0		*$f4xx～$ffxx	半角外字
	lsl	#4,d1
	adda	d1,a0
	bra	b_putmes11

putmes_extk:				*拡張外字
	move.l	(EXCHRVECT,pc),d2
	beq	putmes_undef		*拡張外字ベクタは未設定
	movea.l	d2,a0
	subi.b	#$40,d1
	bcs	putmes_undef
	cmpi.b	#$7f-$40,d1
	bcs	putmes_extk1
	beq	putmes_undef
	subq.b	#1,d1
putmes_extk1:
	cmpi.b	#$fc-1-$40,d1
	bhi	putmes_undef
	exg	d0,d1
	ext	d1
	add.b	d1,d1
	subq.b	#2,d1
	cmpi.b	#$5e,d0			*	<+06
	bcs	putmes_extk2
	subi.b	#$5e,d0			*	<+06
	addq.b	#1,d1
putmes_extk2:
	moveq	#8,d2
	jsr	(a0)			*拡張外字処理呼び出し
	movea.l	d0,a0
	tst	d1
	beq	b_putmes11
	bra	putmes_kanji1

putmes_knjAB:				*～$889e:非漢字   / $889f～:第１水準
	cmpi.b	#$9f,d1			*～$989e:第１水準 / $989f～:第２水準
	bcs	putmes_kanji
	ext	d0
.if CPU>=68030
	lea	([(FONTKNJ16B-11*4).w,pc,d0.w*4],-$0bc0),a0
.else
	add	d0,d0
	add	d0,d0
	lea	(FONTKNJ16B,pc),a0
	movea.l	(-11*4,a0,d0.w),a0
	lea	(-$0bc0,a0),a0
.endif
	bra	putmes_kanji

putmes_uskA:				*外字Ａ/拡張外字
	adda.l	(USKFONT0),a0
	cmpi.b	#$06,d0
	bcs	putmes_extk
	bne	putmes_uskA1
	cmpi.b	#$9f,d1
	bcc	putmes_kanji
	bra	putmes_extk
putmes_uskA1:
	cmpi.b	#$9f,d1
	bcs	putmes_kanji
	bra	putmes_extk

putmes_undef:				*未定義の漢字コード
	movea.l	(UNDEFPTR,pc),a0
	bra	putmes_kanji1

putmes_knjeb:				*～$eb9e:漢字     / $eb9f～:外字Ｂ
	cmpi.b	#$9f,d1
	bcs.s	putmes_kanji
	movea	#-$0bc0,a0
putmes_uskB:				*外字Ｂ
	adda.l	(USKFONT1),a0
	bra	putmes_kanji

putmes_knj88:				*～$889e:拡張外字 / $889f～:漢字
	cmpi.b	#$9f,d1
	bcs	putmes_extk
putmes_kanji:				*全角漢字/非漢字
.if CPU>=68020
	move	(sjis2tbl,pc,d1.w*2),d1
.else
	lea	(sjis2tbl,pc),a6
	add	d1,d1
	move	(a6,d1.w),d1
.endif
	bmi.s	putmes_undef		*未定義コード
	adda	d1,a0
putmes_kanji1:
	subq	#1,d4
	bmi	putmes_kanji3		*表示桁数が半角１文字分しか残っていない
	move	a3,d0
	lea	(putc_wetbl,pc),a6	*全角文字の場合(偶数アドレス)
.if CPU<68020
	lsr	#1,d0
	bcc	putmes_kanji2
	lea	(putc_wotbl,pc),a6	*全角文字の場合(奇数アドレス)
putmes_kanji2:
.endif
	move	(a2),d2
	jsr	(a6,d6.w)		*文字パターンの表示ルーチンを呼ぶ
	move	d2,(a2)
	addq	#2,d5
	addq.l	#2,a3
	dbra	d4,b_putmes2		*桁数が終わるまで繰り返し
	move	d5,d2
	movem.l	(sp)+,d1/d3/d5-d6/a2-a4/a6
	rts
putmes_kanji3:
	moveq	#0,d4
	bra	b_putmes4

putmes_hkanji:				*半角非漢字	<+07
	beq	putmes_hkanji1
	cmpi.b	#$9f,d1
	bcc	putmes_kanji		*～$869e:半角非漢字 / $869f～:全角非漢字
putmes_hkanji1:
.if CPU>=68020
	move	(sjis2tbl,pc,d1.w*2),d1
.else
	lea	(sjis2tbl,pc),a6
	add	d1,d1
	move	(a6,d1.w),d1
.endif
	bmi.s	putmes_undef		*未定義コード
	adda	d1,a0
	bra	b_putmes11

putmes_small:				*1/4角文字
	cmpi.b	#$12,d0			*	<+07
	bcc	putmes_hkanji		*半角非漢字
	lsr.b	#1,d0
	bcc	@f
	SHIFT_HALF_HIRA d1
@@:
	bsr	putc_fonchg0
	lea	(MKFONTBUF),a6
	lea	(8,a6),a4
	lsr.b	#1,d0
	bcs	putmes_small2
	exg	a6,a4
putmes_small2:
	clr.l	(a4)+
	clr.l	(a4)+
	lsl	#3,d1
	adda	d1,a0
	move.l	(a0)+,(a6)+
	move.l	(a0)+,(a6)+
	lea	(MKFONTBUF),a0
	lea	(chrtable,pc),a4	*(レジスタ復帰)
	bra	b_putmes11

putmes_hira:				*半角ひらがな
	SHIFT_HALF_HIRA d1
	bsr	putc_fonchg
	lsl	#4,d1
	adda	d1,a0

b_putmes10:				*半角文字の表示		<+05
	move.b	(CHRSELFLG,pc),d0
	bne	b_putmes11		*半角文字変換はしない
	cmpi	#'\'<<3,d1
	bcs	b_putmes11
	beq	b_putmes10_1
	cmpi	#'~'<<3,d1
	beq	b_putmes10_2
	cmpi	#'|'<<3,d1
	bne	b_putmes11

	btst	#2,(S_CHRSEL)		*|
	beq	b_putmes11

	lea	($82*16),a0
	bra	b_putmes10_3
b_putmes10_1:				*\
	btst	#0,(S_CHRSEL)
	beq	b_putmes11

	lea	($80*16),a0
	bra	b_putmes10_3
b_putmes10_2:				*~
	btst	#1,(S_CHRSEL)
	beq	b_putmes11

	lea	($81*16),a0
b_putmes10_3:
	adda.l	(FONTANK8,pc),a0
b_putmes11:
	lea	(putc_btbl,pc),a6
	move	(a2),d2
	jsr	(a6,d6.w)		*文字パターンの表示ルーチンを呼ぶ
	move	d2,(a2)
	addq	#1,d5
	addq.l	#1,a3
	dbra	d4,b_putmes2		*桁数が終わるまで繰り返し
	move	d5,d2
b_putmes99:
	movem.l	(sp)+,d1/d3/d5-d6/a2-a4/a6
	rts

*	IOCS _FNTADRのベクタが変更されている場合

b_putmes50:
	moveq	#0,d1
	move.b	(a1)+,d1
	beq	b_putmes51		*表示文字列が終了した
	cmpi.b	#$fe,d1			*$fe→$20
	bne	b_putmes53
	bra	b_putmes52
b_putmes51:
	subq.l	#1,a1
b_putmes52:
	moveq	#' ',d1
b_putmes53:
	tst.b	d1
	bpl	b_putmes55		*半角文字($00～$7f)
	cmpi.b	#$a0,d1
	bcs	b_putmes54		*全角文字($80xx～$9fxx)
	cmpi.b	#$e0,d1
	bcs	b_putmes55		*半角文字($a0～$df)
b_putmes54:
.if CPU>=68020
	lsl	#8,d1
.else
	move.b	d1,-(sp)
	move	(sp)+,d1
.endif
	move.b	(a1)+,d1		*下位バイト
	beq	b_putmes51		*上位バイトで文字列が終わってしまった
b_putmes55:
	moveq	#8,d2
	movea.l	(_FNTADR*4+$400),a0
	jsr	(a0)
	movea.l	d0,a0			*フォントパターンの格納アドレス
	tst	d1
	beq	b_putmes60
	subq	#1,d4
	bmi	b_putmes57		*表示桁数が半角１文字分しか残っていない
	lea	(putc_wetbl,pc),a6	*全角文字の場合(偶数アドレス)
.if CPU<68020
	move	a3,d0
	lsr	#1,d0
	bcc	b_putmes56
	lea	(putc_wotbl,pc),a6	*全角文字の場合(奇数アドレス)
b_putmes56:
.endif
	move	(a2),d2
	jsr	(a6,d6.w)		*文字パターンの表示ルーチンを呼ぶ
	move	d2,(a2)
	addq	#2,d5
	addq.l	#2,a3
	dbra	d4,b_putmes50		*桁数が終わるまで繰り返し
	move	d5,d2
	movem.l	(sp)+,d1/d3/d5-d6/a2-a4/a6
	rts
b_putmes57:
	moveq	#0,d4
	beq	b_putmes52

b_putmes60:				*半角文字の表示
	lea	(putc_btbl,pc),a6
	move	(a2),d2
	jsr	(a6,d6.w)		*文字パターンの表示ルーチンを呼ぶ
	move	d2,(a2)
	addq	#1,d5
	addq.l	#1,a3
	dbra	d4,b_putmes50		*桁数が終わるまで繰り返し
	move	d5,d2
	movem.l	(sp)+,d1/d3/d5-d6/a2-a4/a6
	rts



*****************************************
*	IOCS $21	_B_PRINT	*
*****************************************

b_print::
	tst.b	(CSRSW)			*_B_CUROFFの処理
	bne.s	b_print1		*_OS_CUROFの状態
	move	#5,(CSRTIMER)
	sf	(CSRSWITCH)
	tst.b	(CSRSTAT)
	beq.s	b_print1
	bsr	csrwrite		*カーソルを消去
	sf	(CSRSTAT)
b_print1:
	movem.l	d1-d3/a2-a3,-(sp)
	moveq	#0,d1
	move.b	(a1)+,d1
	beq	b_putc2
b_print2:
	bsr	putc
b_print3:
	moveq	#0,d1
	move.b	(a1)+,d1
	bne	b_print2
b_putc2:
	movem.l	(sp)+,d1-d3/a2-a3
	tst.b	(CSRSW)			*_B_CURONの処理(必ず_B_CUROFFの状態)
	bne.s	b_print4		*_OS_CUROFの状態
	move	#5,(CSRTIMER)		*0.05秒後にカーソル点灯
	st	(CSRSWITCH)
b_print4:
	move.l	(CSRX),d0
	rts



*=======================================*
*　　バックログ付き１文字表示ルーチン	*
*=======================================*

putc_log::
	movea.l	(LOGBUFVECT,pc),a2
	move.b	(FIRSTBYTE),d0
	bne.s	putc_log1
	cmpi.l	#fntadr,(_FNTADR*4+$400)	*IOCS _FNTADRは内部ルーチンか？
	bne.s	putc_log5
	cmpi	#$0100,d1
	bcc.s	putc_log3		*２バイト文字
putc_log0:
	lea	(chrtable,pc),a3
.if CPU>=68020
	lea	(a3,d1.w*sizeof_CHRTABLE),a0
.else
	move	d1,d2
	lsl	#3,d2
	lea	(a3,d2.w),a0
.endif
	move	(a0)+,d2
	tst.b	(~jisflag-~fntadr,a0)
	bgt	@f
	jsr	(a2)			*!(mi or eq)
@@:
	jmp	(a3,d2.w)

putc_log1:				*文字コードの続き
	bpl	putc_log2
.if CPU>=68020
	lsl	#8,d0
.else
	move	(FIRSTBYTE),d0
.endif
	move.b	d1,d0
	move	d0,d1
	moveq	#0,d0			*condrvの仕様上、ESCシーケンス中でないときはd0.b!=$1bにする。
					*FIRSTBYTE==$80,d1.w==$1bのとき、d0.bに$1bが残らないように注意。
	move.b	d0,(FIRSTBYTE)
	jsr	(a2)
	cmpi.l	#fntadr,(_FNTADR*4+$400)	*IOCS _FNTADRは内部ルーチンか？
	beq	putc_2bA		*２バイト文字の２バイト目	<+03
	bra	putc4			*<+02 to here
putc_log2:
	jsr	(a2)
	bra	putc_escsq		*ESCシーケンス

putc_log3:				*２バイト文字
	jsr	(a2)
	bra	putc_2bB

putc_log4:				*IOCS _FNTADRによってフォントアドレスを得る
	jsr	(a2)
	bra	putc4

putc_log5:				*IOCS _FNTADRのベクタが変更されている場合
	cmpi	#$0020,d1
	bcs.s	putc_log0		*コントロールコード
	cmpi	#$0100,d1
	bcc.s	putc_log4		*２バイト文字
.if CPU>=68020
;d0.b == 0
	tst.b	(chrtable+~jisflag,pc,d1.w*8)
.else
	move	d1,d0
	lsl	#3,d0			*d0.b!=$1bなのでcondrv対策のクリアは不要
	LEA_CHRTABLE $00,~jisflag,a3
	tst.b	(a3,d0.w)
.endif
	ble.s	putc_log4		*mi or eq
	move.b	d1,(FIRSTBYTE)		*２バイト文字の１バイト目
	rts

*****************************************
*	IOCS $20	_B_PUTC		*
*****************************************

b_putc::
	tst.b	(CSRSW)			*_B_CUROFFの処理
	bne.s	b_putc1			*_OS_CUROFの状態
	move	#5,(CSRTIMER)
	sf	(CSRSWITCH)
	tst.b	(CSRSTAT)
	beq.s	b_putc1
	bsr	csrwrite		*カーソルを消去
	sf	(CSRSTAT)
b_putc1:
	movem.l	d1-d3/a2-a3,-(sp)
	pea	(b_putc2,pc)

*=======================================*
*	１文字表示ルーチン		*
*=======================================*

putc::
	move.b	(FIRSTBYTE),d0
	bne	putc1			*２バイト文字,ESCシーケンスの続き
	cmpi.l	#fntadr,(_FNTADR*4+$400)
	bne	putc5			*IOCS _FNTADRは内部ルーチンではない

	cmpi	#$0100,d1
	bcc	putc_2bB		*２バイト文字
putc0:
.if CPU>=68020
	lea	(chrtable,pc,d1.w*8),a0
.else
	move	d1,d0
	lsl	#3,d0
	lea	(chrtable,pc,d0.w),a0
.endif
	move	(a0)+,d0		*~jobadr
	jmp	(chrtable,pc,d0.w)

putc1:					*文字コードの続き
	bpl	putc_escsq		*ESCシーケンス

	clr.b	(FIRSTBYTE)		*２バイト文字の２バイト目	<+03
	cmpi.l	#fntadr,(_FNTADR*4+$400)
	beq	putc_2bA		*IOCS _FNTADRは内部ルーチン
.if CPU>=68020
	lsl	#8,d0
	move.b	d1,d0
	move	d0,d1
.else
	move	d1,-(sp)
	move.b	d0,(sp)
	move	(sp)+,d1
.endif
putc4:					*IOCS _FNTADRによってフォントアドレスを得る
	moveq	#8,d2
	movea.l	(_FNTADR*4+$400),a0
	jsr	(a0)
	movea.l	d0,a0			*フォントパターンの格納アドレス
	tst	d1
	beq	putc_bpat		*半角文字の場合
	bra	putc_wpat		*全角文字の場合

putc5:					*IOCS _FNTADRのベクタが変更されている場合
	cmpi	#$0020,d1
	bcs.s	putc0			*コントロールコード
	cmpi	#$0100,d1
	bcc.s	putc4			*２バイト文字
.if CPU>=68020
	tst.b	(chrtable+~jisflag,pc,d1.w*8)
.else
	move	d1,d0
	lsl	#3,d0
	move.b	(chrtable+~jisflag,pc,d0.w),d0
.endif
	ble.s	putc4			*mi or eq
	move.b	d1,(FIRSTBYTE)		*２バイト文字の１バイト目
	rts



*-------------------------------------------------------*
*	文字コード→処理アドレスの変換テーブル		*
*-------------------------------------------------------*

TABLE:	.macro	jobadr,fntadr,knjflag,jisflag
	.dc	jobadr-chrtable
	.dc.l	fntadr
	.dc.b	knjflag,jisflag
	i:=i+1
	.endm

*	jisflag
*	$00:未定義コード
*	$ff:ＪＩＳコード範囲/半角文字	($21～$7e)
*	$01:非漢字			($81～$84($87))
*	$02:第１水準漢字		($89～$97)
*	$03:第２水準漢字		($99～$ea)
*	$04:半角ひらがな		($80)
*	$05～$07:拡張外字/外字Ａ	($85～$87)
*	$08:拡張外字/漢字 境界		($88)
*	$09:漢字/外字Ｂ 境界		($eb)
*	$0a:外字Ｂ/未定義		($ec～$ef)
*	$0b:非漢字/第１水準 境界	($88)
*	$0c:第１水準/第２水準 境界	($98)
*	$0d:半角外字			($f4～$f5)
*	$0e～$11:1/4角文字		($f0～$f3)
*	$12:半角非漢字			($85)
*	$13:半角非漢字/全角非漢字 境界	($86)

chrtable::
	i:=0
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$00		<+05
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$01
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$02
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$03
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$04
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$05
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$06
	TABLE	putc_bel,i*16+fon_ank8,0,-1	*$07:BEL
	TABLE	putc_bs,i*16+fon_ank8,0,-1	*$08:BS
	TABLE	putc_ht,i*16+fon_ank8,0,-1	*$09:HT
	TABLE	putc_lf,i*16+fon_ank8,0,-1	*$0a:LF
	TABLE	putc_vt,i*16+fon_ank8,0,-1	*$0b:VT
	TABLE	putc_ff,i*16+fon_ank8,0,-1	*$0c:FF
	TABLE	putc_cr,i*16+fon_ank8,0,-1	*$0d:CR
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$0e
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$0f
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$10
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$11
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$12
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$13
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$14
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$15
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$16
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$17
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$18
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$19
	TABLE	putc_sub,i*16+fon_ank8,0,-1	*$1a:SUB
	TABLE	putc_esc,i*16+fon_ank8,0,-1	*$1b:ESC
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$1c
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$1d
	TABLE	putc_rs,i*16+fon_ank8,0,-1	*$1e:RS
	TABLE	putc_nul,i*16+fon_ank8,0,-1	*$1f		<+05

	TABLE	putc_1b,i*16+fon_ank8,0,0	*$20
	.rept	$5c-$21				*$21～$5b(ANK)
	TABLE	putc_1b,i*16+fon_ank8,0,-1
	.endm
	TABLE	putc_1bsw1,i*16+fon_ank8,0,-1	*$5c(\)
	.rept	$7c-$5d				*$5d～$7b
	TABLE	putc_1b,i*16+fon_ank8,0,-1
	.endm
	TABLE	putc_1bsw2,i*16+fon_ank8,0,-1	*$7c(|)
	TABLE	putc_1b,i*16+fon_ank8,0,-1	*$7d
	TABLE	putc_1bsw3,i*16+fon_ank8,0,-1	*$7e(~)
	TABLE	putc_1b,i*16+fon_ank8,0,0	*$7f(DEL)

	TABLE	putc_first,fon_ank8,0,4		*$80(半角ひらがな)

	i:=0
	.rept	4				*$81～$84(非漢字)
	TABLE	putc_first,i*$1780+fon_knj16,-1,1
	.endm

	TABLE	putc_first,0,0,5		*$85～$87(外字Ａ/拡張外字)
	TABLE	putc_first,-$0bc0,0,6
	TABLE	putc_first,$0bc0,0,7

	i:=0					*$88(拡張外字/第１水準)
	TABLE	putc_first,i*$1780+$5e00-$0bc0+fon_knj16,0,8
	.rept	$98-$89				*$89～$97(第１水準)
	TABLE	putc_first,i*$1780+$5e00-$0bc0+fon_knj16,-1,2
	.endm					*$98(第１水準/第２水準)
	TABLE	putc_first,i*$1780+$5e00-$0bc0+fon_knj16,-1,2
	i:=1
	.rept	$a0-$99				*$99～$9f(第２水準)
	TABLE	putc_first,i*$1780+$1d600-$0bc0+fon_knj16,-1,3
	.endm

	i:=$a0
	.rept	$40				*$a0～$df(ANK)
	TABLE	putc_1b,i*16+fon_ank8,0,0
	.endm

	i:=8
	.rept	$eb-$e0				*$e0～$ea(第２水準)
	TABLE	putc_first,i*$1780+$1d600-$0bc0+fon_knj16,-1,3
	.endm					*$eb(第２水準/外字Ｂ)
	TABLE	putc_first,i*$1780+$1d600-$0bc0+fon_knj16,0,9

	TABLE	putc_first,$0bc0,0,10		*$ec～$ef(外字Ｂ/未定義)
	TABLE	putc_first,$0bc0+$1780,0,10
	TABLE	putc_first,$0bc0+$1780*2,0,10
	TABLE	putc_first,$0bc0+$1780*3,0,10

	TABLE	putc_first,fon_sml8,0,14	*$f0～$f3(1/4角文字)
	TABLE	putc_first,fon_sml8,0,15
	TABLE	putc_first,fon_sml8,0,16
	TABLE	putc_first,fon_sml8,0,17

	.rept	6				*$f4～$ff(半角外字/未定義)
	TABLE	putc_first,$0000,0,13
	TABLE	putc_first,$1000,0,13
	.endm


*---------------------------------------*
*	１バイト文字の処理		*
*---------------------------------------*

*	１バイト文字の表示

putc_1bsw1:				*\
	btst	#0,(S_CHRSEL)
	beq	putc_1b
	move.b	(CHRSELFLG,pc),d0
	bne	putc_1b
.if CPU>=68020
	lea	([FONTANK8,pc],$80*16),a0
.else
	movea.l	(FONTANK8,pc),a0
	lea	($80*16,a0),a0
.endif
	bra	putc_bpat
putc_1bsw2:				*|
	btst	#2,(S_CHRSEL)
	beq	putc_1b
	move.b	(CHRSELFLG,pc),d0
	bne	putc_1b
.if CPU>=68020
	lea	([FONTANK8,pc],$82*16),a0
.else
	movea.l	(FONTANK8,pc),a0
	lea	($82*16,a0),a0
.endif
	bra	putc_bpat
putc_1bsw3:				*~
	btst	#1,(S_CHRSEL)
	beq	putc_1b
	move.b	(CHRSELFLG,pc),d0
	bne	putc_1b
.if CPU>=68020
	lea	([FONTANK8,pc],$81*16),a0
.else
	movea.l	(FONTANK8,pc),a0
	lea	($81*16,a0),a0
.endif
	bra	putc_bpat

putc_1b:
	movea.l	(a0),a0			*フォントパターン格納アドレス

*	(a0)の半角フォントパターンの表示

putc_bpat:
	move	(CSRX),d2
	cmp	(CSRXMAX),d2
	bhi.s	putc_bpat2		*カーソルが画面右端を越えている
putc_bpat1:
	moveq	#0,d3
	move	(CSRY),d3
	swap	d3
	lsr.l	#5,d3			*128×16倍
	add	d2,d3
	add.l	(TXSTOFST),d3
	add.l	(TXADR),d3		*ＶＲＡＭアドレス
	movea.l	d3,a3
	lea	(_CRTC21),a2
	moveq	#$f,d0
	and.b	(TXCOLOR),d0
	move	(a2),d2
.if CPU>=68020
	jsr	(putc_btbl,pc,d0.w*2)
.else
	add	d0,d0
	jsr	(putc_btbl,pc,d0.w)	*色コード別の文字表示ルーチンを呼ぶ
.endif
	move	d2,(a2)
	addq	#1,(CSRX)
	rts

putc_bpat2:
	pea	(putc_bpat1,pc)
	moveq	#0,d2
putc_crlf:				*改行する
putc_lf:				*LFで復帰もする
	clr	(CSRX)
	move	(CSRY),d0
	addq	#1,d0
	cmp	(CSRYMAX),d0
	bhi	putc_rollup		*スクロールする
	move	d0,(CSRY)
	rts



putc_bbld1:
	move	#$0111,(a2)
	bsr	putc_bputbld		*プレーン０に表示
	move	#$0122,(a2)
	bra	putc_bclrpat		*プレーン１を消去
putc_bbld2:
	move	#$0111,(a2)
	bsr	putc_bclrpat		*プレーン０に消去
	move	#$0122,(a2)
	bra	putc_bputbld		*プレーン１を表示
putc_bbld3:
	move	#$0133,(a2)		*プレーン0,1同時アクセス
	bra	putc_bputbld
putc_brev1:
	move	#$0111,(a2)
	bsr	putc_bputrev		*プレーン０に表示
	move	#$0122,(a2)
	bra	putc_bclrpat		*プレーン１を消去
putc_brev2:
	move	#$0111,(a2)
	bsr	putc_bclrpat		*プレーン０に消去
	move	#$0122,(a2)
	bra	putc_bputrev		*プレーン１を表示
putc_brev3:
	move	#$0133,(a2)		*プレーン0,1同時アクセス
	bra	putc_bputrev

*	色コード別半角文字表示ルーチンジャンプテーブル

putc_btbl:
	bra.s	putc_bcol0	*通常表示
	bra.s	putc_bcol1
	bra.s	putc_bcol2
	bra.s	putc_bcol3
	bra.s	putc_bcol0	*強調
	bra.s	putc_bbld1
	bra.s	putc_bbld2
	bra.s	putc_bbld3
	bra.s	putc_bcol0	*反転
	bra.s	putc_brev1
	bra.s	putc_brev2
	bra.s	putc_brev3
	bra.s	putc_bcol0	*強調＋反転
	bra.s	putc_bbrv1
	bra.s	putc_bbrv2
**	bra.s	putc_bbrv3
**putc_bbrv3:
	move	#$0133,(a2)		*プレーン0,1同時アクセス
	bra	putc_bputbrv

putc_bbrv1:
	move	#$0111,(a2)
	bsr	putc_bputbrv		*プレーン０に表示
	move	#$0122,(a2)
	bra	putc_bclrpat		*プレーン１を消去
putc_bbrv2:
	move	#$0111,(a2)
	bsr	putc_bclrpat		*プレーン０に消去
	move	#$0122,(a2)
	bra	putc_bputbrv		*プレーン１を表示
**putc_bbrv3:
**	move	#$0133,(a2)		*プレーン0,1同時アクセス
**	bra	putc_bputbrv
putc_bcol0:
	move	#$0133,(a2)		*プレーン0,1同時アクセス
	bra	putc_bclrpat
putc_bcol1:
	move	#$0111,(a2)
	bsr	putc_bputpat		*プレーン０に表示
	move	#$0122,(a2)
	bra	putc_bclrpat		*プレーン１を消去
putc_bcol2:
	move	#$0111,(a2)
	bsr	putc_bclrpat		*プレーン０を消去
	move	#$0122,(a2)
	bra	putc_bputpat		*プレーン１に表示
putc_bcol3:
	move	#$0133,(a2)		*プレーン0,1同時アクセス


*	半角文字パターンを転送する

putc_bputpat:
.if UNROLL
	i:=0
	.rept	16
	move.b	(a0)+,(i,a3)
	i:=i+$0080
	.endm
.else
	moveq	#$80-1,d1
	moveq	#16/2-1,d3
@@:
	.rept	2
	move.b	(a0)+,(a3)+
	adda.l	d1,a3
	.endm
	dbra	d3,@b
	lea	(-$80*16,a3),a3
.endif
	rts

*	半角１文字分をクリアする

putc_bclrpat:
	moveq	#0,d0
.if UNROLL
	i:=0
	.rept	16
	move.b	d0,(i,a3)
	i:=i+$0080
	.endm
.else
	moveq	#$80-1,d1
	moveq	#16/2-1,d3
@@:
	.rept	2
	move.b	d0,(a3)+
	adda.l	d1,a3
	.endm
	dbra	d3,@b
	lea	(-$80*16,a3),a3
.endif
	rts

*	半角文字パターンを反転表示する

putc_bputrev:
.if UNROLL
	i:=0
	.rept	4
	move.l	(a0)+,d0
	not.l	d0
	move.b	d0,(i+$0180,a3)
	swap	d0
	move.b	d0,(i+$0080,a3)
	ror.l	#8,d0
	move.b	d0,(i+$0000,a3)
	swap	d0
	move.b	d0,(i+$0100,a3)
	i:=i+$0200
	.endm
.else
	moveq	#4-1,d1
@@:
	move.l	(a0)+,d0
	not.l	d0
	move.b	d0,($0180,a3)
	swap	d0
	move.b	d0,($0080,a3)
	ror.l	#8,d0
	move.b	d0,($0000,a3)
	swap	d0
	move.b	d0,($0100,a3)
	lea	($0200,a3),a3
	dbra	d1,@b
	lea	(-$80*16,a3),a3
.endif
	rts

*	半角文字パターンを強調表示する

putc_bputbld:
	move.l	#$7f7f7f7f,d0
.if UNROLL
	i:=0
	.rept	4
	move.l	(a0)+,d1
	move.l	d1,d3
	lsr.l	#1,d1
	and.l	d0,d1
	or.l	d3,d1
	move.b	d1,(i+$0180,a3)
	swap	d1
	move.b	d1,(i+$0080,a3)
	ror.l	#8,d1
	move.b	d1,(i+$0000,a3)
	swap	d1
	move.b	d1,(i+$0100,a3)
	i:=i+$0200
	.endm
.else
	move.l	d7,-(sp)
	moveq	#4-1,d7
@@:
	move.l	(a0)+,d1
	move.l	d1,d3
	lsr.l	#1,d1
	and.l	d0,d1
	or.l	d3,d1
	move.b	d1,($0180,a3)
	swap	d1
	move.b	d1,($0080,a3)
	ror.l	#8,d1
	move.b	d1,($0000,a3)
	swap	d1
	move.b	d1,($0100,a3)
	lea	($0200,a3),a3
	dbra	d7,@b
	lea	(-$80*16,a3),a3
	move.l	(sp)+,d7
.endif
	rts

*	半角文字パターンを強調＋反転表示する

putc_bputbrv:
	move.l	#$7f7f7f7f,d0
.if UNROLL
	i:=0
	.rept	4
	move.l	(a0)+,d1
	move.l	d1,d3
	lsr.l	#1,d1
	and.l	d0,d1
	or.l	d3,d1
	not.l	d1
	move.b	d1,(i+$0180,a3)
	swap	d1
	move.b	d1,(i+$0080,a3)
	ror.l	#8,d1
	move.b	d1,(i+$0000,a3)
	swap	d1
	move.b	d1,(i+$0100,a3)
	i:=i+$0200
	.endm
.else
	move.l	d7,-(sp)
	moveq	#4-1,d7
@@:
	move.l	(a0)+,d1
	move.l	d1,d3
	lsr.l	#1,d1
	and.l	d0,d1
	or.l	d3,d1
	not.l	d1
	move.b	d1,($0180,a3)
	swap	d1
	move.b	d1,($0080,a3)
	ror.l	#8,d1
	move.b	d1,($0000,a3)
	swap	d1
	move.b	d1,($0100,a3)
	lea	($0200,a3),a3
	dbra	d7,@b
	lea	(-$80*16,a3),a3
	move.l	(sp)+,d7
.endif
	rts


*---------------------------------------*
*	２バイト文字の処理		*
*---------------------------------------*

*	２バイト文字の１バイト目

putc_first:
	move.b	d1,(FIRSTBYTE)
	lea	(FIRSTFNT,pc),a2
	move.l	(a0)+,(a2)+		*FIRSTFNT
	move	(a0)+,(a2)+		*FIRSTFLG
	rts

*	２バイトが同時に送られた場合

putc_2bB:
	move	d1,d2
	clr.b	d2
	eor	d2,d1			*andi #$00ff,d1
	lsr	#5,d2			*d2.w = 上位バイト*sizeof_CHRTABLE
putc_2bB1:
	lea	(chrtable,pc),a0
	move.b	(~jisflag,a0,d2.w),d0
	movea.l	(~fntadr,a0,d2.w),a0
	beq	putc_undef		*未定義コード
	bpl	putc_2bA1

	cmpi	#$20*8,d2
	bcs	putc_ank		*?? $0100～$1fffは半角文字	<+06
	cmpi.b	#$21,d1			*ＪＩＳコード→Ｓ－ＪＩＳコード
	bcs	putc_undef
	cmpi.b	#$7e,d1
	bhi	putc_undef
	addi	#($81*2-$21)*8,d2
	lsr	#4,d2
	bcc	putc_2bB2
	addi.b	#$7f-$21,d1
putc_2bB2:
	addi.b	#$40-$21,d1
	cmpi.b	#$7f,d1
	bcs	putc_2bB3
	addq.b	#1,d1
putc_2bB3:
	cmpi.b	#$a0,d2
	bcs	putc_2bB4
	add.b	#$e0-$a0,d2
putc_2bB4:
	lsl	#3,d2
	bra	putc_2bB1


*	半角文字の変換

putc_fonchg:
	btst	#0,(CHRSELFLG,pc)	*( tst.b CHRSELFLG(pc) )
	bne	putc_fonchg1		*半角文字変換はしない
putc_fonchg0:
	cmpi.b	#'\',d1
	bcs	putc_fonchg1
	beq	putc_fonchg2
	cmpi.b	#'~',d1
	beq	putc_fonchg3
	cmpi.b	#'|',d1
	beq	putc_fonchg4
putc_fonchg1:
	rts
putc_fonchg2:				*\
	btst	#0,(S_CHRSEL)
	beq	putc_fonchg1

	move.b	#$80,d1
	rts
putc_fonchg3:				*~
	btst	#1,(S_CHRSEL)
	beq	putc_fonchg1

	addq.b	#$81-'~',d1
	rts
putc_fonchg4:				*|
	btst	#2,S_CHRSEL
	beq	putc_fonchg1

	addq.b	#$82-'|',d1
	rts

putc_extk:				*拡張外字
	move.l	(EXCHRVECT,pc),d2
	beq	putc_undef		*拡張外字ベクタは未設定
	movea.l	d2,a0
	subi.b	#$40,d1
	bcs	putc_undef
	cmpi.b	#$7f-$40,d1
	bcs	putc_extk1
	beq	putc_undef
	subq.b	#1,d1
putc_extk1:
	cmpi.b	#$fc-1-$40,d1
	bhi	putc_undef
	exg	d0,d1
	ext	d1
	add.b	d1,d1
	subq.b	#2,d1
	cmpi.b	#$5e,d0			*	<+06
	bcs	putc_extk2
	subi.b	#$5e,d0			*	<+06
	addq.b	#1,d1
putc_extk2:
	moveq	#8,d2
	jsr	(a0)			*拡張外字処理呼び出し
	movea.l	d0,a0
	tst	d1
	beq	putc_bpat
	bra	putc_wpat

putc_hkanji:				*半角非漢字	<+07
	beq	putc_hkanji1
	cmpi.b	#$9f,d1
	bcc	putc_kanji		*～$869e:半角非漢字 / $869f～:全角非漢字
putc_hkanji1:
.if CPU>=68020
	move	(sjis2tbl,pc,d1.w*2),d1
.else
	lea	(sjis2tbl,pc),a3
	add	d1,d1
	move	(a3,d1.w),d1
.endif
	bmi	putc_undef		*未定義コード
	adda	d1,a0
	bra	putc_bpat

putc_small:				*1/4角文字
	cmpi.b	#$12,d0			*	<+07
	bcc	putc_hkanji		*半角非漢字
	lsr.b	#1,d0
	bcc	@f
	SHIFT_HALF_HIRA d1
@@:
	bsr	putc_fonchg0
	lea	(MKFONTBUF),a3
	lea	(8,a3),a2
	lsr.b	#1,d0
	bcs	putc_small2
	exg	a3,a2
putc_small2:
	clr.l	(a2)+
	clr.l	(a2)+
	lsl	#3,d1
	adda	d1,a0
	move.l	(a0)+,(a3)+
	move.l	(a0)+,(a3)+
	lea	(MKFONTBUF),a0
	bra	putc_bpat

putc_ank:				*半角文字($01xx～$1fxx)		<+06
	movea.l	(FONTANK8,pc),a0
	bra	putc_hira1

putc_hira:				*半角ひらがな
	SHIFT_HALF_HIRA d1
putc_hira1:
	bsr	putc_fonchg
	lsl	#4,d1
	adda	d1,a0
	bra	putc_bpat

putc_knjAB:				*～$889e:非漢字   / $889f～:第１水準
	cmpi.b	#$9f,d1			*～$989e:第１水準 / $989f～:第２水準
	bcs	putc_kanji
	ext	d0
.if CPU>=68020
	lea	([(FONTKNJ16B-11*4).w,pc,d0.w*4],-$0bc0),a0
.else
	add	d0,d0
	add	d0,d0
	lea	(FONTKNJ16B,pc),a0
	movea.l	(-11*4,a0,d0.w),a0
	lea	(-$0bc0,a0),a0
.endif
	bra	putc_kanji

*	２バイトが別々に送られた場合

putc_2bA:
	andi	#$00ff,d1
	movea.l	(FIRSTFNT,pc),a0
	move	(FIRSTFLG,pc),d0
	bmi.s	putc_kanji		*		全角漢字/非漢字
putc_2bA1:				*<+03
	cmpi.b	#$04,d0
	bcs.s	putc_kanji		*		全角漢字/非漢字
	beq.s	putc_hira		*$80xx		半角ひらがな
	cmpi.b	#$08,d0
	beq	putc_knj88		*$88xx		拡張外字/漢字 境界
	bcs	putc_uskA		*$85xx～$87xx	外字Ａ/拡張用
	cmpi.b	#$0a,d0
	beq	putc_uskB		*$ecxx～$efxx	外字Ｂ/未定義
	bcs	putc_knjeb		*$ebxx		漢字/外字Ｂ 境界
	cmpi.b	#$0d,d0
	bhi	putc_small		*$f0xx～$f3xx	1/4角文字 / $85xx,$86xx 半角非漢字
	bcs	putc_knjAB		*$88xx,$98xx	非漢字/第１水準/第２水準 境界
	adda.l	(USKFONT2),a0		*$f4xx～$ffxx	半角外字
	lsl	#4,d1
	adda	d1,a0
	bra	putc_bpat

putc_uskA:				*外字Ａ/拡張外字
	adda.l	(USKFONT0),a0
	cmpi.b	#$06,d0
	bcs	putc_extk
	bne	putc_uskA1
	cmpi.b	#$9f,d1
	bcc	putc_kanji
	bra	putc_extk
putc_uskA1:
	cmpi.b	#$9f,d1
	bcs	putc_kanji
	bra	putc_extk

putc_undef:				*未定義の漢字コード
	movea.l	(UNDEFPTR,pc),a0
	bra	putc_wpat

putc_knjeb:				*～$eb9e:漢字     / $eb9f～:外字Ｂ
	cmpi.b	#$9f,d1
	bcs.s	putc_kanji
	movea	#-$0bc0,a0
putc_uskB:				*外字Ｂ
	adda.l	(USKFONT1),a0
	bra	putc_kanji

putc_knj88:				*～$889e:拡張外字 / $889f～:漢字
	cmpi.b	#$9f,d1
	bcs	putc_extk
putc_kanji:				*全角漢字/非漢字
.if CPU>=68020
	move	(sjis2tbl,pc,d1.w*2),d1
.else
	lea	(sjis2tbl,pc),a3
	add	d1,d1
	move	(a3,d1.w),d1
.endif
	bmi.s	putc_undef		*未定義コード
	adda	d1,a0

*	(a0)の全角フォントパターンの表示

putc_wpat:
	move	(CSRX),d2
	cmp	(CSRXMAX),d2
	bcc	putc_wpat2		;カーソル位置に半角１文字分しかスペースがない
*	bhi	putc_wpat3		;カーソルが画面右端を越えている
putc_wpat1:
	moveq	#0,d3
	move	(CSRY),d3
	swap	d3
	lsr.l	#5,d3			*128×16倍
	add	d2,d3
	add.l	(TXSTOFST),d3
	add.l	(TXADR),d3		*ＶＲＡＭアドレス
	movea.l	d3,a3
	lea	(_CRTC21),a2
	moveq	#$f,d0
	and.b	(TXCOLOR),d0
	move	(a2),d2
.if CPU>=68020
	jsr	(putc_wetbl,pc,d0.w*2)
.else
	add	d0,d0
	lsr	#1,d3
	bcs	putc_wpat5		*アドレスが奇数の場合
	jsr	(putc_wetbl,pc,d0.w)	*色コード別の文字表示ルーチンを呼ぶ(偶数)
.endif
	move	d2,(a2)
	addq	#2,(CSRX)
	rts

putc_wpat2:
	bhi	putc_wpat3		*カーソルが画面右端を越えている
	move.l	a0,-(sp)
	movea.l	(chrtable+(' '*sizeof_CHRTABLE)+~fntadr,pc),a0
	bsr	putc_bpat1
	movea.l	(sp)+,a0
putc_wpat3:				*改行する
	pea	(putc_wpat1,pc)
	moveq	#0,d2
	bra	putc_crlf


*	アドレスが偶数の場合の全角文字表示

putc_webld1:
	move	#$0111,(a2)
	bsr	putc_weputbld		*プレーン０に表示
	move	#$0122,(a2)
	bra	putc_weclrpat		*プレーン１を消去
putc_webld2:
	move	#$0111,(a2)
	bsr	putc_weclrpat		*プレーン０に消去
	move	#$0122,(a2)
	bra	putc_weputbld		*プレーン１を表示
putc_webld3:
	move	#$0133,(a2)		*プレーン0,1同時アクセス
	bra	putc_weputbld
putc_werev1:
	move	#$0111,(a2)
	bsr	putc_weputrev		*プレーン０に表示
	move	#$0122,(a2)
	bra	putc_weclrpat		*プレーン１を消去
putc_werev2:
	move	#$0111,(a2)
	bsr	putc_weclrpat		*プレーン０に消去
	move	#$0122,(a2)
	bra	putc_weputrev		*プレーン１を表示
putc_werev3:
	move	#$0133,(a2)		*プレーン0,1同時アクセス
	bra	putc_weputrev

*	色コード別全角文字表示ルーチンジャンプテーブル(偶数)

putc_wetbl:
	bra.s	putc_wecol0	*通常表示
	bra.s	putc_wecol1
	bra.s	putc_wecol2
	bra.s	putc_wecol3
	bra.s	putc_wecol0	*強調
	bra.s	putc_webld1
	bra.s	putc_webld2
	bra.s	putc_webld3
	bra.s	putc_wecol0	*反転
	bra.s	putc_werev1
	bra.s	putc_werev2
	bra.s	putc_werev3
	bra.s	putc_wecol0	*強調＋反転
	bra.s	putc_webrv1
	bra.s	putc_webrv2
**	bra.s	putc_webrv3
**putc_webrv3:
	move	#$0133,(a2)		*プレーン0,1同時アクセス
	bra	putc_weputbrv

putc_webrv1:
	move	#$0111,(a2)
	bsr	putc_weputbrv		*プレーン０に表示
	move	#$0122,(a2)
	bra	putc_weclrpat		*プレーン１を消去
putc_webrv2:
	move	#$0111,(a2)
	bsr	putc_weclrpat		*プレーン０に消去
	move	#$0122,(a2)
	bra	putc_weputbrv		*プレーン１を表示
**putc_webrv3:
**	move	#$0133,(a2)		*プレーン0,1同時アクセス
**	bra	putc_weputbrv
putc_wecol0:
	move	#$0133,(a2)		*プレーン0,1同時アクセス
	bra	putc_weclrpat
putc_wecol1:
	move	#$0111,(a2)
	bsr	putc_weputpat		*プレーン０に表示
	move	#$0122,(a2)
	bra	putc_weclrpat		*プレーン１を消去
putc_wecol2:
	move	#$0111,(a2)
	bsr	putc_weclrpat		*プレーン０を消去
	move	#$0122,(a2)
	bra	putc_weputpat		*プレーン１に表示
putc_wecol3:
	move	#$0133,(a2)		*プレーン0,1同時アクセス


*	全角文字パターンを転送する(偶数)

putc_weputpat:
.if UNROLL
	i:=0
	.rept	16
	move	(a0)+,(i,a3)
	i:=i+$0080
	.endm
.else
	moveq	#$80-2,d1
	moveq	#16/2-1,d3
@@:
	.rept	2
	move	(a0)+,(a3)+
	adda.l	d1,a3
	.endm
	dbra	d3,@b
	lea	(-$80*16,a3),a3
.endif
	rts

*	全角１文字分をクリアする(偶数)

putc_weclrpat:
	moveq	#0,d0
.if UNROLL
	i:=0
	.rept	16
	move	d0,(i,a3)
	i:=i+$0080
	.endm
.else
	moveq	#$80-2,d1
	moveq	#16/2-1,d3
@@:
	.rept	2
	move	d0,(a3)+
	adda.l	d1,a3
	.endm
	dbra	d3,@b
	lea	(-$80*16,a3),a3
.endif
	rts

*	全角文字パターンを反転表示する(偶数)

putc_weputrev:
.if UNROLL
	i:=0
	.rept	8
	move.l	(a0)+,d0
	not.l	d0
	move	d0,(i+$0080,a3)
	swap	d0
	move	d0,(i+$0000,a3)
	i:=i+$0100
	.endm
.else
	moveq	#$0100>>8,d1
	lsl	#8,d1
	moveq	#8-1,d3
@@:
	move.l	(a0)+,d0
	not.l	d0
	move	d0,($0080,a3)
	swap	d0
	move	d0,($0000,a3)
	adda.l	d1,a3
	dbra	d3,@b
	lea	(-$80*16,a3),a3
.endif
	rts

*	全角文字パターンを強調表示する(偶数)

putc_weputbld:
	move.l	#$7fff7fff,d0
.if UNROLL
	i:=0
	.rept	8
	move.l	(a0)+,d1
	move.l	d1,d3
	lsr.l	#1,d1
	and.l	d0,d1
	or.l	d3,d1
	move	d1,(i+$0080,a3)
	swap	d1
	move	d1,(i+$0000,a3)
	i:=i+$0100
	.endm
.else
	move.l	d7,-(sp)
	moveq	#8-1,d7
@@:
	move.l	(a0)+,d1
	move.l	d1,d3
	lsr.l	#1,d1
	and.l	d0,d1
	or.l	d3,d1
	move	d1,($0080,a3)
	swap	d1
	move	d1,($0000,a3)
	lea	($0100,a3),a3
	dbra	d7,@b
	lea	(-$80*16,a3),a3
	move.l	(sp)+,d7
.endif
	rts

*	全角文字パターンを強調＋反転表示する(偶数)

putc_weputbrv:
	move.l	#$7fff7fff,d0
.if UNROLL
	i:=0
	.rept	8
	move.l	(a0)+,d1
	move.l	d1,d3
	lsr.l	#1,d1
	and.l	d0,d1
	or.l	d3,d1
	not.l	d1
	move	d1,(i+$0080,a3)
	swap	d1
	move	d1,(i+$0000,a3)
	i:=i+$0100
	.endm
.else
	move.l	d7,-(sp)
	moveq	#8-1,d7
@@:
	move.l	(a0)+,d1
	move.l	d1,d3
	lsr.l	#1,d1
	and.l	d0,d1
	or.l	d3,d1
	not.l	d1
	move	d1,($0080,a3)
	swap	d1
	move	d1,($0000,a3)
	lea	($0100,a3),a3
	dbra	d7,@b
	lea	(-$80*16,a3),a3
	move.l	(sp)+,d7
.endif
	rts



.if CPU<68020
putc_wpat5:
	jsr	(putc_wotbl,pc,d0.w)	*色コード別の文字表示ルーチンを呼ぶ(奇数)
	move	d2,(a2)
	addq	#2,(CSRX)
	rts

*	アドレスが奇数の場合の全角文字表示

putc_wobld1:
	move	#$0111,(a2)
	bsr	putc_woputbld		*プレーン０に表示
	move	#$0122,(a2)
	bra	putc_woclrpat		*プレーン１を消去
putc_wobld2:
	move	#$0111,(a2)
	bsr	putc_woclrpat		*プレーン０に消去
	move	#$0122,(a2)
	bra	putc_woputbld		*プレーン１を表示
putc_wobld3:
	move	#$0133,(a2)		*プレーン0,1同時アクセス
	bra	putc_woputbld
putc_worev1:
	move	#$0111,(a2)
	bsr	putc_woputrev		*プレーン０に表示
	move	#$0122,(a2)
	bra	putc_woclrpat		*プレーン１を消去
putc_worev2:
	move	#$0111,(a2)
	bsr	putc_woclrpat		*プレーン０に消去
	move	#$0122,(a2)
	bra	putc_woputrev		*プレーン１を表示
putc_worev3:
	move	#$0133,(a2)		*プレーン0,1同時アクセス
	bra	putc_woputrev

*	色コード別全角文字表示ルーチンジャンプテーブル(奇数)

putc_wotbl:
	bra.s	putc_wocol0	*通常表示
	bra.s	putc_wocol1
	bra.s	putc_wocol2
	bra.s	putc_wocol3
	bra.s	putc_wocol0	*強調
	bra.s	putc_wobld1
	bra.s	putc_wobld2
	bra.s	putc_wobld3
	bra.s	putc_wocol0	*反転
	bra.s	putc_worev1
	bra.s	putc_worev2
	bra.s	putc_worev3
	bra.s	putc_wocol0	*強調＋反転
	bra.s	putc_wobrv1
	bra.s	putc_wobrv2
**	bra.s	putc_wobrv3
**putc_wobrv3:
	move	#$0133,(a2)		*プレーン0,1同時アクセス
	bra	putc_woputbrv

putc_wobrv1:
	move	#$0111,(a2)
	bsr	putc_woputbrv		*プレーン０に表示
	move	#$0122,(a2)
	bra	putc_woclrpat		*プレーン１を消去
putc_wobrv2:
	move	#$0111,(a2)
	bsr	putc_woclrpat		*プレーン０に消去
	move	#$0122,(a2)
	bra	putc_woputbrv		*プレーン１を表示
**putc_wobrv3:
**	move	#$0133,(a2)		*プレーン0,1同時アクセス
**	bra	putc_woputbrv
putc_wocol0:
	move	#$0133,(a2)		*プレーン0,1同時アクセス
	bra	putc_woclrpat
putc_wocol1:
	move	#$0111,(a2)
	bsr	putc_woputpat		*プレーン０に表示
	move	#$0122,(a2)
	bra	putc_woclrpat		*プレーン１を消去
putc_wocol2:
	move	#$0111,(a2)
	bsr	putc_woclrpat		*プレーン０を消去
	move	#$0122,(a2)
	bra	putc_woputpat		*プレーン１に表示
putc_wocol3:
	move	#$0133,(a2)		*プレーン0,1同時アクセス


	.fail	UNROLL.eq.0

*	全角文字パターンを転送する(奇数)

putc_woputpat:
	i:=0
	.rept	16
	move.b	(a0)+,(i+0,a3)
	move.b	(a0)+,(i+1,a3)
	i:=i+$0080
	.endm
	rts

*	全角１文字分をクリアする(奇数)

putc_woclrpat:
	moveq	#0,d0
	i:=0
	.rept	16
	move.b	d0,(i+0,a3)
	move.b	d0,(i+1,a3)
	i:=i+$0080
	.endm
	rts

*	全角文字パターンを反転表示する(奇数)

putc_woputrev:
	i:=0
	.rept	8
	move.l	(a0)+,d0
	not.l	d0
	move.b	d0,(i+$0081,a3)
	swap	d0
	move.b	d0,(i+$0001,a3)
	ror.l	#8,d0
	move.b	d0,(i+$0000,a3)
	swap	d0
	move.b	d0,(i+$0080,a3)
	i:=i+$0100
	.endm
	rts

*	全角文字パターンを強調表示する(奇数)

putc_woputbld:
	move.l	#$7fff7fff,d0
	i:=0
	.rept	8
	move.l	(a0)+,d1
	move.l	d1,d3
	lsr.l	#1,d1
	and.l	d0,d1
	or.l	d3,d1
	move.b	d1,(i+$0081,a3)
	swap	d1
	move.b	d1,(i+$0001,a3)
	ror.l	#8,d1
	move.b	d1,(i+$0000,a3)
	swap	d1
	move.b	d1,(i+$0080,a3)
	i:=i+$0100
	.endm
	rts

*	全角文字パターンを強調＋反転表示する(奇数)

putc_woputbrv:
	move.l	#$7fff7fff,d0
	i:=0
	.rept	8
	move.l	(a0)+,d1
	move.l	d1,d3
	lsr.l	#1,d1
	and.l	d0,d1
	or.l	d3,d1
	not.l	d1
	move.b	d1,(i+$0081,a3)
	swap	d1
	move.b	d1,(i+$0001,a3)
	ror.l	#8,d1
	move.b	d1,(i+$0000,a3)
	swap	d1
	move.b	d1,(i+$0080,a3)
	i:=i+$0100
	.endm
	rts
.endif


*****************************************
*	IOCS $38	(_CHR_ADR)	*
*****************************************

chr_adr::
	move.l	d3,-(sp)
	tst.l	d2
	smi	d3
	move	d2,d0
	cmpi	#6,d0
	bcc	chr_adr10

*	d2.w=0～5	外字フォントアドレスの変更

.if CPU>=68020
	lea	(USKFONT0,d0.w*4),a0
.else
	add	d0,d0
	add	d0,d0
	lea	(USKFONT0),a0
	adda	d0,a0
.endif
	move.l	(a0),d0			*変更前のフォントアドレス
	tst.b	d3
	bne	chr_adr90		*d2.lが負ならアドレスを参照するだけ
	btst	#$00,d1
	bne	chr_adr99		*設定しようとしたアドレスが奇数
	move.l	d1,(a0)
chr_adr90:
	move.l	(sp)+,d3
	rts
chr_adr99:
	moveq	#-1,d0
	bra	chr_adr90

*	d2.w=6～12	普通文字フォントアドレスの変更

chr_adr10:
	subq	#6,d0
	cmpi	#7,d0
	bcc	chr_adr20
.if CPU>=68020
	lea	(FONTANK6.w,pc,d0.w*4),a0
.else
	add	d0,d0
	add	d0,d0
	lea	(FONTANK6,pc),a0
	adda	d0,a0
.endif
	move.l	(a0),d0			*変更前のフォントアドレス
	tst.b	d3
	bne	chr_adr90		*d2.lが負ならアドレスを参照するだけ
	btst	#0,d1
	bne	chr_adr99		*設定しようとしたアドレスが奇数
	move.l	d1,(a0)
	move	d2,d3
	subq	#7,d3
	beq	chr_adr30		*８×８ 1/4角フォント
	subq	#1,d3
	beq	chr_adr40		*８×16 半角フォント
	subq	#1,d3
	beq	chr_adr50		*16×16 全角フォント
	bra	chr_adr90		*８ドットフォントでなければ終了する

*	d2.w=13～15	16×16 全角文字ブロック別フォントアドレス変更

chr_adr20:
	subq	#7,d0
	cmpi	#3,d0
	bcc	chr_adr21
.if CPU>=68020
	lea	(FONTKNJ16A.w,pc,d0.w*4),a0
.else
	add	d0,d0
	add	d0,d0
	lea	(FONTKNJ16A,pc),a0
	adda	d0,a0
.endif
	move.l	(a0),d0			*変更前のフォントアドレス
	tst.b	d3
	bne	chr_adr90		*d2.lが負ならアドレスを参照するだけ
	btst	#0,d1
	bne	chr_adr99		*設定しようとしたアドレスが奇数
	move.l	d1,(a0)
	move	d2,d3
	subi	#14,d3
	bcs	chr_adr60		*非漢字
	beq	chr_adr70		*第１水準漢字
	bra	chr_adr80		*第２水準漢字

*	d2.w=$80	拡張外字処理ベクタアドレスを得る

chr_adr21:
	cmpi	#$0080,d2
	bne	chr_adr99		*フォントグループ番号が異常

	lea	(EXCHRVECT,pc),a0
	move.l	a0,d0
	bra	chr_adr90

*	８×８ 1/4角フォントアドレス設定

chr_adr30:
	LEA_CHRTABLE $f0,~fntadr,a0
	moveq	#4-1,d3
chr_adr31:
	move.l	d1,(a0)
	addq.l	#sizeof_CHRTABLE,a0
	dbra	d3,chr_adr31
	bra	chr_adr90

*	８×16 半角フォントアドレス設定

chr_adr40:
	move.l	d1,-(sp)
	LEA_CHRTABLE $00,~fntadr,a0
	moveq	#$7f,d3
chr_adr41:
	move.l	d1,(a0)			*$00～$7f	<+05
	addq.l	#sizeof_CHRTABLE,a0
	add.l	#16,d1
	dbra	d3,chr_adr41
	move.l	(sp),d1
	move.l	d1,(a0)			*$80
	add.l	#$a0*16,d1
	LEA_CHRTABLE $a0,~fntadr,a0
	moveq	#$df-$a0,d3
chr_adr43:
	move.l	d1,(a0)			*$a0～$df
	addq.l	#sizeof_CHRTABLE,a0
	addq.l	#8,d1				;add.l	#16,d1
	addq.l	#8,d1				;
	dbra	d3,chr_adr43
	move.l	(sp)+,d1
	bra	chr_adr90

*	16×16 全角フォントアドレス設定

chr_adr50:
	move.l	d1,-(sp)
	bsr	chr_adr600		*非漢字
	lea	(FONTKNJ16A,pc),a0
	move.l	d1,(a0)
	LEA_CHRTABLE $85,~fntadr,a0
	clr.l	(a0)			*$85
	move	#5,((~knjflag-~fntadr),a0)
	move.l	#-$0bc0,(sizeof_CHRTABLE,a0)	*$86
	move	#6,(sizeof_CHRTABLE+(~knjflag-~fntadr),a0)
	move.l	#$0bc0,(sizeof_CHRTABLE*2,a0)	*$87
	move	#7,(sizeof_CHRTABLE*2+(~knjflag-~fntadr),a0)
	move	#8,(sizeof_CHRTABLE*3+(~knjflag-~fntadr),a0)	*$88

	add.l	#$5e00,d1
	bsr	chr_adr700		*第１水準漢字
	lea	(FONTKNJ16B,pc),a0
	move.l	d1,(a0)

	add.l	#$1d600-$5e00,d1
	bsr	chr_adr800		*第２水準漢字
	lea	(FONTKNJ16C,pc),a0
	move.l	d1,(a0)
	LEA_CHRTABLE $98,~knjflag,a0
	move	#-1<<8|2,(a0)
	LEA_CHRTABLE $ec,~fntadr,a0
	move	#9,(-sizeof_CHRTABLE+(~knjflag-~fntadr),a0)	*$eb
	move.l	#$0bc0,d1
	moveq	#$ef-$ec,d3
chr_adr51:
	move.l	d1,(a0)			*$ec～$ef
	move	#10,((~knjflag-~fntadr),a0)
	addq.l	#sizeof_CHRTABLE,a0
	add.l	#$1780,d1
	dbra	d3,chr_adr51

	move.l	(sp)+,d1
	bra	chr_adr90

*	16×16 全角非漢字フォントアドレス設定

chr_adr60:
	pea	(chr_adr90,pc)
chr_adr600:
	move.l	d1,-(sp)
	LEA_CHRTABLE $81,~fntadr,a0
	moveq	#$84-$81,d3
	btst	#0,(USRKNJFLG,pc)	*(tst.b)	<+07
	beq	chr_adr61
	moveq	#$88-$81,d3
chr_adr61:
	move.l	d1,(a0)			*$81～$84($88)
	move	#-1<<8|1,((~knjflag-~fntadr),a0)
	addq.l	#sizeof_CHRTABLE,a0
	add.l	#$1780,d1
	dbra	d3,chr_adr61

	move.b	(USRKNJFLG,pc),d1	*		<+07
	bmi	chr_adr67
	bne	chr_adr68
	LEA_CHRTABLE $85,~fntadr,a0
	clr.l	(a0)			*$85
	move	#5,((~knjflag-~fntadr),a0)
	move.l	#-$0bc0,(sizeof_CHRTABLE,a0)	*$86
	move	#6,(sizeof_CHRTABLE+(~knjflag-~fntadr),a0)
	move.l	#$0bc0,(sizeof_CHRTABLE*2,a0)	*$87
	move	#7,(sizeof_CHRTABLE*2+(~knjflag-~fntadr),a0)
	move.l	(FONTKNJ16B,pc),d1	*$88
	sub.l	#$0bc0,d1
	move.l	d1,(sizeof_CHRTABLE*3,a0)
	move	#8,(sizeof_CHRTABLE*3+(~knjflag-~fntadr),a0)
	bra	chr_adr69
chr_adr67:
	LEA_CHRTABLE $85,~knjflag,a0
	move	#$12,(a0)
	move	#$13,(sizeof_CHRTABLE,a0)	*$86
chr_adr68:
	LEA_CHRTABLE $88,~knjflag,a0
	move	#11,(a0)
chr_adr69:
	move.l	(sp)+,d1
	rts

*	16×16 全角第１水準漢字フォントアドレス設定

chr_adr70:
	pea	(chr_adr90,pc)
chr_adr700:
	move.l	d1,-(sp)
	sub.l	#$0bc0,d1
	LEA_CHRTABLE $88,~fntadr,a0
	moveq	#$98-$88,d3
	cmpi.b	#11,(~jisflag-~fntadr,a0)
	beq	chr_adr72
chr_adr71:
	move.l	d1,(a0)			*$88($89)～$98
chr_adr72:
	addq.l	#sizeof_CHRTABLE,a0
	add.l	#$1780,d1
	dbra	d3,chr_adr71
	move	#12,(-sizeof_CHRTABLE+(~knjflag-~fntadr),a0)
	move.l	(sp)+,d1
	rts

*	16×16 全角第２水準漢字フォントアドレス設定

chr_adr80:
	pea	(chr_adr90,pc)
chr_adr800:
	move.l	d1,-(sp)
	add.l	#$0bc0,d1
	LEA_CHRTABLE $99,~fntadr,a0
	move	#12,(-sizeof_CHRTABLE+(~knjflag-~fntadr),a0)
	moveq	#$9f-$99,d3
chr_adr81:
	move.l	d1,(a0)			*$99～$9f
	addq.l	#sizeof_CHRTABLE,a0
	add.l	#$1780,d1
	dbra	d3,chr_adr81
	LEA_CHRTABLE $e0,~fntadr,a0
	moveq	#$ef-$e0,d3
chr_adr82:
	move.l	d1,(a0)			*$e0～$eb($ef)
	move	#-1<<8|3,((~knjflag-~fntadr),a0)
	addq.l	#sizeof_CHRTABLE,a0
	add.l	#$1780,d1
	dbra	d3,chr_adr82

	move.b	(USRKNJ2FLG,pc),d1	*		<+08
	bne	chr_adr89
	LEA_CHRTABLE $ec,~fntadr,a0
	move	#9,(-sizeof_CHRTABLE+(~knjflag-~fntadr),a0)	*$eb
	move.l	#$0bc0,d1
	moveq	#$ef-$ec,d3
chr_adr83:
	move.l	d1,(a0)			*$ec～$ef
	move	#10,((~knjflag-~fntadr),a0)
	addq.l	#sizeof_CHRTABLE,a0
	add.l	#$1780,d1
	dbra	d3,chr_adr83
chr_adr89:
	move.l	(sp)+,d1
	rts



*****************************************
*	IOCS $19	_FNTGET		*
*****************************************

fntget::
	movem.l	d1-d2/a1,-(sp)
	move.l	d1,d2
	swap	d2			*フォントサイズ
	movea.l	(_FNTADR*4+$400),a0
	jsr	(a0)			*フォントアドレスを得る
	movea.l	d0,a0
	swap	d1
	move	d1,(a1)+		*文字パターンのＸドット数
	addq	#1,d2
	move	d2,(a1)+		*文字パターンのＹドット数
	swap	d1
	addq	#1,d1
	mulu	d1,d2			*フォントパターンのバイト数
	lsr	#2,d2
	subq	#1,d2
fntget1:
	move.l	(a0)+,(a1)+		*フォントパターンの転送
	dbra	d2,fntget1
	movem.l	(sp)+,d1-d2/a1
	rts



*****************************************
*	IOCS $16	_FNTADR		*
*****************************************

SET_FONT_SIZE:	.macro	xdot,ydot,dreg1,dreg2
	.if	xdot<=8
		moveq	#xdot,dreg1
		swap	dreg1
	.else
		move.l	#(xdot<<16)|((xdot+7)/8-1),dreg1
	.endif
	moveq	#ydot-1,dreg2
	.endm

fntadr::
	cmpi.b	#8,d2
	beq	@f
	tst.b	d2
	beq	@f
	cmpi.b	#6,d2
	bne	fntadr24		;12×24,24×24ドットフォント
					;bhiならROM1.3と同じ動作になる(d2.b=1～5が×16ドットフォント)
@@:
;8×16,16×16ドットフォント
;6×12,12×12ドットフォント(8×16,16×16を縮小して作成する)
	move.b	d2,-(sp)		;サイズ判別用、スタックから取り除くのを忘れないこと

	cmpi	#$2000,d1		*?? ($0000～$1fffは半角)
	bcs	fntadr_ank		*半角１バイト文字

;$2000以上なら2バイト文字
	move	d1,d2
	clr.b	d2
	eor	d2,d1
	lsr	#5,d2
fntadr3:
	lea	(chrtable,pc),a0
	move.b	(~jisflag,a0,d2.w),d0
	bmi	fntadr_JIS		*ＪＩＳコード
	beq	fntadr_undef		*未定義コード
	movea.l	(~fntadr,a0,d2.w),a0

	cmpi.b	#$04,d0
	bcs	fntadr_kanji		*		全角漢字/非漢字
	beq	fntadr_hira		*$80xx		半角ひらがな
	cmpi.b	#$08,d0
	beq	fntadr_knj88		*$88xx		拡張外字/漢字 境界
	bcs	fntadr_uskA		*$85xx～$87xx	外字Ａ/拡張用
	cmpi.b	#$0a,d0
	beq	fntadr_uskB		*$ecxx～$efxx	外字Ｂ/未定義
	bcs	fntadr_knjeb		*$ebxx		漢字/外字Ｂ 境界
	cmpi.b	#$0d,d0
	bhi	fntadr_small		*$f0xx～$f3xx	1/4角文字 / $85xx,$86xx 半角非漢字
	bcs	fntadr_knjAB		*$88xx,$98xx	非漢字/第１水準/第２水準 境界
	adda.l	(USKFONT2),a0		*$f4xx～$ffxx	半角外字
	lsl	#4,d1
	adda	d1,a0
	move.l	a0,d0
	bra	fntadr_ank8


*	ＪＩＳコード→Ｓ－ＪＩＳコード

fntadr_JIS:
	cmpi.b	#$21,d1
	bcs	fntadr_undef
	cmpi.b	#$7e,d1
	bhi	fntadr_undef
	addi	#($81*2-$21)*8,d2
	lsr	#4,d2
	bcc	fntadr_JIS1
	addi.b	#$7f-$21,d1
fntadr_JIS1:
	addi.b	#$40-$21,d1
	cmpi.b	#$7f,d1
	bcs	fntadr_JIS2
	addq.b	#1,d1
fntadr_JIS2:
	cmpi.b	#$a0,d2
	bcs	fntadr_JIS3
	addi.b	#$e0-$a0,d2
fntadr_JIS3:
	lsl	#3,d2
	bra	fntadr3


fntadr_extk:				*拡張外字
	move.l	(EXCHRVECT,pc),d2
	beq	fntadr_undef		*拡張外字ベクタは未設定
	subi.b	#$40,d1
	bcs	fntadr_undef
	cmpi.b	#$7f-$40,d1
	bcs	fntadr_extk1
	beq	fntadr_undef
	subq.b	#1,d1
fntadr_extk1:
	cmpi.b	#$fc-1-$40,d1
	bhi	fntadr_undef
	exg	d0,d1
	ext	d1
	add.b	d1,d1
	subq.b	#2,d1
	cmpi.b	#$5e,d0			*	<+06
	bcs	fntadr_extk2
	subi.b	#$5e,d0			*	<+06
	addq.b	#1,d1
fntadr_extk2:
	move.b	(sp)+,d2			;パターンの大きさ
	jmp	(a0)			*拡張外字処理呼び出し

fntadr_hkanji:				*半角非漢字	<+07
	beq	fntadr_hkanji1
	cmpi.b	#$9f,d1
	bcc	fntadr_kanji		*～$869e:半角非漢字 / $869f～:全角非漢字
fntadr_hkanji1:
.if CPU>=68020
	move	(sjis2tbl,pc,d1.w*2),d1
.else
	add	d1,d1
	move.l	a1,-(sp)
	lea	(sjis2tbl,pc),a1
	move	(a1,d1.w),d1
	movea.l	(sp)+,a1
.endif
	bmi	fntadr_undef		*未定義コード
	adda	d1,a0
	move.l	a0,d0
	bra	fntadr_ank8

fntadr_small:				*1/4角文字
	cmpi.b	#$12,d0			*	<+07
	bcc	fntadr_hkanji		*半角非漢字
	movem.l	a2-a3,-(sp)
	lsr.b	#1,d0
	bcc	@f
	SHIFT_HALF_HIRA d1
@@:
	bsr	putc_fonchg0
	lea	(MKFONTBUF),a3
	move.l	a3,d2
	lea	(8,a3),a2
	lsr.b	#1,d0
	bcs	fntadr_small2
	exg	a3,a2
fntadr_small2:
	clr.l	(a2)+
	clr.l	(a2)+
	lsl	#3,d1
	adda	d1,a0
	move.l	(a0)+,(a3)+
	move.l	(a0)+,(a3)+
	movem.l	(sp)+,a2-a3
	move.l	d2,d0
fntadr_ank8:
	subq.b	#6,(sp)+		;パターンの大きさ
	bne	fntadr_ank8end
	bra	fntadr6m


fntadr_hira:				*半角ひらがな
	SHIFT_HALF_HIRA d1
fntadr_ank:				*半角１バイト文字($00～$ff)
	bsr	putc_fonchg		*半角文字の変換
	moveq	#0,d0
	move.b	d1,d0

	subq.b	#6,(sp)+		;パターンの大きさ
	beq	@f

	lsl	#4,d0
	add.l	(FONTANK8,pc),d0
fntadr_ank8end:
	SET_FONT_SIZE	8,16,d1,d2
	rts
@@:
	LSL_2	d0			;4n
	move	d0,d1
	add	d0,d0			;8n
	add	d1,d0			;8n+4n=12n
	add.l	(FONTANK6,pc),d0
	SET_FONT_SIZE	6,12,d1,d2
	rts


;8x16ドットフォントを6x12ドットフォントに縮小する
fntadr6m:
	move.l	a1,-(sp)
	move.l	d0,a0			;8x16
	lea	(MKFONTBUF),a1

	moveq	#0,d1
	move	#%101101101101_0000,d2
fntadr6m_loop:
	bmi	@f
	move.b	(a0)+,d1
	or.b	(a0)+,d1
	bra	1f
@@:	move.b	(a0)+,d1
1:
	moveq	#%0000_1111,d0
	and.b	d1,d0
	lsr.b	#4,d1
	move.b	(fntadr6m_low ,pc,d0.w),d0
	or.b	(fntadr6m_high,pc,d1.w),d0
	move.b	d0,(a1)+
	add	d2,d2
	bne	fntadr6m_loop

	movea.l	(sp)+,a1
	move	#MKFONTBUF,d0			;この時点でd0.hw=0なのでmove.wでよい
	SET_FONT_SIZE	6,12,d1,d2
	rts

P8TO6:	.macro	shift
	i:=0
	.rept	16
	.dc.b	(((i>>3).and.1)<<2+(((i>>2).or.(i>>1)).and.1)<<1+(i.and.1))<<shift
	i:=i+1
	.endm
	.endm

fntadr6m_high:	P8TO6	5			;%1110_0000
fntadr6m_low:	P8TO6	2			;%0001_1100
fntadr12m_tbl:	P8TO6	4			;%0111_0000
	.even

;16x16ドットフォントを12x12ドットフォントに縮小する
fntadr12m:
	movem.l	d3-d4/a1,-(sp)
	movea.l	d0,a0			;16x16
	lea	(MKFONTBUF),a1
	move.l	a1,d0

	move	#%101101101101_0000,d2
fntadr12m_loop:
	bmi	@f
	move	(a0)+,d1
	or	(a0)+,d1
	bra	1f
@@:	move	(a0)+,d1
1:
	moveq	#%1111,d4
	and	d1,d4
	move.b	(fntadr12m_tbl,pc,d4.w),d4
	lsr	#4,d1
	moveq	#%1111,d3
	and	d1,d3
	move.b	(fntadr6m_high,pc,d3.w),d3	;move.b	(fntadr12m_table,pc,d3.w),d3
	add	d3,d3				;lsl	#3,d3
	add	d3,d3				;
	or	d3,d4
	lsr	#4,d1
	moveq	#%1111,d3
	and	d1,d3
	lsr	#4,d1
	move.b	(fntadr6m_low ,pc,d3.w),d3
	or.b	(fntadr6m_high,pc,d1.w),d3
	lsl	#8,d3
	or	d3,d4
	move	d4,(a1)+
	add	d2,d2
	bne	fntadr12m_loop

	movem.l	(sp)+,d3-d4/a1
	SET_FONT_SIZE	12,12,d1,d2
	rts


fntadr_knjAB:				*～$889e:非漢字   / $889f～:第１水準
	cmpi.b	#$9f,d1			*～$989e:第１水準 / $989f～:第２水準
	bcs	fntadr_kanji
	ext	d0
.if CPU>=68020
	lea	([(FONTKNJ16B-11*4).w,pc,d0.w*4],-$0bc0),a0
.else
	add	d0,d0
	add	d0,d0
	lea	(FONTKNJ16B,pc),a0
	movea.l	(-11*4,a0,d0.w),a0
	lea	(-$0bc0,a0),a0
.endif
	bra	fntadr_kanji

fntadr_uskA:				*外字Ａ/拡張外字
	adda.l	(USKFONT0),a0
	cmpi.b	#$06,d0
	bcs	fntadr_extk
	bne	fntadr_uskA1
	cmpi.b	#$9f,d1
	bcc	fntadr_kanji
	bra	fntadr_extk
fntadr_uskA1:
	cmpi.b	#$9f,d1
	bcs	fntadr_kanji
	bra	fntadr_extk

fntadr_undef:				*未定義の漢字コード
	move.l	(UNDEFPTR,pc),d0
	bra	fntadr_kanji16

fntadr_knjeb:				*～$eb9e:漢字     / $eb9f～:外字Ｂ
	cmpi.b	#$9f,d1
	bcs	fntadr_kanji
	movea	#-$0bc0,a0
fntadr_uskB:				*外字Ｂ
	adda.l	(USKFONT1),a0
	bra	fntadr_kanji

fntadr_knj88:				*～$889e:拡張外字 / $889f～:漢字
	cmpi.b	#$9f,d1
	bcs	fntadr_extk
fntadr_kanji:				*全角漢字/非漢字
	add	d1,d1
	move	(sjis2tbl,pc,d1.w),d1
	bmi	fntadr_undef		*未定義コード
	adda	d1,a0
	move.l	a0,d0
fntadr_kanji16:
	subq.b	#6,(sp)+		;パターンの大きさ
	beq	fntadr12m

	SET_FONT_SIZE	16,16,d1,d2
	rts


*	シフトＪＩＳコード２バイト目のオフセットテーブル

sjis2tbl:
	.dc	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1	*$0x
	.dc	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1	*$1x
	.dc	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1	*$2x
	.dc	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1	*$3x
	.dc	$0000,$0020,$0040,$0060,$0080,$00a0,$00c0,$00e0	*$4x
	.dc	$0100,$0120,$0140,$0160,$0180,$01a0,$01c0,$01e0
	.dc	$0200,$0220,$0240,$0260,$0280,$02a0,$02c0,$02e0	*$5x
	.dc	$0300,$0320,$0340,$0360,$0380,$03a0,$03c0,$03e0
	.dc	$0400,$0420,$0440,$0460,$0480,$04a0,$04c0,$04e0	*$6x
	.dc	$0500,$0520,$0540,$0560,$0580,$05a0,$05c0,$05e0
	.dc	$0600,$0620,$0640,$0660,$0680,$06a0,$06c0,$06e0	*$7x
	.dc	$0700,$0720,$0740,$0760,$0780,$07a0,$07c0,-1
	.dc	$07e0,$0800,$0820,$0840,$0860,$0880,$08a0,$08c0	*$8x
	.dc	$08e0,$0900,$0920,$0940,$0960,$0980,$09a0,$09c0
	.dc	$09e0,$0a00,$0a20,$0a40,$0a60,$0a80,$0aa0,$0ac0	*$9x
	.dc	$0ae0,$0b00,$0b20,$0b40,$0b60,$0b80,$0ba0,$0bc0
	.dc	$0be0,$0c00,$0c20,$0c40,$0c60,$0c80,$0ca0,$0cc0	*$ax
	.dc	$0ce0,$0d00,$0d20,$0d40,$0d60,$0d80,$0da0,$0dc0
	.dc	$0de0,$0e00,$0e20,$0e40,$0e60,$0e80,$0ea0,$0ec0	*$bx
	.dc	$0ee0,$0f00,$0f20,$0f40,$0f60,$0f80,$0fa0,$0fc0
	.dc	$0fe0,$1000,$1020,$1040,$1060,$1080,$10a0,$10c0	*$cx
	.dc	$10e0,$1100,$1120,$1140,$1160,$1180,$11a0,$11c0
	.dc	$11e0,$1200,$1220,$1240,$1260,$1280,$12a0,$12c0	*$dx
	.dc	$12e0,$1300,$1320,$1340,$1360,$1380,$13a0,$13c0
	.dc	$13e0,$1400,$1420,$1440,$1460,$1480,$14a0,$14c0	*$ex
	.dc	$14e0,$1500,$1520,$1540,$1560,$1580,$15a0,$15c0
	.dc	$15e0,$1600,$1620,$1640,$1660,$1680,$16a0,$16c0	*$fx
	.dc	$16e0,$1700,$1720,$1740,$1760,-1,-1,-1


*	未定義の漢字コード

fntadr24_undef:
	move	(UNDEFJIS,pc),d1
	bra	fntadr24


*	24×24/12×12ドットフォント

fntadr24:
	cmpi	#$2000,d1		*?? ($0000～$1fffは半角)
	bcs	fntadr24_ank		*半角１バイト文字
	move	d1,d0
	clr.b	d0
	eor	d0,d1
	lsr	#8,d0
	cmpi.b	#$80,d0
	beq	fntadr24_hira		*$80xx		半角ひらがな
	bcs	fntadr24_JIS		*ＪＩＳコード
	cmpi.b	#$f0,d0
	bcc	fntadr24_small		*$f0xx～$ffxx	1/4角文字 / 半角外字

	cmpi.b	#$a0,d0			*シフトＪＩＳコード
	bcs	fntadr24_1		*$81xx～$9fxx
	cmpi.b	#$e0,d0
	bcs	fntadr24_undef		*$a0xx～$dfxx
	subi.b	#$e0-$a0+$81,d0		*$e0xx～$efxx
	bra	fntadr24_2
fntadr24_1:
	subi.b	#$81,d0
fntadr24_2:
	add.b	d0,d0
	cmpi.b	#$9f,d1
	bcc	fntadr24_3
	subi.b	#$40,d1
	bcs	fntadr24_undef		*$xx00～$xx3f
	cmpi.b	#$7f-$40,d1
	bcs	fntadr24_10		*$xx40～$xx7e
	beq	fntadr24_undef		*$xx7f
	subq.b	#1,d1
	bra	fntadr24_10
fntadr24_3:
	subi.b	#$9f,d1
	cmpi.b	#$fc-$9f,d1
	bhi	fntadr24_undef		*$xxfd～$xxff
	addq.b	#1,d0			*$xx9f～$xxfc
	bra	fntadr24_10

fntadr24_JIS:				*ＪＩＳコード
	subi.b	#$21,d0
	cmpi.b	#$7f-$21,d0
	bcc	fntadr24_undef
	subi.b	#$21,d1
	cmpi.b	#$7f-$21,d1
	bcc	fntadr24_undef
fntadr24_10:
	cmpi.b	#$30-$21,d0
	bcc	fntadr24_kanjiB
	lea	(fntadr24flg,pc,d0.w),a0
	tst.b	(a0)
	beq	fntadr24_kanjiA
	bpl	fntadr24_uskA
	exg	d0,a0			*拡張外字
	move.l	(EXCHRVECT,pc),d0
	exg	d0,a0
	exg	d0,d1
	beq	fntadr24_undef		*拡張外字ベクタは未設定
	jmp	(a0)			*拡張外字処理へ

fntadr24flg:	.dc.b	0,0,0,0,0,0,0,0,-1,-1,-1,1,1,-1,-1
	.even

fntadr24_kanjiB:			*$30xx～$75xx	第１水準/第２水準漢字
	cmpi.b	#$76-$21,d0
	bcc	fntadr24_uskB
	subq.b	#$30-$29,d0
fntadr24_kanjiA:			*$21xx～$28xx	非漢字
	mulu	#$005e,d0
	add	d1,d0
	lsl.l	#3,d0			*×$8
	move.l	d0,d1
	lsl.l	#3,d0			*×$40
	add.l	d1,d0			*(mulu #24*3,d0)
	add.l	(FONTKNJ24,pc),d0
	SET_FONT_SIZE	24,24,d1,d2
	rts

fntadr24_uskA:				*$2cxx～$2dxx	外字Ａ
	subi.b	#$2c-$21,d0
	movea.l	(USKFONT3),a0
	bra	fntadr24_usk
fntadr24_uskB:				*$76xx～$77xx	外字Ｂ
	subi.b	#$76-$21,d0
	movea.l	(USKFONT4),a0
fntadr24_usk:
	mulu	#$005e,d0
	add	d1,d0
	lsl.l	#3,d0			*×$8
	move.l	d0,d1
	lsl.l	#3,d0			*×$40
	add.l	d1,d0			*(mulu #24*3,d0)
	add.l	a0,d0
	SET_FONT_SIZE	24,24,d1,d2
	rts

*	半角ひらがな($8000～$80ff)

fntadr24_hira:
	SHIFT_HALF_HIRA d1
	bra	fntadr24_ank

*	半角１バイト文字($00～$ff)

fntadr24_ank:
	bsr	putc_fonchg		*半角文字の変換
	moveq	#0,d0
	move.b	d1,d0
	lsl	#4,d0			;16n
	move	d0,d1
	add	d0,d0			;32n
	add	d1,d0			;32n+16n=48n
	add.l	(FONTANK12,pc),d0
	SET_FONT_SIZE	12,24,d1,d2
	rts

*	1/4角文字 ($f000～$f3ff)

fntadr24_small:
	cmpi.b	#$f4,d0
	bcc	fntadr24_uskhan		*半角外字
	movem.l	a2-a3,-(sp)
	lsr.b	#1,d0
	bcc	@f
	SHIFT_HALF_HIRA d1
@@:
	bsr	putc_fonchg0
	lea	(MKFONTBUF),a3
	lea	(24,a3),a2
	lsr.b	#1,d0
	bcc	fntadr24_small2
	exg	a3,a2
fntadr24_small2:
	movea.l	(FONTSML12,pc),a0
	lsl	#3,d1
	adda	d1,a0
	add	d1,d1
	adda	d1,a0
	moveq	#6-1,d0
fntadr24_small3:
	clr.l	(a2)+
	move.l	(a0)+,(a3)+
	dbra	d0,fntadr24_small3
	movem.l	(sp)+,a2-a3
	move	#MKFONTBUF,d0		;この時点でd0.hw=0なのでmove.wでよい
	SET_FONT_SIZE	12,24,d1,d2
	rts

*	半角外字($f400～$f5ff)

fntadr24_uskhan:
	lsr.b	#1,d0
	beq	fntadr24_uskhan1
	addi	#$100,d1
fntadr24_uskhan1:
	lsl	#4,d1			;16n
	moveq	#0,d0
	move	d1,d0
	add	d1,d0
	add	d1,d0			;48n
	add.l	(USKFONT5),d0
	SET_FONT_SIZE	12,24,d1,d2
	rts


*---------------------------------------*
*	コントロール文字の処理		*
*---------------------------------------*

putc_nul:				*なにもしないコード
	move	(CSRX),d0		*	<+08
	cmp	(CSRXMAX),d0
	bhi	putc_crlf		*カーソルが画面右端を越えている
putc_nul9:
	rts

putc_bel:				*07:BEL
	move	(CSRX),d0		*	<+08
	cmp	(CSRXMAX),d0
	bls	putc_bel0
	bsr	putc_crlf		*カーソルが画面右端を越えている
putc_bel0:
	move.l	(EXBEEPVEC),d0
	beq	@f

	move.l	d0,-(sp)		;登録された拡張処理を呼び出す
	rts
@@:
	move.b	(VBELLFLG,pc),d0
	bne	putc_bel1		*ビジュアルベルの場合

	moveq	#0,d2
	move	(BEEPLEN),d2
	beq	putc_nul9		*ビープ音データがない

	move.l	a1,-(sp)
	movea.l	(BEEPADR),a1
	move	#$0403,d1		*15.6KHz 左右
	moveq	#0,d0
	movea.l	(_ADPCMOUT*4+$400),a0
	jsr	(a0)			*PCMでビープ音を鳴らす
	move.l	(sp)+,a1
	rts
putc_bel1:
	lea	(_MFP_GPIP),a2
	moveq	#4-1,d0

	lea	(_TEXTPAL),a0
	movem.l	(a0),d1-d2
	cmp.l	(10*2,a0),d2
	bne	putc_bel2
	cmp	(9*2,a0),d1
	bne	putc_bel2
	cmpi	#1,(8*2,a0)
	beq	putc_bel_gm
putc_bel2:
	btst	#4,(a2)
	beq	putc_bel2		*垂直表示期間まで待つ
putc_bel3:
	btst	#4,(a2)
	bne	putc_bel3		*垂直帰線期間まで待つ

	swap	d1
	swap	d2
	exg	d1,d2
	movem.l	d1-d2,(a0)		*テキストパレットを反転する
	dbra	d0,putc_bel2
	rts
putc_bel_gm:
@@:	btst	#4,(a2)
	beq	@b
@@:	btst	#4,(a2)
	bne	@b

	movem.l	(a0),d1-d2
	swap	d1
	swap	d2
	exg	d1,d2
	movem.l	d1-d2,(a0)		*テキストパレットを反転する

	movem.l	(8*2,a0),d1-d2
	swap	d1
	swap	d2
	exg	d1,d2
	movem.l	d1-d2,(8*2,a0)

	dbra	d0,putc_bel_gm
	rts

putc_bs:				*08:BS
	subq	#1,(CSRX)
	bcc	putc_nul9
	move	(CSRXMAX),(CSRX)	*Ｘ座標が０だった
	subq	#1,(CSRY)
	bcc	putc_nul9
putc_rs:				*1e:RS(カーソルホーム)
	clr.l	(CSRX)
	rts

putc_ht:				*09:HT
	move	(CSRX),d0
	cmp	(CSRXMAX),d0		*	<+08
	bls	putc_ht1
	bsr	putc_crlf		*カーソルが画面右端を越えている
	moveq	#0,d0
putc_ht1:
	addq	#8,d0
	andi	#$fff8,d0
	cmp	(CSRXMAX),d0
	bhi	putc_crlf		*改行する
	move	d0,(CSRX)
	rts

putc_vt:				*0b:VT(カーソル上移動)
	tst	(CSRY)
	beq	putc_vt1		*Ｙ座標が０
	subq	#1,(CSRY)
putc_vt1:
	rts

putc_ff:				*0c:FF(カーソル右移動)
	move	(CSRX),d0
	cmp	(CSRXMAX),d0
	bls	putc_ff1
	bsr	putc_crlf		*改行する
putc_ff1:
	addq	#1,(CSRX)
	rts

putc_cr:				*0d:CR
	clr	(CSRX)
	rts

putc_sub:				*1a:SUB(画面クリア)
	clr.l	(CSRX)
	bra	putc_cls		*画面を消去する

putc_esc:				*1b:ESCシーケンスの開始
	move.b	d1,(FIRSTBYTE)
	lea	(ESCSQBUF),a0
	move.l	a0,(ESCSQPTR)
	rts



*---------------------------------------*
*	画面クリア処理			*
*---------------------------------------*

*	画面をクリアする

putc_cls:
	movem.l	d0-d1,-(sp)
	moveq	#0,d1
	move	(CSRYMAX),d0
	addq	#1,d0			*表示行数
	bsr	putc_eral
	movem.l	(sp)+,d0-d1
	rts

*	d1.w行目からd0.w行クリアする

putc_eral:
	tst	(SCROLLMOD)
	bne	putc_erals		*ソフトウェアクリア
	movem.l	d2-d7/a0-a4,-(sp)	*ラスターコピークリア
	moveq	#0,d2
	move	d1,d2
	swap	d2
	lsr.l	#5,d2			*128×16倍
	add.l	(TXADR),d2
	add.l	(TXSTOFST),d2
	andi	#$ff80,d2		*クリアする行のカラム０のＶＲＡＭアドレス
	move.l	d2,d1
	addi	#$0200,d2
	swap	d1
	rol.l	#7,d1			*クリア開始ラスター番号
	lea	(_CRTC21),a4
	bset	#0,(a4)			*テキストＶＲＡＭ同時アクセス
	move.b	(TXCOLOR),d4
	btst	#3,d4
	beq	putc_eral2		*反転表示でない
	andi.b	#$03,d4
	beq	putc_eral2		*黒の反転
	moveq	#$ff,d3
	subq.b	#$02,d4
	bhi	putc_eral3		*白の反転
	bcs	putc_eral1		*水色の反転
	bset	#17,d2			*黄色の反転
putc_eral1:
	bclr	#0,(a4)			*テキストＶＲＡＭシングルアクセス
	bsr	putc_fill512
	bchg	#17,d2
putc_eral2:
	moveq	#0,d3
putc_eral3:
	bsr	putc_fill512
	bclr	#0,(a4)			*テキストＶＲＡＭシングルアクセス
	move.b	d1,-(sp)		;move.b	d1,d2	*転送元ラスター
	move	(sp),d1			;lsl	#8,d1
	move.b	(sp)+,d1		;move.b	d2,d1
	addq.b	#1,d1			*転送先ラスター
	LSL_2	d0
	subq	#1,d0			*転送ラスター数
	move	#$0101,d2
	bsr	putc_rascpy
	movem.l	(sp)+,d2-d7/a0-a4
	rts

putc_fill512:
	movea.l	d2,a0
	move.l	d3,d4
	move.l	d3,d5
	move.l	d3,d6
	move.l	d3,d7
	movea.l	d3,a1
	movea.l	d3,a2
	movea.l	d3,a3
	.rept	512/4/8			*512バイトクリア
	movem.l	d3-d7/a1-a3,-(a0)
	.endm
	rts


putc_erals:				*ソフトウェアクリア
	movem.l	d2-d4/a0-a3,-(sp)
	lsl	#4,d0
	subq	#1,d0			*クリアライン数－１
	ext.l	d1
	swap	d1
	lsr.l	#5,d1			*128×16倍
	add.l	(TXADR),d1
	add.l	(TXSTOFST),d1		*ＶＲＡＭアドレス
putc_erals0:
	move	(CSRXMAX),d2
	addq	#1,d2			*表示桁数
	move	#128,d3
	sub	d2,d3			*横方向無表示部のバイト数
	btst	#0,d1
	beq	putc_erals1
	subq	#1,d2
putc_erals1:
	moveq	#3,d4
	and	d2,d4			*バイト数を４で割った余り
	lsr	#2,d2			*バイト数／４
	neg	d4
	neg	d2
.if CPU>=68020
	lea	(putc_eralsdo4,pc,d2.w*2),a1
	lea	(putc_eralsdo3,pc,d4.w*2),a2
.else
	add	d2,d2
	lea	(putc_eralsdo4,pc),a1
	adda	d2,a1
	add	d4,d4
	lea	(putc_eralsdo3,pc,d4.w),a2
.endif
	lea	(_CRTC21),a3
	bset	#0,(a3)			*テキストＶＲＡＭ同時アクセス
	move.b	(TXCOLOR),d4
	btst	#3,d4
	beq	putc_erals3		*反転表示でない
	andi.b	#$03,d4
	beq	putc_erals3		*黒の反転
	moveq	#$ff,d2
	subq.b	#$02,d4
	bhi	putc_erals4		*白の反転
	bcs	putc_erals2		*水色の反転
	bset	#17,d1			*黄色の反転
putc_erals2:
	bclr	#0,(a3)			*テキストＶＲＡＭシングルアクセス
	bsr	putc_eralsdo
	bchg	#17,d1
putc_erals3:
	moveq	#0,d2
putc_erals4:
	bsr	putc_eralsdo
	bclr	#0,(a3)			*テキストＶＲＡＭシングルアクセス
	movem.l	(sp)+,d2-d4/a0-a3
	rts

putc_eralsdo
	movea.l	d1,a0
	move	d0,d4			*クリアライン数－１
putc_eralsdo1:
	btst	#0,d1
	beq	putc_eralsdo2
	move.b	d2,(a0)+		*クリア開始アドレスが奇数
putc_eralsdo2:
	jmp	(a1)
	move.b	d2,(a0)+		*右端の補正
	move.b	d2,(a0)+
	move.b	d2,(a0)+
putc_eralsdo3:
	adda	d3,a0
	dbra	d4,putc_eralsdo1	*Ｙ方向ドット数だけ繰り返す
	rts
	.rept	32			*128バイトクリア
	move.l	d2,(a0)+
	.endm
putc_eralsdo4:
	jmp	(a2)



*****************************************
*	IOCS $df	_TXRASCPY	*
*****************************************

txrascpy::
	movem.l	d1-d2/d7/a0,-(sp)
	lea	(_CRTC21),a0
	move	(a0),d7
	moveq	#%1111,d0
	and	d3,d0			*対象プレーン
	ori	#$0100,d0		*テキスト画面同時アクセス有効
	move	d0,(a0)
	move	#$0101,d0		*ポインタを下方向へ移動
	tst	d3
	bpl	@f
	neg	d0			*$feff ポインタを上方法へ移動
@@:
	exg	d0,d2			*d0=コピー数 d2=ポインタ増分
	bsr	putc_rascpy
	move	d7,(a0)
	movem.l	(sp)+,d1-d2/d7/a0
	rts


*	ラスターコピーを行なう

putc_rascpy:
	subq	#1,d0
	bcs	putc_rascpy9

	movem.l	d3/a0-a1,-(sp)
	lea	(_MFP_GPIP),a0
	lea	(_CRTC22-_MFP_GPIP,a0),a1
	clr.b	(_MFP_DDR-_MFP_GPIP,a0)
	move	sr,d3
putc_rascpy1:
@@:	tst.b	(a0)					*(for X68030)
	bmi	@b			*H-SYNCはLow	*
	ori	#$0700,sr		*割り込み禁止
@@:	tst.b	(a0)
	bpl	@b			*H-SYNCはHigh

	move	d1,(a1)			*転送ラスターセット
	move	#%1000,(_CRTC_ACT-_CRTC22,a1)		*ラスターコピー開始
	move	d3,sr			*割り込み禁止解除
	add	d2,d1			*次のラスターへ
putc_rascpy3:
	dbra	d0,putc_rascpy1
@@:	tst.b	(a0)					*(for X68030)
	bmi	@b			*H-SYNCはLow	*
@@:	tst.b	(a0)
	bpl	@b			*H-SYNCはHigh

	clr	(_CRTC_ACT-_MFP_GPIP,a0)		*ラスターコピー停止
	movem.l	(sp)+,d3/a0-a1
putc_rascpy9:
	rts



*---------------------------------------*
*	スクロール処理			*
*---------------------------------------*

*	画面をスクロールアップする

putc_rollup:
	movem.l	d0-d2,-(sp)
	.fail	(SCROLLMOD+2).ne.SMTSCROLL
	move.l	(SCROLLMOD),d0
	bne	putc_sftrup		*ソフトコピー/スムーススクロール

	move.l	(TXSTOFST),d1		*ラスターコピースクロール
	swap	d1
	rol.l	#7,d1
.if CPU>=68020
	move.b	d1,d0			*スクロール開始ラスター	(転送先)
	addq	#4,d1			*			(転送元)
	lsl	#8,d1
	move.b	d0,d1
.else
	move	d1,-(sp)
	addq.b	#4,d1
	move.b	d1,(sp)
	move	(sp)+,d1
.endif
	move	(CSRYMAX),d0
	LSL_2	d0			;スクロールラスター数
	move	#$0101,d2
	bsr	putc_rascpy		*スクロールアップ
	move	(CSRYMAX),d1
	moveq	#$01,d0
	bsr	putc_eral		*最下行をクリア
	movem.l	(sp)+,d0-d2
	rts

*	画面をスクロールダウンする

putc_rolldw:
	movem.l	d0-d2,-(sp)
	tst	(SCROLLMOD)
	bne	putc_sftrdw		*ソフトコピースクロール
	move.l	(TXSTOFST),d1
	swap	d1
	rol.l	#7,d1
	move	(CSRYMAX),d0
	LSL_2	d0			;スクロールラスター数
	add.b	d0,d1
	addq.b	#3,d1
.if CPU>=68020
	move.b	d1,d2			*スクロール開始ラスター	(転送先)
	subq	#4,d1			*			(転送元)
	lsl	#8,d1
	move.b	d2,d1
.else
	move	d1,-(sp)
	subq	#4,d1
	move.b	d1,(sp)
	move	(sp)+,d1
.endif
	move	#$feff,d2
	bsr	putc_rascpy		*スクロールダウン
	moveq	#$00,d1
	moveq	#$01,d0
	bsr	putc_eral		*最上行をクリア
	movem.l	(sp)+,d0-d2
	rts

*	ソフトコピーによってスクロールアップする

putc_sftrup:
	tst	(SCROLLMOD)		;この時点で SCROLLMOD!=0 or SMTSCROLL!=0
	beq	putc_smtrup		;SMTSCROLL = 1,2,3

	movem.l	d3-d4/a0-a5,-(sp)
	move	(CSRYMAX),d4
	lsl	#5,d4			*32倍
	subq	#1,d4
	movea.l	(TXSTOFST),a2
	adda.l	(TXADR),a2		*スクロール開始アドレス　(転送先)
	lea	($0800,a2),a1		*１行下のＶＲＡＭアドレス(転送元)
	bsr	putc_supdo		*スクロールアップ
	move	(CSRYMAX),d1
	moveq	#$01,d0
	bsr	putc_erals		*最下行をクリア(ソフトウェア)
putc_sftrup9:
	movem.l	(sp)+,d3-d4/a0-a5
	movem.l	(sp)+,d0-d2
	rts

*	ソフトコピーによってスクロールダウンする

putc_sftrdw:
	movem.l	d3-d4/a0-a5,-(sp)
	moveq	#0,d0
	move	(CSRYMAX),d0
	move.l	d0,d4
	lsl	#5,d4			*32倍
	subq	#1,d4
	swap	d0
	lsr.l	#5,d0			;(テキスト行数-1)*16*128
	movea.l	d0,a2
	lea	(128*15,a2),a2
	adda.l	(TXSTOFST),a2
	adda.l	(TXADR),a2		*スクロール開始アドレス　(転送先)
	lea	(-128*16,a2),a1		*１行上のＶＲＡＭアドレス(転送元)
	bsr	putc_sdwdo		*スクロールダウン
	moveq	#$00,d1
	moveq	#$01,d0
	bsr	putc_erals		*最上行をクリア(ソフトウェア)
	bra	putc_sftrup9


putc_sdwdo:
	move	(CSRXMAX),d3
	addq	#1,d3			*表示桁数
	move	#128,d2
	add	d3,d2
	neg	d2
	bra	putc_sftrdo
putc_supdo:				*(a1-)から(a2-)へd4.w/2ラインスクロールする
	move	(CSRXMAX),d3
	moveq	#128-1,d2
	sub	d3,d2			*横方向無表示部のバイト数
	addq	#1,d3			*表示桁数
putc_sftrdo:
	movea.l	a1,a3
	movea.l	a2,a4
	moveq	#$02,d0
	swap	d0
	adda.l	d0,a3			*プレーン１
	adda.l	d0,a4
	move.l	a1,d0
	lsr	#1,d0
	scs.b	d0
	bcc	putc_sftrdo1
	subq	#1,d3			*ＶＲＡＭアドレスが偶数
putc_sftrdo1:
	moveq	#3,d1
	and	d3,d1			*バイト数を４で割った余り
	lsr	#2,d3			*バイト数／４
	neg	d1
	neg	d3
.if CPU>=68020
	lea	(putc_sftrdo5,pc,d3.w*2),a5
	lea	(putc_sftrdo4,pc,d1.w*2),a0
.else
	add	d3,d3
	lea	(putc_sftrdo5,pc),a5
	adda	d3,a5
	add	d1,d1
	lea	(putc_sftrdo4,pc,d1.w),a0
.endif
putc_sftrdo2:
	tst.b	d0
	beq	putc_sftrdo3
	move.b	(a1)+,(a2)+		*奇数バイトの補正
putc_sftrdo3:
	jmp	(a5)
	move.b	(a1)+,(a2)+		*右端の補正
	move.b	(a1)+,(a2)+
	move.b	(a1)+,(a2)+
putc_sftrdo4:
	adda	d2,a1
	adda	d2,a2
	exg	a1,a3			*プレーン０←→１の切り替え
	exg	a2,a4
	dbra	d4,putc_sftrdo2		*Ｙ方向ドット数×2だけ繰り返す
	rts
	.rept	32			*128バイトスクロール
	move.l	(a1)+,(a2)+
	.endm
putc_sftrdo5:
	jmp	(a0)

;スムーススクロール
putc_smtrup:
	andi	#3,d0			;d0.w=SMTSCROLL 1,2,3
	lsl	#3,d0
	movem.l	d3/a0-a1,-(sp)
	lea	(putc_smtdata-8,pc,d0.w),a1
	movea.l	(TXADR),a0
	adda.l	(TXSTOFST),a0		*ＶＲＡＭアドレス
	moveq	#0,d0
	move	(CSRYMAX),d0
	addq	#1,d0			*表示行数
	lsl.l	#4,d0			*16倍
	sub	(a1),d0
	subq	#1,d0
	lsl.l	#7,d0			*128倍
	adda.l	d0,a0			*スクロールアップ時の最下行アドレス
	move	(2,a1),d3
	move.l	(TXSTOFST),d0
	lsr.l	#7,d0			*1/128
	lsr.l	#2,d0			*1/4
	move.l	d0,d1			*スクロール開始ラスター (転送先)
	add	(4,a1),d1		*			(転送元)
.if CPU>=68020
	lsl	#8,d1
.else
	move.b	d1,-(sp)
	move	(sp)+,d1
.endif
	move.b	d0,d1
	move	(CSRYMAX),d0
	addq	#1,d0
	lsl	#2,d0			*4倍
	sub	(4,a1),d0
	move	#$0101,d2
putc_smtup1:
	btst	#$04,(_MFP_GPIP)
	bne	putc_smtup1		*垂直表示期間
	movem.l	d0-d2,-(sp)
	bsr	putc_rascpy
	pea	(putc_smtup2,pc)
	movem.l	d2-d4/a0-a3,-(sp)
	move	(a1),d0
	move.l	a0,d1
	bra	putc_erals0		*最下行を消去する
putc_smtup2:
	movem.l	(sp)+,d0-d2
	dbra	d3,putc_smtup1		*スクロールを繰り返す
	movem.l	(sp)+,d3/a0-a1
	movem.l	(sp)+,d0-d2
	rts

SMTDATA:.macro	dot,padding
	.sizem	sz,count
	.dc	dot-1,16/dot-1,dot/4
	.if	count>1
	.dc	padding			;8バイト単位にするための詰め物
	.endif
	.endm

putc_smtdata:				*スムーススクロール用データ
	SMTDATA	4,0
	SMTDATA	8,0
	SMTDATA	16



*---------------------------------------*
*	ESCシーケンス処理		*
*---------------------------------------*

putc_escsq:
	movem.l	d4/a1/a4-a5,-(sp)
	movea.l	(ESCSQPTR),a1
	move.b	d1,(a1)+		*ESCシーケンスを保存する
	lea	(ESCSQBUF+9),a0
	cmpa.l	a0,a1
	beq	putc_escsq1

	move.l	a1,(ESCSQPTR)
putc_escsq1:
	move.b	(ESCSQBUF),d0
	cmpi.b	#'[',d0
	beq	putc_esc10
	cmpi.b	#'=',d0
	beq	putc_esc20
	cmpi.b	#'*',d0
	beq	putc_esc30
	cmpi.b	#'D',d0
	beq	putc_esc40
	cmpi.b	#'E',d0
	beq	putc_esc50
	cmpi.b	#'M',d0
	beq	putc_esc60

	move.b	(CONESCFLG,pc),d4
putc_escsq0::
	bra	putc_escsq8		;condrv 常駐時は hiocs.s から
**	bne	putc_escsq8		;bne に書き換えられる

	movea.l	(LOGBUFVECT,pc),a2
	subi.b	#'0',d0			;CONDRV.SYS対応処理
	subq.b	#1,d0
	bhi	putc_escsq02		;2->1 3->2
	beq	putc_escsq01

* condrv のシステムコール $24 を使用する方法.
* 従来と互換性がないが、ネストが可能(ESC 0 の状態
* で ESC 0 ESC 1 を処理すると ESC 0 の状態に戻る).
* ただしキーボードから制御できないので、ESC 0 と
* ESC 1 を組で使用しなければ面倒なことになる.
	move.l	d1,-(sp)
	moveq	#+1,d1			;ESC 0	バックログ記録禁止
	bra	@f
putc_escsq01:
	move.l	d1,-(sp)
	moveq	#-1,d1			;ESC 1	バックログ記録許可
@@:
	movea.l	(CONDSYSCALL,pc),a2
	moveq	#$24,d0			;バッファリング制御II
	jsr	(a2)			;システムコールを呼び出す
	move.l	(sp)+,d1
	bra	putc_escsq8

putc_escsq02:
	subq.b	#2,d0
	beq	putc_escsq03
	bhi	putc_escsq8
;ESC 2
	cmpi	#MOVEM,(a2)
	beq	@f			;!>が表示されていないならそのまま

	move	#MOVEM,(a2)
	bsr	clear_mpu_cache
	bsr	redraw_system_status	;!>を強制的に消す
	move	#RTS,(a2)
	bsr	clear_mpu_cache
@@:
	movea.l	(CONDFLAG,pc),a2
	bset	#0,(a2)			;ESC 2  ステータス表示禁止
	bra	putc_escsq8
putc_escsq03:
	movea.l	(CONDFLAG,pc),a2
	bclr	#0,(a2)			;ESC 3  ステータス表示許可
putc_escsq04:
	bsr	redraw_system_status
	bra	putc_escsq8

redraw_system_status:
	move.l	#$000e_ffff,-(sp)
	DOS	_CONCTRL		;ファンクションキー表示
	addq.l	#4,sp
	rts

clear_mpu_cache::
	cmpi.b	#1,(MPUTYPE)
	bls	@f
	move.l	d1,-(sp)
	moveq	#3,d1
	IOCS	_SYS_STAT
	move.l	(sp)+,d1
@@:	rts

putc_esc10:				*ESC [
	moveq	#$20,d0
	or.b	d1,d0
	subi.b	    #($20.or.'@'),d0
	cmpi.b	#'z'-($20.or.'@'),d0
	bhi	putc_escsq9	*英文字でない

	bsr	putc_escex
putc_escsq8:
	clr.b	(FIRSTBYTE)
putc_escsq9:
	movem.l	(sp)+,d4/a1/a4-a5
	rts


putc_esc40:				*ESC D	カーソル下移動
	bsr	putc_down_s
	bra	putc_escsq8


putc_esc50:				*ESC E	改行
	bsr	putc_crlf
	bra	putc_escsq8


putc_esc60:				*ESC M	カーソル上移動
	bsr	putc_up_s
	bra	putc_escsq8


putc_esc30:				*ESC *	画面クリア
	bsr	putc_cls
	clr.l	(CSRX)
	bra	putc_escsq8


putc_esc20:				*ESC =
	lea	(ESCSQBUF+3),a0
	cmpa.l	a0,a1
	bne	putc_escsq9		*座標が揃っていない
	moveq	#$1f,d0			*オフセット値
	moveq	#$00,d1
	moveq	#$00,d2
	move.b	(ESCSQBUF+1),d2		*Ｙ座標
	move.b	(ESCSQBUF+2),d1		*Ｘ座標
	sub	d0,d1
	sub	d0,d2
	bsr	putc_csrmove2		*カーソル座標を設定する
	bra	putc_escsq8


putc_escex20:				*ESC [>
	swap	d0
	moveq	#0,d1
	cmpi	#'5l',d0
	beq	putc_escex21		*ESC [>5l	カーソル表示
	moveq	#$ff,d1
	cmpi	#'5h',d0
	bne	putc_escex15		*ESC [>5h	カーソル消去
putc_escex21:
	move.b	d1,(CSRSW)
	rts

putc_escex10:				*ESC [?
	swap	d0
	moveq	#0,d1
	cmpi	#'4l',d0
	beq	putc_escex11		*ESC [?4l	ジャンプスクロールモード
	moveq	#2,d1			*８ドットスクロール
	cmpi	#'4h',d0		*ESC [?4h	スムーススクロールモード
	bne	putc_escex15
putc_escex11:
	move	d1,(SMTSCROLL)
	rts

putc_escex15:				*拡張ESCシーケンスの処理
	move.l	(ESCEXVECT),d1
	beq	putc_escex16		*拡張ベクタは未設定

	move.l	d1,a1
	lea	(ESCSQBUF),a0
	movem.l	d5-d7/a6,-(sp)
	jsr	(a1)
	bsr	b_curoff		*(拡張ベクタ内で_B_CURONされる)
	movem.l	(sp)+,d5-d7/a6
putc_escex16:
	rts

putc_escex:				*ESC [ に続くコードの処理
	move.l	(ESCSUBSTVEC),d0
	beq	@f

	move.l	d0,-(sp)		;登録された拡張処理を呼び出す
	rts
@@:
	lea	(ESCSQBUF),a0
	move.l	(a0),d0
	swap	d0
	cmpi	#'[?',d0
	beq	putc_escex10		*ESC [?...
	cmpi	#'[>',d0
	beq	putc_escex20		*ESC [>...
	addq.l	#1,a0
	bsr	putc_escnum		*10進数値を得る
	cmpi.b	#'A',d0
	beq	putc_up			*ESC [pnA
	cmpi.b	#'B',d0
	beq	putc_down		*ESC [pnB
	cmpi.b	#'C',d0
	beq	putc_right		*ESC [pnC
	cmpi.b	#'D',d0
	beq	putc_left		*ESC [pnD
	cmpi.b	#'s',d0
	beq	putc_atrsave		*ESC [s
	cmpi.b	#'u',d0
	beq	putc_atrrst		*ESC [u
	cmpi.b	#'n',d0
	beq	putc_escex15		*(ESC [～n は拡張シーケンス)
	cmpi.b	#'J',d0
	beq	putc_clr_st		*ESC [0J～[2J
	cmpi.b	#'K',d0
	beq	putc_era_st		*ESC [0K～[2K
	cmpi.b	#'M',d0
	beq	putc_del		*ESC [pnM
	cmpi.b	#'L',d0
	beq	putc_ins		*ESC [pnL
	cmpi.b	#'P',d0
	beq	putc_cdel		*ESC [pnP
	cmpi.b	#'@',d0
	beq	putc_cins		*ESC [pn@
	cmpi.b	#'X',d0
	beq	putc_cera		*ESC [pnX
	cmpi.b	#'m',d0
	beq	putc_escatr2		*ESC [psm
	cmpi.b	#';',d0
	bne	putc_escex15		*該当するESCシーケンスがないので拡張シーケンス
	move	d1,d2
	bsr	putc_escnum		*10進数値を得る
	cmpi.b	#'H',d0
	beq	putc_csrmove		*ESC [pl;pcH
	cmpi.b	#'f',d0
	beq	putc_csrmove		*ESC [pl;pcf
	cmpi.b	#'m',d0
	beq	putc_escatr1		*ESC [ps;psm
	cmpi.b	#';',d0
	bne	putc_escex15
	move	d1,d3
	bsr	putc_escnum		*10進数値を得る
	cmpi.b	#'m',d0
	bne	putc_escex15
putc_escatr:
	move	d2,d0			*ESC [ps;ps;psm
	bsr	putc_escatr3
	exg	d2,d3
putc_escatr1:				*ESC [ps;psm
	move	d2,d0
	bsr	putc_escatr3
putc_escatr2:				*ESC [psm	文字属性の指定
	move	d1,d0
putc_escatr3:
	tst.b	d0
	beq	putc_atrinit
	cmpi.b	#1,d0
	beq	putc_atrhi
	cmpi.b	#7,d0
	beq	putc_atrrev
	cmpi.b	#30,d0
	bcs	putc_escatr5
	cmpi.b	#37+1,d0
	bcc	putc_escatr4
	subi.b	#30,d0			*30～37
	move.b	d0,(TXCOLOR)
	rts
putc_escatr4:
	cmpi.b	#40,d0
	bcs	putc_escatr5
	cmpi.b	#47+1,d0
	bcc	putc_escatr5
	subi.b	#32,d0			*40～47
	move.b	d0,(TXCOLOR)
putc_escatr5:
	rts
putc_atrinit:				*ESC [0m	属性初期化
	move.b	#$03,(TXCOLOR)
	rts
putc_atrhi:				*ESC [1m	ハイライト
	eori.b	#$04,(TXCOLOR)
	rts
putc_atrrev:				*ESC [7m	リバース
	eori.b	#$08,(TXCOLOR)
	rts

putc_escnum:				*ESCシーケンスの10進数値を得る
	move	#$8000,d1
	moveq	#0,d0
putc_escnum1:
	move.b	(a0)+,d0
	cmpi.b	#' ',d0
	beq	putc_escnum1
	cmpi.b	#'0',d0
	bcs	putc_escnum9
	cmpi.b	#'9'+1,d0
	bcc	putc_escnum9
	subi.b	#'0',d0
	mulu	#10,d1
	add	d0,d1
	bra	putc_escnum1
putc_escnum9:
	rts


putc_atrsave:				*ESC [s	カーソル属性をセーブ
	tst	d1
	bpl	putc_atrsave9
	move.l	(CSRX),(CSRXYSAVE)
	move.b	(TXCOLOR),(TXCOLSAVE)
putc_atrsave9:
	rts


putc_atrrst:				*ESC [u	セーブした属性を元に戻す
	tst	d1
	bpl	putc_atrrst9
	move.l	(CSRXYSAVE),(CSRX)
	move.b	(TXCOLSAVE),(TXCOLOR)
putc_atrrst9:
	rts


putc_csrmove:				*ESC [y;xH / ESC [y;xf	カーソル移動
	tst	d1
	bgt	putc_csrmove1
	moveq	#1,d1			*Ｘ座標が省略された
putc_csrmove1:
	tst	d2
	bgt	putc_csrmove2
	moveq	#1,d2			*Ｙ座標が省略された
putc_csrmove2:
	subq	#1,d1
	subq	#1,d2
	cmp	(CSRXMAX),d1
	bhi	putc_csrmove9		*Ｘ座標が範囲外
	cmp	(CSRYMAX),d2
	bhi	putc_csrmove9		*Ｙ座標が範囲外
	move	d1,(CSRX)		*カーソル位置を設定する
	move	d2,(CSRY)
	moveq	#0,d0
	rts
putc_csrmove9:
	moveq	#-1,d0
	rts



*****************************************
*	IOCS $24	_B_DOWN_S	*
*****************************************

b_down_s::
	bsr	b_curoff
	pea	(b_curon,pc)

putc_down_s:				*_B_DOWN_Sの実処理
	addq	#1,(CSRY)
	move	(CSRYMAX),d0
	cmp	(CSRY),d0
	bcc	putc_down_s9
	subq	#1,(CSRY)
	bsr	putc_rollup		*スクロールアップする
putc_down_s9:
	moveq	#0,d0
	rts



*****************************************
*	IOCS $25	_B_UP_S		*
*****************************************

b_up_s::
	bsr	b_curoff
	pea	(b_curon,pc)

putc_up_s:				*_B_UP_Sの実処理
	tst	(CSRY)
	beq	putc_up_s9
	subq	#1,(CSRY)
	moveq	#0,d0
	rts
putc_up_s9:
	bsr	putc_rolldw		*スクロールダウンする
	moveq	#0,d0
	rts



*****************************************
*	IOCS $26	_B_UP		*
*****************************************

b_up9:
	move.l	(sp)+,d1
	bra	b_curon
b_up::
	move.l	d1,-(sp)
	bsr	b_curoff
	pea	(b_up9,pc)

putc_up:				*ESC [pnA	カーソルn行上移動
	andi	#$00ff,d1		*_B_UP
	bne	putc_up1
	moveq	#1,d1
putc_up1:
	move	(CSRY),d0
	sub	d1,d0
	bmi	putc_up9
	move	d0,(CSRY)
	moveq	#0,d0
	rts
putc_up9:				*指定行だけ移動できないので移動しない
	moveq	#-1,d0
	rts



*****************************************
*	IOCS $27	_B_DOWN		*
*****************************************

b_down::
	move.l	d1,-(sp)
	bsr	b_curoff
	pea	(b_up9,pc)

putc_down:				*ESC [pnB	カーソルn行下移動
	lea	(CSRY),a0		*_B_DOWN
	andi	#$00ff,d1
	bne	putc_down1
	moveq	#1,d1
putc_down1:
	add	d1,(a0)
	move	(CSRYMAX),d0
	cmp	(a0),d0
	bcc	putc_down3
putc_down2:
	move	d0,(a0)			*指定行だけ移動できないので最下行へ移動する
putc_down3:
	moveq	#0,d0
	rts



*****************************************
*	IOCS $28	_B_RIGHT	*
*****************************************

b_right::
	move.l	d1,-(sp)
	bsr	b_curoff
	pea	(b_up9,pc)

putc_right:				*ESC [pnC	カーソルn行右移動
	lea	(CSRX),a0		*_B_RIGHT
	andi	#$00ff,d1
	bne	putc_right1
	moveq	#1,d1
putc_right1:
	add	d1,(a0)
	move	(CSRXMAX),d0
	cmp	(a0),d0
	bcc	putc_down3
	bra	putc_down2



*****************************************
*	IOCS $29	_B_LEFT		*
*****************************************

b_left::
	move.l	d1,-(sp)
	bsr	b_curoff
	pea	(b_up9,pc)

putc_left:				*ESC [pnD	カーソルn行左移動
	andi	#$00ff,d1		*_B_LEFT
	bne	putc_left1
	moveq	#1,d1
putc_left1:
	sub	d1,(CSRX)
	bpl	putc_left2
	clr	(CSRX)
putc_left2:
	moveq	#0,d0
	rts



*****************************************
*	IOCS $2a	_B_CLR_ST	*
*****************************************

b_clr_st9:
	movem.l	(sp)+,d1-d3/a1/a4
	bra	b_curon
b_clr_st::
	movem.l	d1-d3/a1/a4,-(sp)
	bsr	b_curoff
	pea	(b_clr_st9,pc)

putc_clr_st:				*ESC [nJ
	tst.b	d1			*_B_CLR_ST
	beq	putc_clr_st0
	subq.b	#2,d1
	bcs	putc_clr_st1
	bhi	putc_clr_st9
	bsr	putc_cls		*ESC [2J	画面クリア
	clr.l	(CSRX)
	moveq	#0,d0
	rts
putc_clr_st9:
	moveq	#-1,d0			*消去指定が無効
	rts

putc_clr_st0:				*ESC [0J	カーソル以降全クリア
	move	(CSRYMAX),d0
	move	(CSRY),d1
	sub	d1,d0
	beq	putc_era_st0		*カーソルが最下行にある
	bcs	putc_clr_st9		*カーソルが画面の外にある
	addq	#1,d1
	bsr	putc_eral		*カーソルの次の行以降をクリア
	bra	putc_era_st0		*カーソル以降行末までクリア

putc_clr_st1:				*ESC [1J	カーソル以前全クリア
	moveq	#0,d1
	move	(CSRY),d0
	beq	putc_era_st1		*カーソルが最上行にある
	bsr	putc_eral		*カーソルの上の行までクリア
	bra	putc_era_st1		*カーソル以前行頭までクリア



*****************************************
*	IOCS $2b	_B_ERA_ST	*
*****************************************

b_era_st::
	movem.l	d1-d3/a1/a4,-(sp)
	bsr	b_curoff
	pea	(b_clr_st9,pc)

putc_era_st:				*ESC [nK
	tst.b	d1			*_B_ERA_ST
	beq	putc_era_st0
	subq.b	#2,d1
	bcs	putc_era_st1
	bhi	putc_era_st9
putc_era_st2:
	move	(CSRY),d1		*ESC [2K	カーソル行クリア
	moveq	#1,d0
	bsr	putc_eral		*カーソル行を消去
	moveq	#0,d0
	rts
putc_era_st9:
	moveq	#-1,d0			*消去指定が無効
	rts

putc_era_st0:				*ESC [0K	カーソル以降行末までクリア
	move	(CSRX),d2
	move	(CSRXMAX),d0
	sub	d2,d0
	bcs	putc_era_st9		*カーソルが画面の外にある
	bra	putc_erac

putc_era_st1:				*ESC [1K	カーソル以前行頭までクリア
	moveq	#0,d2
	move	(CSRX),d0
	cmp	(CSRXMAX),d0
	bcc	putc_era_st2		*カーソルが行末にあるのでカーソル行クリア
putc_erac:				*カーソル行のd2.w桁からd0.w+1文字クリア
	move.b	(TXCOLOR),d1
putc_erac0:
	lea	(_CRTC21),a4
	moveq	#0,d3
	move	(CSRY),d3
	swap	d3
	lsr.l	#5,d3			*128×16倍
	add.l	(TXSTOFST),d3
	add.l	(TXADR),d3
	movea.l	d3,a0			*カーソル行のＶＲＡＭアドレス
	adda	d2,a0			*クリア開始位置のＶＲＡＭアドレス
	bset	#0,(a4)			*テキストＶＲＡＭ同時アクセス
	moveq	#0,d2			*クリアするデータ
	btst	#$03,d1
	beq	putc_erac2		*反転表示でない
	andi.b	#$03,d1
	beq	putc_erac2		*黒の反転
	moveq	#$ff,d2
	cmpi.b	#$03,d1
	beq	putc_erac2		*白の反転(プレーン0,1フィル)
	movea.l	a0,a1
	adda.l	#$020000,a1		*プレーン１のＶＲＡＭアドレス
	bclr	#0,(a4)			*テキストＶＲＡＭシングルアクセス
	cmpi.b	#$02,d1
	beq	putc_erac1
	exg	a0,a1			*水色の反転(プレーン０フィル)
putc_erac1:				*黄色の反転(プレーン１フィル)
	i:=$0780
	.rept	15
	clr.b	(i,a0)			*クリア
	move.b	d2,(i,a1)		*フィル
	i:=i-$0080
	.endm
	clr.b	(a0)+
	move.b	d2,(a1)+
	dbra	d0,putc_erac1
	moveq	#0,d0
	rts
putc_erac2:
	i:=$0780
	.rept	15
	move.b	d2,(i,a0)		*クリア/フィル
	i:=i-$0080
	.endm
	move.b	d2,(a0)+
	dbra	d0,putc_erac2
	bclr	#0,(a4)			*テキストＶＲＡＭシングルアクセス
	moveq	#0,d0
	rts



*****************************************
*	IOCS $2c	_B_INS		*
*****************************************

b_ins9:
	movem.l	(sp)+,d1-d4/a1-a5
	bra	b_curon
b_ins::
	movem.l	d1-d4/a1-a5,-(sp)
	bsr	b_curoff
	pea	(b_ins9,pc)

putc_ins:				*ESC [pnL	カーソル行にn行挿入
	andi	#$ff,d1
	bne	putc_ins1

	moveq	#1,d1
putc_ins1:
	moveq	#0,d2
	moveq	#0,d3
	move	(CSRYMAX),d3
	move	(CSRY),d2
	move	d3,d0
	addq	#1,d0
	sub	d2,d0			*カーソル行以降の行数
	cmp	d0,d1
	bcc	putc_ins3		*挿入行数の方が多い
	movem.l	d1-d2,-(sp)
	tst	(SCROLLMOD)
	bne	putc_ins4		*ソフトコピーモード
	move	d1,d4			*挿入行数
	move.l	(TXSTOFST),d0
	swap	d0
	rol.l	#7,d0
	move	d3,d1			*CSRYMAX
	addq	#1,d1
	LSL_2	d1			;4倍
	subq	#1,d1
	add	d1,d0			*スクロール開始ラスター (転送先)
	move.l	d0,d1
	sub	d4,d1
	sub	d4,d1
	sub	d4,d1
	sub	d4,d1			*			(転送元)
.if CPU>=68020
	lsl	#8,d1
.else
	move.b	d1,-(sp)
	move	(sp)+,d1
.endif
	move.b	d0,d1
	move	d3,d0
	addq	#1,d0			*表示行数
	sub	d2,d0			*カーソル行以降の行数
	sub	d4,d0			*スクロール行数
	lsl	#2,d0
	move	#$feff,d2
	bsr	putc_rascpy		*ラスターコピーによるスクロールダウン
putc_ins2:
	movem.l	(sp)+,d1-d2
	move	d1,d0
putc_ins3:
	move	d2,d1
	bsr	putc_eral		*挿入行をクリア
	moveq	#0,d0
	move	d0,(CSRX)		*カーソルＸ座標は０
	rts

putc_ins4:				*ソフトコピーによる行挿入
	move	d0,d4			*カーソル行以降の行数
	sub	d1,d4			*スクロール行数
	lsl	#5,d4			*32倍
	subq	#1,d4
	addq	#1,d3			*表示行数
	lsl.l	#4,d3			*16倍
	subq.l	#1,d3
	lsl.l	#7,d3			*128倍
	movea.l	d3,a2
	moveq	#0,d0
	move	d1,d0			*挿入行数
	swap	d0
	lsr.l	#5,d0
	neg.l	d0
	movea.l	d0,a1
	adda.l	a2,a1
	move.l	(TXADR),d0
	add.l	(TXSTOFST),d0
	adda.l	d0,a1			*スクロール開始アドレス (転送元)
	adda.l	d0,a2			*			(転送先)
	bsr	putc_sdwdo		*ソフトコピーによるスクロールダウン
	bra	putc_ins2		*挿入行をクリア



*****************************************
*	IOCS $2d	_B_DEL		*
*****************************************

b_del::
	movem.l	d1-d4/a1-a5,-(sp)
	bsr	b_curoff
	pea	(b_ins9,pc)

putc_del:				*ESC [pnM	カーソル以下n行を削除
	andi	#$ff,d1
	bne	putc_del1

	moveq	#1,d1
putc_del1:
	moveq	#0,d2
	moveq	#0,d3
	move	(CSRYMAX),d3
	move	(CSRY),d2
	move	d3,d0
	addq	#1,d0
	sub	d2,d0			*カーソル行以降の行数
	cmp	d0,d1
	bcc	putc_ins3		*削除行数の方が多い
	movem.l	d0-d2,-(sp)
	tst	(SCROLLMOD)
	bne	putc_del3		*ソフトコピーモード
	move	d1,d4			*削除行数
	move.l	(TXSTOFST),d0
	swap	d0
	rol.l	#7,d0
	move	d2,d1
	LSL_2	d1			;4倍
	add	d1,d0			*スクロール開始ラスター (転送先)
	move.l	d0,d1
	add	d4,d1
	add	d4,d1
	add	d4,d1
	add	d4,d1			*			(転送元)
.if CPU>=68020
	lsl	#8,d1
.else
	move.b	d1,-(sp)
	move	(sp)+,d1
.endif
	move.b	d0,d1
	move	d3,d0
	addq	#1,d0			*表示行数
	sub	d2,d0			*カーソル行以降の行数
	sub	d4,d0			*スクロール行数
	lsl	#2,d0
	move	#$0101,d2
	bsr	putc_rascpy		*ラスターコピーによるスクロールアップ
putc_del2:
	movem.l	(sp)+,d0-d2
	sub	d1,d0
	add	d0,d2
	move	d1,d0
	bra	putc_ins3		*スクロール部の下をクリア

putc_del3:				*ソフトコピーによる行削除
	move	d0,d4			*カーソル行以降の行数
	sub	d1,d4			*スクロール行数
	lsl	#5,d4			*32倍
	subq	#1,d4
	swap	d2
	lsr.l	#5,d2
	movea.l	d2,a2
	moveq	#$00,d0
	move	d1,d0
	swap	d0
	lsr.l	#5,d0
	movea.l	d0,a1
	adda.l	a2,a1
	move.l	(TXADR),d0
	add.l	(TXSTOFST),d0
	adda.l	d0,a1			*スクロール開始アドレス (転送元)
	adda.l	d0,a2			*			(転送先)
	bsr	putc_supdo		*ソフトコピーによるスクロールアップ
	bra	putc_del2		*スクロール部の下をクリア


putc_cera:				*ESC [pnX	カーソル以降n文字をクリア
	tst	d1
	bpl	putc_cera1
	moveq	#1,d1
putc_cera1:
	move	(CSRXMAX),d3
	move	(CSRX),d2
	sub	d2,d3
	bcs	putc_cera9		*カーソルが画面の外にある
	cmp	d1,d3
	bcs	putc_cera2		*行末を越えてクリア
	move	d1,d0
	subq	#1,d0
	move	(CSRX),d2
	bra	putc_cera3
putc_cera2:				*カーソル以降行末までクリア
	move	(CSRXMAX),d0
	move	(CSRX),d2
	sub	d2,d0
putc_cera3:
	moveq	#0,d1			*属性をクリア
	bra	putc_erac0		*d2.w桁からd0.w+1文字クリア
putc_cera9:
	moveq	#-1,d0
	rts


putc_cdel:				*ESC [pnP	カーソル以降n文字を削除
	tst	d1
	bgt	putc_cdel1
	moveq	#1,d1
putc_cdel1:
	move	d1,d4
	move	(CSRXMAX),d3
	move	(CSRX),d1
	sub	d1,d3
	bcs	putc_cera9		*カーソルが画面の外にある
	sub	d4,d3
	bcs	putc_cdel2		*行末を越えて削除
	add	d4,d1
	move	(CSRX),d2
	bsr	putc_cmvlt		*d1.w桁からd3.w+1文字をd2.w桁以降に移動
	move	(CSRXMAX),d2
	move	d4,d0
	subq	#1,d0
	sub	d0,d2
	bra	putc_erac		*削除行の右をクリア
putc_cdel2:				*カーソル以降行末までクリア
	move	(CSRXMAX),d0
	move	(CSRX),d2
	sub	d2,d0
	bra	putc_erac		*d2.w桁からd0.w+1文字クリア


putc_cins:				*ESC [pn@	カーソル位置にn文字挿入
	tst	d1
	bpl	putc_cins1
	moveq	#1,d1
putc_cins1:
	move	d1,d4
	move	(CSRXMAX),d3
	move	(CSRX),d1
	sub	d1,d3
	bcs	putc_cera9		*カーソルが画面の外にある
	sub	d4,d3
	bcs	putc_cera2		*挿入した空白が行末を越える
	move	(CSRXMAX),d2
	add	d3,d1
	addq	#1,d1
	addq	#1,d2
	bsr	putc_cmvrt		*d1.w-1桁から左のd3.w+1文字をd2.w-1桁以前に移動
	move	(CSRX),d2
	move	d4,d0
	subq	#1,d0
	bra	putc_cera3		*挿入部分をクリア

putc_cmvrt:				*移動方向は右向き
	lea	(putc_cmvrdo,pc),a4
	bra	putc_cmove
putc_cmvlt:				*移動方向は左向き
	lea	(putc_cmvldo,pc),a4
putc_cmove:				*カーソル行のd1.w桁からd2.w桁へd3.w-1文字移動
	moveq	#0,d0
	move	(CSRY),d0
	swap	d0
	lsr.l	#5,d0
	movea.l	d0,a0
	adda.l	(TXSTOFST),a0
	adda.l	(TXADR),a0		*カーソル行のＶＲＡＭアドレス
	movea.l	a0,a1
	adda	d1,a0			*挿入/削除開始アドレス　(転送元)
	adda	d2,a1			*			(転送先)
	moveq	#$02,d0
	swap	d0
	movea.l	a0,a2
	movea.l	a1,a3
	adda.l	d0,a2			*プレーン１のＶＲＡＭアドレス
	adda.l	d0,a3
	moveq	#128-1,d2
	sub	d3,d2			*非移動部のバイト数
	moveq	#16-1,d1
	jmp	(a4)

putc_cmvldo:				*左方向移動(削除)
	move	d3,d0
putc_cmvldo1:
	move.b	(a0)+,(a1)+
	move.b	(a2)+,(a3)+
	dbra	d0,putc_cmvldo1
	adda	d2,a0
	adda	d2,a1
	adda	d2,a2
	adda	d2,a3
	dbra	d1,putc_cmvldo
	rts

putc_cmvrdo:				*右方向移動(挿入)
	move	#$0780,d0
	adda	d0,a0
	adda	d0,a1
	adda	d0,a2
	adda	d0,a3
putc_cmvrdo1:
	move	d3,d0
putc_cmvrdo2:
	move.b	-(a0),-(a1)
	move.b	-(a2),-(a3)
	dbra	d0,putc_cmvrdo2
	suba	d2,a0
	suba	d2,a1
	suba	d2,a2
	suba	d2,a3
	dbra	d1,putc_cmvrdo1
	rts



*****************************************
*	IOCS $22	_B_COLOR	*
*****************************************

b_color::
	moveq	#0,d0
	lea	(TXCOLOR),a0
	move.b	(a0),d0			*現在のカラーコード
	cmpi	#-1,d1
	beq	b_color1
	cmpi	#$0010,d1
	bcc	b_color2
	move.b	d1,(a0)			*カラーコードを設定
b_color1:
	rts
b_color2:
	moveq	#-1,d0			*カラーコードが異常
	rts


*****************************************
*	IOCS $23	_B_LOCATE	*
*****************************************

b_locate::
	move.l	(CSRX),d0		*現在のカーソル座標
	cmpi	#-1,d1
	beq	b_locate1
	cmp	(CSRXMAX),d1
	bhi	b_color2		*Ｘ座標が異常
	cmp	(CSRYMAX),d2
	bhi	b_color2		*Ｙ座標が異常
	move.l	d0,-(sp)
	bsr	b_curoff
	move	d1,(CSRX)		*カーソル座標を設定
	move	d2,(CSRY)
	bsr	b_curon
	move.l	(sp)+,d0
	rts
b_locate1:
	move.l	d0,d1
	rts


*****************************************
*	IOCS $2e	_B_CONSOL	*
*****************************************

b_consol::
	bsr	b_curoff
	move.l	(TXSTOFST),d0
	cmpi.l	#-1,d1
	beq	b_consol1		*表示開始位置の読み出し
	and.l	#$03ff03ff,d1		*1024以下
	move.l	d1,d0
	clr	d0
	swap	d0
	lsr	#3,d0			*Ｘ方向表示開始桁
	and.l	#$0000fffc,d1		*Ｙ方向表示開始ドット
	lsl.l	#7,d1
	add.l	d0,d1
	move.l	(TXSTOFST),d0		*テキスト表示開始アドレス
	move.l	d1,(TXSTOFST)
	clr.l	(CSRX)			*カーソルはホーム位置
b_consol1:
	move.l	d0,d1
	andi	#$fe00,d1
	lsr.l	#7,d1			*変更前のＹ方向表示開始ドット
	and.l	#$0000007f,d0
	lsl	#3,d0			*	 Ｘ方向表示開始ドット
	swap	d0
	or.l	d0,d1
	move.l	(CSRXMAX),d0
	cmpi.l	#-1,d2
	beq	b_consol2		*表示桁数の読み出し
	and.l	#$007f003f,d2
	move.l	d2,(CSRXMAX)		*表示桁数の設定
	clr.l	(CSRX)			*カーソルはホーム位置
b_consol2:
	move.l	d0,d2
	moveq	#0,d0
	bra	b_curon



*****************************************
*	IOCS $ad	_B_CONMOD	*
*****************************************

b_conmod::
	bsr	b_curoff
	cmpi	#1,d1
	bmi	b_conmod3		*カーソル点滅をする
	beq	b_conmod4		*カーソル点滅を禁止
	cmpi	#3,d1
	bmi	b_conmod5		*カーソルパターン指定
	beq	b_conmod6		*カーソルパターン定義
	cmpi	#$10,d1
	beq	b_conmod2		*スムーススクロール指定
	cmpi	#$12,d1
	bmi	b_conmod0		*ラスタコピー指定
	beq	b_conmod1		*ソフトコピー指定
b_conmod9:
	bra	b_curon

*	d1.w=17 ラスタコピースクロールモード指定

b_conmod0:
	clr	(SCROLLMOD)
	bra	b_conmod9

*	d1.w=18 ソフトコピースクロールモード指定

b_conmod1:
	move	#-1,(SCROLLMOD)
	bra	b_conmod9

*	d1.w=16	スムーススクロール指定

b_conmod2:
	moveq	#3,d0
	and	d2,d0
	move	d0,(SMTSCROLL)
	bra	b_conmod9

*	d1.w=0	カーソル点滅をする

b_conmod3:
	clr	(CSRWINKSW)
	bra	b_conmod9

*	d1.w=1	カーソル点滅を禁止

b_conmod4:
	move	#-1,(CSRWINKSW)
	bra	b_conmod9

*	d1.w=2	カーソルパターンを指定

b_conmod5:
	move	d2,(CSRLPAT)		*カーソルパターン
	move.l	d2,d0
	swap	d0
	andi	#$000f,d0		*カーソル描画開始ライン
	lsl	#2,d0
	move	d0,(CSRDRLINE)
	lea	(CSRPATSW,pc),a0
	sf	(a0)
	bra	b_conmod9

*	d1.w=3	カーソルパターンを定義

b_conmod6:
	lea	(CSRPAT0,pc),a0
	move.l	a1,-(sp)
	movea.l	d2,a1			*カーソルパターンデータアドレス
	moveq	#32-1,d0
b_conmod7:
	move.b	(a1)+,(a0)+		*カーソルパターンをコピー
	dbra	d0,b_conmod7
	movea.l	(sp)+,a1
	bra	b_conmod9


*****************************************
*	IOCS $0f	_DEFCHR		*
*****************************************

defchr::
	move.l	d1,d0
	beq	defchr1			*カーソルパターン設定(CONDRV)
	addq.l	#1,d0
	beq	defchr5			*カーソルパターン初期化
defchr9:
	movea.l	(old_defchr,pc),a0
	jmp	(a0)

defchr1:
	bsr	b_curoff
	move.l	a1,-(sp)
	lea	(CSRPATC,pc),a0
	moveq	#16-1,d0
defchr2:
	move.b	(a1)+,(a0)+
	dbra	d0,defchr2
	clr	(CSRLPAT)
*	lea	(CSRPATSW,pc),a0
	st	(a0)
	movea.l	(sp)+,a1
	bsr	b_curon
	bra	defchr9

defchr5:
	bsr	b_curoff
*	clr	(CSRDRLINE)
*	move	#$ffff,(CSRLPAT)
	move.l	#$0000_ffff,(CSRDRLINE)
	lea	(CSRPATSW,pc),a0
	sf	(a0)
	bsr	b_curon
	bra	defchr9


*****************************************
*	IOCS $1e	_B_CURON	*
*****************************************

b_curon::
*	tst.b	CSRSW.w
*	bne	b_curon1		*_OS_CUROFの状態
*	tst.b	CSRSWITCH.w
*	bne	b_curon1		*_B_CURONの状態
	tst	(CSRSWITCH)		*_OS_CUROF or _B_CURONの状態	<+08
	bne	b_curon1
	move	#5,(CSRTIMER)		*0.05秒後にカーソル点灯
	st	(CSRSWITCH)
	sf	(CSRSTAT)
b_curon1:
	rts


*****************************************
*	IOCS $1f	_B_CUROFF	*
*****************************************

b_curoff::
	tst.b	(CSRSW)
	bne	b_curoff1		*_OS_CUROFの状態
b_curoff5:
	move	#5,(CSRTIMER)
	sf	(CSRSWITCH)
	tst.b	(CSRSTAT)
	beq	b_curoff1
	bsr	csrwrite		*カーソルを消去
	sf	(CSRSTAT)
b_curoff1:
	rts


*****************************************
*	IOCS $ae	_OS_CURON	*
*****************************************

os_curon::
	move	(CSRTINIT),(CSRTIMER)	*タイマーを初期化
	move	sr,-(sp)
	ori	#$0700,sr		*割り込み禁止
	tst.b	(CSRSW)
	bne	os_curon1		*_OS_CUROFの状態だった
	tst.b	(CSRSTAT)
	bne	os_curon2		*カーソルがついている
os_curon1:
	bsr	csrwrite		*カーソルを点灯
	st	(CSRSTAT)
os_curon2:
	st	(CSRSWITCH)
	sf	(CSRSW)
os_curon_rte::
	move	(sp)+,sr
	rts


*****************************************
*	IOCS $af	_OS_CUROF	*
*****************************************

os_curof::
	st	(CSRSW)
	bra	b_curoff5


*************************************************
*	Timer-C カーソル点滅ルーチン		*
*************************************************

csrwink8:
	not.b	(CSRSTAT)
csrwink9:
	rts

csrwink::
	tst.b	(CSRSWITCH)
	beq	csrwink9		*カーソル無表示モード
	tst	(CSRWINKSW)
	beq	csrwink1		*カーソル点滅モード
	tst.b	(CSRSTAT)
	bne	csrwink9		*カーソル点灯中
csrwink1:
	pea	(csrwink8,pc)
*	btst	#1,(_CRTC21)
*	bne	csrwink9		*テキストアクセスビットマスクがONになっている
*	bsr	csrwrite
*	not.b	(CSRSTAT)
*csrwink9:
*	rts

*	カーソルを描画する

csrwrite:
	movem.l	d0-d1/a0,-(sp)
	moveq	#0,d0
	move	(CSRY),d0
	swap	d0
	lsr.l	#5,d0			*128×16倍
	movea.l	d0,a0
	move	(CSRX),d0
	cmp	(CSRXMAX),d0
	bcs	csrwrite1
	move	(CSRXMAX),d0		*カーソルが画面の右端にある
csrwrite1:
	adda	d0,a0
	adda.l	(TXSTOFST),a0
	adda.l	#$e00000,a0		*カーソル位置のVRAMアドレス(プレーン０)
	move	(_CRTC21),-(sp)
	clr.b	(_CRTC21)			*テキストシングルアクセス/ビットマスクOFF
*	bclr	#0,(_CRTC21)
	move	(CSRLPAT),d1
	beq	csrwriteB		*バッファパターンでカーソル描画
	move	(CSRDRLINE),d0		*カーソル描画開始ライン×4
	jsr	(csrwriteA,pc,d0.w)	*プレーン０に表示
	move	d1,-(sp)		;lsr	#8,d1
	move.b	(sp)+,d1		;
	adda.l	#$020000,a0
	jsr	(csrwriteA,pc,d0.w)	*プレーン１に表示
	move	(sp)+,(_CRTC21)
	movem.l	(sp)+,d0-d1/a0
	rts

*	カーソルパターン描画Ａ

csrwriteA:
	i:=0
	.rept	16
	eor.b	d1,(i.w,a0)		;(a0)/nopより(0,a0)の方が速いかもしれない
	i:=i+$0080
	.endm
	rts

*	カーソルパターン描画Ｂ

csrwriteB:
	move.b	(CSRPATSW,pc),d0
	bne	csrwriteC

	move.l	a2,-(sp)
	move.l	a1,-(sp)
	lea	(CSRSAVE0,pc),a1
	lea	(CSRPAT0,pc),a2
	move	#128,d1
	bsr	csrwriteB1		*プレーン０にカーソル表示
	adda.l	#$01f800,a0
	lea	(CSRSAVE1,pc),a1
	lea	(CSRPAT1,pc),a2
	bsr	csrwriteB1		*プレーン１にカーソル表示
	move.l	(sp)+,a1
	move.l	(sp)+,a2
	move	(sp)+,(_CRTC21)
	movem.l	(sp)+,d0-d1/a0
	rts

csrwriteB1:
	moveq	#16-1,d0
	tst.b	(CSRSTAT)
	bne	csrwriteB3
csrwriteB2:				*消されていたカーソルを表示
	move.b	(a0),(a1)+
	move.b	(a2)+,(a0)
	adda	d1,a0
	dbra	d0,csrwriteB2
	rts
csrwriteB3:				*表示されていたカーソルを消去
	move.b	(a1)+,(a0)
	adda	d1,a0
	dbra	d0,csrwriteB3
	rts

*	カーソルパターン描画Ｃ

csrwriteC:
	move.l	a1,-(sp)
	bsr	csrwriteC1
	adda.l	#$020000,a0
	bsr	csrwriteC1
	movea.l	(sp)+,a1
	move	(sp)+,(_CRTC21)
	movem.l	(sp)+,d0-d1/a0
	rts

csrwriteC1:
	lea	(CSRPATC,pc),a1
	i:=0
	.rept	16
	move.b	(a1)+,d1
	eor.b	d1,(i,a0)
	i:=i+$80
	.endm
	rts



*************************************************
*	Timer-C 割り込み処理ルーチン(100Hz)	*
*************************************************

timercint::
	move.l	a0,-(sp)
	subq	#1,(MSTIMER)
	bne	timercint1
	lea	(MSTINIT),a0
	move	(a0)+,(a0)+
	movea.l	(a0)+,a0
	jsr	(a0)			*マウスデータ送信要求処理
timercint1:
	subq	#1,(CSRTIMER)
	bne	timercint2
	lea	(CSRTINIT),a0
	move	(a0)+,(a0)+
	movea.l	(a0)+,a0
	jsr	(a0)			*カーソル点滅処理
timercint2:
	subq	#1,(FDTIMER)
	bne	timercint3
	lea	(FDTINIT),a0
	move	(a0)+,(a0)+
	movea.l	(a0)+,a0
	jsr	(a0)			*ＦＤモーター停止処理
timercint3:
	subq	#1,(ALMTIMER)
	bne	timercint4
	lea	(ALMTINIT),a0
	move	(a0)+,(a0)+
	movea.l	(a0)+,a0
	jsr	(a0)			*アラーム電源ＯＦＦ処理
timercint4:
	movea.l	(sp)+,a0
	rte



*****************************************
*	IOCS $a0	_SFTJIS		*
*****************************************
sftjis::
	moveq	#0,d0
	move.b	d1,d0			*ＳＪＩＳ下位
	lsr	#8,d1			*	 上位
	subi.b	#$81,d1
	cmpi.b	#$6f,d1
	bcc	sftjis9			*$f0～ エラー
	cmpi.b	#$1f,d1
	bcs	sftjis1			*$81～$9f
	cmpi.b	#$3f,d1
	bcs	sftjis9			*$a0～$df エラー
	subi.b	#$40,d1
sftjis1:
	add.b	d1,d1
	add.b	#$21,d1
	subi.b	#$40,d0
	cmpi.b	#$bd,d0
	bcc	sftjis9			*$fd～ エラー
	cmpi.b	#$3f,d0
	beq	sftjis9			*$7f エラー
	bcc	sftjis2
	addq.b	#1,d0
sftjis2:
	cmpi.b	#$5f,d0
	bcc	sftjis3			*$9f～$fc
	addi.b	#$20,d0
	bra	sftjis4
sftjis3:
	addq.b	#1,d1
	subi.b	#$3e,d0
sftjis4:
	lsl	#8,d1
	or	d1,d0
	move.l	d0,d1
	rts

sftjis9:
	moveq	#-1,d0
	move	(UNDEFJIS,pc),d0
	move.l	d0,d1
	rts


*****************************************
*	IOCS $a1	_JISSFT		*
*****************************************
jissft::
	moveq	#0,d0
	move	d1,d0
	lsr	#8,d0			*ＪＩＳ上位
	cmpi.b	#$21,d1
	bcs	jissft9
	cmpi.b	#$7f,d1
	bcc	jissft9
	cmpi.b	#$21,d0
	bcs	jissft9
	cmpi.b	#$7f,d0
	bcc	jissft9
	add.b	#$1f,d1
	addq.b	#1,d0
	lsr.b	#1,d0
	bcc	jissft1
	add.b	#$5e,d1
jissft1:
	cmpi.b	#$7f,d1
	bcs	jissft2
	addq.b	#1,d1
jissft2:
	add.b	#$70,d0
	cmpi.b	#$a0,d0
	bcs	jissft3
	add.b	#$40,d0
jissft3:
	asl	#8,d0
	move.b	d1,d0
	move.l	d0,d1
	rts

jissft9:
	moveq	#-1,d0
	move	(UNDEFCHR,pc),d0
	move.l	d0,d1
	rts


*****************************************
*	IOCS $a2	_AKCONV		*	($ffb4ec)
*****************************************

akconv::
	movea.l	(old_akconv,pc),a0
	jsr	(a0)
	tst.l	d0
	bpl	akconv9

	move	(UNDEFCHR,pc),d0
akconv9:
	rts

	.end

* End of File ------------------------- *

*	$Log:	CONSOLE.HA_ $
* Revision 1.5  93/04/03  22:49:06  YuNK
* ラスターコピー処理を改善し，X68030で正常動作するようにした。
* 
* Revision 1.4  92/10/28  11:32:00  YuNK
* CONDRV.SYSと同様のカーソル表示処理ルーチンを用意。
* 
* Revision 1.3  92/10/11  20:10:54  YuNK
* 24,12ドットフォントが正常に得られないことがあるバグを修正
* 
* Revision 1.2  92/09/21  15:26:42  YuNK
* 拡張ESCシーケンスを使用するとカーソル表示が異常になるバグを修正
* 
* Revision 1.1  92/09/14  01:16:46  YuNK
* Initial revision
* 
