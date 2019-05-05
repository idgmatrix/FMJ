;=========================================;
;  F.M.J. rotated sprite routine          ;
;                                         ;
;=========================================;
	.386

	LOCALS

	include	VGA.INC

WIDE 	equ	46
HWIDE   equ	23

DGROUP	GROUP	_DATA,_BSS

_DATA	SEGMENT	PUBLIC DWORD USE32 'DATA'

extrn	StartOffset:	dword
extrn	PageOffset:	dword

extrn	Lbound:		dword
extrn	Rbound:		dword
extrn	Ubound:		dword
extrn	Dbound:		dword

extrn	eye_x:		word
extrn	eye_x_:		dword
extrn	eye_y:		word
extrn	eye_y_:		dword
extrn	eye_z:		word
extrn	eye_zd:		dword

extrn	eye_th:		byte
extrn	d_th:		byte
extrn	dif:		word

extrn	shadow_d:	word
extrn	shadow_dx:	word
extrn	shadow_dy:	word

extrn	pers:		word

extrn	mapw_z:		word
extrn	mapw_zd:	dword

extrn	map_mask:	byte
extrn	read_plane:	byte
extrn	SIN:		word

extrn _XC_ :dword
extrn _YC_ :dword

_DATA	ENDS

_BSS	SEGMENT	PUBLIC DWORD USE32 'BSS'

extrn	ey1:	word
extrn	ey2:	word

extrn	x1:	word
extrn	y1:	word
extrn	z1:	word
extrn	x2:	word
extrn	y2:	word
extrn	z2:	word

extrn	xx_:	dword
extrn	yy_:	dword
extrn	zz_:	dword

extrn	ey1_:	dword
extrn	ey2_:	dword

extrn	x1_:    dword
extrn	y1_:    dword
extrn	z1_:    dword
extrn	x2_:    dword
extrn	y2_:    dword
extrn	z2_:    dword

extrn	xa_:    dword
extrn	ya_:    dword

extrn	lstart:		dword

extrn	sine:		word
extrn	cosine:		word

extrn	sined:		dword
extrn	cosined:	dword

extrn	TIL_load:	byte
extrn	PAL:		byte
;extrn	ATTR:		byte
extrn	TIL:		byte

extrn	MAP_load:	byte
extrn	TEXMAP:		dword
extrn	TEXMAPADD:	dword

extrn	DARKER_TABLE:	byte

PUBLIC	obj_x_
PUBLIC	obj_y_

spr_pointer	dd	0

xxx	dw	0
yyy	dw	0
zzz	dw	0
rx 	dw	0
ry 	dw	0
rx_ 	dd	0
ry_ 	dd	0
rz 	dw	0

xxxx	dd	0
yyyy	dd	0
zzzz	dd	0

xl	dd	0
xleft	dd	0
xright	dd	0
xr	dd	0
yu	dd	0
yup	dd	0
ydown	dd	0

XD	dd	0
YD      dd	0

ya	dd	0
yb      dd	0
dii     dd	0
xdd_    dd	0
ydd_    dd	0

xdd     dw	0
ydd     dw	0
ydu     dw	0
yinc    dw	0
y_d     dw	0

sx      dd      0
sy      dd      0
sxsy    dd      0
sxq     dd      0
sy80    dd      0

sx_start	dd	0
sy_start	dd	0

hlength		dd	0
vlength		dd	0
_vlength	dd	0

_vline_		dd	0

put_RT		dd	0
obj_vth		dd	0
obj_x_		dd	0
obj_y_		dd	0

_BSS	ENDS

_TEXT	SEGMENT	PUBLIC DWORD USE32 'CODE'
	ASSUME	cs:_TEXT,ds:DGROUP,ss:DGROUP
;--------------------------------------
; put sprite
; esi : sprite
; eax, edx : X, Y
;--------------------------------------
PUBLIC	put_spr
put_spr PROC

	push    eax
	push    ecx
	push    edx

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
	mov     lstart,edi

	movzx   eax,word ptr[esi]       ;sx
	mov     sx,eax                  ;
	shr     eax,2                   ;
	mov     sxq,eax                 ;sxq = sx / 4

	movzx   eax,word ptr[esi+2]     ;sy
	mov     sy,eax                  ;
	mul     sx                      ;
	mov     sxsy,eax                ;sxsy = sx * sy

	mov     eax,80                  ;
	mul     sy                      ;
	mov     sy80,eax                ;sy80 = sy * 80

	mov     dx,SC_INDEX             ;Let's prepare SC_INDEX
	mov     al,MAP_MASK             ;For the MAP_MASK
	out     dx,al                   ;.....

	xor     ebp,ebp

	cmp     sxq,0
	je      @@pppp

	mov     ecx,4
@@nextp: ; 4-planes loop
	mov     dx,SC_INDEX+1           ;set Map Mask reg.
	mov     al,map_mask             ;
	out     dx,al                   ;

	xor     ebx,ebx
	add     ebx,ebp

	mov     edi,lstart

	push    ecx
	mov     ecx,sxq
@@x:    ; X-offset loop

	push    ecx
	mov     ecx,sy
@@y:    ; Y-offset loop

	mov     al,byte ptr[esi+ebx+4]
	cmp     al,0
	jz      SHORT @@skip0
	mov     byte ptr[edi],al
@@skip0:
	add     ebx,sx
	add     edi,80
	dec     ecx
	jnz     @@y

	sub     ebx,sxsy
	add     ebx,4
	sub     edi,sy80
	add     edi,1

	pop     ecx
	dec     ecx
	jnz     @@x

	rol     map_mask,1
	adc     lstart,0
	add     ebp,1
	pop     ecx
	dec     ecx
	jnz     @@nextp

;;;;;-------------------
@@pppp:
	mov     ecx,sx
	and     ecx,3
	jz      SHORT @@here

	mov     ebx,sx
	sub     ebx,ecx

	ror     map_mask,1
	jc      SHORT @@noo
	sub     edi,1
@@noo:
	rol     map_mask,1

@@x1:
	mov     al,map_mask                 ;
	out     dx,al                   ;

	push    ecx
	mov     ecx,sy
@@y1:    ; Y-offset loop

	mov     al,byte ptr[esi+ebx+4]
	cmp     al,0
	jz      SHORT @@skip00
	mov     byte ptr[edi],al
@@skip00:
	add     ebx,sx
	add     edi,80
	dec     ecx
	jnz     @@y1

	sub     ebx,sxsy
	add     ebx,1
	sub     edi,sy80

	rol     map_mask,1
	adc     edi,0

	pop     ecx
	dec     ecx
	jnz    @@x1

@@here:
	pop     edx
	pop     ecx
	pop     eax
	ret

put_spr ENDP

;--------------------------------------
; put shadow
; esi : sprite
; eax, edx : X, Y
;--------------------------------------
PUBLIC	put_shadow
put_shadow      PROC

	push    eax
	push    ecx
	push    edx

	mov     map_mask,11h
	mov     ecx,eax
	and     ecx,3
	rol     map_mask,cl
	mov     read_plane,cl

	shr     eax,2                   ; 3  X / 4
	lea     edx,[edx * 8]           ; 2  Y * 8
	lea     edx,[edx * 2]           ; 2  Y * 8 * 2
	lea     edx,[edx * 4][edx]      ; 2  Y * 8 * 2 * 5
	add     eax,edx                 ; 2  X / 4 + Y * 80
					; total 11 clock

	mov     edi,eax
	add     edi,SCREEN_OFF          ;Calculate Init Pixel on dest.
	add     edi,PageOffset          ;
	mov     lstart,edi

	movzx   eax,word ptr[esi]       ;sx
	mov     sx,eax                  ;
	shr     eax,2                   ;
	mov     sxq,eax                 ;sxq = sx / 4

	movzx   eax,word ptr[esi+2]     ;sy
	mov     sy,eax                  ;
	mul     sx                      ;
	mov     sxsy,eax                ;sxsy = sx * sy

	mov     eax,80                  ;
	mul     sy                      ;
	mov     sy80,eax                ;sy80 = sy * 80

	mov     dx,SC_INDEX             ;Let's prepare SC_INDEX
	mov     al,MAP_MASK             ;For the MAP_MASK
	out     dx,al                   ;.....

	xor     ebp,ebp

	cmp     sxq,0
	je      @@pppp

	mov     ecx,4
@@nextp: ; 4-planes loop
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

	xor     ebx,ebx
	add     ebx,ebp

	mov     edi,lstart

	push    ecx
	mov     ecx,sxq
@@x:    ; X-offset loop

	push    ecx
	mov     ecx,sy
@@y:    ; Y-offset loop

	mov     al,byte ptr[esi+ebx+4]
	cmp     al,0
	jz      SHORT @@skip0
	xor     eax,eax
	mov     al,byte ptr[edi]
	mov   	al,DARKER_TABLE[eax]
	mov     byte ptr[edi],al
@@skip0:
	add     ebx,sx
	add     edi,80
	dec     ecx
	jnz     @@y

	sub     ebx,sxsy
	add     ebx,4
	sub     edi,sy80
	add     edi,1

	pop     ecx
	dec     ecx
	jnz     @@x

	rol     map_mask,1
	adc     lstart,0
	add     ebp,1
	pop     ecx
	dec     ecx
	jnz     @@nextp

;;;;;-------------------
@@pppp:
	mov     ecx,sx
	and     ecx,3
	jz      @@here

	mov     ebx,sx
	sub     ebx,ecx

	ror     map_mask,1
	jc      SHORT @@noo
	sub     edi,1
@@noo:
	rol     map_mask,1

@@x1:
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

	push    ecx
	mov     ecx,sy
@@y1:    ; Y-offset loop

	mov     al,byte ptr[esi+ebx+4]
	cmp     al,0
	jz      SHORT @@skip00
	xor     eax,eax
	mov     al,byte ptr[edi]
	mov     al,DARKER_TABLE[eax]
	mov     byte ptr[edi],al
@@skip00:
	add     ebx,sx
	add     edi,80
	dec     ecx
	jnz     @@y1

	sub     ebx,sxsy
	add     ebx,1
	sub     edi,sy80

	rol     map_mask,1
	adc     edi,0

	pop     ecx
	dec     ecx
	jnz    @@x1

@@here:
	pop     edx
	pop     ecx
	pop     eax
	ret

put_shadow	ENDP

;---------------------------------
; input & output
;  eax : X
;  edx : Y
;---------------------------------
PUBLIC	world2eye
world2eye       proc

	push	esi
	push	edi

	mov     esi,eax
	mov     edi,edx

	movsx   ebx,eye_th              ;
	and     ebx,255                 ; sine table indexing
	shl     ebx,1                   ; for word ptr
	movsx	edx,SIN[ebx]            ; sin(eye_th)
	mov     sined,edx               ;

	movsx   ebx,eye_th              ;
	add     ebx,64                  ; cosine
	and     ebx,255                 ;
	shl     ebx,1                   ;
	movsx   edx,SIN[ebx]            ; dx = cos(eye_th)
	mov     cosined,edx

	mov     eax,esi           	;
	sub     eax,eye_x_              ; rx = x - eye_x
	mov	ebx,128
	imul	ebx
	idiv	eye_zd
	mov     rx_,eax

	mov     eax,edi   ;
	sub     eax,eye_y_                ; ry = y - eye_y
	mov	ebx,128
	imul	ebx
	idiv	eye_zd
	mov     ry_,eax

	mov	ebx,32767
	mov     eax,rx_                   ; rx * cos(eye_th)
	imul    cosined                  ;
	idiv	ebx
	mov     xxxx,eax

	mov     eax,ry_                   ;
	imul    sined                    ; ry * sin(eye_th)
	idiv	ebx
	sub     xxxx,eax          ;

	mov     eax,ry_                   ; ry * cos(eye_th)
	imul    cosined
	idiv	ebx
	mov     yyyy,eax

	mov     eax,rx_                   ;
	imul    sined
	idiv	ebx		                  ; rx * sin(eye_th)
	add     yyyy,eax          ;

	mov   	eax,xxxx
	mov   	edx,yyyy

	pop	edi
	pop	esi

	ret

world2eye       endp

;---------------------------------
; input & output
;  eax : X_
;  edx : Y_
;---------------------------------
PUBLIC	world2map
world2map       PROC

	push	esi
	push	edi

	mov     esi,eax
	mov     edi,edx

	movsx   ebx,eye_th              ;
	and     ebx,255                 ; sine table indexing
	shl     ebx,1                   ; for word ptr
	movsx	edx,SIN[ebx]            ; sin(eye_th)
	mov     sined,edx               ;

	movsx   ebx,eye_th              ;
	add     ebx,64                  ; cosine
	and     ebx,255                 ;
	shl     ebx,1                   ;
	movsx   edx,SIN[ebx]            ; dx = cos(eye_th)
	mov     cosined,edx

	mov     eax,esi           	;
	sub     eax,eye_x_              ; rx = x - eye_x
	mov	ebx,128
	imul	ebx
	idiv	mapw_zd
	mov     rx_,eax

	mov     eax,edi   ;
	sub     eax,eye_y_                ; ry = y - eye_y
	mov	ebx,128
	imul	ebx
	idiv	mapw_zd
	mov     ry_,eax

	mov	ebx,32767
	mov     eax,rx_                   ; rx * cos(eye_th)
	imul    cosined                  ;
	idiv	ebx
	mov     xxxx,eax

	mov     eax,ry_                   ;
	imul    sined                    ; ry * sin(eye_th)
	idiv	ebx
	sub     xxxx,eax          ;

	mov     eax,ry_                   ; ry * cos(eye_th)
	imul    cosined
	idiv	ebx
	mov     yyyy,eax

	mov     eax,rx_                   ;
	imul    sined
	idiv	ebx		                  ; rx * sin(eye_th)
	add     yyyy,eax          ;

	mov   	eax,xxxx
	mov   	edx,yyyy

	pop	edi
	pop	esi

	ret

world2map       ENDP

;---------------------------------
; vertical draw for normal sprite
;---------------------------------
vline   PROC

	push    ebp
	push    ecx

	mov   	eax,ebp
	shl     eax,16
	imul    eye_zd
	mov     ebx,128
	idiv    ebx
	mov     xx_,eax

	mov     eax,yu
	shl     eax,16
	imul    eye_zd
	idiv    ebx
	mov     ey1_,eax

	mov     eax,HWIDE
	shl     eax,16
	imul    eye_zd
	idiv    ebx
	mov     ey2_,eax

	movzx   ebx,eye_th              ;
	add	ebx,obj_vth
	and     ebx,255                 ; sine table indexing
	shl     ebx,1                   ; for word ptr
	movsx   edx,SIN[ebx]            ; sin(eye_th)
	mov     sined,edx               ;

	movzx   ebx,eye_th               ;
	add	ebx,obj_vth
	add     ebx,64                   ; cosine
	and     ebx,255                  ;
	shl     ebx,1                    ;
	movsx   edx,SIN[ebx]              ; dx = cos(eye_th)
	mov     cosined,edx

; x1, y1
	mov     ebx,32767

	mov     eax,xx_                 ; ey1 * cos(eye_th)
	imul    cosined                  ;
	idiv    ebx
	mov     x1_,eax

	mov     eax,ey1_                ;
	imul    sined                   ; xx * sin(eye_th)
	idiv    ebx
	add     x1_,eax

	mov     eax,ey1_                ; xx * cos(eye_th)
	imul    cosined
	idiv    ebx
	mov     y1_,eax

	mov     eax,xx_                 ;
	imul    sined                   ; ex1 * sin(eye_th)
	idiv    ebx
	sub     y1_,eax

; x2, y2
	mov     eax,xx_                   ; ex2 * cos(eye_th)
	imul    cosined                 ;
	idiv    ebx
	mov     x2_,eax

	mov     eax,ey2_                  ;
	imul    sined                   ; xx * sin(eye_th)
	idiv    ebx
	add     x2_,eax

	mov     eax,ey2_                ; xx * cos(eye_th)
	imul    cosined
	idiv    ebx
	mov     y2_,eax

	mov     eax,xx_                   ;
	imul    sined                   ; ex2 * sin(eye_th)
	idiv    ebx
	sub     y2_,eax

;;;;;;;;;
	mov     eax,x2_
	sub     eax,x1_
	cdq
	mov     ebx,_vlength
	idiv    ebx
	mov     xa_,eax

	mov     eax,y2_
	sub     eax,y1_
	cdq
	idiv    ebx
	mov     ya_,eax

	mov     edi,lstart

	mov     esi,x1_
	add	esi,_XC_
	mov     ebp,y1_
	add	ebp,_YC_

	mov     ecx,vlength
	align 4
@@nextp:
	;calculate SPRITE coordinator
	mov     edx,ebp
	sar     edx,16
	test	dx,NOT 31
	jnz	SHORT @@skip
	and     edx,31  ;;;;;;
	shl     edx,5   ;;;;;     ;y * 32

	mov     ebx,esi
	sar     ebx,16
	test	bx,NOT 31
	jnz	SHORT @@skip
	and     ebx,31  ;;;;;;;
	add     ebx,edx                 ;ebx : offset of tile data

	add	ebx,[spr_pointer]

	mov     al,[ebx+4]   ;load color
	cmp	al,0
	jz	@@skip
	mov     byte ptr[edi],al        ;
@@skip:
	add     edi,80

	add     esi,xa_
	add     ebp,ya_

	dec     ecx
	jnz     @@nextp

	pop     ecx
	pop     ebp

	ret

vline   ENDP

;---------------------------------
; vertical draw for shadow sprite
;---------------------------------
vlines	PROC

	push    ebp
	push    ecx

	mov   	eax,ebp
	shl     eax,16
	imul    eye_zd
	mov     ebx,128
	idiv    ebx
	mov     xx_,eax

	mov     eax,yu
	shl     eax,16
	imul    eye_zd
	idiv    ebx
	mov     ey1_,eax

	mov     eax,HWIDE
	shl     eax,16
	imul    eye_zd
	idiv    ebx
	mov     ey2_,eax

	movzx   ebx,eye_th              ;
	add	ebx,obj_vth
	and     ebx,255                 ; sine table indexing
	shl     ebx,1                   ; for word ptr
	movsx   edx,SIN[ebx]            ; sin(eye_th)
	mov     sined,edx               ;

	movzx   ebx,eye_th               ;
	add	ebx,obj_vth
	add     ebx,64                   ; cosine
	and     ebx,255                  ;
	shl     ebx,1                    ;
	movsx   edx,SIN[ebx]              ; dx = cos(eye_th)
	mov     cosined,edx

; x1, y1
	mov     ebx,32767

	mov     eax,xx_                 ; ey1 * cos(eye_th)
	imul    cosined                  ;
	idiv    ebx
	mov     x1_,eax

	mov     eax,ey1_                ;
	imul    sined                   ; xx * sin(eye_th)
	idiv    ebx
	add     x1_,eax

	mov     eax,ey1_                ; xx * cos(eye_th)
	imul    cosined
	idiv    ebx
	mov     y1_,eax

	mov     eax,xx_                 ;
	imul    sined                   ; ex1 * sin(eye_th)
	idiv    ebx
	sub     y1_,eax

; x2, y2
	mov     eax,xx_                   ; ex2 * cos(eye_th)
	imul    cosined                 ;
	idiv    ebx
	mov     x2_,eax

	mov     eax,ey2_                  ;
	imul    sined                   ; xx * sin(eye_th)
	idiv    ebx
	add     x2_,eax

	mov     eax,ey2_                ; xx * cos(eye_th)
	imul    cosined
	idiv    ebx
	mov     y2_,eax

	mov     eax,xx_                   ;
	imul    sined                   ; ex2 * sin(eye_th)
	idiv    ebx
	sub     y2_,eax
;;;;;;;;;
	mov     eax,x2_
	sub     eax,x1_
	cdq
	mov     ebx,_vlength
	idiv    ebx
	mov     xa_,eax

	mov     eax,y2_
	sub     eax,y1_
	cdq
	idiv    ebx
	mov     ya_,eax

	mov     edi,lstart

;	mov     esi,x1_
;	add	esi,16 SHL 16
;	mov     ebp,y1_
;	add	ebp,16 SHL 16

	mov     esi,x1_
	add	esi,_XC_
	mov     ebp,y1_
	add	ebp,_YC_

	;----------------------
	; select read plane
	;----------------------
	mov	dx,3CEh
	mov	al,4
	out	dx,al        ;
	inc	dx
	in      al,dx
	and	al,NOT 03h
	or      al,read_plane
	out     dx,al         ;
	inc     read_plane
	and     read_plane,3
	;-------------------------

	mov     ecx,vlength
	align 4
@@nextp:
	;calculate SPRITE coordinator
	mov     edx,ebp
	sar     edx,16
	test	dx,NOT 31
	jnz	SHORT @@skip
	and     edx,31  ;;;;;;
	shl     edx,5   ;;;;;     ;y * 32

	mov     ebx,esi
	sar     ebx,16
	test	bx,NOT 31
	jnz	SHORT @@skip
	and     ebx,31  ;;;;;;;
	add     ebx,edx                 ;ebx : offset of tile data

	add	ebx,[spr_pointer]

	mov     al,[ebx+4]   ;load color
	cmp	al,0
	jz	@@skip
	xor     eax,eax
	mov     al,byte ptr[edi]          ; read from screen
	mov     al,DARKER_TABLE[eax]
	mov     byte ptr[edi],al
@@skip:
	add     edi,80

	add     esi,xa_
	add     ebp,ya_

	dec     ecx
	jnz     @@nextp

	pop     ecx
	pop     ebp

	ret

vlines	ENDP

;------------------------------
;
;------------------------------
draw_sprR      PROC

	mov     edi,SCREEN_OFF          ;Calculate Init Pixel on dest.
	add     edi,PageOffset          ;

	call	world2eye		; center of spr
	sar	eax,16
	sar	edx,16

	mov	hlength,WIDE
	mov	vlength,WIDE
	mov	_vlength,WIDE

	mov	xl,-HWIDE
	mov	yu,-HWIDE

	;---------------------------
	;  cliping
	;---------------------------
	add	eax,64+128		; x
	sub	eax,HWIDE
	mov     xleft,eax
	add	eax,WIDE
	mov	xright,eax
	cmp	eax,Lbound
	jle     @@quit
	mov	eax,xleft
	cmp	eax,Rbound
	jge	@@quit

	add	edx,200                 ; Y
	sub	edx,HWIDE
	mov	yup,edx
	add	edx,WIDE
	mov	ydown,edx
	cmp	edx,Ubound
	jle	@@quit
	mov	edx,yup
	cmp	edx,Dbound
	jge	@@quit

	mov	eax,xright
	cmp	eax,Rbound
	jle	@@skipR
	sub	eax,Rbound
	sub	eax,WIDE
	neg	eax
	inc	eax
	mov	hlength,eax
	mov	eax,xleft
@@skipR:
	mov	eax,xleft
	cmp	eax,Lbound
	jge	@@skipL
	sub	eax,Lbound
	sub	xl,eax
	add	eax,WIDE
	mov	hlength,eax
	mov	eax,Lbound
@@skipL:

	mov	ebp,ydown
	cmp	ebp,Dbound
	jle	@@skipD
	sub	ebp,Dbound
	sub	vlength,ebp
	inc	vlength
@@skipD:
	mov	ebp,yup
	cmp	ebp,Ubound
	jge	@@skipU
	sub	ebp,Ubound
	sub	yu,ebp
	add	ebp,WIDE
	mov	vlength,ebp
	mov	_vlength,ebp
	mov	edx,Ubound
@@skipU:

@@gogo:
	mov	map_mask,11h

	mov	ecx,eax
	shr	eax,2
	mov	lstart,eax
	and	ecx,3
	shl	map_mask,cl
	mov     read_plane,cl     ;;;;;;

	mov	eax,edx
	imul	eax,80
	add	lstart,eax
	add	lstart,edi

	mov     dx,SC_INDEX             ;Let's prepare SC_INDEX
	mov     al,MAP_MASK             ;For the MAP_MASK
	out     dx,al                   ;.....

	mov     ebp,xl                 ; start x
	mov     ecx,hlength
@@nextx:
	mov     dx,SC_INDEX + 1
	mov     al,map_mask
	out     dx,al

	call    [_vline_]

	add     ebp,1

	rol     map_mask,1
	adc     lstart,0

	dec     ecx
	jnz     @@nextx
@@quit:

	ret

draw_sprR      ENDP

;-----------------------------------
; put rotated sprite
; input
;	eax : x  ; world coord.
;	edx : y  ;
;	ebx : angle
;	esi : sprite source
;-----------------------------------
PUBLIC	put_sprR
put_sprR	PROC

	push	ebp

	mov	[obj_vth],ebx
	mov	bx,eye_z

	mov	[spr_pointer],esi
	mov	_vline_,OFFSET vline
	call	draw_sprR

	pop	ebp

	ret

put_sprR	ENDP

;-----------------------------------
; put rotated shadow sprite
; input
;	eax : x
;	edx : y
;	ebx : angle
;	esi : sprite source
;-----------------------------------
PUBLIC	put_shadowR
put_shadowR	PROC

	push	ebp

	sub	eax,3 SHL 16
	add	edx,3 SHL 16
	mov	obj_vth,ebx
	mov	bx,eye_z

	mov	spr_pointer,esi
	mov	_vline_,OFFSET vlines
	call	draw_sprR

	pop	ebp
	ret

put_shadowR	ENDP

;-----------------------------------
; put sprite scaling  : CENTER
;
; esi : sprite image offset
; eax, edx, ebx :  x, y, z
; ecx : scaling
;-----------------------------------
PUBLIC	put_sprSC
put_sprSC	PROC
	mov	[put_RT],OFFSET put_sprS5
	call	draw_sprSC
	ret
put_sprSC	ENDP

;-----------------------------------
; put sprite scaling  : CENTER
;
; esi : sprite image offset
; eax, edx, ebx :  x, y, z
; ecx : scaling
;-----------------------------------
PUBLIC	put_shadowSC
put_shadowSC	PROC
	mov	[put_RT],OFFSET put_shadowS5
	call	draw_sprSC
	ret
put_shadowSC	ENDP

draw_sprSC       proc

	push	ebp
	push    pers

	mov     xxxx,eax              ; screen X
	mov     yyyy,edx              ; screen Y
	mov     zzzz,ebx              ; Z

	movsx   ebx,pers
	add     ebx,ecx
	mov     pers,bx

	mov     sx_start,0
	mov     sy_start,0

	movzx   eax,word ptr[esi]
	imul    ebx
	cdq
	idiv    zzzz
	mov     XD,eax
	cmp     eax,2
	jb      @@quit

	movzx   eax,word ptr[esi+2]
	imul    ebx
	cdq
	idiv    zzzz
	mov     YD,eax
	cmp     eax,2
	jb      @@quit

	shr     eax,1
	sub     yyyy,eax

	mov     eax,XD
	shr     eax,1
	sub     xxxx,eax

	mov     ebp,XD
	add     ebp,xxxx
	mov     xr,ebp

	mov	eax,xr
	cmp     eax,Lbound
	jl      @@quit

	mov     ebp,YD
	add     ebp,yyyy
	mov     yb,ebp

	cmp     ebp,Ubound
	jl      @@quit

	mov     eax,xxxx
	mov     xl,eax
	mov     edx,yyyy
	mov     ya,edx

	cmp     edx,Dbound        ; yb > Dbound
	jg      @@quit            ;

	movzx   eax,word ptr[esi]   ; image sx
	shl     eax,16
	cdq
	mov     ebx,XD
	div     ebx
	mov     xdd_,eax

	movzx   eax,word ptr[esi+2]  ; image sy
	shl     eax,16
	cdq
	mov     ebx,YD
	div     ebx
	mov     ydd_,eax
	mov     ydd,ax
	shr     eax,16
	mov     ydu,ax
	mul     word ptr[esi]
	mov     yinc,ax

@@xclip:
	mov	eax,Rbound
	sub     xr,eax
	jle     SHORT @@lclip
	mov	eax,xl
	cmp     eax,Rbound
	jg      @@quit
	mov     ebp,xr
	sub     XD,ebp
	inc     XD
@@lclip:
	mov	eax,Lbound
	sub     xl,eax
	jge     @@yclip
	mov     ebp,xl
	add     XD,ebp
	inc     XD
	neg     ebp
;;;;    inc     ebp
	imul    ebp,xdd_
	mov     sx_start,ebp
	mov	eax,Lbound
	mov     xxxx,eax

@@yclip:
	mov     eax,YD
	mov	ebx,Dbound
	sub     yb,ebx
	jle     SHORT @@uclip           ;
	mov     ebp,yb
	sub     YD,ebp
	mov     eax,YD
	inc     YD
@@uclip:                                ; yb <= Dbound
	mov	ebx,Ubound
	sub     ya,ebx
	jge     @@noclip
	mov     YD,eax
	mov     ebp,ya
	add     YD,ebp
	inc     YD
	neg     ebp
	sub     ebp,1
	imul    ebp,ydd_
	shr     ebp,16
	movzx   ecx,word ptr[esi]
	imul    ebp,ecx
	mov     sy_start,ebp
	mov	eax,Ubound
	mov     yyyy,eax

@@noclip:
	mov     eax,xxxx
	mov     edx,yyyy
	shr     eax,2                   ; 3  X / 4
	lea     edx,[edx * 8]           ; 2  Y * 8
	lea     edx,[edx * 2]           ; 2  Y * 8 * 2
	lea     edx,[edx * 4][edx]      ; 2  Y * 8 * 2 * 5
	add     eax,edx                 ; 2  X / 4 + Y * 80
					; total 11 clock
	mov     edi,eax
	add     edi,SCREEN_OFF           ;Calculate Init Pixel on dest.
	add     edi,PageOffset           ;

	mov     eax,YD
	lea     eax,[eax * 8]           ; dii = YD * 80
	lea     eax,[eax * 2]           ;
	lea     eax,[eax * 4][eax]      ;
	mov     dii,eax                 ;

	call    [put_RT]

@@quit:
	pop     pers
	pop	ebp

	ret

draw_sprSC       endp

;--------------------------------------
; normal sprite
;--------------------------------------
put_sprS5       PROC    near

	mov     map_mask,11h
	mov     ecx,xxxx                ; xxxx
	and     ecx,3
	rol     map_mask,cl

	mov     dx,SC_INDEX             ;Let's prepare SC_INDEX
	mov     al,MAP_MASK             ;For the MAP_MASK
	out     dx,al                   ;.....

	mov     ebp,sx_start            ; ebx = sx_start  source X

	mov     ecx,XD
@@X:
	mov     dx,SC_INDEX+1           ;set Map Mask reg.
	mov     al,map_mask
	out     dx,al                   ;
	;
	mov     ebx,sy_start
	mov     y_d,0

	push    ecx
	mov     ecx,YD
@@Y:
	mov     eax,ebp
	shr     eax,16

	add     eax,ebx

	mov     al,byte ptr[esi+eax+4]
	cmp     al,0
	jz      SHORT @@skip0
	mov     byte ptr[edi],al
@@skip0:
	mov     ax,ydd
	add     y_d,ax
	jnc     @@noinc
	add     bx,word ptr[esi]
@@noinc:
	add     bx,yinc

	add     edi,80

	loop    @@Y
	;
	add     ebp,xdd_

	sub     edi,dii

	rol     map_mask,1
	adc     edi,0

	pop     ecx
	loop    @@X

@@quit:
	ret

put_sprS5       ENDP

;--------------------------------------
; shadow sprite
;--------------------------------------
put_shadowS5       PROC    near
	push	ebp

	mov     map_mask,11h
	mov     ecx,xxxx                ; xxxx
	and     ecx,3
	rol     map_mask,cl
	mov	read_plane,cl

	mov     dx,SC_INDEX             ;Let's prepare SC_INDEX
	mov     al,MAP_MASK             ;For the MAP_MASK
	out     dx,al                   ;.....

	mov     ebp,sx_start            ; ebx = sx_start  source X

	mov     ecx,XD
@@X:
	;----------------------
	; select read plane
	;----------------------
	mov	dx,3CEh
	mov	al,4
	out	dx,al        ;
	inc	dx
	in      al,dx
	and	al,NOT 03h
	or      al,read_plane
	out     dx,al         ;
	inc     read_plane
	and     read_plane,3
	;-------------------------

	mov     dx,SC_INDEX+1           ;set Map Mask reg.
	mov     al,map_mask
	out     dx,al                   ;
	;
	mov     ebx,sy_start
	mov     y_d,0

	push    ecx
	mov     ecx,YD
@@Y:
	mov     eax,ebp
	shr     eax,16

	add     eax,ebx

	mov     al,byte ptr[esi+eax+4]
	cmp     al,0
	jz      SHORT @@skip0
	xor     eax,eax
	mov     al,byte ptr[edi]          ; read from screen
	mov     al,DARKER_TABLE[eax]
	mov     byte ptr[edi],al
@@skip0:
	mov     ax,ydd
	add     y_d,ax
	jnc     @@noinc
	add     bx,word ptr[esi]
@@noinc:
	add     bx,yinc

	add     edi,80

	loop    @@Y
	;
	add     ebp,xdd_

	sub     edi,dii

	rol     map_mask,1
	adc     edi,0

	pop     ecx
	dec	ecx
	jnz	@@X

@@quit:
	pop	ebp
	ret

put_shadowS5	ENDP

;-----------------------------
; eax : X, edx : Y
; esi : spr data
;-----------------------------
PUBLIC	draw_compas
draw_compas	PROC

;;	mov	eax,16			; (16,65)
;;	mov	edx,65                  ;
;;	mov	esi,OFFSET compas_spr_data

	push    eax
	push    ecx
	push    edx

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
	mov     lstart,edi

;;	movzx   eax,word ptr[esi]       ;sx
	mov   	eax,41
	mov     sx,eax                  ;
	shr     eax,2                   ;
	mov     sxq,eax                 ;sxq = sx / 4
	mov	sx,274

;;	movzx   eax,word ptr[esi+2]     ;sy
	mov   	eax,7
	mov     sy,eax                  ;
	mul     sx                      ;
	mov     sxsy,eax                ;sxsy = sx * sy

	mov     eax,80                  ;
	mul     sy                      ;
	mov     sy80,eax                ;sy80 = sy * 80

	mov	ax,137
	movzx	bx,eye_th
	add	bx,2
	neg	bx
	add	bx,32
	and	bx,255
	mul     bx
	mov	bx,255
	div	bx
	movzx   eax,ax
	add	esi,eax

	mov     dx,SC_INDEX             ;Let's prepare SC_INDEX
	mov     al,MAP_MASK             ;For the MAP_MASK
	out     dx,al                   ;.....

	xor     ebp,ebp

	cmp     sxq,0
	je      @@pppp

	mov     ecx,4
@@nextp: ; 4-planes loop
	mov     dx,SC_INDEX+1           ;set Map Mask reg.
	mov     al,map_mask             ;
	out     dx,al                   ;

	xor     ebx,ebx
	add     ebx,ebp

	mov     edi,lstart

	push    ecx
	mov     ecx,sxq
@@x:    ; X-offset loop

	push    ecx
	mov     ecx,sy
@@y:    ; Y-offset loop

	mov     al,byte ptr[esi+ebx+4]
	cmp     al,0
	jz      SHORT @@skip0
	mov     byte ptr[edi],al
@@skip0:
	add     ebx,sx
	add     edi,80
	dec     ecx
	jnz     @@y

	sub     ebx,sxsy
	add     ebx,4
	sub     edi,sy80
	add     edi,1

	pop     ecx
	dec     ecx
	jnz     @@x

	rol     map_mask,1
	adc     lstart,0
	add     ebp,1
	pop     ecx
	dec     ecx
	jnz     @@nextp

;;;;;-------------------
@@pppp:
	mov     ecx,41    ; sx
	and     ecx,3
	jz      SHORT @@here

	mov     ebx,41    ; sx
	sub     ebx,ecx

	ror     map_mask,1
	jc      SHORT @@noo
	sub     edi,1
@@noo:
	rol     map_mask,1

@@x1:
	mov     al,map_mask                 ;
	out     dx,al                   ;

	push    ecx
	mov     ecx,sy
@@y1:    ; Y-offset loop

	mov     al,byte ptr[esi+ebx+4]
	cmp     al,0
	jz      SHORT @@skip00
	mov     byte ptr[edi],al
@@skip00:
	add     ebx,sx
	add     edi,80
	dec     ecx
	jnz     @@y1

	sub     ebx,sxsy
	add     ebx,1
	sub     edi,sy80

	rol     map_mask,1
	adc     edi,0

	pop     ecx
	dec     ecx
	jnz    @@x1

@@here:
	pop     edx
	pop     ecx
	pop     eax

	ret

draw_compas	ENDP

;-----------------------
; vertical draw
;-----------------------
vline3  PROC

	push    ebp
	push    ecx

	mov   	eax,ebp
	shl     eax,16
	imul    eye_zd
	mov     ebx,128
	idiv    ebx
	mov     xx_,eax

	mov     eax,yu
	shl     eax,16
	imul    eye_zd
	idiv    ebx
	mov     ey1_,eax

	mov     eax,HWIDE
	shl     eax,16
	imul    eye_zd
	idiv    ebx
	mov     ey2_,eax

	movzx   ebx,eye_th              ;
	shl     ebx,1                   ; for word ptr
	movsx   edx,SIN[ebx]            ; sin(eye_th)
	mov     sined,edx               ;

	movzx   ebx,eye_th               ;
	add     ebx,64                   ; cosine
	and     ebx,255                  ;
	shl     ebx,1                    ;
	movsx   edx,SIN[ebx]              ; dx = cos(eye_th)
	mov     cosined,edx

; x1, y1
	mov     ebx,32767

	mov     eax,xx_                 ; ey1 * cos(eye_th)
	imul    cosined                  ;
	idiv    ebx
	mov     x1_,eax

	mov     eax,ey1_                ;
	imul    sined                   ; xx * sin(eye_th)
	idiv    ebx
	add     x1_,eax

	mov     eax,ey1_                ; xx * cos(eye_th)
	imul    cosined
	idiv    ebx
	mov     y1_,eax

	mov     eax,xx_                 ;
	imul    sined                   ; ex1 * sin(eye_th)
	idiv    ebx
	sub     y1_,eax

; x2, y2
	mov     eax,xx_                   ; ex2 * cos(eye_th)
	imul    cosined                 ;
	idiv    ebx
	mov     x2_,eax

	mov     eax,ey2_                  ;
	imul    sined                   ; xx * sin(eye_th)
	idiv    ebx
	add     x2_,eax

	mov     eax,ey2_                ; xx * cos(eye_th)
	imul    cosined
	idiv    ebx
	mov     y2_,eax

	mov     eax,xx_                   ;
	imul    sined                   ; ex2 * sin(eye_th)
	idiv    ebx
	sub     y2_,eax
;;;;;;;;;
	mov     eax,obj_x_
	add     x1_,eax
	add     x2_,eax

	mov     eax,obj_y_
	add     y1_,eax
	add     y2_,eax
;;;
	mov     esi,x1_
	mov     ebp,y1_

	mov     eax,x2_
	sub     eax,x1_
	cdq
	mov     ebx,_vlength
	idiv    ebx
	mov     xa_,eax

	mov     eax,y2_
	sub     eax,y1_
	cdq
	idiv    ebx
	mov     ya_,eax

	mov     edi,lstart

	mov     ecx,vlength
	align 4
@@nextp:
	;calculate map coordinator
	mov     edx,ebp
	shr     edx,16+3
	and     edx,255
	shl     edx,8                   ;mapy * 256

	mov     eax,esi
	shr     eax,16+3
	and     eax,255                 ;
	add     eax,edx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     edx,ebp
	shr     edx,16
	and     edx,7  ;;;;;;
	shl     edx,3   ;;;;;     ;y * 8

	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data

	test	ebx,00200000h
	jz	SHORT @@skip

	test	ebx,00400000h
	jz	SHORT @@skip_

	shr	ebx,12
	and	ebx,0FFh
	shl	ebx,6
	add	ebx,offset TIL
	mov     eax,ebx     ;load pointer of tile data
	jmp	SHORT @@skip__
@@skip_:
	mov	eax,TEXMAPADD[eax * 4]
@@skip__:
	mov     ebx,esi
	shr     ebx,16
	and     ebx,7  ;;;;;;;
	add     ebx,edx                 ;ebx : offset of tile data

	mov     al,byte ptr[eax][ebx]   ;load color
	cmp	al,0
	jz	SHORT @@skip
	mov     byte ptr[edi],al        ;
@@skip:
	add     edi,80

	add     esi,xa_
	add     ebp,ya_

	dec     ecx
	jnz     @@nextp

	pop     ecx
	pop     ebp

	ret

vline3  ENDP

;------------------------------
;
;------------------------------
PUBLIC	draw_floor3
draw_floor3     PROC
	push	ebp

	mov     edi,SCREEN_OFF          ;Calculate Init Pixel on dest.
	add     edi,PageOffset          ;

	mov	obj_x_,eax
	mov	obj_y_,edx

	call	world2eye
	sar	eax,16
	sar	edx,16

	mov	hlength,WIDE
	mov	vlength,WIDE
	mov	_vlength,WIDE

	mov	xl,-HWIDE
	mov	yu,-HWIDE

	;---------------------------
	;  cliping
	;---------------------------
	add	eax,64+128		; x
	sub	eax,HWIDE
	mov     xleft,eax
	add	eax,WIDE
	mov	xright,eax
	cmp	eax,Lbound
	jle     @@quit
	mov	eax,xleft
	cmp	eax,Rbound
	jge	@@quit

	add	edx,200                 ; Y
	sub	edx,HWIDE
	mov	yup,edx
	add	edx,WIDE
	mov	ydown,edx
	cmp	edx,Ubound
	jle	@@quit
	mov	edx,yup
	cmp	edx,Dbound
	jge	@@quit

	mov	eax,xright
	cmp	eax,Rbound
	jle	@@skipR
	sub	eax,Rbound
	sub	eax,WIDE
	neg	eax
	inc	eax
	mov	hlength,eax
	mov	eax,xleft
@@skipR:
	mov	eax,xleft
	cmp	eax,Lbound
	jge	@@skipL
	sub	eax,Lbound
	sub	xl,eax
	add	eax,WIDE
	mov	hlength,eax
	mov	eax,Lbound
@@skipL:

	mov	ebp,ydown
	cmp	ebp,Dbound
	jle	@@skipD
	sub	ebp,Dbound
	sub	vlength,ebp
	inc	vlength
@@skipD:
	mov	ebp,yup
	cmp	ebp,Ubound
	jge	@@skipU
	sub	ebp,Ubound
	sub	yu,ebp
	add	ebp,WIDE
	mov	vlength,ebp
	mov	_vlength,ebp
	mov	edx,Ubound
@@skipU:

@@gogo:
	mov	map_mask,11h

	mov	ecx,eax
	shr	eax,2
	mov	lstart,eax
	and	ecx,3
	shl	map_mask,cl

	mov	eax,edx
	imul	eax,80
	add	lstart,eax
	add	lstart,edi

	mov     dx,SC_INDEX             ;Let's prepare SC_INDEX
	mov     al,MAP_MASK             ;For the MAP_MASK
	out     dx,al                   ;.....

	mov     ebp,xl                 ; start x
	mov     ecx,hlength
@@nextx:
	mov     dx,SC_INDEX + 1
	mov     al,map_mask
	out     dx,al

	call    vline3

	add     ebp,1

	rol     map_mask,1
	adc     lstart,0

	dec     ecx
	jnz     @@nextx
@@quit:

	pop	ebp

	ret

draw_floor3     ENDP

_TEXT	ENDS
	END
