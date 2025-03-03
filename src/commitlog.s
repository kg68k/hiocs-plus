;console.s
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

;doscon.s
*	$Log:	DOSCON.HA_ $
* Revision 1.1  92/09/14  01:17:08  YuNK
* Initial revision
* 

;graph.s
*	$Log:	GRAPH.HA_ $
* Revision 1.1  92/09/14  01:17:30  YuNK
* Initial revision
* 

;header.s
*	$Log:	HEADER.HA_ $
* Revision 1.1  92/09/14  01:17:52  YuNK
* Initial revision
* 

;hiocs.equ
*	$Log:	HIOCS.EQ_ $
* Revision 1.9  93/04/02  23:37:44  YuNK
* ラスターコピー処理を改善し，X68030で正常動作するようにした。
* 
* Revision 1.8  93/02/15  00:36:32  YuNK
* CONFIG.SYSの program= 行での登録ができるようにした。
* 
* Revision 1.7  92/11/16  20:06:36  YuNK
* マウス周りの処理の一部変更
* 
* Revision 1.6  92/10/28  10:33:52  YuNK
* ベクタ変更処理の一部変更、カーソル表示処理の変更。
* 
* Revision 1.5  92/10/11  00:27:46  YuNK
* バグ取り
* 
* Revision 1.4  92/09/21  14:47:02  YuNK
* バグ取り
* 
* Revision 1.3  92/09/18  13:26:34  YuNK
* バグ取り
* 
* Revision 1.2  92/09/16  14:47:34  YuNK
* ＳＸウィンドウでマウスが動作しないバグ取り
* 
* Revision 1.1  92/09/14  01:18:10  YuNK
* Initial revision
* 

;hiocs.s
*	$Log:	HIOCS.HA_ $
* Revision 1.6  93/02/15  00:39:30  YuNK
* CONFIG.SYSの program= 行での登録ができるようにした。
* 
* Revision 1.5  92/11/17  23:41:06  YuNK
* 常駐時にマウスデータ送信の終了を待たないようにした
* 
* Revision 1.4  92/11/09  00:09:22  YuNK
* 一部のベクタ変更処理を変更。
* 
* Revision 1.3  92/10/11  00:27:38  YuNK
* 拡張フォント使用時に常駐解除すると、次の常駐時にフォントが崩れるバグを修正
* 
* Revision 1.2  92/09/18  13:39:10  YuNK
* CONDRV.SYS常駐時にTimer-C割り込み処理を変更しないようにした
* 
* Revision 1.1  92/09/14  01:15:02  YuNK
* Initial revision
* 

;mouse.s
*	$Log:	MOUSE.HA_ $
* Revision 1.7  92/11/18  00:12:10  YuNK
* Timer-C処理ルーチンを変更する一部のプログラムとの相性を良くした
* 
* Revision 1.6  92/11/08  22:17:06  YuNK
* マウス送信要求処理を少し変更。
* 
* Revision 1.5  92/10/21  17:08:56  YuNK
* IOCS _MS_LIMITなどでマウスカーソルが残ることがあるバグを修正
* 
* Revision 1.4  92/09/21  14:33:04  YuNK
* 割り込み禁止解除の処理の不都合を修正
* 
* Revision 1.3  92/09/18  13:29:50  YuNK
* IOCS _MS_CURSTが正常に動作しないバグを修正
* 
* Revision 1.2  92/09/16  14:47:58  YuNK
* ＳＸウィンドウでマウスが動作しないバグ取り
* 
* Revision 1.1  92/09/14  01:19:12  YuNK
* Initial revision
* 

;rompatch.s
*	$Log:	ROMPATCH.HA_ $
* Revision 1.1  92/09/14  01:15:56  YuNK
* Initial revision
* 

;work.s
*	$Log:	WORK.HA_ $
* Revision 1.2  92/10/28  11:02:56  YuNK
* カーソル表示処理の追加にあわせてワークを増加。
* 
* Revision 1.1  92/09/14  01:16:22  YuNK
* Initial revision
* 
