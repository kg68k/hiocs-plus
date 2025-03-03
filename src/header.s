	.title	HIOCS PLUS (header.s)

*****************************************************************
*	HIOCS version 1.10
*		< HEADER.HAS >
*	$Id: HEADER.HA_ 1.1 92/09/14 01:17:52 YuNK Exp $
*
*		Copyright 1990,91,92  SHARP / Y.Nakamura
*****************************************************************


* Global Symbols --------------------- *

	.xref	dev_strtgy,dev_intrpt


* Text Section ----------------------- *

	.text

*****************************************
*	デバイスヘッダ			*
*****************************************

dev_header::
	.dc.l	-1			*リンクポインタ
	.dc	$c020			*属性(ｷｬﾗｸﾀﾃﾞﾊﾞｲｽ/IOCTRL可/RAW MODE)
	.dc.l	dev_strtgy		*ストラテジルーチンエントリ
	.dc.l	dev_intrpt		*割り込みルーチンエントリ
	.dc.b	'@IOCS   '		*デバイス名

	.end
