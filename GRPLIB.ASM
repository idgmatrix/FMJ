;---------------------------------------
;  Graphics library
;
;  (c) 1995,1996 Mirinae Software, Inc.
;---------------------------------------

	.386

	LOCALS

	include	VGA.INC

PUBLIC	StartOffset
PUBLIC	PageOffset
PUBLIC	map_mask
PUBLIC	erase_flag
PUBLIC	pcx_buffer
PUBLIC	GAMMA
PUBLIC	gammano
PUBLIC	pcxfilename

include	files.ash

; Real Mode Interrupt information structure
RMInfo	struc
	_EDI		dd	0;
	_ESI		dd	0;
	_EBP		dd	0;
reserved_by_system	dd	0;
	_EBX		dd	0;
	_EDX		dd	0;
	_ECX		dd	0;
	_EAX		dd	0;
	cpu_flags	dw      0;
	_ES		dw	0
	_DS		dw	0
	_FS		dw	0
	_GS		dw	0
	_IP		dw      0
	_CS		dw	0
	_SP		dw	0
	_SS		dw	0
RMInfo	ends            ;  50 bytes

DGROUP	GROUP	_DATA,_BSS

_DATA	SEGMENT	PUBLIC DWORD USE32 'DATA'

StartOffset     dd      0               ;view screen page
PageOffset      dd      4B00h           ;active screen page

map_mask 	db      11h 		;map mask reg. value
bit_mask 	db      10000000b 	;bit mask

GAMMA   label   dword                   ;GAMMA correction table
	dd      offset GAMMA0, offset GAMMA1, offset GAMMA2, offset GAMMA3
	dd      offset GAMMA4, offset GAMMA5, offset GAMMA6, offset GAMMA7

gammano dd      7

GAMMA0  label   byte
	include gamma10.dat
GAMMA1  label   byte
	include gamma11.dat
GAMMA2  label   byte
	include gamma12.dat
GAMMA3  label   byte
	include gamma13.dat
GAMMA4  label   byte
	include gamma14.dat
GAMMA5  label   byte
	include gamma15.dat
GAMMA6  label   byte
	include gamma18.dat
GAMMA7  label   byte
	include gamma23.dat

font5	label	byte
include	font5.inc

PCXHDR  label
	maker	db 10		;             // PCX이면 항상 10임.
	version	db 5		;           // PCX 버전.
	code	db 1		;              // RLE 압축이면 1, 아니면 0.
	bpp	db 8		;               // 픽셀당 비트수.
		dw 0,0,319,239	;    // 화면 좌표.
		dw 320,240	;        // 수평 해상도, 수직 해상도.
	pal16	db 48 dup(0)	;         // 16색상.
	vmode	db 0		;             // 비디오 모드 번호.
	nplanes db 1		;           // 컬러 플레인의 개수. 256이면 8임.
	bpl	dw 320		;               // 라인당 바이트 수.
	palinfo	dw 0		;           // 팔레트 정보.
	sresol	dw 0,0		;      // 스캐너의 수평, 수직 해상도.
	unused	db 54 dup(0)	;        // 사용하지 않음.

decoding	db	320*240 dup(?)
		db	320*240 dup(?)
		db	768 dup(?)

pcxfilename	db	"test0000.pcx",0

_DATA	ENDS

_BSS	SEGMENT	PUBLIC DWORD USE32 'BSS'

extrn	PAL	:byte
extrn	PALtmp	:byte

pcx_buffer	db	320*240 dup(?)
erase_flag	db	0

cap_buffer	EQU	pcx_buffer

lstart		dd 0
lstartd		dd 0
read_plane	db 0

RMI	RMInfo	<>

_BSS	ENDS

_TEXT   SEGMENT PUBLIC USE32 DWORD 'CODE'
	ASSUME  cs:_TEXT,ds:DGROUP,es:DGROUP

;-----------------------------
; video mode setting
; input: eax  vmode
;-----------------------------
PUBLIC	vid_mode_
vid_mode_	proc

	pusha

	mov	ebx,eax

	mov	ax,ds
	mov	es,ax

	xor	eax,eax
	mov	edi,OFFSET RMI
	mov	ecx,50
	cld
	rep	stosb

	; Use DMPI call 300h to issue the DOS interrupt 10h
	mov	edi,OFFSET RMI
	mov	[edi]._EAX,ebx		; video mode
	mov	ax,300h
	mov	bl,10h			; interrupt 10h
	mov	bh,0
	mov	cx,0
	int	31h

	popa

	ret

vid_mode_	endp

;------------------------
; 13h plane mode
;------------------------
PUBLIC	xmode
xmode   PROC

;	mov     ax,13h                  ; BIOS call
;	int     10h                     ; Ordinary 320 x 200 MCGA
	mov	eax,13h
	call	vid_mode_

	mov     dx,SC_INDEX             ; Sequencer controller
	mov     ax,0604h                ; 0110b  index 4  Memory mode reg.
	out     dx,ax                   ; |__________ chain 4 bit 0

	mov     dx,SC_INDEX             ;
	mov     ax,0f02h                ; 1111b  index 2  Map mask reg
	out     dx,ax
	mov     edi,SCREEN_OFF          ;
	xor     eax,eax                 ;
	mov     ecx,4000h               ;
	rep     stosd                   ; clean the screen

	mov     dx,CRTC_INDEX           ; CRT controller
	mov     ax,0014h                ; index 14 Underline Location reg.
	out     dx,ax                   ; double word mode bit 0
	mov     ax,0E317h               ; index 17 Mode Control reg.
	out     dx,ax                   ; word/byte mode bit 1 (byte mode)

	ret

xmode   ENDP

;-----------------------------------
;  320 * 240 256 color mode
;-----------------------------------
PUBLIC	mode320X240
mode320X240     PROC

;	mov   ax,0013h                  ; set mode 13h
;	int   10h
	mov	eax,13h
	call	vid_mode_

	mov   dx,SC_INDEX
	mov   ax,0604h
	out   dx,ax                     ; disable chain4 mode
	mov   ax,0F02h
	out   dx,ax                     ; enable writes to all four planes

	mov   edi,SCREEN_OFF            ; now clear all display memory, 8
	xor   eax,eax                   ; clear to zero-value pixels
	mov   ecx,4000h                 ; # of words in display memory
	rep   stosd                     ; clear all of display memory

	mov   ax,0100h
	out   dx,ax                     ; synchronous reset while setting
					; Misc Output for safety, even
					; though clock unchanged

	mov   dx,MISC_OUTPUT
	mov   al,0E3h
	out   dx,al                     ; select 25 MHz dot clock & 60 Hz
					; scanning rate

	mov   dx,SC_INDEX
	mov   ax,0300h
	out   dx,ax                     ; undo reset (restart sequencer)

	mov   dx,CRTC_INDEX             ; reprogram the CRT Controller
	mov   al,11h                    ; VSync End reg contains register
	out   dx,al                     ; write protect bit
	inc   dx                        ; CRT Controller Data register
	in    al,dx                     ; get current VSync End register setting
	and   al,7Fh                    ; remove write protect on various
	out   dx,al                     ; CRTC registers
	dec   dx                        ; CRT Controller Index

	mov   ax,00D06h                 ; set CRT parameters
	out   dx,ax
	mov   ax,03E07h
	out   dx,ax
	mov   ax,04109h
	out   dx,ax
	mov   ax,0EA10h
	out   dx,ax
	mov   ax,0AC11h
	out   dx,ax
	mov   ax,0DF12h
	out   dx,ax
	mov   ax,00014h
	out   dx,ax
	mov   ax,0E715h
	out   dx,ax
	mov   ax,00616h
	out   dx,ax
	mov   ax,0E317h
	out   dx,ax

	ret

mode320X240     ENDP

PUBLIC	SCROFF
SCROFF: CLI
	MOV     AL,1
	MOV     DX,03C4H
	OUT     DX,AL
	INC     DX
	IN      AL,DX
	OR      AL,20H
	OUT     DX,AL
	STI
	RET
	;
PUBLIC	SCRON
SCRON:  CLI
	MOV     AL,1
	MOV     DX,03C4H
	OUT     DX,AL
	INC     DX
	IN      AL,DX
	AND     AL,0DFH
	OUT     DX,AL
	STI
	RET

;------------------------------------
; wait for start of vertical retrace
;------------------------------------
PUBLIC	wait_vrt
wait_vrt       PROC

	push    eax
	push    edx

	mov     dx,3dah
@@wvrt1:
	in      al,dx
	test    al,8
	je      @@wvrt1
@@wvrt2:
	in      al,dx
	test    al,8
	jne     @@wvrt2

	pop     edx
	pop     eax

	ret

wait_vrt        ENDP

;--------------------------------
; clean active Page (not visual)
;--------------------------------
PUBLIC	clean
clean   PROC
	push    es

	mov     ax,ds
	mov     es,ax

	mov     dx,SC_INDEX
	mov     ax,0f02h
	out     dx,ax

	mov     edi,SCREEN_OFF
	add     edi,PageOffset

	cld
	xor     eax,eax
	mov     ecx,1000h
	rep     stosd

	pop     es

	ret

clean   ENDP

;--------------------------------
; erase
;--------------------------------
PUBLIC	erase
erase   PROC
	cmp	erase_flag,0
	jle	@@quit
	push    es

	mov     ax,ds
	mov     es,ax

	mov     dx,SC_INDEX
	mov     ax,0f02h
	out     dx,ax

	mov     edi,SCREEN_OFF
	add	edi,PageOffset
	add	edi,16

	cld

	xor     eax,eax
	mov	ecx,240
@@next:
	push	ecx

	mov     ecx,16
	rep     stosd

	add	edi,16

	pop	ecx
	dec	ecx
	jnz	@@next

	pop     es

	dec	erase_flag

@@quit:
	ret

erase   ENDP

;------------------------
; Page flip
;------------------------
PUBLIC	showp
showp   PROC

	push    ebx
	push    ecx
	push    edx
	push    eax

	mov     bl,START_ADDRESS_LOW
	mov     bh,Byte ptr [StartOffset]
	mov     cl,START_ADDRESS_HIGH
	mov     ch,Byte ptr [StartOffset+1]
	mov     dx,CRTC_INDEX
	mov     ax,bx
	out     dx,ax
	mov     ax,cx
	out     dx,ax

	cmp     PageOffset,0
	jne     SHORT @@Page0
	mov     PageOffset,4B00h
	mov     StartOffset,4B00h
	pop     eax
	pop     edx
	pop     ecx
	pop     ebx

	ret

@@Page0:
	mov     PageOffset,0
	mov     StartOffset,0
	pop     eax
	pop     edx
	pop     ecx
	pop     ebx

	ret

showp   ENDP

;------------------------
; Page flip
;------------------------
PUBLIC	show_p
show_p	PROC

	push    ebx
	push    ecx
	push    edx
	push    eax

	mov     bl,START_ADDRESS_LOW
	mov     bh,Byte ptr [StartOffset]
	mov     cl,START_ADDRESS_HIGH
	mov     ch,Byte ptr [StartOffset+1]
	mov     dx,CRTC_INDEX
	mov     ax,bx
	out     dx,ax
	mov     ax,cx
	out     dx,ax

	cmp     PageOffset,0
	jne     SHORT @@Page0
	mov     PageOffset,4000h
	mov     StartOffset,4000h
	pop     eax
	pop     edx
	pop     ecx
	pop     ebx

	ret

@@Page0:
	mov     PageOffset,0
	mov     StartOffset,0
	pop     eax
	pop     edx
	pop     ecx
	pop     ebx

	ret

show_p	ENDP

;---------------------------
; set palette registers
; esi : palette offset
;---------------------------
PUBLIC	set_palette
set_palette     PROC

	call	wait_vrt

	mov     al,0                    ;
	mov     dx,3c8h                 ; I/O port of palette reg
	out     dx,al                   ; 0 - 255

	mov     dx,3c9h                 ;
	mov     ecx,768                 ; R G B * 256
@invid:
	lodsb
	out     dx,al

	loop    @invid

	ret
set_palette      endp

;---------------------------
;  GAMMA
;   esi :  Org. palette
;   edi :  gamma corrected palette
;   edx  : gamma table
;---------------------------
PUBLIC	gamma_correction
gamma_correction        PROC

	push	edi

	mov     ecx,768
@@npal:
	mov     bl,byte ptr[esi]
	movzx   ebx,bl
	mov     al,[edx][ebx]
	mov     byte ptr[edi],al

	inc     esi
	inc     edi

	loop    @@npal

	pop	esi
	call    set_palette

	ret

gamma_correction        ENDP

;---------------------------
;  GAMMA  for C
;   eax :  Org. palette
;   edx  : gamma no
;---------------------------
PUBLIC	Gamma_
Gamma_	PROC

	pushad

	mov	edx,GAMMA[edx*4]
	mov	esi,eax
	mov	edi,OFFSET PALtmp
	push	edi

	mov     ecx,768
@@npal:
	mov     bl,byte ptr[esi]
	movzx   ebx,bl
	mov     al,[edx][ebx]
	mov     byte ptr[edi],al

	inc     esi
	inc     edi

	loop    @@npal

	pop	esi
	call	set_palette

	popad

	ret

Gamma_	ENDP

;-------------------------
; eax : X   edx : Y
; bl : color
;-------------------------
PUBLIC	put_pixel
put_pixel	PROC
	push	ecx

	mov     map_mask,11h
	mov     ecx,eax
	and     ecx,3
	rol     map_mask,cl

	shr     eax,2                   ; 3  X / 4
	lea     edx,[edx * 8]           ; 2  Y * 8
	lea     edx,[edx * 2]           ; 2  Y * 8 * 2
	lea     edx,[edx * 4][edx]      ; 2  Y * 8 * 2 * 5
	add     eax,edx                 ; 2  X / 4 + Y * 80
					; total 11 clock

	mov     edi,eax
	add     edi,SCREEN_OFF          ;Calculate Init Pixel on dest.
	add     edi,PageOffset          ;

	mov     dx,SC_INDEX             ;Let's prepare SC_INDEX
	mov     al,MAP_MASK             ;For the MAP_MASK
	out     dx,al                   ;.....

	mov     dx,SC_INDEX+1           ;set Map Mask reg.
	mov     al,map_mask             ;
	out     dx,al                   ;

	mov	byte ptr[edi],bl

	pop	ecx
	ret

put_pixel	ENDP

;-------------------------------------
; esi : file name ( no header )
; using in MCGA mode
;-------------------------------------
PUBLIC	load_put_PCX
load_put_PCX    PROC

loading:
	mov	edi,OFFSET pcx_buffer
	push	edi
	mov     ecx,64000
	call    load_file

encoding:
	pop	esi
	mov     edi,0A0000h
@@next:
	mov     al,[esi]
	cmp     al,0C0h
	jbe     SHORT @@norpt
	and     al,3Fh
	movzx   ecx,al
	inc     esi
	mov     al,[esi]
@@rpt:
	mov     [edi],al
	inc     edi
	dec	ecx
	jnz	SHORT @@rpt
	jmp     SHORT @@chk
@@norpt:
	mov     [edi],al
	inc     edi
@@chk:
	inc     esi
	cmp     edi,64000 + 0A0000h
	jb      SHORT @@next
;;;-------
	mov     edi,offset PAL
	mov     ecx,768
	inc     esi
@@nextp:
	mov     al,[esi]
	shr     al,2
	mov     [edi],al
	inc     esi
	inc     edi
	dec	ecx
	jnz	@@nextp
;;;------------
	mov     esi,offset PAL
	call    set_palette

	mov     ebx,gammano
	mov     edx,GAMMA[ebx * 4]
	mov     esi,offset PAL
	mov     edi,offset PALtmp
	call    gamma_correction

	ret

load_put_PCX    ENDP

;-------------------------------------
; esi : file name ( no header )
; using in X mode
;-------------------------------------
PUBLIC	load_put_PCXX
load_put_PCXX	PROC

	mov	edi,OFFSET decoding
	push	edi
	mov     ecx,64000
	call    load_file

	pop	esi
	mov     edi,OFFSET pcx_buffer
@@next:
	mov     al,[esi]
	cmp     al,0C0h
	jbe     SHORT @@norpt
	and     al,3Fh
	movzx   ecx,al
	inc     esi
	mov     al,[esi]
@@rpt:
	mov     [edi],al
	inc     edi
	dec	ecx
	jnz	SHORT @@rpt
	jmp     SHORT @@chk
@@norpt:
	mov     [edi],al
	inc     edi
@@chk:
	inc     esi
	cmp     edi,64000 + OFFSET pcx_buffer
	jb      SHORT @@next
;;;-------
	mov     edi,offset PAL
	mov     ecx,768
	inc     esi
@@nextp:
	mov     al,[esi]
	shr     al,2
	mov     [edi],al
	inc     esi
	inc     edi
	dec	ecx
	jnz	@@nextp
;;;------------

	mov	map_mask,11h

	mov	esi,0
	mov     edi,SCREEN_OFF          ;Calculate Init Pixel on dest.
	add     edi,8000h       	;
	mov     lstart,edi

	mov     dx,SC_INDEX             ;Let's prepare SC_INDEX
	mov     al,MAP_MASK             ;For the MAP_MASK
	out     dx,al                   ;.....

	mov	ecx,320
@@nextX:
	mov     dx,SC_INDEX+1           ;set Map Mask reg.
	mov     al,map_mask             ;
	out     dx,al                   ;

	mov	edi,lstart

	push	ecx
	mov	ecx,200
@@nextY:
	mov	al,pcx_buffer[esi]
	mov	[edi],al

	add	esi,320
	add	edi,80

	dec	ecx
	jnz	@@nextY

	sub	esi,320*200
	add	esi,1

	rol     map_mask,1
	adc     lstart,0

	pop	ecx
	dec	ecx
	jnz	@@nextX

	mov     esi,offset PAL
	call    set_palette

	mov     ebx,gammano
	mov     edx,GAMMA[ebx * 4]
	mov     esi,offset PAL
	mov     edi,offset PALtmp
	call    gamma_correction

	ret

load_put_PCXX	ENDP

;---------------------------------------
; put picture
;---------------------------------------
PUBLIC	put_pic
put_pic PROC

	mov     dx,GRP_INDEX            ;graphic controller
	mov     ax,4105h                ;index 5 Mode reg.
	out     dx,ax                   ;256 color write mode 1

	mov     dx,SC_INDEX             ;SC_INDEX
	mov     ax,0f02h                ;For the MAP_MASK 1111b
	out     dx,ax                   ;all four planes enable

	mov     edi,SCREEN_OFF           ;Calculate Init Pixel on dest.
	add     edi,PageOffset           ;

	mov     esi,SCREEN_OFF           ;Calculate Init Pixel on source
	add     esi,8000h               ; Page 2

	cld

	mov     ecx,80*200              ;  (320/4) * 55
	rep     movsb

	mov     dx,GRP_INDEX            ;graphic controller
	mov     ax,4005h                ;index 5 Mode reg.
	out     dx,ax                   ;256 color write mode 0

	ret

put_pic ENDP

;-------------------------------------
; esi : file name ( no header )
; using in MCGA mode
;-------------------------------------
PUBLIC	decoding_PCX
decoding_PCX    PROC

	pushad

	mov	esi,0A0000h
	mov	lstart,esi
	mov	edi,OFFSET cap_buffer
	mov	lstartd,edi

	mov     map_mask,11h
	mov     read_plane,0

	mov     ecx,320
@@x:    ; X-offset loop

	MOV     DX,3CEH
	MOV     AL,4
	OUT     DX,AL        ;
	INC     DX
	IN      AL,DX
	AND     AL,NOT  03H
	OR      AL,read_plane
	OUT     DX,AL         ;
	inc     read_plane
	and     read_plane,3

	mov     dx,SC_INDEX             ;Let's prepare SC_INDEX
	mov     al,MAP_MASK             ;For the MAP_MASK
	mov     ah,map_mask             ;set write map mask
	out     dx,ax                   ;

	mov     esi,lstart
	mov     edi,lstartd

	push    ecx
	mov     ecx,240
@@y:    ; Y-offset loop

	mov     al,byte ptr[esi]
	mov     byte ptr[edi],al

	add     esi,80
	add     edi,320

	dec     ecx
	jnz     @@y

	rol     map_mask,1
	adc     lstart,0

	inc	lstartd

	pop     ecx
	dec     ecx
	jnz     @@x

;;;;;;;;;;

	mov     esi,OFFSET cap_buffer
	mov	edi,OFFSET decoding

	mov	ecx,240
@@loopY:

	mov	ah,0C0h
	mov	bh,1
	mov	dl,0

	mov	al,[esi] 	; the First Pixel of line
	inc	esi

	push	ecx
	mov	ecx,319
@@loopX:

	mov	bl,[esi]
	inc	esi

	cmp	al,bl
	jne	@@rptend

@@rptcnt:
	mov	dl,1
	inc	bh
	cmp	bh,3Fh
	jae     @@write_rpt
	jmp	SHORT @@rpt

@@rptend:
	cmp	dl,0
	jnz	@@write_rpt

@@write_one:
	cmp	al,0C0h
	jb	@@normal
	mov	byte ptr[edi],0C1h
	inc	edi
@@normal:
	mov	[edi],al
	inc	edi
	jmp	SHORT @@renew

@@write_rpt:
	add	ah,bh
	mov	[edi],ah
	inc	edi
	mov	[edi],al
	inc	edi

@@renew:
	mov	al,bl
	mov	dl,0

	mov	ah,0C0h
	mov	bh,1

@@rpt:
	dec	ecx
	jnz	@@loopX

	cmp	dl,1
	jne 	@@out
	add	ah,bh
	mov	[edi],ah
	inc	edi
	mov	[edi],al
	inc	edi
	mov	dl,0
	jmp	@@out2
@@out:
	cmp	bl,0C0h
	jb	@@normal2

	mov	byte ptr[edi],0C1h
	inc	edi
@@normal2:
	mov	[edi],bl
	inc	edi

@@out2:
	pop	ecx
	dec	ecx
	jnz	@@loopY


@@palette:
	mov	esi,OFFSET PAL
	mov	byte ptr [edi],12	;PALID
	inc	edi
	mov	ecx,768
@@npal:
	mov	al,[esi]
	shl	al,2
	mov	[edi],al

	inc	esi
	inc	edi

	dec	ecx
	jnz	@@npal

	sub	edi,OFFSET decoding
	add	edi,128

	mov	ecx,edi

	mov	esi,OFFSET PCXHDR
	mov	edi,OFFSET pcxfilename
	call	save_file

	popad

	ret

decoding_PCX    ENDP

;-------------------------
; eax : X   edx : Y
; bl : ASCII
; cl : color
;-------------------------
PUBLIC	put_ch
put_ch	PROC

	movzx	ebx,bl
	sub	ebx,32
	lea	esi,font5[ebx*4][ebx]

	mov	bl,cl

	mov     map_mask,11h
	mov     ecx,eax
	and     ecx,3
	rol     map_mask,cl

	mov	bit_mask,10000000b

	shr     eax,2                   ; 3  X / 4
	lea     edx,[edx * 8]           ; 2  Y * 8
	lea     edx,[edx * 2]           ; 2  Y * 8 * 2
	lea     edx,[edx * 4][edx]      ; 2  Y * 8 * 2 * 5
	add     eax,edx                 ; 2  X / 4 + Y * 80
					; total 11 clock

	mov     edi,eax
	add     edi,SCREEN_OFF          ;Calculate Init Pixel on dest.
	add     edi,PageOffset          ;

	mov     dx,SC_INDEX             ;Let's prepare SC_INDEX
	mov     al,MAP_MASK             ;For the MAP_MASK
	out     dx,al                   ;.....

	mov     dx,SC_INDEX+1           ;set Map Mask reg.
	mov     al,map_mask             ;
	out     dx,al                   ;

	mov	ecx,5
@@next:
	mov     dx,SC_INDEX+1           ;set Map Mask reg.
	mov     al,map_mask             ;
	out     dx,al                   ;

	mov	al,byte ptr[esi+4]
	test	al,bit_mask
	jz	@@skip1
	mov	byte ptr[edi],bl
@@skip1:
	mov	al,byte ptr[esi+3]
	test	al,bit_mask
	jz	@@skip2
	mov	byte ptr[edi+80],bl
@@skip2:
	mov	al,byte ptr[esi+2]
	test	al,bit_mask
	jz	@@skip3
	mov	byte ptr[edi+80*2],bl
@@skip3:
	mov	al,byte ptr[esi+1]
	test	al,bit_mask
	jz	@@skip4
	mov	byte ptr[edi+80*3],bl
@@skip4:
	mov	al,byte ptr[esi]
	test	al,bit_mask
	jz	@@skip5
	mov	byte ptr[edi+80*4],bl
@@skip5:

	shr	bit_mask,1

	rol	map_mask,1
	adc	edi,0

	dec	ecx
	jnz	@@next

	ret

put_ch	ENDP

;-------------------------
; eax : X   edx : Y
; ebx : pointer of ASCIIZ
; cl : color
;-------------------------
PUBLIC	put_string
put_string	PROC
@@next:
	mov	ch,byte ptr[ebx]
	cmp	ch,0
	jz	SHORT @@quit

	push	eax
	push	edx
	push	ebx
	push	ecx
	mov	bl,ch
	call	put_ch
	pop	ecx
	pop	ebx
	pop	edx
	pop	eax

	add	eax,6
	inc	ebx

	jmp     SHORT @@next

@@quit:
	ret

put_string	ENDP

_TEXT   ENDS
	END
