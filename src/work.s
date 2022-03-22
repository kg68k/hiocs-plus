		.title	HIOCS PLUS v16.09 (work.s)

*****************************************************************
*	HIOCS version 1.10
*		< WORK.HAS >
*	$Id: WORK.HA_ 1.2 92/10/28 11:02:56 YuNK Exp $
*
*		Copyright 1990,91,92  SHARP / Y.Nakamura
*****************************************************************


* Include Files ----------------------- *

		.include	hiocs.equ

* Text Section ------------------------ *

		.text
		.quad

*=======================================*
*	ワークエリア			*
*=======================================*

FIRSTFNT::	.ds.l	1	*フォント格納アドレス(１バイト目より)
FIRSTFLG::	.ds	1	*１バイト目の文字種類

KBUFOLDNUM::	.dc	0	*キーバッファに入っているキーの数(ブレークチェック用)

		.even		*カーソルパターンバッファ(プレーン0,1の順)
CSRPAT0::	.dcb	16/2,$aa55
CSRPAT1::	.dcb	16/2,$55aa
CSRSAVE0::	.ds.b	16	*カーソルパターン保存バッファ(プレーン0)
CSRSAVE1::	.ds.b	16	*			     (プレーン1)
CSRPATC::	.dcb.b	16,$ff
CSRPATSW::	.dc.b	0	*≠0ならCONDRV用カーソルパターンを使用する
		.even

STDOUTPTR::	.ds.l	1	*Human内stdoutファイルハンドルポインタ
EXCHRVECT::	.dc.l	0	*拡張外字処理ベクタ(０なら処理しない)

FONTANK6::	.dc.l	fon_ank6	*６×12 半角フォント格納アドレス
FONTSML8::	.dc.l	fon_sml8	*８×８ 1/4角フォント
FONTANK8::	.dc.l	fon_ank8	*８×16 半角フォント
FONTKNJ16::	.dc.l	fon_knj16	*16×16 全角フォント
FONTSML12::	.dc.l	fon_sml12	*12×12 1/4角フォント
FONTANK12::	.dc.l	fon_ank12	*12×24 半角フォント
FONTKNJ24::	.dc.l	fon_knj24	*24×24 全角フォント

FONTKNJ16A::	.dc.l	fon_knj16	 *16×16 全角(ＪＩＳ非漢字)
FONTKNJ16B::	.dc.l	fon_knj16+$5e00	 *16×16 全角(ＪＩＳ第１水準漢字)
FONTKNJ16C::	.dc.l	fon_knj16+$1d600 *16×16 全角(ＪＩＳ第２水準漢字)

LOGBUFVECT::	.ds.l	1	*CONDRV.SYSのバックログ処理アドレス
CONDFLAG::	.ds.l	1	*CONDRV.SYSのオプションフラグのアドレス
		.if	1
CONDSYSCALL::	.ds.l	1	*CONDRV.SYSのシステムコールのアドレス
		.endif

		.end

* End of File ------------------------- *

*	$Log:	WORK.HA_ $
* Revision 1.2  92/10/28  11:02:56  YuNK
* カーソル表示処理の追加にあわせてワークを増加。
* 
* Revision 1.1  92/09/14  01:16:22  YuNK
* Initial revision
* 
