	.title	HIOCS PLUS (hiocs.s)

*****************************************************************
*	HIOCS version 1.10
*		< HIOCS.HAS >
*	$Id: HIOCS.HA_ 1.6 93/02/15 00:39:30 YuNK Exp $
*
*		Copyright 1990-93  SHARP / Y.Nakamura
*****************************************************************


* Include Files ----------------------- *

	.include	doscall.mac
	.include	iocscall.mac
	.include	hiocs.equ


* Global Symbols ---------------------- *

	.xref	dev_header
	.xref	csrwink
	.xref	timercint
	.xref	sccbrcv
	.xref	FONTANK6,FONTKNJ16A,FONTKNJ16C
	.xref	LOGBUFVECT
	.xref	STDOUTPTR
* ROMPATCH
	.xref	patchbegin,patchend,gpalet,dmamove,ms_patst
* CONDRV
	.xref	putc,putc_log,putc_escsq0
* rte修正
	.xref	os_curon_rte,mscdraw_rte,mscerase_rte,txyline_rte,txline_rte
* MOUSE
	.xref	mscdrawA,msceraseA,msctrlsetA,msctrlsetB,msdpatch1,msdpatch2,msepatch1,msepatch2

	.xref	akconv,jissft,sftjis
	.xref	b_clr_st,b_del,b_era_st,b_ins
	.xref	b_down,b_down_s,b_left,b_locate,b_right,b_up,b_up_s
	.xref	b_color,b_conmod,b_consol,defchr
	.xref	b_curoff,b_curon,os_curof,os_curon
	.xref	b_print,b_putc,b_putmes
	.xref	box,circle,fill,drawmode,getgrm,line,paint,point,pset,putgrm,symbol,wipe
	.xref	chr_adr,fntadr,fntget,putchar
	.xref	ms_curgt,ms_curof,ms_curon,ms_curst,ms_getdt,ms_init,ms_stat,ms_vcs
	.xref	txbox,txfill,txline,txrev,txxline,txyline
	.xref	fputc,fputs,conctrl,inpout,print,write
	.xref	clear_mpu_cache
	.xref	txrascpy


* Fixed Numbers ----------------------- *

FONTSIZE0:	.equ	4096		*半角文字のフォントサイズ
FONTSIZE1:	.equ	49216-4096	*ＪＩＳ非漢字
FONTSIZE2:	.equ	145472-49216	*ＪＩＳ第１水準漢字
FONTSIZE3:	.equ	286848-145472	*ＪＩＳ第２水準漢字


* Macros ------------------------------ *

PRINT:	.macro	adr
	pea	adr
	DOS	_PRINT
	addq.l	#4,sp
	.endm


* Text Section ------------------------ *

	.text
	.even
checkstr:
	.dc.b	HIOCS_ID,version		*(16bytes)
	.dc.b	'IOCS'


*************************************************
*	trap #15 (IOCS呼び出し) 処理ルーチン	*
*************************************************

iocscall:
	move.l	a0,-(sp)
.if CPU>=68020
	andi.l	#$00ff,d0
	move	d0,(IOCSNUM)
	jsr	([$400,d0.w*4])
.else
	andi	#$00ff,d0
	ext.l	d0
	move	d0,(IOCSNUM)
	movea.l	d0,a0
	adda	a0,a0
	adda	a0,a0
	movea.l	($400,a0),a0
	jsr	(a0)
.endif
	move	#-1,(IOCSNUM)
	movea.l	(sp)+,a0
	rte


*************************************************
*	IOCS/DOSコールベクタを変更する		*
*************************************************

setvect:
	tst.b	(~IOCSCALLFLG,a1)	*trap #15ベクタ
	bne	setvect1		*すでに変更されている
	tst.b	(~IOCSCALLFLG,a0)
	beq	setvect1		*変更しない

	lea	(OLDTRAPVC,pc),a2
	move.l	(TRAPFVEC),a3
	move.l	a3,(a2)
	cmpa.l	#$ff0000,a3
	bcs	setvect1		*trap #15処理は変更されている
	lea	(iocscall,pc),a2
	move.l	a2,(TRAPFVEC)
	st	(~IOCSCALLFLG,a1)
setvect1:
	tst.b	(~IOCSCONFLG,a1)	*IOCS文字出力ベクタ
	bne	setvect2		*すでに変更されている
	move.b	(~IOCSCONFLG,a0),(~IOCSCONFLG,a1)
	beq	setvect2		*変更しない

	IOCS	_B_CUROFF		*<+08

	move.l	#0<<16+$ffff,(CSRDRLINE)
	.fail	(CSRDRLINE+2)!=CSRLPAT
@@:
	lea	(iocsctbl,pc),a3
	bsr	chgvecttbl_iocs		*IOCSベクタを変更する

	lea	(OLDCSRVC,pc),a2
	move.l	(CSRTADR),(a2)		*timer-C カーソル点滅処理アドレス
	lea	(csrwink,pc),a2
	move.l	a2,(CSRTADR)
	IOCS	_B_CURON		*<+08

	lea	(OLDTIMERCVC,pc),a2
	clr.l	(a2)
	move.l	(TIMERCVEC),a3		*timer-C 割り込み処理アドレス
	cmpa.l	#$ff0000,a3
	bcs	setvect13		*timer-C処理は変更されている

	move.l	a3,(a2)
	lea	(timercint,pc),a2
	move.l	a2,(TIMERCVEC)
setvect13:
	bsr	check_condrv_mark
	bne	setvect2		*CONDRV.SYSは常駐していない

	lea	(LOGBUFVECT,pc),a3
	move.l	(-16,a2),(a3)+
	pea	(-28,a2)		*CONDRV.SYSのオプションの格納アドレス
	move.l	(sp)+,(a3)+		*CONDFLAG
	move.l	(-22,a2),(a3)		*CONDSYSCALL

	lea	(CONDRVPATCH,pc),a2
	lea	(putc,pc),a3		*CONDRV.SYS用のパッチ当てを行なう
	move.l	(a3),(a2)+
	move.l	#BRA_W<<16+.loww.(putc_log-(putc+2)),(a3)
	addq.b	#(BNE_W-BRA_W)>>8,(putc_escsq0-putc,a3)
*	lea	(CONDRVFLG,pc),a2
	st	(a2)

	bsr	clear_mpu_cache
setvect2:
	tst.b	(~IOCSGRFLG,a1)		*IOCSグラフィック描画ベクタ
	bne	setvect3		*すでに変更されている
	move.b	(~IOCSGRFLG,a0),(~IOCSGRFLG,a1)
	beq	setvect3		*変更しない

	lea	(iocsgtbl,pc),a3
	bsr	chgvecttbl_iocs		*IOCSベクタを変更する
setvect3:
	tst.b	(~DOSCONFLG,a1)		*DOS文字出力ベクタ
	bne	setvect4		*すでに変更されている
	move.b	(~DOSCONFLG,a0),(~DOSCONFLG,a1)
	beq	setvect4		*変更しない

	bsr	seahumanptr		*stdoutファイルハンドルポインタを検索する
	move.l	(STDOUTPTR,pc),d0
	beq	setvect4
	lea	($1800),a2
	lea	(dosctbl,pc),a3
	bsr	chgvecttbl		*DOSベクタを変更する

setvect4:
	tst.b	(~IOCSMSFLG,a1)		*IOCSマウス処理ベクタ
	bne	setvect10		*すでに変更されている
	move.b	(~IOCSMSFLG,a0),(~IOCSMSFLG,a1)
	beq	setvect10		*変更しない

	lea	(iocsmtbl,pc),a3
	bsr	chgvecttbl_iocs		*IOCSベクタを変更する

	lea	(OLDMSCVC,pc),a2
	clr.l	(a2)
	move.l	(MSTADR),a3
	cmpa.l	#$ff0000,a3
	bcs	setvect5		*マウス送信要求処理は変更されている
	move.l	(SCCBRCVEC),a3
	cmpa.l	#$ff0000,a3
	bcs	setvect5		*SCC受信処理は変更されている

	move	sr,d0
	ori	#$0700,sr		*割り込み禁止
	lea	(OLDMSCVC,pc),a2
	move.l	(MSTADR),(a2)		*timer-C マウス送信要求
	lea	(msctrlsetA,pc),a2
	move.l	a2,(MSTADR)
	clr.b	(MSCTRLFLG)
	lea	(OLDSCCBVC,pc),a2
	move.l	(SCCBRCVEC),(a2)+	*SCC-B受信処理
	move.l	(SCCBRCVEC2),(a2)
	lea	(sccbrcv,pc),a2
	move.l	a2,(SCCBRCVEC)
	move.l	a2,(SCCBRCVEC2)
	move	d0,sr
setvect5:
	moveq	#0,d1
	IOCS	_SETMSADR		*マウスカーソル表示処理アドレス変更
setvect10:
	moveq	#0,d0
	rts

check_condrv_mark:
	movea.l	(_KEY_INIT*4+$400),a2
	cmpi.l	#'hmk*',(-4,a2)
chgvecttbl2:
	rts

*	IOCS/DOSベクタを変更する

chgvecttbl_iocs:
	lea	($400),a2
chgvecttbl:
	move.l	a3,d1
chgvecttbl1:
	move	(a3)+,d0
	bmi	chgvecttbl2

	add	d0,d0
	add	d0,d0
	movea.l	d1,a4
	adda	(a3)+,a4		*変更先アドレス
	move.l	(a2,d0.w),(a3)+		*現在のベクタを保存
	move.l	a4,(a2,d0.w)		*ベクタを変更する
	bra	chgvecttbl1

*	DOS内ファイルハンドルバッファを検索

seahumanptr:				*<+03
	movem.l	d0-d7/a0-a6,-(sp)
	clr.l	-(sp)
	movea.l	sp,a6
	movea.l	(.low.(_DUP0)*4+$1800),a0
	jsr	(a0)
	addq.l	#4,sp
	move.l	a0,d0
	addq.l	#3,d0
	lea	(STDOUTPTR,pc),a0
	move.l	d0,(a0)
	movem.l	(sp)+,d0-d7/a0-a6
	rts



*************************************************
*	IOCS/DOSコールベクタを元の値に戻す	*
*************************************************

*	復帰するベクタが変更されていないかどうかチェック

restorevect:
	tst.b	(~IOCSCALLFLG,a1)	*trap #15ベクタ
	beq	restorevect1		*変更されていない
	tst.b	(~IOCSCALLFLG,a0)
	bne	restorevect1		*元の値に戻さない

	lea	(iocscall,pc),a2
	cmpa.l	(TRAPFVEC),a2
	bne	restorevect99

restorevect1:
	tst.b	(~IOCSCONFLG,a1)	*IOCS文字出力ベクタ
	beq	restorevect2		*変更されていない
	tst.b	(~IOCSCONFLG,a0)
	bne	restorevect2		*元の値に戻さない

	lea	(iocsctbl,pc),a3
	bsr	chkvecttbl_iocs
	bne	restorevect99
	lea	(csrwink,pc),a2
	cmpa.l	(CSRTADR),a2
	bne	restorevect99

	move.l	(OLDTIMERCVC,pc),d0
	beq	restorevect15		*timer-C処理ベクタは変更していない
	lea	(timercint,pc),a2
	cmpa.l	(TIMERCVEC),a2
	bne	restorevect99

restorevect15:
	move.b	(CONDRVFLG,pc),d0
	beq	restorevect2		*CONDRV.SYSは常駐していない

	bsr	check_condrv_mark
	bne	restorevect99
restorevect2:
	tst.b	(~IOCSGRFLG,a1)		*IOCSグラフィック描画ベクタ
	beq	restorevect3		*変更されていない
	tst.b	(~IOCSGRFLG,a0)
	bne	restorevect3		*元の値に戻さない

	lea	(iocsgtbl,pc),a3
	bsr	chkvecttbl_iocs
	bne	restorevect99

restorevect3:
	tst.b	(~DOSCONFLG,a1)		*DOS文字出力ベクタ
	beq	restorevect4		*変更されていない
	tst.b	(~DOSCONFLG,a0)
	bne	restorevect4		*元の値に戻さない

	lea	($1800),a2
	lea	(dosctbl,pc),a3
	bsr	chkvecttbl
	bne	restorevect99

restorevect4:
	tst.b	(~IOCSMSFLG,a1)		*IOCSマウス処理ベクタ
	beq	restorevect50		*変更されていない
	tst.b	(~IOCSMSFLG,a0)
	bne	restorevect50		*元の値に戻さない

	lea	(iocsmtbl,pc),a3
	bsr	chkvecttbl_iocs
	bne	restorevect99

	move.l	(OLDMSCVC,pc),d0
	beq	restorevect50		*マウス送信要求/SCC受信処理は変更していない

	move.l	(MSTADR),a3
	lea	(msctrlsetA,pc),a2	*本体側マウス送信要求ルーチン
	cmpa.l	a3,a2
	beq	restorevect5
	lea	(msctrlsetB,pc),a2	*キーボード側マウス送信要求ルーチン
	cmpa.l	a3,a2
	bne	restorevect99
restorevect5:

	lea	(sccbrcv,pc),a2
	cmpa.l	(SCCBRCVEC),a2
	bne	restorevect99
	cmpa.l	(SCCBRCVEC2),a2
	bne	restorevect99

*	ベクタを元の値に戻す

restorevect50:
	tst.b	(~IOCSCALLFLG,a1)	*trap #15ベクタ
	beq	restorevect51		*変更されていない
	move.b	(~IOCSCALLFLG,a0),(~IOCSCALLFLG,a1)
	bne	restorevect51		*元の値に戻さない

	move.l	(OLDTRAPVC,pc),(TRAPFVEC)

restorevect51:
	tst.b	(~IOCSCONFLG,a1)	*IOCS文字出力ベクタ
	beq	restorevect52		*変更されていない
	move.b	(~IOCSCONFLG,a0),(~IOCSCONFLG,a1)
	bne	restorevect52		*元の値に戻さない

	IOCS	_B_CUROFF		*<+03
	lea	(iocsctbl,pc),a3
	bsr	rstvecttbl_iocs
	move.l	(OLDCSRVC,pc),(CSRTADR)
	IOCS	_B_CURON		*<+03

	move.l	(OLDTIMERCVC,pc),d0
	beq	restorevect513		*timer-C処理ベクタは変更していない
	move.l	d0,(TIMERCVEC)

restorevect513:
	move.b	(CONDRVFLG,pc),d0
	beq	restorevect52		*CONDRV.SYSは常駐していない

	lea	(CONDRVPATCH,pc),a2
	lea	(putc,pc),a3
	move.l	(a2)+,(a3)
*	lea	(CONDRVFLG,pc),a2
	sf	(a2)

	bsr	clear_mpu_cache
restorevect52:
	tst.b	(~IOCSGRFLG,a1)		*IOCSグラフィック描画ベクタ
	beq	restorevect53		*変更されていない
	move.b	(~IOCSGRFLG,a0),(~IOCSGRFLG,a1)
	bne	restorevect53		*元の値に戻さない

	lea	(iocsgtbl,pc),a3
	bsr	rstvecttbl_iocs

restorevect53:
	tst.b	(~DOSCONFLG,a1)		*DOS文字出力ベクタ
	beq	restorevect54		*変更されていない
	move.b	(~DOSCONFLG,a0),(~DOSCONFLG,a1)
	bne	restorevect54		*元の値に戻さない

	lea	($1800),a2
	lea	(dosctbl,pc),a3
	bsr	rstvecttbl

restorevect54:
	tst.b	(~IOCSMSFLG,a1)		*IOCSマウス処理ベクタ
	beq	restorevect60		*変更されていない
	move.b	(~IOCSMSFLG,a0),(~IOCSMSFLG,a1)
	bne	restorevect60		*元の値に戻さない

	lea	(iocsmtbl,pc),a3
	bsr	rstvecttbl_iocs

	move.l	(OLDMSCVC,pc),d0
	beq	restorevect55		*マウス送信要求/SCC受信処理は変更していない

	move	sr,d0
	ori	#$0700,sr		*割り込み禁止
	move.l	(OLDMSCVC,pc),(MSTADR)	*timer-C マウス送信要求
	clr.b	(MSCTRLFLG)
	move.l	(OLDSCCBVC,pc),(SCCBRCVEC)	*SCC-B受信処理
	move.l	(OLDSCCBVC2,pc),(SCCBRCVEC2)
	move	d0,sr
restorevect55:
	moveq	#0,d1
	IOCS	_SETMSADR		*マウスカーソル表示処理アドレス変更

restorevect60:
	moveq	#0,d0
	rts
restorevect99:
	moveq	#-1,d0
	rts


*	変更したIOCS/DOSベクタを元に戻す

rstvecttbl_iocs:
	lea	($400),a2
	bra	rstvecttbl
rstvecttbl1:
	add	d0,d0
	add	d0,d0
	addq.l	#2,a3
	move.l	(a3),(a2,d0.w)
	clr.l	(a3)+
rstvecttbl:
	move	(a3)+,d0
	bpl	rstvecttbl1
	rts


*	IOCS/DOSベクタが変更されていないか調べる

chkvecttbl_iocs:
	lea	($400),a2
chkvecttbl:
	move.l	a3,d1
chkvecttbl1:
	move	(a3)+,d0
	bmi	chkvecttbl2

	add	d0,d0
	add	d0,d0
	movea.l	d1,a4
	adda	(a3)+,a4
	addq.l	#4,a3
	cmp.l	(a2,d0.w),a4
	beq	chkvecttbl1

	moveq	#-1,d0			*ベクタが変更されている
	rts
chkvecttbl2:
	moveq	#0,d0			*ベクタは変更されていない
	rts

*****************************************
*	未定義漢字コードを設定する	*
*****************************************

setundefchr:
	move.l	(FONTKNJ16A,pc),d1	*	<+07
	cmpi.l	#fon_knj16,d1
	bcc	setundefchr1		*ＲＯＭフォントを使用中の場合
	moveq	#13,d2
	IOCS	_SETFNTADR		*$29xx～$2Fxxの扱いを設定する
setundefchr1:
	move.l	(FONTKNJ16C,pc),d1	*	<+08
	cmpi.l	#fon_knj16+$1d600,d1
	bcc	setundefchr2		*ＲＯＭフォントを使用中の場合
	moveq	#15,d2
	IOCS	_SETFNTADR		*$76xx～$7Exxの扱いを設定する
setundefchr2:
	lea	(UNDEFFLG,pc),a0
	move.b	(a0),d0
	beq	setundefchr5
	move	#'※',(UNDEFCHR-UNDEFFLG,a0)	*ユーザー定義パターンの場合
	move	#$2228,(UNDEFJIS-UNDEFFLG,a0)
	lea	(UNDEFPAT,pc),a1
	move.l	a1,(UNDEFPTR-UNDEFFLG,a0)
	rts
setundefchr4:
	lea	(UNDEFCHR,pc),a0
	move	#'※',(a0)
setundefchr5:
	move	(UNDEFCHR,pc),d1
	IOCS	_SFTJIS
	tst.l	d1
	bmi	setundefchr4		*未定義漢字コードがない
	cmpi	#$2900,d1		*	<+07
	bcs	setundefchr6
	cmpi	#$3000,d1
	bcs	setundefchr4		*$29xx～$2fxxは使用しない
setundefchr6:
	lea	(UNDEFJIS,pc),a0
	move	d1,(a0)
	moveq	#8,d2
	IOCS	_FNTADR
	cmpi	#2-1,d1
	bne	setundefchr4		*未定義漢字コードが全角文字でない
	lea	(UNDEFPTR,pc),a0
	move.l	d0,(a0)
	rts


*	IOCTRL用データ

	.offset	0
~IOCSCALLFLG:	.ds.b	1	*trap #15処理ルーチン変更フラグ	(※順序を変更しないこと)
~IOCSCONFLG:	.ds.b	1	*IOCS文字出力ベクタ変更フラグ
~IOCSGRFLG:	.ds.b	1	*IOCSグラフィック描画ベクタ変更フラグ
~DOSCONFLG:	.ds.b	1	*DOS文字出力ベクタ変更フラグ
~IOCSMSFLG:	.ds.b	1	*IOCSマウス処理ベクタ変更フラグ
VECTFLGSIZE:
	.text

	.even
IOCTRLDATA:	.dc.b	HIOCS_ID,version	*(16bytes)
IOCTRLERR:	.ds	1			*(IOCTRL時のエラーコード)
TOPADR:		.dc.l	0	*常駐部先頭アドレス(デバイスドライバ登録なら0)

IOVECTFLG:	.ds.b	VECTFLGSIZE
	.even

EXFONTBUF:	.dc.l	0	*拡張フォントバッファ先頭アドレス(なければ0)
FONTBUFSIZE:	.dc.b	0	*フォントバッファサイズ(0～3)
		.dc.b	0	*常駐フォントバッファサイズ(0～3)
CHRSELFLG::	.dc.b	0	*半角文字('\','~','|')の変換をしないなら-1
VBELLFLG::	.dc.b	0	*ビジブルベルにするなら-1
UNDEFFLG::	.dc.b	0	*未定義漢字コードをユーザーパターンにするなら-1
USRKNJFLG::	.dc.b	0	*JIS $29xx～$2Fxxのフォントモード		<+07
				*0:IOCS.X準拠/正:ユーザーフォント使用/負:TC.X準拠
USRKNJ2FLG::	.dc.b	0	*JIS $76xx～$7Exxのフォントモード		<+08
				*0:外字エリア/-1:ユーザーフォント使用
CONESCFLG::	.dc.b	0	*CONDRV -eスイッチフラグ(ESC 0/1の無効化)
		.even

MSSPEED::	.dc	3	*マウスカーソル移動速度(高速 1 ～ 3 ～ 4 低速)
UNDEFCHR::	.dc	'※'	*未定義漢字コードのキャラクタ(ユーザー定義なら'※')
UNDEFPAT::			*		   フォントパターン
		.dcb.l	16/2,$aaaa5555
IOCTRLEND:
IOCTRLSIZE:	.equ	IOCTRLEND-IOCTRLDATA

CONDRVPATCH:	.ds.l	1
CONDRVFLG:	.dc.b	0	*CONDRV.SYS対応フラグ
	.even

UNDEFJIS::	.dc	$2228	*		    (ＪＩＳコード)
UNDEFPTR::	.dc.l	$f00ca0	*		    フォントアドレス

LINKPTR:	.ds.l	1	*デバイスドライバリンクポインタ

OLDTRAPVC:	.ds.l	1	*trap #15ベクタ変更前の値
OLDCSRVC:	.ds.l	1	*timer-C カーソル点滅
OLDTIMERCVC:	.ds.l	1	*timer-C 割り込み処理
OLDMSCVC:	.ds.l	1	*timer-C MSCTRL
OLDSCCBVC:	.ds.l	1	*SCC-B 受信処理
OLDSCCBVC2:	.ds.l	1

*	IOCSパッチテーブル

PATCHTBL_SIZE:	.equ	3	*_GPALET,_DMAMOVE,_MS_PATST
patchtbl:	.ds.l	PATCHTBL_SIZE

*	IOCSベクタテーブル

viocsc:	.macro	callno,addr
	.dc	callno,addr-iocsctbl
old_&addr::
	.ds.l	1
	.endm

viocsg:	.macro	callno,addr
	.dc	callno,addr-iocsgtbl
old_&addr::
	.ds.l	1
	.endm

viocsm:	.macro	callno,addr
	.dc	callno,addr-iocsmtbl
old_&addr::
	.ds.l	1
	.endm

iocsctbl:
	viocsc	_DEFCHR,defchr
	viocsc	_FNTADR,fntadr
	viocsc	_FNTGET,fntget
	viocsc	_B_CURON,b_curon
	viocsc	_B_CUROFF,b_curoff
	viocsc	_B_PUTC,b_putc
	viocsc	_B_PRINT,b_print
	viocsc	_B_COLOR,b_color
	viocsc	_B_LOCATE,b_locate
	viocsc	_B_DOWN_S,b_down_s
	viocsc	_B_UP_S,b_up_s
	viocsc	_B_UP,b_up
	viocsc	_B_DOWN,b_down
	viocsc	_B_RIGHT,b_right
	viocsc	_B_LEFT,b_left
	viocsc	_B_CLR_ST,b_clr_st
	viocsc	_B_ERA_ST,b_era_st
	viocsc	_B_INS,b_ins
	viocsc	_B_DEL,b_del
	viocsc	_B_CONSOL,b_consol
	viocsc	_B_PUTMES,b_putmes
	viocsc	_B_CONMOD,b_conmod
	viocsc	_SETFNTADR,chr_adr
	viocsc	_OS_CURON,os_curon
	viocsc	_OS_CUROF,os_curof
	viocsc	_TXRASCPY,txrascpy
flagjctrl:				*(/jスイッチが指定されたら-1を書き込む)
	viocsc	_SFTJIS,sftjis
	viocsc	_JISSFT,jissft
	viocsc	_AKCONV,akconv
	.dc	-1

iocsgtbl:
	viocsg	_DRAWMODE,drawmode
	viocsg	_WIPE,wipe
	viocsg	_PSET,pset
	viocsg	_POINT,point
	viocsg	_LINE,line
	viocsg	_BOX,box
	viocsg	_FILL,fill
	viocsg	_CIRCLE,circle
	viocsg	_PAINT,paint
	viocsg	_SYMBOL,symbol
	viocsg	_GETGRM,getgrm
	viocsg	_PUTGRM,putgrm
	viocsg	_TXXLINE,txxline
	viocsg	_TXYLINE,txyline
	viocsg	_TXLINE,txline
	viocsg	_TXBOX,txbox
	viocsg	_TXFILL,txfill
	viocsg	_TXREV,txrev
	.dc	-1

iocsmtbl:
	viocsm	_SETMSADR,ms_vcs
	viocsm	_MS_INIT,ms_init
	viocsm	_MS_CURON,ms_curon
	viocsm	_MS_CUROF,ms_curof
	viocsm	_MS_STAT,ms_stat
	viocsm	_MS_GETDT,ms_getdt
	viocsm	_MS_CURGT,ms_curgt
	viocsm	_MS_CURST,ms_curst
	.dc	-1

*	DOSベクタテーブル

vdosc:	.macro	callno,addr
	.dc	callno.and.$ff,addr-dosctbl
old_&addr::
	.ds.l	1
	.endm

dosctbl:
	vdosc	_PUTCHAR,putchar
	vdosc	_INPOUT,inpout
	vdosc	_PRINT,print
	vdosc	_FPUTC,fputc
 	vdosc	_FPUTS,fputs
	vdosc	_CONCTRL,conctrl
	vdosc	_WRITE,write
	.dc	-1


*****************************************
*	@IOCS	ストラテジルーチン	*
*****************************************

	.cpu	68000
dev_strtgy::
	move.l	a5,(dev_rqhptr)	*リクエストヘッダへのポインタ
	rts
	.cpu	CPU


*****************************************
*	@IOCS	割り込みルーチン	*
*****************************************

*	X68000でhiocs030.xを組み込もうとした場合を考慮すると
*	ここでは68020命令を使ってはいけない。

	.cpu	68000
dev_intrpt::
	movem.l	d0-d7/a0-a6,-(sp)
	movea.l	(dev_rqhptr,pc),a5
	moveq	#0,d0
	move.b	(2,a5),d0		*コマンドコード
	add	d0,d0
	move	(dev_jmptbl,pc,d0.w),d0
	jsr	(dev_jmptbl,pc,d0.w)
	addq.l	#3,a5
	move.b	d0,(a5)+		*エラーコード	 (L)
	move	d0,-(sp)		;lsr	#8,d0
	move.b	(sp)+,(a5)		;move.b	d0,(a5)	*(H)
	movem.l	(sp)+,d0-d7/a0-a6
	rts
	.cpu	CPU

dev_rqhptr:	.ds.l	1		*リクエストヘッダへのポインタ
dev_jmptbl:				*コマンド処理ルーチンのジャンプテーブル
	.dc	dev_init-dev_jmptbl	*初期化
	.dc	dev_err-dev_jmptbl	*エラー
	.dc	dev_err-dev_jmptbl	*未使用
	.dc	dev_iocin-dev_jmptbl	*IOCTRLによる入力
	.dc	dev_in-dev_jmptbl	*入力
	.dc	dev_in-dev_jmptbl	*先読み入力
	.dc	dev_instat-dev_jmptbl	*入力ステータスチェック
	.dc	dev_flush-dev_jmptbl	*入力バッファクリア
	.dc	dev_out-dev_jmptbl	*出力(VERIFY OFF)
	.dc	dev_out-dev_jmptbl	*出力(VERIFY ON)
	.dc	dev_outstat-dev_jmptbl	*出力ステータスチェック
	.dc	dev_err-dev_jmptbl	*未使用
	.dc	dev_iocout-dev_jmptbl	*IOCTRLによる出力

*	エラー

dev_err:
	move	#$5003,d0		*コマンドコードが不正
	rts

*	ステータスチェック

dev_instat:
	moveq	#1,d0
	rts

*	IOCTRL入力

dev_iocin:
	move.l	(18,a5),d0		*転送バイト数
	moveq	#IOCTRLSIZE,d1
	cmp.l	d1,d0
	bls	dev_iocin0		*(バージョンチェックを有効にするため)

	move.l	d1,d0
dev_iocin0:
	movea.l	(14,a5),a0		*転送バッファアドレス
	lea	(IOCTRLDATA,pc),a1
	subq.l	#1,d0
@@:
	move.b	(a1)+,(a0)+		*IOCTRLデータを転送する
	dbra	d0,@b
dev_outstat:
dev_flush:
	moveq	#0,d0
	rts

*	IOCTRL出力

dev_iocout:
	move.l	(18,a5),d0		*転送バイト数
	moveq	#IOCTRLSIZE,d1
	cmp.l	d1,d0
	bne	dev_err

	movea.l	(14,a5),a6		*転送バッファアドレス
	movea.l	a6,a0
	lea	(IOCTRLDATA,pc),a1
	moveq	#16-1,d0
dev_iocout1:
	cmpm.b	(a0)+,(a1)+		*バージョン文字列を比較する
	dbne	d0,dev_iocout1
	bne	dev_err

	lea	(IOVECTFLG-IOCTRLDATA,a6),a0
	lea	(IOVECTFLG,pc),a1
	bsr	restorevect		*IOCS/DOSベクタを元に戻す
	bne	dev_iocout9		*ベクタが変更されている
	bsr	setvect			*IOCS/DOSベクタを変更する

	lea	(EXFONTBUF-IOCTRLDATA,a6),a0
	lea	(EXFONTBUF,pc),a1
	moveq	#(IOCTRLEND-EXFONTBUF)-1,d0
dev_iocout2:
	move.b	(a0)+,(a1)+		*その他のフラグを変更する
	dbra	d0,dev_iocout2

	bsr	setundefchr
	moveq	#0,d0
	move	d0,(IOCTRLERR-IOCTRLDATA,a6)
	rts

dev_iocout9:				*ベクタが変更されている場合
	move	#-1,(IOCTRLERR-IOCTRLDATA,a6)
	moveq	#0,d0
	rts

*	入力

dev_in:
	move.l	(18,a5),d0		*転送バイト数
	subq.l	#7,d0
	bcc	dev_err

	movea.l	(14,a5),a0		*転送バッファアドレス
	move	#-1,(a0)		*(IOCS.Xに対するダミー)
	moveq	#0,d0
	rts

*	出力

dev_out:
	move.l	(18,a5),d2		*転送バイト数
	movea.l	(14,a5),a0		*転送バッファアドレス
	movea.l	(EXFONTBUF,pc),a1
	move.l	a1,d0
	bne	dev_out1		*拡張フォントバッファを使用
	lea	(RAMFONTBUF,pc),a1
dev_out1:
	movea.l	a1,a2
	bsr	lentosize		*転送サイズをチェックする
	bpl	dev_out2

	move.l	#fon_knj16,d1		*フォントを初期化する
	moveq	#9,d2
	bsr	chr_adr
	lea	(fon_ank8),a0
	moveq	#0,d1
	move.l	(fontsize0,pc),d2

dev_out2:
	cmp.b	(FONTBUFSIZE,pc),d1
	bls	dev_out3
	move.b	(FONTBUFSIZE,pc),d1
dev_init91:
	bsr	sizetolen
dev_out3:
	move.l	(a0)+,(a1)+
	subq.l	#4,d2
	bne	dev_out3
	subq.b	#1,d1
	bcs	dev_out10
	beq	dev_out20
	subq.b	#1,d1
	beq	dev_out30

	move.l	(fontsize012,pc),d1
	add.l	a2,d1
	moveq	#15,d2
	bsr	chr_adr			*ＪＩＳ第二水準漢字フォント設定
dev_out30:
	move.l	(fontsize01,pc),d1
	add.l	a2,d1
	moveq	#14,d2
	bsr	chr_adr			*ＪＩＳ第一水準漢字
dev_out20:
	move.l	(fontsize0,pc),d1
	add.l	a2,d1
	moveq	#13,d2
	bsr	chr_adr			*ＪＩＳ非漢字
dev_out10:
	move.l	a2,d1
	moveq	#8,d2
	bsr	chr_adr			*半角文字
	moveq	#0,d0
	rts


*	初期化終了

dev_init9:
	lea	(DATABUF,pc),a0
	lea	(RAMFONTBUF,pc),a1
	movea.l	a1,a2
	bsr	dev_init91		*フォントデータを転送・設定

	move.b	(FONTBUFSIZE,pc),d1
	bsr	sizetolen
	adda.l	d2,a2
	move.l	#'iocs',(a2)+

	tst.b	d6
	bne	dev_init95

	move.l	a2,(14,a5)		*デバイスドライバ終了アドレス
	moveq	#0,d0
	rts
dev_init95:				*コマンドライン登録の場合
	lea	(dev_header,pc),a0
	suba.l	a0,a2
	clr	-(sp)
	move.l	a2,-(sp)
	DOS	_KEEPPR

lentosize:
	move.l	a0,-(sp)
	lea	(fontlentbl,pc),a0
	moveq	#0,d1
	cmpi.l	#FONTSIZE0/2,d2
	beq	lentosize9
lentosize1:
	cmp.l	(a0)+,d2
	bcs	lentosize2
	beq	lentosize9
	addq.b	#1,d1
	bra	lentosize1
lentosize2:
	moveq	#-1,d1
lentosize9:
	movea.l	(sp)+,a0
	rts

sizetolen:
	move.b	d1,d2
	ext	d2
	add	d2,d2
	add	d2,d2
	move.l	(fontlentbl,pc,d2.w),d2
	rts

fontlentbl:
fontsize0:	.dc.l	FONTSIZE0
fontsize01:	.dc.l	FONTSIZE0+FONTSIZE1
fontsize012:	.dc.l	FONTSIZE0+FONTSIZE1+FONTSIZE2
		.dc.l	FONTSIZE0+FONTSIZE1+FONTSIZE2+FONTSIZE3
		.dc.l	-1



*=======================================*
*	非常駐部			*
*=======================================*

RAMFONTBUF:				*ＲＡＭフォントはここから格納される

*	初期化

	.cpu	68000
dev_init:
	PRINT	(title_msg,pc)
.if CPU==68030
	cmpi.b	#2,(MPUTYPE)
	bcs	dev_init_err_mpu
.endif
	.cpu	CPU

	lea	(FLAG_DEV,pc),a0
	st	(a0)
	lea	(dev_jmptbl,pc),a0
	move	#dev_err-dev_jmptbl,(0,a0)

	lea	(IOVECTFLG,pc),a0
	moveq	#VECTFLGSIZE-1,d0
dev_init1:
	st	(a0)+			*全ベクタを変更する(デフォルト)
	dbra	d0,dev_init1

	movea.l	(18,a5),a1		*パラメータポインタ
	bsr	dev_param		*パラメータを解釈する
	bmi	dev_init_err

	move.b	(FLAG_R,pc),d0
	bne	dev_init_err		*デバイスドライバ組み込み時は/rは指定不可

	bsr	mask_spurious		;スプリアス割り込みを無効化
.if CPU==68000
	bsr	rte_patch
.endif
	bsr	rompatch		*IOCS ROM へのパッチ当て
	lea	(patchtbl,pc),a0	*<+03
	.rept	PATCHTBL_SIZE
	clr.l	(a0)+			*(デバイスドライバ組み込みの場合は
	.endm				*	パッチ解除は無効)

	bsr	copyank8		*ＲＯＭフォントをＲＡＭに転送

	lea	(VECTFLG,pc),a0
	lea	(IOVECTFLG,pc),a1
	moveq	#VECTFLGSIZE-1,d0
dev_init2:
	move.b	(a1),(a0)+
	sf	(a1)+
	dbra	d0,dev_init2

	lea	(VECTFLG,pc),a0
	lea	(IOVECTFLG,pc),a1
	bsr	setvect			*ベクタを変更する

	bsr	readfont_dev		*フォントファイルを読み込む
	lea	(FONTBUFSIZE,pc),a0
	move.b	d1,(a0)+
	move.b	d1,(a0)
	move.l	d1,-(sp)
	bsr	setundefchr		*未定義漢字コードを設定する
	move.l	(sp)+,d1

	moveq	#0,d6
	bra	dev_init9

	.cpu	68000
dev_init_err:				*初期化時のエラー
	pea	(paramerr_msg,pc)
	bra	@f
.if CPU==68030
dev_init_err_mpu:
	pea	(mpu_err_msg,pc)
.endif
@@:
	DOS	_PRINT
	addq.l	#4,sp
	move	#$500c,d0
	rts
	.cpu	CPU

*	8×16半角フォントをＲＡＭ上に転送する

copyank8:
	lea	(fon_ank8),a0
	lea	(DATABUF,pc),a1
	move	#FONTSIZE0/4-1,d0
copyank81:
	move.l	(a0)+,(a1)+
	dbra	d0,copyank81
	rts

*	フォントファイルをバッファに読み込む

readfont_dev:
	bsr	readfont_init
	movea.l	(18,a5),a1
	bra	skip_fontname
@@:
	move.l	a1,-(sp)
	bsr	readfont_sub
	movea.l	(sp)+,a1
	bmi	readfont9
skip_fontname:
	tst.b	(a1)+
	bne	skip_fontname
	move.b	(a1),d0
	beq	readfont9
	cmpi.b	#'-',d0
	beq	skip_fontname
	bra	@b

readfont_cmd:
	bsr	readfont_init
	move.l	(dev_header-$100+$20,pc),-(sp)
	addq.l	#1,(sp)
	bsr	GetArgCharInit
	addq.l	#4,sp
	bra	@f
skip_option:
	bsr	GetArgChar
	tst.b	d0
	bne	skip_option
@@:
	bsr	GetArgChar
	tst.l	d0
	beq	readfont9
	bmi	@b
	cmpi.b	#'-',d0
	beq	skip_option
	cmpi.b	#'+',d0
	beq	skip_option

	lea	(filename_buf,pc),a1
	move.b	d0,(a1)+
1:	bsr	GetArgChar
	move.b	d0,(a1)+		;ファイル名を転送する
	bne	1b

	lea	(filename_buf,pc),a1
	bsr	readfont_sub
	bpl	@b
readfont9:
	tst.l	d4
	rts

readfont_sub:
	movem.l	d1-d2,-(sp)
	clr	-(sp)
	move.l	a1,-(sp)
	DOS	_OPEN			*フォントファイルをオープンする
	addq.l	#6,sp
	move.l	d0,d3
	bmi	readfont81		*ファイルがオープンできなかった

	move	#2,-(sp)
	clr.l	-(sp)
	move	d3,-(sp)
	DOS	_SEEK			*ファイルサイズを得る
	addq.l	#8,sp

	move.l	d0,d2
	bsr	lentosize
	tst.b	d1
	bmi	readfont80		*ファイルサイズが不正

	move.b	(FLAG_DEV,pc),d0
	bne	readfont1		*(デバイスドライバ組み込みの場合)

 	lea	(DATABUF,pc),a0
 	adda.l	d2,a0
 	cmpa.l	(dev_header-$100+8,pc),a0
	bcc	nomemerr		*メモリが不足している
readfont1:
	clr	-(sp)
	clr.l	-(sp)
	move	d3,-(sp)
	DOS	_SEEK			*ファイル先頭へ移動する
	addq.l	#8,sp

	move.l	d2,-(sp)
	pea	(DATABUF,pc)
	move	d3,-(sp)
	DOS	_READ			*ファイルを読み込む
*	lea	(10,sp),sp
*	tst.l	d0
	addq.l	#10-4,sp
	move.l	d0,(sp)+
	bmi	readfont80		*ファイルが読み込めなかった

	move	d3,-(sp)
	DOS	_CLOSE			*ファイルをクローズする
*	addq.l	#2,sp

	pea	(fontchg_msg,pc)
	DOS	_PRINT
	addq.l	#2+4,sp

	cmp.l	(sp),d1
	bcc	@f

	movem.l	(sp),d1-d2
@@:
	addq.l	#8,sp
	moveq	#0,d4
	rts

readfont81:				*フォントファイルのエラー	<+03
	pea	(nofont_msg,pc)
	bra	readfont82
readfont80:
	move	d3,-(sp)
	DOS	_CLOSE			*ファイルをクローズする
	addq.l	#2,sp
	pea	(badfont_msg,pc)
readfont82:
	DOS	_PRINT
	lea	(8+4,sp),sp
	bsr	copyank8		*ＲＯＭフォントに戻す
readfont_init:
	moveq	#0,d1
	move.l	(fontsize0,pc),d2
	moveq	#-1,d4
	rts


*************************************************
*	コマンドラインによる起動		*
*************************************************

	.cpu	68000
cmd_exec:
	bra.s	@f
	.dc.b	'#HUPAIR',0
@@:
	movea.l	(8,a0),sp		*メモリブロック終了アドレス＋１をスタックにする
	clr.l	-(sp)
	DOS	_SUPER			*スーパーバイザモードに入る
	addq.l	#4,sp

	PRINT	(title_msg_2,pc)
.if CPU==68030
	cmpi.b	#2,(MPUTYPE)
	bcs	mpuerr
.endif
	.cpu	CPU

	lea	(16,a0),a5		*プログラムの先頭アドレス
	lea	(dev_jmptbl,pc),a0
	move	#dev_err-dev_jmptbl,(a0)

	pea	(DATABUF,pc)
	move	#-2,-(sp)
	DOS	_GET_PR			*自分自身のスレッドの情報を得る
	addq.l	#6,sp
	tst.l	d0
	ble	cmd_exec1		*スレッド０かエラーの場合

	pea	(bgerr_msg,pc)
	bra	errout			*ＢＧでの実行は不可能
cmd_exec1:
	clr	-(sp)			*<+08(Human v1.0xのバグ回避)
	pea	(iocsname,pc)
	DOS	_OPEN			*'@IOCS'をオープン
	addq.l	#6,sp
	move.l	d0,d7
	bmi	cmd_exec50		*オープンできない…未登録の場合

	move	d7,-(sp)
	clr	-(sp)
	DOS	_IOCTRL			*'@IOCS'の装置情報を得る
	addq.l	#4,sp
	move	d0,d1			*	<+08

	move	d7,-(sp)
	DOS	_CLOSE			*'@IOCS'をクローズする
	addq.l	#2,sp
	moveq	#-1,d7			*(ファイルディスクリプタを無効にする)

	andi	#$c03f,d1
	cmpi	#$c020,d1		*(ｷｬﾗｸﾀﾃﾞﾊﾞｲｽ/IOCTRL可/RAW MODE)
	bne	cmd_exec50		*装置情報が違う(IOCS.Xが登録済みの場合)

	move	#1,-(sp)		*今度は書き込みオープン
	pea	(iocsname,pc)
	DOS	_OPEN			*'@IOCS'を再度オープン
	addq.l	#6,sp
	move.l	d0,d7
	bmi	cmd_exec50		*必ずオープンできるはずだが念のため

	pea	(IOCTRLSIZE).w
 	lea	(IOCTRLDATA,pc),a0	*	<+06
 	clr.l	(a0)
 	pea	(a0)
	move	d7,-(sp)
	move	#2,-(sp)
	DOS	_IOCTRL			*現在のHIOCSパラメータを得る
	lea	(12,sp),sp

	lea	(IOCTRLDATA,pc),a0
	lea	(checkstr,pc),a1
	moveq	#16/4-1,d0
cmd_exec2:
	cmpm.l	(a0)+,(a1)+		*バージョンチェック用文字列を比較する
	dbne	d0,cmd_exec2
	bne	vererr

	move.b	(IOVECTFLG+~IOCSGRFLG,pc),d0
	bne	cmd_exec4

*(デバイスドライバ解除状態から復帰する場合)
	lea	(IOVECTFLG,pc),a0
	moveq	#VECTFLGSIZE-1,d0
cmd_exec3:
	st	(a0)+
	dbra	d0,cmd_exec3
cmd_exec4:
	bsr	cmd_param		*パラメータの解釈
	bne	usage			*コマンドラインに誤りがある

	move.b	(FLAG_M,pc),d0
	bne	alrromerr		*-mスイッチがある	<+03
	move.b	(FLAG_R,pc),d0
	bne	cmd_rels		*-rスイッチがある

	bsr	ioctrl_write		*HIOCSパラメータを設定する
	move.b	(FLAG_F,pc),d0
	beq	@f

	move	(IOCTRLERR,pc),d0
	bne	cmd_exec5		;ベクタが変更されている
	PRINT	(initfont_msg,pc)
	bsr	freeexbuf		;-f フォントの初期化
@@:
	bsr	readfont_cmd
	bmi	cmd_exec5
	cmp.b	(FONTBUFSIZE,pc),d1
	bhi	cmd_exec26

	move.l	d2,-(sp)		*フォントバッファサイズが足りる場合
	pea	(DATABUF,pc)
	move	d7,-(sp)
	DOS	_WRITE
	lea	(10,sp),sp
cmd_exec5:
	move	(IOCTRLERR,pc),d0
	bne	vecterr			*ベクタが変更されている
	bra	exit

* 既に常駐している状態でフォントバッファが足りない場合、プログラムの先頭に
* フォント指定ルーチンを移動し、その直後にフォントを読み込んで常駐終了する.

cmd_exec26:
	bsr	freeexbuf
	lea	(dev_header,pc),a1
	lea	(ex_fontset9-ex_fontset,a1),a1
	move.l	a1,(a0)+
	move.b	d1,(a0)

	bsr	ioctrl_write		*HIOCSパラメータを設定する

	lea	(ex_fontset,pc),a0
	lea	(dev_header,pc),a1
	move	#(ex_fontset9-ex_fontset+3)/4-1,d0
cmd_exec23:
	move.l	(a0)+,(a1)+
	dbra	d0,cmd_exec23
	bsr	clear_mpu_cache

	lea	(DATABUF,pc),a0
	lea	(dev_header,pc),a1
	jmp	(ex_fontset1-ex_fontset,a1)

ioctrl_write:
	pea	(IOCTRLSIZE).w
	pea	(IOCTRLDATA,pc)
	move	d7,-(sp)
	move	#3,-(sp)
	DOS	_IOCTRL			*HIOCSパラメータを設定する
	lea	(12,sp),sp
	rts

*	拡張フォントバッファがあれば開放する

freeexbuf:
	lea	(FONTBUFSIZE+1,pc),a0
	move.b	(a0),-(a0)
	move.l	-(a0),d0		*拡張フォントバッファ先頭アドレス
	beq	freeexbuf9

	clr.l	(a0)
	subi.l	#$f0+ex_fontset9-ex_fontset,d0
	move.l	d0,-(sp)
	DOS	_MFREE			*拡張フォントバッファを開放する
*	addq.l	#4,sp
*	tst.l	d0
	move.l	d0,(sp)+
	bmi	relserr			*メモリが開放できなかった

	bsr	ioctrl_write
freeexbuf9:
	pea	(1)			*<+02
	pea	(DATABUF,pc)
	move	d7,-(sp)
	DOS	_WRITE			*@IOCSにダミーデータ(1byte)を送る
	lea	(10,sp),sp
	rts


*	拡張フォントバッファ設定ルーチン

ex_fontset:
	.dc.b	'HIOCS external font buffer'
	.even
ex_fontset1:
	move.l	d2,-(sp)
	lea	(ex_fontset9,pc),a1
	move.l	a1,-(sp)
ex_fontset2:
	move.l	(a0)+,(a1)+
	subq.l	#4,d2
	bne	ex_fontset2

*	move.l	d2,-(sp)
*	pea	(ex_fontset9,pc)
	move	d7,-(sp)
	DOS	_WRITE			*フォントを設定する
	DOS	_CLOSE			*'@IOCS'をクローズする
	lea	(10,sp),sp

	lea	(dev_header,pc),a0
	suba.l	a0,a1
	clr	-(sp)			*終了コード
	move.l	a1,-(sp)		*常駐部サイズ
	DOS	_KEEPPR			*常駐終了する
	.quad
ex_fontset9:



*	-rスイッチ(常駐解除)

cmd_rels:
	lea	(IOVECTFLG,pc),a0
	moveq	#VECTFLGSIZE-1,d0
cmd_rels1:
	sf	(a0)+			*全ベクタを復帰する
	dbra	d0,cmd_rels1

	move.l	(TOPADR,pc),d0
	beq	cmd_rels4		*デバイスドライバ登録の場合
	movea.l	d0,a0
	lea	(patchtbl-dev_header+$f0,a0),a1
	tst.l	(a1)+			*ROMパッチのベクタが変更されているか調べる
	beq	cmd_rels2

	lea	(gpalet-dev_header+$f0,a0),a2
	cmpa.l	(_GPALET*4+$400),a2
	bne	vecterr
cmd_rels2:
	tst.l	(a1)+
	beq	cmd_rels3

	lea	(dmamove-dev_header+$f0,a0),a2
	cmpa.l	(_DMAMOVE*4+$400),a2
	bne	vecterr
cmd_rels3:
	tst.l	(a1)+
	beq	cmd_rels4

	lea	(ms_patst-dev_header+$f0,a0),a2
	cmpa.l	(_MS_PATST*4+$400),a2
	bne	vecterr
cmd_rels4:
	bsr	ioctrl_write		*HIOCSパラメータを設定する

	move	(IOCTRLERR,pc),d0
	bne	vecterr			*ベクタが変更されている
	bsr	freeexbuf		*拡張フォントバッファを開放する

	move.l	(TOPADR,pc),d0
	beq	rels_exit		*デバイスドライバ登録の場合
	movea.l	d0,a0

	lea	(patchtbl-dev_header+$f0,a0),a1
	move.l	(a1)+,d1		*ROMパッチのベクタを元に戻す	<+03
	beq	cmd_rels5

	move.l	d1,(_GPALET*4+$400)
cmd_rels5:
	move.l	(a1)+,d1
	beq	cmd_rels6

	move.l	d1,(_DMAMOVE*4+$400)
cmd_rels6:
	move.l	(a1)+,d1
	beq	cmd_rels7

	move.l	d1,(_MS_PATST*4+$400)
cmd_rels7:
	movea.l	(LINKPTR-dev_header+$f0,a0),a1	*前のリンクポインタ
	move.l	($f0,a0),(a1)		*'@IOCS'をデバイスドライバリンクから外す
	move.l	d0,-(sp)
	DOS	_MFREE
*	addq.l	#4,sp
*	tst.l	d0
	move.l	d0,(sp)+
	bmi	relserr			*常駐部が開放できなかった
	bra	rels_exit


*	HIOCS.Xが組み込まれていない場合

cmd_exec50:
	lea	(IOVECTFLG,pc),a0
	moveq	#VECTFLGSIZE-1,d0
cmd_exec51:
	st	(a0)+			*全ベクタを変更する(デフォルト)
	dbra	d0,cmd_exec51

	bsr	mask_spurious		;スプリアス割り込みを無効化
.if CPU==68000
	bsr	rte_patch
.endif
	bsr	cmd_param		*パラメータの解釈
	bne	usage			*コマンドラインに誤りがある

	move.b	(FLAG_R,pc),d0
	bne	nostayerr		*-rスイッチがある
	move.b	(FLAG_M,pc),d0
	bne	cmd_patch		*-mスイッチがある

	bsr	copyank8		*ＲＯＭフォントをＲＡＭに転送
	bsr	readfont_cmd		*フォントファイルを読み込む
	lea	(FONTBUFSIZE,pc),a0
	move.b	d1,(a0)+
	move.b	d1,(a0)

	move.l	d1,-(sp)
	lea	(TOPADR,pc),a1
	move.l	a5,(a1)
	bsr	sealink			*リンクポインタの終端を探す
	lea	LINKPTR(pc),a2
	lea	(dev_header,pc),a0
	move.l	a1,(a2)
	move.l	a0,(a1)			*リンクポインタをつなぐ

	bsr	rompatch		*IOCS ROM へのパッチ当て
	lea	(VECTFLG,pc),a0
	lea	(IOVECTFLG,pc),a1
	moveq	#VECTFLGSIZE-1,d0
cmd_exec52:
	move.b	(a1),(a0)+
	sf	(a1)+
	dbra	d0,cmd_exec52

	lea	(VECTFLG,pc),a0
	lea	(IOVECTFLG,pc),a1
	bsr	setvect			*ベクタを変更する
	bsr	setundefchr		*未定義漢字コードを設定する

	move.l	(sp)+,d1
	moveq	#-1,d6
	bra	dev_init9
relserr:				*メモリが開放できなかった
	PRINT	(relserr_msg,pc)	*(メモリ管理ポインタの異常)
relserr1:
	bra	relserr1

vererr:					*常駐部とバージョンが違う
	pea	(vererr_msg,pc)
	bra	errout

nomemerr:				*フォントファイル読み込み用メモリが不足
	pea	(nomem_msg,pc)
	bra	errout

nostayerr:				*常駐していない
	pea	(nostay_msg,pc)
	bra	errout

vecterr:				*ベクタが変更されている
	pea	(vecterr_msg,pc)
	bra	errout
.if CPU==68030
mpuerr:
	pea	(mpu_err_msg,pc)
	bra	errout
.endif

usage:					*使用法を表示して終了
	bpl	@f
	PRINT	(paramerr_msg,pc)
@@:
	pea	(usage_msg,pc)
errout:					*エラーを出力して終了する
	DOS	_PRINT
	addq.l	#4,sp

	bsr	close_iocs
	move	#-1,-(sp)
	DOS	_EXIT2

rels_exit:
	PRINT	(rels_msg,pc)
exit:
	bsr	close_iocs
	DOS	_EXIT

close_iocs:
	move	d7,-(sp)
	bmi	@f
	DOS	_CLOSE			*'@IOCS'がオープンされていたらクローズする
@@:
	addq.l	#2,sp
	rts

*	NULデバイスを検索し、リンクポインタの終端を探す

sealink::
	lea	($6800),a1
sealink1:
	cmpi	#'NU',(a1)+		*Human中から'NUL     'を探し出す
	bne	sealink1
	cmpi.l	#'L   ',(a1)
	bne	sealink1
	cmpi	#'  ',(4,a1)
	bne	sealink1
	lea	(-16,a1),a1		*NULデバイスのリンクポインタ
sealink2:
	movea.l	(a1),a1			*リンクポインタを１つたどる
	tst.l	(a1)
	bpl	sealink2
	rts


*	-mスイッチの処理

cmd_patch:				*<+03
	bsr	rompatch1		*IOCS ROMへのパッチ当て
	tst.l	d0
	bne	alrromerr		*すでにパッチ済み

	PRINT	(rompat_msg,pc)
	clr	-(sp)
	pea	(patchend-dev_header).w
	DOS	_KEEPPR			*常駐終了する
alrromerr:
	pea	(alrrom_msg,pc)
	bra	errout

* 68000 なら move (sp)+,sr / rts を rte 一命令にする
.if CPU==68000
rte_patch:
	tst.b	(MPUTYPE)
	bne	rte_patch_skip		;68000 以外ならそのまま

	move	#RTE,d0
	lea	(os_curon_rte,pc),a0
	move	d0,(a0)
	move	d0, (mscdraw_rte-os_curon_rte,a0)
	move	d0,(mscerase_rte-os_curon_rte,a0)
	move	d0, (txyline_rte-os_curon_rte,a0)
	move	d0,  (txline_rte-os_curon_rte,a0)
* キャッシュフラッシュは不要.
rte_patch_skip:
	rts
.endif


*	ＩＯＣＳ　ＲＯＭのパッチ当てを行なう

rompatch:				*<+03
	moveq	#0,d1
	moveq	#6,d2
	IOCS	_FNTADR
	lea	(FONTANK6,pc),a0
	move.l	d0,(a0)			*6×12半角フォントアドレス

	IOCS	_ROMVER
	rol.l	#8,d0
	cmpi.b	#$10,d0
	bne	rompatch0		*v1.1ROM以降の場合
	lea	(msdpatchtbl,pc),a0	*マウスカーソル表示処理を変更する
	lea	(mscdrawA,pc),a1
	bsr	mspatch
	lea	(msepatchtbl,pc),a0	*	       消去処理を変更する
	lea	(msceraseA,pc),a1
	bsr	mspatch
rompatch0:
rompatch1:				*/mスイッチ
	lea	(patchbegin+$8000,pc),a1	*パッチルーチンのアドレス
	lea	(-$8000,a1),a1		;姑息な...
	movea.l	a1,a2
	movea.l	(_GPALET*4+$400),a0
	lea	(patchbegin-gpalet,a0),a0
rompatch2:
	move.b	(a2)+,d0
	cmp.b	(a0)+,d0
	bne	rompatch3
	tst.b	d0
	bne	rompatch2
	moveq	#1,d0			*すでにパッチ済み
	rts
rompatch3:
	lea	(patchtbl,pc),a0
	move.l	(_GPALET*4+$400),(a0)+
	lea	(gpalet-patchbegin,a1),a2
	move.l	a2,(_GPALET*4+$400)
	IOCS	_ROMVER
	rol.l	#8,d0
	cmpi.b	#$10,d0
	bne	rompatch4		*v1.0 ROMではない

	move.l	(_DMAMOVE*4+$400),(a0)
	lea	(dmamove-patchbegin,a1),a2
	move.l	a2,(_DMAMOVE*4+$400)
rompatch4:
	addq.l	#4,a0
	IOCS	_ROMVER
	cmpi.l	#$11910111,d0
	bne	rompatch5		*v1.1 ROMではない

	move.l	(_MS_PATST*4+$400),(a0)
	lea	(ms_patst-patchbegin,a1),a2
	move.l	a2,(_MS_PATST*4+$400)
rompatch5:
	moveq	#0,d0			*アドレス変更を行なった
	rts


mspatch:				*マウスカーソル表示/消去処理を変更する
	movea.l	a0,a2
mspatch1:
	move	(a2)+,d0
	beq	mspatch9
	lea	(2,a0,d0.w),a3		*bsr.wのディスプレースメントアドレス
	move.l	a1,d0
	sub.l	a3,d0			*ディスプレースメントを計算する
	move	d0,(a3)
	bra	mspatch1
mspatch9:
	bra	clear_mpu_cache
**	rts

msdpatchtbl:				*マウスカーソル表示処理を呼び出すアドレス
	.dc	msdpatch1-msdpatchtbl
	.dc	msdpatch2-msdpatchtbl
	.dc	0
msepatchtbl:				*マウスカーソル消去処理を呼び出すアドレス
	.dc	msepatch1-msepatchtbl
	.dc	msepatch2-msepatchtbl
	.dc	0


*	スプリアス割り込みの無効化

mask_spurious:
	movem.l	d0/a0,-(sp)
	move	#RTE,d0
	movea.l	(SPURIVEC),a0
	cmp	(a0),d0
	beq	mask_spurious_end	;既に rte になっていたらそのまま
	lea	($ff0000),a0
@@:	cmp	(a0)+,d0		;ROM から rte を探す
	bne	@b
	subq.l	#2,a0
	move.l	a0,(SPURIVEC)		;rte のアドレスを設定
mask_spurious_end:
	movem.l	(sp)+,d0/a0
	rts


*	パラメータの解釈

cmd_param:				*コマンドラインからパラメータリストを作る
	pea	(1,a2)
	bsr	GetArgCharInit
	addq.l	#4,sp
	bra	@f
dev_param:				*デバイスドライバパラメータ解釈
	tst.b	(a1)+
	bne	dev_param
	lea	(ArgPtr,pc),a0
	move.l	a1,(a0)
	st	(a0)
@@:
param1:
	bsr	GetArgChar
	tst.l	d0
	beq	param9
	bmi	param1			;""

	moveq	#-1,d3			*-[スイッチ]
	cmpi.b	#'-',d0
	beq	param2
	moveq	#0,d3			*+[スイッチ] …機能指定を反転させる
	cmpi.b	#'+',d0
	beq	param2

	moveq	#90-2,d1
@@:
	bsr	GetArgChar
	tst.b	d0
	dbeq	d1,@b
	beq	param1
	bra	param8			;ファイル名が長すぎる
param2:
	bsr	GetArgChar
	tst.b	d0
	beq	param8			;-/+のみ
next_option:
	tst.b	d0
	beq	param1
	cmpi.b	#'?',d0
	beq	param_h
	ori.b	#$20,d0
	lea	(param_table-2,pc),a0
@@:
	addq.l	#2,a0
	move	(a0)+,d1
	beq	param8
	cmp.b	d0,d1
	bne	@b
	adda	(a0),a0
	jmp	(a0)
param8:
	moveq	#-1,d0			*パラメータの指定に誤りがある
	rts

param_table:
	.irpc	%a,cdefghjlmrsuv
	.dc	'&%a',param_%a-$
	.endm
	.dc	0

param_h:
	moveq	#1,d0			*使用法表示
param9:
	rts				;d0.l=0

param_d:				*-d[0/1]
	lea	(IOVECTFLG+~DOSCONFLG,pc),a0
	move.b	d3,(a0)
	not.b	(a0)
	bra	paramsw1

param_m:				*-m
	bsr	GetArgChar
	cmpi.b	#'s',d0
	beq	param_ms
	cmpi.b	#'S',d0
	beq	param_ms
	cmpi.b	#'h',d0
	beq	param_mh
	cmpi.b	#'H',d0
	beq	param_mh

	lea	(FLAG_M,pc),a0
	st	(a0)
	bra	next_option

param_ms:				*-ms[0/1]	<+08
	lea	(IOVECTFLG+~IOCSMSFLG,pc),a0
	bsr	GetArgChar
	cmpi.b	#'0',d0
	bcs	param_ms2
	beq	param_ms0
	cmpi.b	#'4',d0
	bhi	param_ms2

	moveq	#'5',d1			;-ms1～-ms4 マウスカーソル移動速度の指定
	sub	d0,d1
	bsr	GetArgChar
param_ms1:
	st	(a0)
	lea	(MSSPEED,pc),a0
	move	d1,(a0)			;1～4 → 4～1
	bra	next_option
param_ms2:
	moveq	#3,d1
	tst.b	d3
	bne	param_ms1		;-ms = -ms2

	st	(a0)			;+ms フックのみ
	bra	next_option
param_ms0:
	sf	(a0)			;-ms0 ROMに戻す
	bra	paramsw9

param_mh:				;-mh[0/1]
	moveq	#$1f,d2			;5MHz
	bsr	check_param01
	beq	@f
	moveq	#$2f,d2			;7.5MHz
@@:
	move	sr,-(sp)
	ori	#$700,sr
	lea	(_SCCCMD_B),a0
	tst.b	(a0)			;空読み
	moveq	#14,d1
	move.b	d1,(a0)
	move.b	#%000_0001_0,(a0)	;ボーレートジェネレータ停止

	move.b	#12,(a0)
	move.b	d2,(a0)			;tc(下位)
	lsr	#8,d2
	move.b	#13,(a0)
	move.b	d2,(a0)			;tc(上位)

	move.b	d1,(a0)
	move.b	#%000_0001_1,(a0)	;ボーレートジェネレータ動作
	move	(sp)+,sr
	bra	next_option


* -x -x1 +x0	d1.b = -1
* +x -x0 +x1	d1.b =  0
check_param01:
	move.b	d3,d1
	bsr	GetArgChar
	cmpi.b	#'1',d0
	beq	@f			;-x=-x1、+x=+x1
	cmpi.b	#'0',d0
	bne	9f
	not.b	d1			;-x0=+x、+x0=-x
@@:	bsr	GetArgChar
9:	tst.b	d1
	rts


param_g:				*-g[0/1]
	bsr	check_param01
	lea	(IOVECTFLG+~IOCSCONFLG,pc),a0
	move.b	d1,(a0)			;IOCSCONFLG
	addq.l	#~DOSCONFLG-~IOCSCONFLG,a0
	move.b	d1,(a0)+		;DOSCONFLG
	move.b	d1,(a0)			;IOCSMSFLG
	bra	next_option

param_r:				*-r
	lea	(FLAG_R,pc),a0
	bra	paramset
param_f:				*-f
	lea	(FLAG_F,pc),a0
	bra	paramset
paramset:
	st	(a0)
paramsw9:
	bsr	GetArgChar
	bra	next_option

param_j:				*-j
	lea	(flagjctrl,pc),a0
	move	#-1,(a0)
	bra	paramsw9

param_e:
	lea	(CONESCFLG,pc),a0
	bra	paramsw
param_l:
	lea	(USRKNJ2FLG,pc),a0
	bra	paramsw
param_s:
	lea	(CHRSELFLG,pc),a0
	bra	paramsw
param_v:
	lea	(VBELLFLG,pc),a0
	bra	paramsw
paramsw:
	move.b	d3,(a0)
paramsw1:
	bsr	GetArgChar
paramsw2:
	cmpi.b	#'1',d0
	beq	paramsw9
	cmpi.b	#'0',d0
	bne	next_option

	not.b	(a0)
	bra	paramsw9

param_u:				*-u[0/1/2]	<+07
	lea	(USRKNJFLG,pc),a0
	move.b	d3,(a0)
	bsr	GetArgChar
	cmpi.b	#'2',d0
	bne	paramsw2

	move.b	#1,(a0)			;-u2
	bra	paramsw9

param_c:
	lea	(UNDEFFLG,pc),a0
	lea	(UNDEFPAT,pc),a2
	bsr	GetArgChar
	tst.b	d0
	spl	(a0)
	beq	param_c2
	bpl	param_c1

	lea	(UNDEFCHR,pc),a0	;-c字
	move.b	d0,(a0)+
	bsr	GetArgChar
	move.b	d0,(a0)+
	beq	param1
	bra	paramsw9
param_c1:				*-c[pattern..]
	moveq	#32-1,d2
@@:
	bsr	gethex
	bmi	next_option

	move.b	d1,(a2)+
	dbra	d2,param_c1
	st	(a0)
	bra	paramsw9
param_c2:
	move.l	#$aaaa_5555,d0		;-c メッシュ
	moveq	#8-1,d1
param_c3:
	move.l	d0,(a2)+
	dbra	d1,param_c3
	bra	param1

gethex:
	bsr	getahex
	bmi	@f
	move.b	d0,d1
	lsl.b	#4,d1
	bsr	getahex
	bmi	@f
	or.b	d0,d1
	moveq	#0,d0
@@:
	rts
getahex:
	bsr	GetArgChar
	cmpi.b	#'0',d0
	bcs	getahex9
	cmpi.b	#'9',d0
	bls	getahex1		;0-9

	cmpi.b	#'_',d0
	beq	getahex

	cmpi.b	#'A',d0
	bcs	getahex9
	cmpi.b	#'F',d0
	bls	getahex2

	cmpi.b	#'a',d0
	bcs	getahex9
	cmpi.b	#'f',d0
	bhi	getahex9

	andi.b	#$df,d0
getahex2:
	subq.b	#'A'-('9'+1),d0		;a-fA-F
getahex1:
	sub.b	#'0',d0
	rts
getahex9:
	moveq	#-1,d1
	rts

* HUPAIRデコード ------------------------------ *

GetArgChar:
	movem.l	d1/a0-a1,-(sp)
	moveq	#0,d0
	lea	(ArgPtr,pc),a0
	movea.l	(a0),a1
	move.b	(a0),d1
	bpl	GetArgChar_next

	move.b	(a1)+,d0
	bne	GetArgChar_end
	tst.b	(a1)
	bne	GetArgChar_abort2
	subq.l	#1,a1
	bra	GetArgChar_end
GetArgChar_next:
	move.b	(a1)+,d0
	beq	GetArgChar_abort
	tst.b	d1
	bne	GetArgChar_inquate
	cmpi.b	#' ',d0
	beq	GetArgChar_separate
	cmpi.b	#"'",d0
	beq	GetArgChar_quate
	cmpi.b	#'"',d0
	bne	GetArgChar_end
GetArgChar_quate:
	move.b	d0,d1
	bra	GetArgChar_next
GetArgChar_end:
	move.l	a1,(a0)
	move.b	d1,(a0)
GetArgChar_abort:
	movem.l	(sp)+,d1/a0-a1
	rts
GetArgChar_inquate:
	cmp.b	d0,d1
	bne	GetArgChar_end
	clr.b	d1
	bra	GetArgChar_next
GetArgChar_separate:
	cmp.b	(a1)+,d0
	beq	GetArgChar_separate
	subq.l	#1,a1
GetArgChar_abort2:
	moveq	#1,d0
	ror.l	#1,d0
	bra	GetArgChar_end

GetArgCharInit:
	movem.l	a0-a1,-(sp)
	movea.l	(12,sp),a1
GetArgCharInit_skip:
	cmpi.b	#' ',(a1)+
	beq	GetArgCharInit_skip
	subq.l	#1,a1
	lea	(ArgPtr,pc),a0
	move.l	a1,(a0)
	movem.l	(sp)+,a0-a1
	rts

* Data Section -------------------------------- *
*	メッセージデータ

	.data
iocsname:	.dc.b	'@IOCS',0

title_msg:	.dc.b	CR,LF
title_msg_2:	.dc.b	program
.if CPU==68030
		.dc.b	' for X68030'
.endif
		.dc.b	' version 1.10+',version,' (C)1990-95 SHARP / Y.Nakamura, ',date,' TcbnErik.'
crlf_msg:	.dc.b	CR,LF,0

paramerr_msg:	.dc.b	'オプション指定に間違いがあります.',CR,LF,0

.if CPU==68030
mpu_err_msg:	.dc.b	'この MPU では使用できません.',CR,LF,0
.endif

usage_msg:	.dc.b	'usage : hiocs [option] [fontfile]',CR,LF
		.dc.b	'	-c[chr]	二バイト文字未定義コードのフォント指定.',CR,LF
		.dc.b	'	-d	DOSコンソール出力を速くしない.',CR,LF
		.dc.b	'	-e	ESC 0-3を無効にする.',CR,LF
		.dc.b	'	-f	フォントを初期化する.',CR,LF
		.dc.b	'	-g	グラフィック描画のみ速くする.',CR,LF
		.dc.b	'	-j	二バイト文字未定義コードをサポートしない.',CR,LF
		.dc.b	'	-l[n]	JISコード$7621～$7e7eのフォントモード指定(n:0～1).',CR,LF
		.dc.b	'	-m	ROMの修正のみ行う.',CR,LF
		.dc.b	'	-ms[n]	マウスカーソルの移動速度指定(n:1～4 標準は2).',CR,LF
		.dc.b	'	-mh	SCCクロック7.5MHzモードにする.',CR,LF
		.dc.b	'	-s	半角文字(\,~,|)のスイッチ指定を無視する.',CR,LF
		.dc.b	'	-u[n]	JISコード$2921～$2f7eのフォントモード指定(n:0～2).',CR,LF
		.dc.b	'	-v	ビープ音をビジュアルベルにする.',CR,LF
		.dc.b	'	-r	組み込み解除.',CR,LF
		.dc.b	0

fontchg_msg:	.dc.b	'ユーザーフォントデータに切り替えます.',CR,LF,0

nofont_msg:	.dc.b	'フォントファイルが見つかりません.',CR,LF,0

badfont_msg:	.dc.b	'フォントファイルが異常です.',CR,LF,0

initfont_msg:	.dc.b	'フォントデータを初期化します.',CR,LF,0

bgerr_msg:	.dc.b	'バックグランドプロセスでの処理はできません.',CR,LF,0

vererr_msg:	.dc.b	'HIOCSの常駐部とバージョンが違います.',CR,LF,0

vecterr_msg:	.dc.b	'ベクタが書き換えられています.',CR,LF,0

rels_msg:	.dc.b	'IOCSを元に戻しました.',CR,LF,0

nostay_msg:	.dc.b	'HIOCSは組み込まれていません.',CR,LF,0

nomem_msg:	.dc.b	'メモリ容量が不足しています.',CR,LF,0

relserr_msg:	.dc.b	'メモリ管理情報が破壊されています！ リセットしてください.'
		.dc.b	$1b,'[>5l',0

alrrom_msg:	.dc.b	'すでにベクタが書き換えられています.',CR,LF,0

rompat_msg:	.dc.b	'IOCS ROMにパッチ当てを行ないました.',CR,LF,0

* Block Storage Section -------------- *

	.bss
	.even

ArgPtr:		.ds.l	1

*	起動時のスイッチ指定フラグ

FLAG_R:		.ds.b	1		*/r  常駐解除
FLAG_M:		.ds.b	1		*/m  v1.1 IOCS _MS_PATSTのバグパッチ
FLAG_F:		.ds.b	1		*/f  フォントファイル指定
FLAG_DEV:	.ds.b	1		*デバイスドライバ起動フラグ

VECTFLG:	.ds.b	VECTFLGSIZE

	.even
filename_buf:	.ds.b	90
DATABUF:	.ds.b	$1000		*雑用データバッファ


	.end	cmd_exec
