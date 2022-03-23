		.title	HIOCS PLUS (doscon.s)

*****************************************************************
*	HIOCS version 1.10
*		< DOSCON.HAS >
*	$Id: DOSCON.HA_ 1.1 92/09/14 01:17:08 YuNK Exp $
*
*		Copyright 1990,91,92  SHARP / Y.Nakamura
*****************************************************************


* Include Files ----------------------- *

		.include	doscall.mac
		.include	iocscall.mac
		.include	hiocs.equ


* Global Symbols ---------------------- *

		.xref	b_curoff,b_curon
		.xref	b_putc,putc
		.xref	old_conctrl,old_fputc,old_fputs,old_inpout
		.xref	old_print,old_putchar,old_write
		.xref	KBUFOLDNUM
		.xref	STDOUTPTR


* Text Section ------------------------ *

		.text

*****************************************
*	DOS $02		_PUTCHAR	*
*****************************************

putchar::
	movea.l	STDOUTPTR(pc),a0
 	cmpi.b	#$01,(a0)
 	bne	putchar9		*標準出力がCONにつながっていない	<+04
putchar1:
	move	KBUFNUM.w,d0
	cmp.w	KBUFOLDNUM(pc),d0
	bne	putchar8		*キーバッファにキーが入った
putchar2:
	moveq.l	#0,d1
	move.b	$0001(a6),d1		*表示する文字
	cmpi.l	#b_putc,_B_PUTC*4+$000400.w
	bne	putchar5

*	_B_PUTCが内部ルーチンの場合

	bsr	b_curoff
*	pea	b_curon(pc)
*	bra	putc
	bsr	putc			*	<+08
putchar3:
	tst.b	CSRSW.w			*_B_CURONの処理(必ず_B_CUROFFの状態)
	bne.s	putchar4		*_OS_CUROFの状態
	move	#5,CSRTIMER.w		*0.05秒後にカーソル点灯
	st.b	CSRSWITCH.w
putchar4:
	moveq.l	#0,d0
	rts

*	_B_PUTCのベクタが変更されている場合

putchar5:				*IOCS _B_PUTC
	suba.l	a5,a5
	movea.l	_B_PUTC*4+$000400.w,a0
	jsr	(a0)			*	<+08
	moveq.l	#0,d0
	rts

*	画面への出力でない場合

putchar8:
	lea	KBUFOLDNUM(pc),a4
	move	d0,(a4)
putchar9:				*<+04
	movea.l	old_putchar(pc),a0
	jmp	(a0)			*Human内部のDOS _PUTCHARへ


putchar99:
	lea	KBUFOLDNUM(pc),a4
	move	KBUFNUM.w,(a4)
	movem.l	d1/d5/a1/a6,-(sp)
	lea	2(sp),a6
	movea.l	old_putchar(pc),a0
	jsr	(a0)			*Human内部のDOS _PUTCHARへ
	movem.l	(sp)+,d1/d5/a1/a6
	move	KBUFOLDNUM(pc),d4
	rts



*****************************************
*	DOS $06 	_INPOUT		*
*****************************************

inpout::
	cmpi.b	#$fe,$0001(a6)
	bcc	inpout9			*文字表示でない場合
	movea.l	STDOUTPTR(pc),a0
 	cmpi.b	#$01,(a0)
 	bne	inpout9			*標準出力がCONにつながっていない
	bsr	putchar2		*ブレークチェックなし１文字表示
	moveq.l	#0,d0
	rts

*	画面への出力でない場合

inpout9:
	movea.l	old_inpout(pc),a0
	jmp	(a0)			*Human内部のDOS _INPOUTへ



*****************************************
*	DOS $09		_PRINT		*
*****************************************

print::
	movea.l	STDOUTPTR(pc),a0
 	cmpi.b	#$01,(a0)
 	bne	print9			*標準出力がCONにつながっていない
print1:
	move	KBUFOLDNUM(pc),d4
	movea.l	(a6),a1			*表示する文字列へのポインタ
	cmpi.l	#b_putc,_B_PUTC*4+$000400.w
	bne	print6

*	_B_PUTCが内部ルーチンの場合

	bsr	b_curoff
	bra	print3
print2:
	cmp.w	KBUFNUM.w,d4
	bne	print4			*キーバッファにキーが入った
	bsr	putc
print3:
	moveq.l	#0,d1
	move.b	(a1)+,d1
	bne	print2
	bra	putchar3		*	<+08
*	bra	b_curon
print4:
	bsr	b_curon
	bsr	putchar99
	bsr	b_curoff
	bra	print3

*	_B_PUTCのベクタが変更されている場合

print5:
	cmp.w	KBUFNUM.w,d4
	bne	print7			*キーバッファにキーが入った
	suba.l	a5,a5			*IOCS _B_PUTC
	movea.l	_B_PUTC*4+$000400.w,a0
	jsr	(a0)
print6:
	moveq.l	#0,d1
	move.b	(a1)+,d1
	bne	print5
	moveq.l	#0,d0			*	<+08
	rts
print7:
	bsr	putchar99
	bra	print6

*	画面への出力でない場合

print9:
	movea.l	old_print(pc),a0
	jmp	(a0)			*Human内部のDOS _PRINTへ



*****************************************
*	DOS $1d 	_FPUTC		*
*****************************************

fputc::
	move	$0002(a6),d0		*ファイルハンドル
	subq.w	#1,d0
	bne	fputc5			*標準出力への出力でない
	movea.l	STDOUTPTR(pc),a0
 	cmpi.b	#$01,(a0)
 	bne	fputc9			*標準出力がCONにつながっていない
	bsr	putchar1		*ブレークチェック付き１文字表示
	moveq.l	#1,d0			*出力文字数
	rts

fputc5:
	subq.w	#1,d0
	bne	fputc9			*標準エラー出力への出力でない
	movea.l	STDOUTPTR(pc),a0
	cmpi.b	#$02,2(a0)
	bne	fputc9			*標準エラー出力がCONにつながっていない	<+04
*	move	KBUFNUM.w,d0		*	<+06 (標準エラー出力は
*	cmp.w	KBUFOLDNUM(pc),d0	*			ブレークチェックしない)
*	bne	fputc8			*キーバッファにキーが入った
	bsr	putchar2		*ブレークチェックなし１文字表示
	moveq.l	#1,d0			*出力文字数
	rts

*	画面への出力でない場合

*fputc8:				*<+04	<+06
*	lea	KBUFOLDNUM(pc),a4
*	move	d0,(a4)
fputc9:
	movea.l	old_fputc(pc),a0
	jmp	(a0)			*Human内部のDOS _FPUTCへ


*fputc99:				*<+04	<+06
*	lea	KBUFOLDNUM(pc),a4
*	move	KBUFNUM.w,(a4)
*	swap.w	d1
*	move	#2,d1
*	movem.l	d1/d5/a1/a6,-(sp)
*	lea	(sp),a6
*	movea.l	old_fputc(pc),a0
*	jsr	(a0)			*Human内部のDOS _FPUTCへ
*	movem.l	(sp)+,d1/d5/a1/a6
*	move	KBUFOLDNUM(pc),d4
*	rts



*****************************************
*	DOS $1e		_FPUTS		*
*****************************************

fputs::
	move	$0004(a6),d0		*ファイルハンドル
	subq.w	#1,d0
	bne	fputs1			*標準出力への出力でない
	movea.l	STDOUTPTR(pc),a0
 	cmpi.b	#$01,(a0)
 	bne	fputs9			*標準出力がCONにつながっていない
	bsr	print1			*文字列表示
	suba.l	(a6),a1
	subq.l	#1,a1
	move.l	a1,d0			*出力文字数
	rts

fputs1:
	subq.w	#1,d0
	bne	fputs9			*標準エラー出力への出力でない
	movea.l	STDOUTPTR(pc),a0
	cmpi.b	#$02,2(a0)		*	<+06
	bne	fputs9			*標準エラー出力がCONにつながっていない	<+04
	moveq.l	#0,d5			*出力文字数
	move	KBUFOLDNUM(pc),d4
	movea.l	(a6),a1			*表示する文字列へのポインタ
	cmpi.l	#b_putc,_B_PUTC*4+$000400.w
	bne	fputs6

*	_B_PUTCが内部ルーチンの場合

	bsr	b_curoff
	bra	fputs3
fputs2:
	addq.l	#1,d5
*	cmp.w	KBUFNUM.w,d4		*	<+06
*	bne	fputs4			*キーバッファにキーが入った
	bsr	putc
fputs3:
	moveq.l	#0,d1
	move.b	(a1)+,d1
	bne	fputs2
	move.l	d5,d0
	bra	b_curon
*fputs4:
*	bsr	b_curon
*	bsr	fputc99
*	bsr	b_curoff
*	bra	fputs3

*	_B_PUTCのベクタが変更されている場合

fputs5:
	addq.l	#1,d5
*	cmp.w	KBUFNUM.w,d4		*	<+06
*	bne	fputs7			*キーバッファにキーが入った
	suba.l	a5,a5			*IOCS _B_PUTC
	movea.l	_B_PUTC*4+$000400.w,a0
	jsr	(a0)
fputs6:
	moveq.l	#0,d1
	move.b	(a1)+,d1
	bne	fputs5
	move.l	d5,d0
	rts
*fputs7:
*	bsr	fputc99
*	bra	fputs6

*	画面への出力でない場合

fputs9:
	movea.l	old_fputs(pc),a0
	jmp	(a0)			*Human内部のDOS _FPUTSへ



*****************************************
*	DOS $23 	_CONCTRL	*
*****************************************

conctrl::
		move	(a6)+,d0
		cmpi	#18,d0
		bhi	conctrl8
		suba.l	a5,a5
.if CPU>=68020
		movea.l	(_B_PUTC*4+$400,d0.w*4),a0
		jmp	(conjmptbl,pc,d0.w*2)
.else
		add	d0,d0			;x2
		move	d0,d1
		add	d1,d1			;x4
		lea	(_B_PUTC*4+$400),a0
		movea.l	(a0,d1.w),a0
		jmp	(conjmptbl,pc,d0.w)
.endif

conctrl8:
	moveq.l	#-1,d0
	rts

conctrl9:
	subq.l	#2,a6
	movea.l	old_conctrl(pc),a0
	jmp	(a0)			*Human内部のDOS _CONCTRLへ

conjmptbl:
	bra.s	conc_putc	* 0:１文字表示
	bra.s	conc_print	* 1:文字列表示
	bra.s	conc_color	* 2:文字属性設定
	bra.s	conc_locate	* 3:カーソル移動
	bra.s	conc_down_s	* 4:カーソル下移動(スクロール有り)
	bra.s	conc_up_s	* 5:	　　上移動(スクロール有り)
	bra.s	conc_up		* 6:	　　上移動
	bra.s	conc_down	* 7:	　　下移動
	bra.s	conc_right	* 8:	　　右移動
	bra.s	conc_left	* 9:	　　左移動
	bra.s	conc_clr_st	*10:画面クリア
	bra.s	conc_era_st	*11:行クリア
	bra.s	conc_ins	*12:行挿入
	bra.s	conc_del	*13:行削除
	bra.s	conctrl9	*14:ファンクションキー表示
	bra.s	conctrl9	*15:スクロール範囲設定
	bra.s	conctrl9	*16:スクリーンモード設定
	bra.s	conc_curon	*17:カーソル表示
	bra.s	conc_curoff	*18:カーソル無表示

conc_putc:
	moveq.l	#0,d1
	move	(a6),d1
	cmpa.l	#b_putc,a0
	bne	conc_putc5
	bsr	b_curoff
	bsr	putc
	bsr	b_curon
	moveq.l	#0,d0
	rts
conc_putc5:
	jsr	(a0)
	moveq.l	#0,d0
	rts

conc_print:
	movea.l	(a6),a1
	jsr	(a0)
	moveq.l	#0,d0
	rts

conc_color:
conc_up:
conc_down:
conc_right:
conc_left:
conc_clr_st:
conc_era_st:
conc_ins:
conc_del:
	move	(a6),d1
conc_down_s:
conc_up_s:
	jsr	(a0)
	moveq.l	#0,d0
	rts

conc_locate:
	move	(a6)+,d1
	move	(a6),d2
	jsr	(a0)
	moveq.l	#0,d0
	rts

conc_curon:
	movea.l	_OS_CURON*4+$000400.w,a0
	jsr	(a0)
	moveq.l	#0,d0
	rts

conc_curoff:
	movea.l	_OS_CUROF*4+$000400.w,a0
	jsr	(a0)
	moveq.l	#0,d0
	rts



*****************************************
*	DOS $40		_WRITE		*
*****************************************

write::
	move	(a6),d0			*ファイルハンドル
	subq.w	#1,d0
	bne	write10			*標準出力への出力でない
	movea.l	STDOUTPTR(pc),a0
 	cmpi.b	#$01,(a0)
 	bne	write9			*標準出力がCONにつながっていない
	move	KBUFOLDNUM(pc),d4
	movea.l	$0002(a6),a1		*書き込みデータバッファへのポインタ
	move.l	$0006(a6),d5		*書き込みバイト数
	cmpi.l	#b_putc,_B_PUTC*4+$000400.w
	bne	write6

*	_B_PUTCが内部ルーチンの場合

	bsr	b_curoff
	bra	write2
write1:
	moveq.l	#0,d1
	move.b	(a1)+,d1
	cmp.w	KBUFNUM.w,d4
	bne	write3			*キーバッファにキーが入った
	bsr	putc
write2:
	subq.l	#1,d5
	bpl	write1
	move.l	$0006(a6),d0
	bra	b_curon
write3:
	bsr	b_curon
	bsr	putchar99
	bsr	b_curoff
	bra	write2

*	_B_PUTCのベクタが変更されている場合

write5:
	moveq.l	#0,d1
	move.b	(a1)+,d1
	cmp.w	KBUFNUM.w,d4
	bne	write7			*キーバッファにキーが入った
	suba.l	a5,a5			*IOCS _B_PUTC
	movea.l	_B_PUTC*4+$000400.w,a0
	jsr	(a0)
write6:
	subq.l	#1,d5
	bpl	write5
	move.l	$0006(a6),d0
	rts
write7:
	bsr	putchar99
	bra	write6


write10:				*<+04
	subq.w	#1,d0
	bne	write9			*標準エラー出力への出力でない
	movea.l	STDOUTPTR(pc),a0
	cmpi.b	#$02,2(a0)
	bne	write9			*標準エラー出力がCONにつながっていない
	move	KBUFOLDNUM(pc),d4
	movea.l	$0002(a6),a1		*書き込みデータバッファへのポインタ
	move.l	$0006(a6),d5		*書き込みバイト数
	cmpi.l	#b_putc,_B_PUTC*4+$000400.w
	bne	write16

*	_B_PUTCが内部ルーチンの場合

	bsr	b_curoff
	bra	write12
write11:
	moveq.l	#0,d1
	move.b	(a1)+,d1
	cmp.w	KBUFNUM.w,d4
	bne	write13			*キーバッファにキーが入った
	bsr	putc
write12:
	subq.l	#1,d5
	bpl	write11
	move.l	$0006(a6),d0
	bra	b_curon
write13:
	bsr	b_curon
	bsr	write99			*<+05
	bsr	b_curoff
	bra	write12

*	_B_PUTCのベクタが変更されている場合

write15:
	moveq.l	#0,d1
	move.b	(a1)+,d1
	cmp.w	KBUFNUM.w,d4
	bne	write17			*キーバッファにキーが入った
	suba.l	a5,a5			*IOCS _B_PUTC
	movea.l	_B_PUTC*4+$000400.w,a0
	jsr	(a0)
write16:
	subq.l	#1,d5
	bpl	write15
	move.l	$0006(a6),d0
	rts
write17:
	bsr	write99			*<+05
	bra	write16


*	画面への出力でない場合

write9:
	movea.l	old_write(pc),a0
	jmp	(a0)			*Human内部のDOS _WRITEへ


write99:				*<+05
	lea	KBUFOLDNUM(pc),a4
	move	KBUFNUM.w,(a4)
	movem.l	d1/d5/a1/a6,-(sp)
	pea	1.w			*書き込みバイト数
	pea	7(sp)			*書き込みデータバッファへのポインタ
	move	#2,-(sp)		*ファイルハンドル
	lea	(sp),a6
	movea.l	old_write(pc),a0
	jsr	(a0)			*Human内部のDOS _WRITEへ
	lea	10(sp),sp
	movem.l	(sp)+,d1/d5/a1/a6
	move	KBUFOLDNUM(pc),d4
	rts

		.end

* End of File ------------------------- *

*	$Log:	DOSCON.HA_ $
* Revision 1.1  92/09/14  01:17:08  YuNK
* Initial revision
* 
