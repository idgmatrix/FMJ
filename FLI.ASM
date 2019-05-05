;===================================================
;  FLI.ASM
;
;  DOS/4GW 386 DOS extender
;  (c) Copyright 1994, 1995 Mirinae Software, Inc.
;
;  code : KIM, SEONG-WAN
;  original coder : JEONG, JAE-SEONG
;
;  1995. 9. 16  revised and comented
;  1995. 9. 19  color chunk bug corrected
;===================================================

	.386

	LOCALS

DGROUP  GROUP   _DATA,_BSS

include	keyscan.inc
include	grplib.ash

LOAD_MEMORY	equ	pcx_buffer

_DATA   SEGMENT DWORD USE32 PUBLIC 'DATA'

CBUF           	DD      0
ERRDAT         	DB      0
HANDLE         	DW      0
LENTH          	DD      0
BUFFER0        	DD      0
BUFFER1        	DD      0
BUFFER2        	DD      0
FRAME_CNT	DW	0

_DATA   ENDS

_BSS    SEGMENT DWORD USE32 PUBLIC 'BSS'
extrn	key_hit:byte
extrn	_TimerTicks:dword
_BSS    ENDS


_TEXT   SEGMENT DWORD USE32 PUBLIC 'CODE'
	ASSUME  CS:_TEXT,DS:DGROUP,ES:DGROUP,SS:DGROUP

PUBLIC	FLI_FILE_RUN
PUBLIC	VRAMCLS

;----------------------------------------------
;
;
;  EDX : file name pointer
;----------------------------------------------
FLI_FILE_RUN	PROC

	MOV	FRAME_CNT,0

;	MOV     EDX,DWORD PTR FILE_FLI
	CALL    OPENFILE
	;
	MOV     ESI,OFFSET LOAD_MEMORY  ;FLI HEADER!!
	MOV     ECX,128         	;128 bytes
	CALL    GETFILE			;read FLI header
	;
	MOV     EBP,OFFSET LOAD_MEMORY
	MOV     AX,DGROUP:[EBP+4]           ;
	CMP     AX,0AF11H 		;check ID
	JNE     @EOP          		;not OK
	;
	XOR     ECX,ECX                 ;
	MOV     CX,DGROUP:[EBP+6]       ;read Number of FRAMES
					;

	mov	_TimerTicks,0

@FRAME: 				;start of frame
	PUSH    ECX                     ; push 'number of frames' in CX

	MOV     ESI,OFFSET LOAD_MEMORY  ;FRAME HEADER!!
	MOV     ECX,16                  ;16 bytes
	CALL    GETFILE                 ;
	MOV     EBP,OFFSET LOAD_MEMORY  ;
	MOV     AX,DGROUP:[EBP+4]           ;
	CMP     AX,0F1FAH    		;check ID
	JE      READ_FRAME              ;OK!

	POP     ECX                     ;
	JMP     @EOP           		;not OK! end
	;
READ_FRAME:
	XOR     ECX,ECX
	MOV     CX,DGROUP:[EBP+6]	; number of chunks in frame
	CMP     CX,0
	JZ      @END_FRAME              ;

	PUSH    ECX                     ; push number of chunks
	MOV     ECX,DGROUP:[EBP+0]      ; total bytes in this frame
	SUB     ECX,16                  ; frame data = total - header
	MOV     ESI,OFFSET LOAD_MEMORY
	CALL    GETFILE                 ; read one frame data
	POP     ECX			; restore number of chunks
	MOV     EBP,OFFSET LOAD_MEMORY

@CHUNK:
	PUSH    ECX		; save number of chunks
	PUSH    EBP
	MOV     AX,DGROUP:[EBP+4]   ; read type of chunks
	ADD     EBP,6           ; skip header of chunks
	SUB     AX,11
	CMP     AX,6            ; check chunk type 11,12,13,14,15,16
	JC      CHUNK_RUN       ; GOOD!

	POP     EBP             ; if invalid chunk type
	POP     ECX             ;
	POP     ECX             ;
	JMP     @EOP           	;END
	;
CHUNK_RUN:
	MOV     ESI,OFFSET CBUF
	MOV     [ESI],EBP
	SHL     AX,2
	MOV     EDI,OFFSET CHUNKS_RT
	ADD     DI,AX
	ADC     EDI,0
	CALL    CS:[EDI]
	POP     EBP
	POP     ECX

	MOV     AX,DGROUP:[EBP]
	ADD     BP,AX
	ADC     EBP,0

	DEC	ECX             ;
	JNZ	@CHUNK		; Go to next chunk

@END_FRAME:

	cmp	key_hit,_ESC   ; key check
	jne	SHORT @@continue1
	pop	ecx
	jmp	@EOP
@@continue1:
	cmp	key_hit,_SPACE  ; key check
	jne	SHORT @@continue2
	pop	ecx
	jmp	@EOP
@@continue2:

@@timechk:
	mov	eax,_TimerTicks
	cmp	eax,3
	ja	SHORT @@goodtime
	jmp	SHORT @@timechk
@@goodtime:
	mov	_TimerTicks,0

	INC	FRAME_CNT
	POP     ECX		;restore number of frames
	DEC	ECX
	JNZ	@FRAME		;Go to next frame

@EOP:  				;End of Play
	CALL    CLOSEFILE

	RET

FLI_FILE_RUN	ENDP


	;----------------------------------------
CHUNKS_RT:
	DD      FLI_RGB   ;11      0
	DD      FLI_LC    ;12      1
	DD      FLI_BLK   ;13      2
	DD      FLI_COPY  ;14   X  3
	DD      FLI_RLE   ;15      4
	DD      FLI_COPY  ;16      5
	;----------------------------------------
	;
	;----------------------------------------
	;
	;
	;
	;
	;---------------------------------------
FLI_RGB	PROC
	CALL	FLI_BLK

	MOV     ESI,OFFSET CBUF
	MOV     ESI,[ESI]

	MOVZX	ECX,WORD PTR[ESI]	; NUMBER OF PACKETS
	ADD	ESI,2
	XOR     EBX,EBX

@@NEXT_PACKET:
	PUSH    ECX

	ADD     BL,[ESI+0]		; number of colors skiped
	MOVZX   ECX,BYTE PTR[ESI+1]     ; number of colors changed
	MOV	BH,CL
	ADD     ESI,2
	CMP	ECX,0
	JNZ	@RGBSET
	MOV	ECX,256
@RGBSET:
	MOV	AL,BL
	CALL    palette
	ADD	BL,BH

	POP	ECX
	DEC	ECX
	JNZ	@@NEXT_PACKET

	RET

FLI_RGB	ENDP

	;----------------------------------------
	;
	;
	;
	;
	;----------------------------------------
FLI_COPY	PROC

	CLD
	MOV     ESI,DWORD PTR CBUF
	MOV     EDI,0A0000H     ;
	MOV     ECX,16000       ;64000/4
	REP     MOVSD
	RET

FLI_COPY	ENDP

	;---------------------------------------
	;
	;
	;
	;
	;---------------------------------------
FLI_BLK	PROC

	CLD
	MOV     EDI,0A0000H     ;0
	MOV     ECX,16000               ;64000/4
	XOR     EAX,EAX
	REP     STOSD
	RET

FLI_BLK	ENDP

	;--------------------------------------
	;
	;
	;
	;--------------------------------------
FLI_LC	PROC

	CLD
	MOV     ESI,DWORD PTR CBUF
	MOV     EDI,0A0000H
	LODSW
	MOV     DX,320
	MUL     DX
	ADD     DI,AX
	LODSW
	MOV     DX,DI
FLI_LC0:
	PUSH    EAX
	XOR     AH,AH
	MOV     DI,DX
	LODSB
	MOV     BL,AL
	TEST    BL,BL
	JZ      FLI_LC4
FLI_LC1:
	LODSB
	ADD     DI,AX
	LODSB
	TEST    AL,AL
	JS      FLI_LC2
	XOR     ECX,ECX
	MOV     CX,AX
	REP     MOVSB
	DEC     BL
	JNZ     FLI_LC1
	JMP     FLI_LC4
FLI_LC2:
	NEG     AL
	XOR     ECX,ECX
	MOV     CX,AX
	LODSB
	REP     STOSB
	DEC     BL
	JNZ     FLI_LC1
FLI_LC4:
	ADD     DX,320
	POP     EAX
	DEC     AX
	JNZ     FLI_LC0
	RET

FLI_LC	ENDP

	;----------------------------------------------
	;
	;
	;
	;
	;----------------------------------------------
FLI_RLE	PROC

	CLD
	MOV     ESI,DWORD PTR CBUF
	MOV     EDI,0A0000H             ;0
	MOV     AX,200
	MOV     DX,DI
FLI_RLE0:
	PUSH    EAX
	XOR     AH,AH
	MOV     DI,DX
	LODSB
	MOV     BL,AL
	TEST    BL,BL
	JZ      FLI_RLE4
FLI_RLE1:
	LODSB
	TEST    AL,AL
	JNS     FLI_RLE2
	NEG     AL
	XOR     ECX,ECX
	MOV     CX,AX
	REP     MOVSB
	DEC     BL
	JNZ     FLI_RLE1
	JMP     FLI_RLE4
FLI_RLE2:
	XOR     ECX,ECX
	MOV     CX,AX
	LODSB
	REP     STOSB
	DEC     BL
	JNZ     FLI_RLE1
FLI_RLE4:
	ADD     DX,320
	POP     EAX
	DEC     AX
	JNZ     FLI_RLE0
	RET

FLI_RLE	ENDP

	;---------------------------------------------------
	;
	;
	;---------------------------------------------------
VRAMCLS	PROC
	CALL    SCROFF
	MOV     ECX,64000/4
	MOV     EDI,0A0000H     ;00
	XOR     EAX,EAX
	REP     STOSD
	CALL    SCRON
	RET
VRAMCLS	ENDP

;--------------------------------------
; set palette registers
; al : start
; ecx : numbers
; esi : pointer of palette data
;--------------------------------------
palette	PROC

	push	ebx

	mov	ebx,gammano
	mov	ebx,GAMMA[ebx*4]

	mov     dx,3c8h                 ; I/O port of palette reg
	out     dx,al                   ; 0 - 255

	xor	eax,eax

	mov     dx,3c9h                 ;
	lea	ecx,[ecx*2][ecx]
@@next:
	mov	al,[esi]
	mov	al,DGROUP:[ebx][eax]
	out     dx,al

	inc	esi

	dec	ecx
	jnz	SHORT @@next

	pop	ebx

	ret

palette	ENDP

	;==========================================================
	;
	;       ESI : 로드번지
	;       EDX : 파일이름 번지
	;
	;==========================================================
DKREAD:
	MOV     DWORD PTR BUFFER1,EDX
	MOV     DWORD PTR BUFFER0,ESI
	CALL    DISKREAD
	MOV     EDX,DWORD PTR BUFFER1
	RET
	;----------------------------------------------------
	;
	;
	;----------------------------------------------------
DISKREAD:
	XOR     EAX,EAX
	MOV     DWORD PTR LENTH,EAX
	MOV     EDX,DWORD PTR BUFFER1
	MOV     AL,0
	MOV     AH,3DH
	INT     21H
	JC      ERROR
	MOV     WORD PTR HANDLE,AX
	MOV     BX,WORD PTR HANDLE
	MOV     ECX,0100000H
	MOV     EDX,DWORD PTR BUFFER0   ;DS
	MOV     AH,3FH
	INT     21H
	JC      ERROR
	MOV     DWORD PTR LENTH,EAX
	MOV     BX,WORD PTR HANDLE
	MOV     AH,3EH
	INT     21H
	JC      ERROR
	XOR     AL,AL
	MOV     BYTE PTR ERRDAT,AL
	RET

	;---------------------------------------------------------
	;
	;       ESI : 시작 어드레스
	;       EDI : 끝   어드레스
	;       EDX : 파일이름 번지
	;
	;---------------------------------------------------------
DKSAVE:
	MOV     DWORD PTR BUFFER1,EDX
	MOV     ECX,EDI
	SUB     ECX,ESI
	INC     ECX
	MOV     DWORD PTR BUFFER2,ECX
	MOV     DWORD PTR BUFFER0,ESI
	CALL    NEWFIL
	MOV     EDX,DWORD PTR BUFFER1
	RET

NEWFIL:
	MOV     EDX,DWORD PTR BUFFER1
	MOV     AH,3CH
	MOV     ECX,0
	INT     21H
	JC      ERROR
	JMP     DISK100
	RET

DISKSAVE:
	MOV     EDX,DWORD PTR BUFFER1
	MOV     AL,1
	MOV     AH,3DH
	INT     21H
	JC      ERROR
DISK100:
	MOV     WORD PTR HANDLE,AX
	;
	MOV     ECX,DWORD PTR BUFFER2
	MOV     BX,WORD PTR HANDLE
	MOV     EDX,DWORD PTR BUFFER0
	MOV     AH,40H
	INT     21H
	JC      ERROR
	MOV     BX,WORD PTR HANDLE
	MOV     AH,3EH
	INT     21H
	JC      ERROR
	XOR     AL,AL
	MOV     BYTE PTR ERRDAT,AL
	RET

ERROR:
	CMP     AL,2
	JZ      ERROR1
	MOV     BYTE PTR ERRDAT,1
	RET
ERROR1:
	MOV     BYTE PTR ERRDAT,2
	RET
	;-------------------------------------------------
	;
	;
	;
	;
	;
	;
	;--------------------------------------------------
OPENFILE:
	XOR     ECX,ECX
	MOV     DWORD PTR BUFFER1,EDX
	MOV     AL,0
	MOV     AH,3DH
	INT     21H
	JC      ERROR
	MOV     WORD PTR HANDLE,AX
	XOR     AL,AL
	MOV     BYTE PTR ERRDAT,AL
	RET
	;------------------------------------------
	;       ECX:NUMBER
	;       ESI:32BIT ADDRESS
	;------------------------------------------
PUTFILE:
	MOV     BX,WORD PTR HANDLE
	MOV     EDX,ESI
	MOV     AH,40H
	INT     21H
	JC      ERROR
	XOR     AL,AL
	MOV     BYTE PTR ERRDAT,AL
	RET

	;------------------------------------------
	;       ECX:NUMBER
	;       ESI:32BIT ADDRESS
	;------------------------------------------
GETFILE:
	MOV     BX,WORD PTR HANDLE
	MOV     EDX,ESI
	MOV     AH,3FH
	INT     21H
	JC      ERROR
	XOR     AL,AL
	MOV     BYTE PTR ERRDAT,AL
	RET

	;------------------------------------------
CLOSEFILE:
	MOV     BX,WORD PTR HANDLE
	MOV     AH,3EH
	INT     21H
	JC      ERROR
	XOR     AL,AL
	MOV     BYTE PTR ERRDAT,AL
	RET
	;
_TEXT   ENDS
	END
