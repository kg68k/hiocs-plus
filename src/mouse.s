	.title	HIOCS PLUS (mouse.s)

*****************************************************************
*	HIOCS version 1.10
*		< MOUSE.HAS >
*	$Id: MOUSE.HA_ 1.7 92/11/18 00:12:10 YuNK Exp $
*
*		Copyright 1990,91,92  SHARP / Y.Nakamura
*****************************************************************


* Global Symbols --------------------- *

	.xref	MSSPEED
	.xref	old_ms_init

* Include Files ---------------------- *

	.include	hiocs.equ

* Text Section ----------------------- *

	.text

*************************************************
*	マウスデータ送信要求処理ルーチン(10ms)	*
*************************************************

*	本体側マウスに送信要求を出す

msctrlsetA::
	subq.b	#1,MSCTRLFLG.w
	bcs	msctrlsetA5		*マウスからデータが来た→送信要求を下ろす
	bpl	msctrlsetA7		*データが来ていないのでしばらく待つ
					*送信要求を出す
	tst.b	MSJOBFLG.w
	bmi	msctrlsetA1		*(b7=1)前回の受信データをまだ処理中
	move.l	a0,-(sp)
	move	#3,MSRCVCNT.w		*受信カウンタ初期化
	move.l	#MSRCVBUF,MSRCVPTR.w	*受信バッファポインタ初期化
	lea	_SCCDATA_B,a0
	tst.b	(a0)			*(ゴミデータがバッファに残っていたらキャンセル)
	tst.b	(a0)
	tst.b	(a0)
	tst.b	(a0)
	move.b	#$05,(_SCCCMD_B-_SCCDATA_B,a0)	*WR5
	move.b	#$62,(_SCCCMD_B-_SCCDATA_B,a0)	*RTS=L(本体側マウス送信要求)
	move.l	(sp)+,a0
	move.b	#$04,MSCTRLFLG.w	*次に送信要求を下ろすことにする
	rts				*(データが来ない場合は割り込み４回分まで待つ)

msctrlsetA5:				*送信要求を下ろす
	move.b	#$05,_SCCCMD_B		*WR5
	move.b	#$60,_SCCCMD_B		*RTS=H(本体側マウス)
	rts				*(MSCTRLFLG.w = $ff になっている)

msctrlsetA7:				*マウスがデータを送るかどうかしばらく待つ
	bne	msctrlsetA8
	move.b	#$05,_SCCCMD_B		*WR5
	move.b	#$60,_SCCCMD_B		*RTS=H(本体側マウス)
	move.l	#msctrlsetB,MSTADR.w	*割り込みアドレスをキーボード側マウスに切り替える
msctrlsetA1:
	st.b	MSCTRLFLG.w
msctrlsetA8:
	rts


*	キーボード側マウスに送信要求を出す

msctrlsetB::
	subq.b	#1,MSCTRLFLG.w
	bcs	msctrlsetB5		*マウスからデータが来た→送信要求を下ろす
	bpl	msctrlsetB7		*データが来ていないのでしばらく待つ
					*送信要求を出す
	tst.b	MSJOBFLG.w
	bmi	msctrlsetB1		*(b7=1)前回の受信データをまだ処理中
	move.l	a0,-(sp)
	move	#3,MSRCVCNT.w		*受信カウンタ初期化
	move.l	#MSRCVBUF,MSRCVPTR.w	*受信バッファポインタ初期化
	lea	_SCCDATA_B,a0
	tst.b	(a0)			*(ゴミデータがバッファに残っていたらキャンセル)
	tst.b	(a0)
	tst.b	(a0)
	tst.b	(a0)
msctrlsetB2:
	tst.b	_MFP_TSR
	bpl	msctrlsetB2		*送信バッファが空になるまで待つ
	move.b	#$40,_MFP_UDR		*MSCTRL=L(キーボード側マウス送信要求)
	move.l	(sp)+,a0
	move.b	#$04,MSCTRLFLG.w	*次に送信要求を下ろすことにする
	rts				*(データが来ない場合は割り込み４回分まで待つ)

msctrlsetB5:
	tst.b	_MFP_TSR
	bpl	msctrlsetB5		*送信バッファが空になるまで待つ
	move.b	#$41,_MFP_UDR		*MSCTRL=H(キーボード側マウス)
	rts				*(MSCTRLFLG.w = $ff になっている)

msctrlsetB7:				*マウスがデータを送るかどうかしばらく待つ
	bne	msctrlsetB8
msctrlsetB7_1:
	tst.b	_MFP_TSR
	bpl	msctrlsetB7_1		*送信バッファが空になるまで待つ
	move.b	#$41,_MFP_UDR		*MSCTRL=H(キーボード側マウス)
	move.l	#msctrlsetA,MSTADR.w	*割り込みアドレスを本体側マウスに切り替える
msctrlsetB1:
	st.b	MSCTRLFLG.w
msctrlsetB8:
	rts


	.if	0


msctrlsetA::
msctrlsetB::
	not.b	MSCTRLFLG.w
	beq	msctrlset5

	move.b	#$05,_SCCCMD_B		*WR5
	move.b	#$60,_SCCCMD_B		*RTS=H(本体側マウス)
msctrlset1:
	tst.b	_MFP_TSR
	bpl	msctrlset1		*送信バッファが空になるまで待つ
	move.b	#$41,_MFP_UDR		*MSCTRL=H(キーボード側マウス)
	rts

msctrlset5:
	tst.b	MSJOBFLG.w
	bmi	msctrlset9		*(b7=1)前回の受信データをまだ処理中
	move	#3,MSRCVCNT.w		*受信カウンタ初期化
	move.l	#MSRCVBUF,MSRCVPTR.w	*受信バッファポインタ初期化
	move.b	#$05,_SCCCMD_B		*WR5
	move.b	#$62,_SCCCMD_B		*RTS=L(本体側マウス送信要求)
msctrlset6:
	tst.b	_MFP_TSR
	bpl	msctrlset6		*送信バッファが空になるまで待つ
	move.b	#$40,_MFP_UDR		*MSCTRL=L(キーボード側マウス送信要求)
	rts

msctrlset9:				*前回の受信データを処理中
	st.b	MSCTRLFLG.w		*フラグを元に戻す
	rts


	.endif



*************************************************
*	ＳＣＣ－Ｂ(マウス)１バイト入力処理	*
*************************************************

sccbrcv::
	move	#$2700,sr		*割り込み禁止(Timer-Cの方が上位のため)
	tst.b	MSCTRLFLG.w		**受信フラグをセット
	smi.b	MSCTRLFLG.w		**(b7をb6～b0にコピー)
	move.l	a1,-(sp)
	movea.l	MSRCVPTR.w,a1
	move.b	_SCCDATA_B,(a1)+	*受信データ読み出し
	subq	#1,MSRCVCNT.w
	beq	sccbrcv1		*３バイト受信した
	move.l	a1,MSRCVPTR.w
sccbrcv9:
	move.l	(sp)+,a1
	move.b	#$38,_SCCCMD_B		*下位割り込み要求許可
	rte

sccbrcv1:
	move	#3,MSRCVCNT.w		*受信カウンタ初期化
**	lea	MSRCVBUF.w,a1
	subq.l	#3,a1
	move.l	a1,MSRCVPTR.w		*受信バッファポインタ初期化
.if CPU>=68020
	tst.b	MSJOBFLG.w
	bmi	sccbrcv9		*(b7=1)前の受信データを処理中
	bset	#$07,MSJOBFLG.w
.else
	tas.b	MSJOBFLG.w		*(tst.b & bset.b #7,MSJOBFLG.w)
	bmi	sccbrcv9		*(b7=1)前の受信データを処理中
.endif
	movem.l	d0-d1/a0,-(sp)
	movea.l	a1,a0			*lea MSRCVBUF.w,a0
	lea	MSRCVDATA.w,a1
.if CPU>=68020
	move	(a0)+,(a1)
	move.b	(a0)+,(2,a1)
.else
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	move.b	(a0)+,(a1)+
	subq.l	#3,a1			*lea MSRCVDATA.w,a1
.endif
	move.b	#$38,_SCCCMD_B		*下位割り込み要求許可
	move	4*4(sp),d0		*スタック上のsr
	ori	#$2000,d0		*スーパーバイザモード
	move	d0,sr			*割り込みレベルを元に戻す
	movea.l	MSSKEYVECT.w,a0
	jsr	(a0)			*ソフトキーボード処理
	movea.l	MSCSRVECT.w,a0
	jsr	(a0)			*マウスカーソル処理
	bclr	#$07,MSJOBFLG.w
	movem.l	(sp)+,d0-d1/a0-a1
	rte



*****************************************
*	IOCS $71	_MS_CURON	*
*****************************************
ms_curon::
	movem.l	d0-d7/a1-a6,-(sp)
	st.b	MSIOCSJOB.w		**
	tst.b	MSCSRSW.w		**マウスカーソル表示中か？
	bne	ms_curon1
	move.l	MSCSRX.w,d0
msdpatch1::
	bsr	mscdrawB		*マウスカーソルを表示する
	st.b	MSCSRSW.w		**
ms_curon1:
	sf.b	MSIOCSJOB.w		**
	movem.l	(sp)+,d0-d7/a1-a6
	rts

*****************************************
*	IOCS $72	_MS_CUROF	*
*****************************************
ms_curof::
	movem.l	d0-d7/a1-a6,-(sp)
	st.b	MSIOCSJOB.w		**
	tst.b	MSCSRSW.w		**マウスカーソル表示中か？
	beq	ms_curof1
	clr	MSCSRSW.w		**
	move.l	MSCSRX.w,d0
msepatch1::
	bsr	msceraseB		*マウスカーソルを消去する
ms_curof1:
	sf.b	MSIOCSJOB.w		**
	movem.l	(sp)+,d0-d7/a1-a6
	rts

*****************************************
*	IOCS $73	_MS_STAT	*
*****************************************
ms_stat::
	moveq	#0,d0
	move.b	MSCSRSW.w,d0		*カーソル表示の状態
	ext	d0
	rts

*****************************************
*	IOCS $74	_MS_GETDT	*
*****************************************
ms_getdt::
	lea	MSLEFT.w,a0
	movep.l	1(a0),d0		*MSLEFT|MSRIGHT|MSMOVEX|MSMOVEY
	swap	d0
	rts

*****************************************
*	IOCS $75	_MS_CURGT	*
*****************************************
ms_curgt::
	move.l	MSCSRX.w,d0		*MSCSRX|MSCSRY
	rts

*****************************************
*	IOCS $76	_MS_CURST	*	($ffa0ac)
*****************************************
ms_curst::
	movem.l	d2-d3,-(sp)
	move.l	d1,d0			*設定するマウスカーソル座標
	move.l	MSXMIN.w,d3
	move.l	MSXMAX.w,d2
	sub	d3,d2
	sub	d3,d0
	cmp	d0,d2
	bcs	ms_curst9		*Ｙ座標が範囲外
	swap	d0
	swap	d2
	swap	d3
	sub	d3,d2
	sub	d3,d0
	cmp	d0,d2
	bcs	ms_curst9		*Ｘ座標が範囲外
	st.b	MSIOCSJOB.w		**
	move	MSCSRSW.w,-(sp)
	bsr	ms_curof		*マウスカーソル消去	!!!IOCSJOB
	move.l	d1,MSCSRX.w
	tst	(sp)+
	beq	ms_curst1
	bsr	ms_curon		*マウスカーソル描画	!!!IOCSJOB
ms_curst1:
	sf.b	MSIOCSJOB.w		**
	movem.l	(sp)+,d2-d3
	moveq	#0,d0
	rts

ms_curst9:				*座標が範囲外なのでエラー
	movem.l	(sp)+,d2-d3
	moveq	#-1,d0
	rts



*************************************************
*	マウスカーソル移動処理			*
*************************************************

mscmove:
	tst.b	MSIOCSJOB.w		**
	bne	mscmove9
	tst.b	MSSKEYJOB.w
	bne	mscmove9
	st.b	MSIOCSJOB.w		**

	movem.l	d2-d7/a1-a6,-(sp)

	move.b	(a1)+,d0		*受信データ１バイト目
	lsr.b	#1,d0			*(btst #0,d0)
	scs.b	d1
	ext	d1
	swap	d1
	lsr.b	#1,d0			*(btst #1,d0)
	scs.b	d1
	ext	d1
	move.l	d1,MSLEFT.w		*ボタンの状態
	move.b	(a1)+,d0		*受信データ２バイト目（Ｘ方向データ）
	ext	d0
	swap	d0
	move.b	(a1),d0			*	   ３バイト目（Ｙ方向データ）
	ext	d0

	tst.b	MSANIMSW.w
	beq	mscmove1
	addq	#1,MSASCNT.w		*マウスカーソルアニメーションを行なう
	move	MSASCNT.w,d1		*アニメーション速度カウンタ
	cmp	MSASPEED.w,d1
	bne	mscmove1

	move.l	d0,MSMOVEX.w

	clr	MSASCNT.w
	addq	#1,MSAPATN.w		*次のパターンデータのアドレスを得る
	move	(MSAPATN),d1
.if CPU>=68020
	tst	(MSCSRPAT,d1.w*4)
.else
	lea	(MSCSRPAT),a0
	add	d1,d1
	add	d1,d1
	tst	(a0,d1.w)		*パターンアドレスが存在するか？
.endif
	bne	mscmove2
	clr	MSAPATN.w		*最初のパターンに戻る
	bra	mscmove2

mscmove1:
	move.l	d0,MSMOVEX.w
	beq	mscmove8		*移動量０なのでなにもしない
mscmove2:
	move.l	MSCSRX.w,d2
	move.l	MSXMIN.w,d3
	move.l	MSXMAX.w,d4
	move	MSSPEED(pc),d5
	move	d5,d6
	subq	#1,d6

	bsr	msdelta			*実際の移動量を計算する
	add	d2,d0			*移動後のＹ座標
	cmp	d3,d0
	bge	mscmove3
	move	d3,d0			*画面上端に達した(MSYMIN)
	bra	mscmove4
mscmove3:
	cmp	d4,d0
	ble	mscmove4
	move	d4,d0			*画面下端に達した(MSYMAX)
mscmove4:

	swap	d0
	swap	d2
	swap	d3
	swap	d4

	bsr	msdelta			*実際の移動量を計算する
	add	d2,d0			*移動後のＸ座標
	cmp	d3,d0
	bge	mscmove5
	move	d3,d0			*画面左端に達した(MSXMIN)
	bra	mscmove6
mscmove5:
	cmp	d4,d0
	ble	mscmove6
	move	d4,d0			*画面右端に達した(MSXMAX)
mscmove6:
	swap	d0
	move.l	d0,MSCSRX.w

	tst.b	MSCSRSW.w
	beq	mscmove8		*マウスカーソルは無表示

	swap	d2
	move.l	d2,d0
msepatch2::
	bsr	msceraseB		*マウスカーソルを消去する
	move.l	MSCSRX.w,d0
msdpatch2::
	bsr	mscdrawB		*マウスカーソルを表示する
mscmove8:
	movem.l	(sp)+,d2-d7/a1-a6
	sf.b	MSIOCSJOB.w
mscmove9:
	rts


*	マウスの移動量からマウスカーソルの実際の移動量を計算する

msdelta:
	tst	d0
	bgt	msdelta5
	neg	d0			*負の移動量
	move	d0,d1
	lsr	d5,d1			*Δx / 8
	bne	msdelta1
	moveq	#1,d1
msdelta1:
	mulu	d0,d1			*t = ((Δx / 8) ? (Δx / 8) : 1) * Δx
	move	d1,d0
	lsr	d6,d0
	add	d1,d0			*Δx'= t + t / 4
	neg	d0
	rts
msdelta5:				*正の移動量
	move	d0,d1
	lsr	d5,d1			*Δx / 8
	bne	msdelta6
	moveq	#1,d1
msdelta6:
	mulu	d0,d1			*t = ((Δx / 8) ? (Δx / 8) : 1) * Δx
	move	d1,d0
	lsr	d6,d0
	add	d1,d0			*Δx'= t + t / 4
	rts



*	マウスカーソルを描画する（v1.0ＲＯＭ対応）

mscdrawA::
	movea.l	MSTXADR2.w,a0
	movea.l	MSTXADR3.w,a1
	lea	MSSAVE2.w,a2
	lea	MSSAVE3.w,a3
	move	(MSAPATN),d1		*マウスカーソルパターン番号
.if CPU>=68020
	movea.l	(MSCSRPAT,d1.w*4),a4
.else
	lea	(MSCSRPAT),a4
	add	d1,d1
	add	d1,d1
	movea.l	(a4,d1.w),a4		*パターンデータアドレス
.endif
	lea	$0020(a4),a5

	move.l	MSHOTX.w,d1
	move.l	MSCOLMIN.w,d2
	move.l	MSCOLMAX.w,d3

	sub	d1,d0
	move	d0,d1			*マウスカーソル表示開始ライン
	moveq	#16,d4
	add	d0,d4			*		   終了ライン＋１
	moveq	#15,d7			*表示ライン数－１
	sub	d2,d1
	bge	mscdrawA1
	add	d1,d7			*途中ラインから表示する
	bmi	mscdrawA495		*マウスカーソルが表示範囲外
	move	d2,d0
	add	d1,d1
	suba	d1,a2			*パターンデータアドレスを変更
	suba	d1,a3
	suba	d1,a4
	suba	d1,a5
mscdrawA1:
	sub	d3,d4
	ble	mscdrawA2
	sub	d4,d7			*途中ラインで終了する
	bmi	mscdrawA495		*マウスカーソルが表示範囲外
mscdrawA2:
	move	#128,d6			*(move MSTXLLEN.w,d6)
	move	d0,d4
	ext.l	d4			*(mulu d6,d4)
	asl.l	#7,d4
	adda.l	d4,a0			*ＶＲＡＭアドレス
	adda.l	d4,a1

	swap	d0
	swap	d1
	swap	d2
	swap	d3

	sub	d1,d0
	move	d0,d1			*マウスカーソル表示開始カラム
	asr	#3,d1
	adda	d1,a0			*ＶＲＡＭアドレス
	adda	d1,a1
	andi	#$0007,d0
	bne	mscdrawA50		*Ｘ座標が８の倍数でない

	lea	_CRTC21,a6		*Ｘ座標が８の倍数の場合
	move	(a6),-(sp)
	clr.b	(a6)			*テキストＶＲＡＭシングルアクセス

	subq	#1,d2
	cmp	d2,d1
	beq	mscdrawA30
	blt	mscdrawA49		*マウスカーソルが表示範囲外
	subq	#1,d3
	cmp	d3,d1
	beq	mscdrawA40
	bgt	mscdrawA49		*マウスカーソルが表示範囲外

.if CPU<68020
	lsr	#1,d1			*左右とも表示範囲内
	bcs	mscdrawA20
.endif
mscdrawA10:				*偶数アドレスの場合
	move	(a0),d0			*ＶＲＡＭデータ読み出し
	move	(a1),d1
	move	d0,(a2)+		*変更前データを保存する
	move	d1,(a3)+
	move	(a4)+,d2		*パターンデータ２
	and	d2,d1
	or	(a5)+,d1		*パターンデータ３
	not	d2
	or	d2,d0
	move	d0,(a0)			*パターンデータ書き込み
	move	d1,(a1)
	adda	d6,a0
	adda	d6,a1
	dbra	d7,mscdrawA10
	move	(sp)+,(a6)
	rts

.if CPU<68020
mscdrawA20:				*奇数アドレスの場合
	move.b	(a0)+,-(sp)		;move.b	(a0)+,d0	*ＶＲＡＭデータ読み出し
	move	(sp)+,d0		;lsl	#8,d0
	move.b	(a0),d0
	move.b	(a1)+,-(sp)		;move.b	(a1)+,d1
	move	(sp)+,d1		;lsl	#8,d1
	move.b	(a1),d1
	move	d0,(a2)+		*変更前データを保存する
	move	d1,(a3)+
	move	(a4)+,d2		*パターンデータ２
	and	d2,d1
	or	(a5)+,d1		*パターンデータ３
	not	d2
	or	d2,d0
	move.b	d0,(a0)			*パターンデータ書き込み
	move	d0,-(sp)		;lsr	#8,d0
	move.b	(sp)+,-(a0)		;move.b	d0,-(a0)
	move.b	d1,(a1)
	move	d1,-(sp)		;lsr	#8,d1
	move.b	(sp)+,-(a1)		;move.b	d1,-(a1)
	adda	d6,a0
	adda	d6,a1
	dbra	d7,mscdrawA20
	move	(sp)+,(a6)
	rts
.endif

mscdrawA30:
	cmp	d3,d1
	bge	mscdrawA49		*マウスカーソルが表示範囲外
	addq.l	#1,a0
	addq.l	#1,a1
mscdrawA31:				*左側が表示範囲外
	move.b	(a0),d0			*ＶＲＡＭデータ読み出し
	move.b	(a1),d1
	move	d0,(a2)+		*変更前データを保存する
	move	d1,(a3)+
	move	(a4)+,d2		*パターンデータ２
	and	d2,d1
	or	(a5)+,d1		*パターンデータ３
	not	d2
	or	d2,d0
	move.b	d0,(a0)			*パターンデータ書き込み
	move.b	d1,(a1)
	adda	d6,a0
	adda	d6,a1
	dbra	d7,mscdrawA31
	move	(sp)+,(a6)
	rts

mscdrawA40:				*右側が表示範囲外
	move.b	(a0),d0			*ＶＲＡＭデータ読み出し
	move.b	(a1),d1
	move.b	d0,(a2)+		*変更前データを保存する
	addq.l	#1,a2
	move.b	d1,(a3)+
	addq.l	#1,a3
	move.b	(a4)+,d2		*パターンデータ２
	addq.l	#1,a4
	and.b	d2,d1
	or.b	(a5)+,d1		*パターンデータ３
	addq.l	#1,a5
	not.b	d2
	or.b	d2,d0
	move.b	d0,(a0)			*パターンデータ書き込み
	move.b	d1,(a1)
	adda	d6,a0
	adda	d6,a1
	dbra	d7,mscdrawA40
mscdrawA49:
	move	(sp)+,(a6)
mscdrawA495:
	rts

msevenmask1:	.dc.w	$0000,$8000,$c000,$e000,$f000,$f800,$fc00,$fe00

mscdrawA50:				*Ｘ座標が８の倍数でない場合
	move	sr,-(sp)
	ori	#$0700,sr		*割り込み禁止
	lea	_CRTC21,a6
	move	(a6),-(sp)
	move.b	#2,(a6)			*テキストＶＲＡＭビットマスクモード
	addq.l	#_CRTC23-_CRTC21,a6
	move	(a6),-(sp)		*ビットマスクデータを保存

.if CPU<68020
	btst	#0,d1
	bne	mscdrawA70
.endif
					*偶数アドレスの場合	llmm rr00
.if CPU>=68020
	move	(msevenmask1,pc,d0.w*2),d4
.else
	move	d0,d4
	add	d4,d4
	move	(msevenmask1,pc,d4.w),d4	*左ワードマスクデータ
.endif
	move	d4,d5
	not	d5			*右ワード

	sub	d1,d2
	ble	mscdrawA55		*左側は完全に表示範囲内
	subq	#2,d2
	bcs	mscdrawA51
	bhi	mscdrawA99		*表示範囲外
	moveq	#-1,d4			*左・中央は表示範囲外	0000 rr00
	bra	mscdrawA55
mscdrawA51:
	ori	#$ff00,d4		*左は表示範囲外		00mm rr00

mscdrawA55:
	subq	#2,d3
	sub	d1,d3
	bgt	mscdrawA60		*右側は完全に表示範囲内
	beq	mscdrawA56
	addq	#1,d3
	bne	mscdrawA99		*表示範囲外
*	move.b	#$ff,d4			*中央・右は表示範囲外	ll00 0000
	st	d4
mscdrawA56:
	moveq	#-1,d5			*右は表示範囲外		llmm 0000

mscdrawA60:				*偶数アドレスのデータ転送
	subq	#2,d6
mscdrawA61:
	move.l	(a0),d1			*ＶＲＡＭデータ読み出し
	move.l	(a1),d2
	swap	d1
	swap	d2
	rol.l	d0,d1
	rol.l	d0,d2
	move	d1,(a2)+		*変更前データを保存する
	move	d2,(a3)+
	move	(a4)+,d3		*パターンデータ２
	and	d3,d2
	or	(a5)+,d2		*パターンデータ３
	not	d3
	or	d3,d1
	swap	d2
	move	d1,d2
	ror.l	d0,d2			*右シフト
	move	d4,(a6)			*左ワードマスク
	move	d2,(a0)+
	swap	d2
	move	d2,(a1)+
	move	d5,(a6)			*右ワードマスク
	move	d2,(a0)
	swap	d2
	move	d2,(a1)
	add	d6,a0
	add	d6,a1
	dbra	d7,mscdrawA61
	bra	mscdrawA99

.if CPU<68020
msoddmask1:	.dc.b	$00,$80,$c0,$e0,$f0,$f8,$fc,$fe

mscdrawA70:				*奇数アドレスの場合	00ll mmrr
	subq.l	#1,a0
	subq.l	#1,a1

	moveq	#-1,d4
	move.b	msoddmask1(pc,d0.w),d4	*左ワードマスクデータ	$ffxx
	move	d4,d5
	not	d5			*右ワード

	sub	d1,d2
	ble	mscdrawA75		*左側は完全に表示範囲内
	subq	#2,d2
	bcs	mscdrawA71
	bhi	mscdrawA99		*表示範囲外
	ori	#$ff00,d5		*左・中央は表示範囲外	0000 00rr
mscdrawA71:
	moveq	#-1,d4			*左は表示範囲外		0000 mmrr

mscdrawA75:
	subq	#2,d3
	sub	d1,d3
	bgt	mscdrawA80		*右側は完全に表示範囲内
	beq	mscdrawA76
	addq	#1,d3
	bne	mscdrawA99		*表示範囲外
	moveq	#-1,d5			*中央・右は表示範囲外	00ll 0000
	bra	mscdrawA80
mscdrawA76:
*	move.b	#$ff,d5			*右は表示範囲外		00ll mm00
	st	d5
mscdrawA80:				*奇数アドレスのデータ転送
	moveq	#8,d3
	sub	d0,d3
	subq	#2,d6
mscdrawA81:
	move.l	(a0),d0			*ＶＲＡＭデータ読み出し
	move.l	(a1),d1
	ror.l	d3,d0
	ror.l	d3,d1
	move	d0,(a2)+		*変更前データを保存する
	move	d1,(a3)+
	move	(a4)+,d2		*パターンデータ２
	and	d2,d1
	or	(a5)+,d1		*パターンデータ３
	not	d2
	or	d2,d0
	swap	d0
	move	d1,d0
	rol.l	d3,d0			*左シフト
	move	d4,(a6)			*左ワードマスク
	move	d0,(a0)+
	swap	d0
	move	d0,(a1)+
	move	d5,(a6)			*右ワードマスク
	move	d0,(a0)
	swap	d0
	move	d0,(a1)
	add	d6,a0
	add	d6,a1
	dbra	d7,mscdrawA81
.endif
mscdrawA99:
	move	(sp)+,(a6)
	move	(sp)+,_CRTC21-_CRTC23(a6)
mscdraw_rte::
	move	(sp)+,sr
	rts


*	マウスカーソルを消去する（v1.0ＲＯＭ対応）

msceraseA::
	movea.l	MSTXADR2.w,a0
	movea.l	MSTXADR3.w,a1
	lea	MSSAVE2.w,a2
	lea	MSSAVE3.w,a3

	move.l	MSHOTX.w,d1
	move.l	MSCOLMIN.w,d2
	move.l	MSCOLMAX.w,d3

	sub	d1,d0
	move	d0,d1			*マウスカーソル表示開始ライン
	moveq	#16,d4
	add	d0,d4			*		   終了ライン＋１
	moveq	#15,d7			*表示ライン数－１
	sub	d2,d1
	bge	msceraseA1
	add	d1,d7			*途中ラインから表示する
	bmi	msceraseA495		*マウスカーソルが表示範囲外
	move	d2,d0
	add	d1,d1
	suba	d1,a2			*パターンデータアドレスを変更
	suba	d1,a3
msceraseA1:
	sub	d3,d4
	ble	msceraseA2
	sub	d4,d7			*途中ラインで終了する
	bmi	msceraseA495		*マウスカーソルが表示範囲外
msceraseA2:
	move	#128,d6			*(move MSTXLLEN.w,d6)
	move	d0,d4
	ext.l	d4			*(mulu d6,d4)
	asl.l	#7,d4
	adda.l	d4,a0			*ＶＲＡＭアドレス
	adda.l	d4,a1

	swap	d0
	swap	d1
	swap	d2
	swap	d3

	sub	d1,d0
	move	d0,d1			*マウスカーソル表示開始カラム
	asr	#3,d1
	adda	d1,a0			*ＶＲＡＭアドレス
	adda	d1,a1
	andi	#$0007,d0
	bne	msceraseA50		*Ｘ座標が８の倍数でない

	lea	_CRTC21,a6		*Ｘ座標が８の倍数の場合
	move	(a6),-(sp)
	clr.b	(a6)			*テキストＶＲＡＭシングルアクセス

	subq	#1,d2
	cmp	d2,d1
	beq	msceraseA30
	blt	msceraseA49		*マウスカーソルが表示範囲外
	subq	#1,d3
	cmp	d3,d1
	beq	msceraseA40
	bgt	msceraseA49		*マウスカーソルが表示範囲外

.if CPU<68020
	lsr	#1,d1			*左右とも表示範囲内
	bcs	msceraseA20
.endif
msceraseA10:				*偶数アドレスの場合
	move	(a2)+,(a0)
	move	(a3)+,(a1)
	adda	d6,a0
	adda	d6,a1
	dbra	d7,msceraseA10
	move	(sp)+,(a6)
	rts

.if CPU<68020
msceraseA20:				*奇数アドレスの場合
	subq	#2,d6
msceraseA21:
	move.b	(a2)+,(a0)+
	move.b	(a2)+,(a0)+
	move.b	(a3)+,(a1)+
	move.b	(a3)+,(a1)+
	adda	d6,a0
	adda	d6,a1
	dbra	d7,msceraseA21
	move	(sp)+,(a6)
	rts
.endif

msceraseA30:
	cmp	d3,d1
	bge	msceraseA49		*マウスカーソルが表示範囲外
	addq.l	#1,a0
	addq.l	#1,a1
msceraseA31:				*左側が表示範囲外
	move	(a2)+,d0
	move	(a3)+,d1
	move.b	d0,(a0)
	move.b	d1,(a1)
	adda	d6,a0
	adda	d6,a1
	dbra	d7,msceraseA31
	move	(sp)+,(a6)
	rts

msceraseA40:				*右側が表示範囲外
	move.b	(a2)+,(a0)
	move.b	(a3)+,(a1)
	addq.l	#1,a2
	addq.l	#1,a3
	adda	d6,a0
	adda	d6,a1
	dbra	d7,msceraseA40
msceraseA49:
	move	(sp)+,(a6)
msceraseA495:
	rts

msevenmask2:	.dc.w	$0000,$8000,$c000,$e000,$f000,$f800,$fc00,$fe00

msceraseA50:				*Ｘ座標が８の倍数でない場合
	move	sr,-(sp)
	ori	#$0700,sr		*割り込み禁止
	lea	_CRTC21,a6
	move	(a6),-(sp)
	move.b	#2,(a6)			*テキストＶＲＡＭビットマスクモード
	addq.l	#_CRTC23-_CRTC21,a6
	move	(a6),-(sp)		*ビットマスクデータを保存
.if CPU<68020
	btst	#0,d1
	bne	msceraseA70
.endif
					*偶数アドレスの場合	llmm rr00
.if CPU>=68020
	move	(msevenmask2,pc,d0.w*2),d4
.else
	move	d0,d4
	add	d4,d4
	move	(msevenmask2,pc,d4.w),d4	*左ワードマスクデータ
.endif
	move	d4,d5
	not	d5			*右ワード

	sub	d1,d2
	ble	msceraseA55		*左側は完全に表示範囲内
	subq	#2,d2
	bcs	msceraseA51
	bhi	msceraseA99		*表示範囲外
	moveq	#-1,d4			*左・中央は表示範囲外	0000 rr00
	bra	msceraseA55
msceraseA51:
	ori	#$ff00,d4		*左は表示範囲外		00mm rr00

msceraseA55:
	subq	#2,d3
	sub	d1,d3
	bgt	msceraseA60		*右側は完全に表示範囲内
	beq	msceraseA56
	addq	#1,d3
	bne	msceraseA99		*表示範囲外
*	move.b	#$ff,d4			*中央・右は表示範囲外	ll00 0000
	st	d4
msceraseA56:
	moveq	#-1,d5			*右は表示範囲外		llmm 0000

msceraseA60:				*偶数アドレスのデータ転送
	subq	#2,d6
msceraseA61:
	move	(a3)+,d2
	swap	d2
	move	(a2)+,d2
	ror.l	d0,d2			*右シフト
	move	d4,(a6)			*左ワードマスク
	move	d2,(a0)+
	swap	d2
	move	d2,(a1)+
	move	d5,(a6)			*右ワードマスク
	move	d2,(a0)
	swap	d2
	move	d2,(a1)
	add	d6,a0
	add	d6,a1
	dbra	d7,msceraseA61
	bra	msceraseA99

.if CPU<68020
msoddmask2:	.dc.b	$00,$80,$c0,$e0,$f0,$f8,$fc,$fe

msceraseA70:				*奇数アドレスの場合	00ll mmrr
	subq.l	#1,a0
	subq.l	#1,a1

	moveq	#-1,d4
	move.b	msoddmask2(pc,d0.w),d4	*左ワードマスクデータ	$ffxx
	move	d4,d5
	not	d5			*右ワード

	sub	d1,d2
	ble	msceraseA75		*左側は完全に表示範囲内
	subq	#2,d2
	bcs	msceraseA71
	bhi	msceraseA99		*表示範囲外
	ori	#$ff00,d5		*左・中央は表示範囲外	0000 00rr
msceraseA71:
	moveq	#-1,d4			*左は表示範囲外		0000 mmrr

msceraseA75:
	subq	#2,d3
	sub	d1,d3
	bgt	msceraseA80		*右側は完全に表示範囲内
	beq	msceraseA76
	addq	#1,d3
	bne	msceraseA99		*表示範囲外
	moveq	#-1,d5			*中央・右は表示範囲外	00ll 0000
	bra	msceraseA80
msceraseA76:
*	move.b	#$ff,d5			*右は表示範囲外		00ll mm00
	st	d5
msceraseA80:				*奇数アドレスのデータ転送
	moveq	#8,d3
	sub	d0,d3
	subq	#2,d6
msceraseA81:
	move	(a2)+,d1
	swap	d1
	move	(a3)+,d1
	rol.l	d3,d1			*左シフト
	move	d4,(a6)			*左ワードマスク
	move	d1,(a0)+
	swap	d1
	move	d1,(a1)+
	move	d5,(a6)			*右ワードマスク
	move	d1,(a0)
	swap	d1
	move	d1,(a1)
	add	d6,a0
	add	d6,a1
	dbra	d7,msceraseA81
.endif
msceraseA99:
	move	(sp)+,(a6)
	move	(sp)+,_CRTC21-_CRTC23(a6)
mscerase_rte::
	move	(sp)+,sr
	rts


*	マウスカーソルを描画する（v1.1ＲＯＭ以降対応）

mscdrawB::
	move	_CRTC21,d5
	clr.b	_CRTC21			*テキストＶＲＡＭシングルアクセス

	movea.l	MSTXADR2.w,a0
	movea.l	MSTXADR3.w,a1
	lea	MSVRAM2.w,a2
	lea	MSVRAM3.w,a3

	moveq	#0,d2
	move	d0,d2
	move.l	MSHOTX.w,d1

	sub	d1,d2			*マウスカーソル表示開始ライン
	bpl	mscdrawB1
	moveq	#0,d2			*表示開始ラインが画面上部を超える
mscdrawB1:
	moveq	#16-1,d3
	cmpi	#$03f0,d2
	bls	mscdrawB2
	move	#$03ff,d3
	sub	d2,d3
	bmi	mscdrawB99		*表示開始ラインが画面下部を超える
mscdrawB2:
	asl.l	#7,d2			*(mulu MSTXLLEN.w,d2)
	adda.l	d2,a0			*マウスカーソル表示ラインのＶＲＡＭアドレス
	adda.l	d2,a1

	move.l	d0,d2
	swap	d2
	swap	d1
	sub	d1,d2			*表示開始Ｘ座標
	bpl	mscdrawB3
	moveq	#0,d2			*表示開始Ｘ座標が画面左端を超える
mscdrawB3:
	lsr	#4,d2
	add	d2,d2
	adda	d2,a0			*表示開始ＶＲＡＭアドレス
	adda	d2,a1
	move	#128,d4			*(move MSTXLLEN.w,d4)
	cmpi	#$007e,d2
	bcs	mscdrawB6

mscdrawB5:				*(右ワードが隠れる場合）
	move	(a0),(a2)+		*テキストページ２を退避する
	move	(a1),(a3)+		*テキストページ３を退避する
	adda	d4,a0
	adda	d4,a1
	dbra	d3,mscdrawB5
	bra	mscdrawB10

mscdrawB6:				*ＶＲＡＭからデータを退避する
	move.l	(a0),(a2)+		*テキストページ２を退避する
	move.l	(a1),(a3)+		*テキストページ３を退避する
	adda	d4,a0
	adda	d4,a1
	dbra	d3,mscdrawB6

mscdrawB10:
	move	(MSAPATN),d2	*マウスカーソルパターン番号
.if CPU>=68020
	movea.l	(MSCSRPAT,d2.w*4),a2
.else
	lea	(MSCSRPAT),a0
	add	d2,d2
	add	d2,d2
	movea.l	(a0,d2.w),a2	*パターンデータアドレス
.endif
	movea.l	MSTXADR2.w,a0
	movea.l	MSTXADR3.w,a1

	moveq	#0,d2
	move	d0,d2
	swap	d1			*(move.l MSHOTX.w,d1)

	sub	d1,d2			*マウスカーソル表示開始ライン
	bpl	mscdrawB11
	addi	#$000f,d2		*パターンの上が隠れる場合
	bmi	mscdrawB99		*パターンが完全に隠れる
	move	d2,d3
	add	d2,d2
	lea	($001e,a2),a2
	suba	d2,a2			*パターンデータアドレスを調節する
	bra	mscdrawB13
mscdrawB11:
	moveq	#16-1,d3
	cmpi	#$03f0,d2
	bls	mscdrawB12
	move	#$03ff,d3		*パターンの下が隠れる場合
	sub	d2,d3
	bmi	mscdrawB99		*パターンが完全に隠れる
mscdrawB12:
	asl.l	#7,d2			*(mulu MSTXLLEN.w,d2)
	adda.l	d2,a0			*表示開始ラインのページ２ＶＲＡＭアドレス
	adda.l	d2,a1			*		 ページ３

mscdrawB13:
	lea	$0020(a2),a3
	move	#128,d4			*(move MSTXLLEN.w,d4)
	swap	d0
	swap	d1
	sub	d1,d0			*マウスカーソル表示開始Ｘ座標
	bpl	mscdrawB14
	neg	d0			*パターンの左が隠れる場合
	move	d0,d2
	bra	mscdrawB40

mscdrawB14:
	move	d0,d1
	lsr	#4,d1
	add	d1,d1
	adda	d1,a0
	adda	d1,a1
	andi	#$000f,d0
	beq	mscdrawB50		*表示開始位置がワード境界に合致
	moveq	#16,d2
	sub	d0,d2
	cmpi	#$007e,d1
	bcc	mscdrawB30		*パターンの右が隠れる場合
mscdrawB20:				*パターン全体が表示できる場合
	moveq	#$ff,d0
	moveq	#$00,d1
	move	(a3)+,d1		*ページ３データ
	move	(a2)+,d0		*ページ２データ
	rol.l	d2,d0
	rol.l	d2,d1
	and.l	d0,(a1)
	or.l	d1,(a1)			*ページ３書き込み
	not.l	d0
	or.l	d0,(a0)			*ページ２書き込み
	adda	d4,a0
	adda	d4,a1
	dbra	d3,mscdrawB20
	move	d5,_CRTC21
	rts

mscdrawB30:				*パターンの右が隠れる場合
	moveq	#$ff,d0
	moveq	#$00,d1
	move	(a3)+,d1		*ページ３データ
	move	(a2)+,d0		*ページ２データ
	rol.l	d2,d0
	rol.l	d2,d1
	swap	d0
	swap	d1
	and	d0,(a1)
	or	d1,(a1)			*ページ３書き込み
	not	d0
	or	d0,(a0)			*ページ２書き込み
	adda	d4,a0
	adda	d4,a1
	dbra	d3,mscdrawB30
	move	d5,_CRTC21
	rts

mscdrawB40:				*パターンの左が隠れる場合
	moveq	#$ff,d0
	moveq	#$00,d1
	move	(a3)+,d1		*ページ３データ
	move	(a2)+,d0		*ページ２データ
	rol.l	d2,d0
	rol.l	d2,d1
	and	d0,(a1)
	or	d1,(a1)			*ページ３書き込み
	not	d0
	or	d0,(a0)			*ページ２書き込み
	adda	d4,a0
	adda	d4,a1
	dbra	d3,mscdrawB40
	move	d5,_CRTC21
	rts

mscdrawB50:				*表示座標がワード境界に合致する場合
	move	(a3)+,d1		*ページ３データ
	move	(a2)+,d0		*ページ２データ
	and	d0,(a1)
	or	d1,(a1)			*ページ３書き込み
	not	d0
	or	d0,(a0)			*ページ２書き込み
	adda	d4,a0
	adda	d4,a1
	dbra	d3,mscdrawB50
mscdrawB99:
	move	d5,_CRTC21
	rts


*	マウスカーソルを消去する（v1.1ＲＯＭ以降対応）

msceraseB::
	move	_CRTC21,d4
	clr.b	_CRTC21			*テキストＶＲＡＭシングルアクセス

	lea	MSVRAM2.w,a0
	lea	MSVRAM3.w,a1
	movea.l	MSTXADR2.w,a2
	movea.l	MSTXADR3.w,a3

	moveq	#0,d2
	move	d0,d2
	move.l	MSHOTX.w,d1
	sub	d1,d2			*マウスカーソル表示開始ライン
	bpl	msceraseB1
	moveq	#0,d2			*表示開始ラインが画面上部を超える
msceraseB1:
	moveq	#16-1,d3
	cmpi	#$03f0,d2
	bls	msceraseB2
	move	#$03ff,d3
	sub	d2,d3
	bmi	msceraseB9		*表示開始ラインが画面下部を超える
msceraseB2:
	asl.l	#7,d2			*(mulu MSTXLLEN.w,d2)
	adda.l	d2,a2			*マウスカーソル表示ラインのＶＲＡＭアドレス
	adda.l	d2,a3

	swap	d0
	swap	d1
	sub	d1,d0			*表示開始Ｘ座標
	bpl	msceraseB3
	moveq	#0,d0			*表示開始Ｘ座標が画面左端を超える
msceraseB3:
	lsr	#4,d0
	add	d0,d0
	adda	d0,a2			*表示開始ＶＲＡＭアドレス
	adda	d0,a3
	move	#128,d1			*(move MSTXLLEN.w,d1)
	cmpi	#$007e,d0
	bcc	msceraseB6

msceraseB5:				*ＶＲＡＭにデータを転送する
	move.l	(a0)+,(a2)		*テキストページ２を復帰する
	move.l	(a1)+,(a3)		*テキストページ３を復帰する
	adda	d1,a2
	adda	d1,a3
	dbra	d3,msceraseB5
	move	d4,_CRTC21
	rts

msceraseB6:				*（右ワードが隠れる場合）
	move	(a0)+,(a2)		*テキストページ２を復帰する
	move	(a1)+,(a3)		*テキストページ３を復帰する
	adda	d1,a2
	adda	d1,a3
	dbra	d3,msceraseB6
msceraseB9:
	move	d4,_CRTC21
	rts



*****************************************
*	IOCS $70	_MS_INIT	*
*****************************************
ms_init::
	movea.l	old_ms_init(pc),a0
	jsr	(a0)
ms_vcs1:				*パラメータをデフォルト値にする
	lea	mscmove(pc),a0
	move.l	a0,MSCSRVECT.w
	moveq	#1,d0
	move	d0,MSTINIT.w
	move	d0,MSTIMER.w
	rts


*****************************************
*	IOCS $36	(_MS_VCS)	*
*****************************************

ms_vcs::
	tst.l	d1
	beq	ms_vcs1

	move.l	d1,(MSCSRVECT)		*マウス受信データ処理アドレス
	move	d2,(MSTINIT)
	move	d2,(MSTIMER)
	rts

	.end
