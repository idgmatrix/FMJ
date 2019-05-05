;---------------------------------------------;
;   FILE ACCES LIB     files.asm              ;
;                                             ;
;   header file : files.ash                   ;
;---------------------------------------------;

	LOCALS
	.386

GROUP	DGROUP	_DATA,_BSS

_DATA   SEGMENT PUBLIC USE32 DWORD 'DATA'

message01       db   "reading$"
message02       db   "file saving error..$"
message03       db   "file saving OK!!$"

_DATA   ENDS

_BSS	SEGMENT PUBLIC USE32 DWORD 'BSS'
_BSS	ENDS

_TEXT   SEGMENT PUBLIC USE32 DWORD 'CODE'
	ASSUME  cs:_TEXT,ds:DGROUP,es:DGROUP

;------------------------------------------
; input
; 	esi : filemame(ASCIIZ)
;	 al : open mode   0 read only
;                         1 write only
;                         2 read/write
; output
;  	ax : file handle
;------------------------------------------
PUBLIC	open_file
open_file	PROC

	mov     ah,3dh                  ; open file
	mov     edx,esi
	int     21h
	jc      @@error

	ret

@@error:

	ret

open_file	ENDP

;------------------------------------------
; input
; 	ax : file handle
;------------------------------------------
PUBLIC close_file
close_file	PROC

	mov	bx,ax                   ; bx : handle
	mov     ah,3eh                  ; close
	int     21h

	ret

close_file	ENDP

;------------------------------------------
;  ax : file handle
; edi : memory pointer
; ecx : read bytes
;------------------------------------------
PUBLIC read_file
read_file	PROC

	mov     bx,ax                   ; file handle
	mov     ah,3fh                  ; read
	mov     edx,edi
	int     21h
	jc      @@error

	ret

@@error:
	mov     ah,09h
	mov     edx,offset message01   ; "file reading error.."
	int     21h

	ret

read_file	ENDP

;------------------------------------------
;  ax : file handle
; esi : memory pointer
; ecx : read bytes
;------------------------------------------
PUBLIC write_file
write_file	PROC

	mov     ebx,eax                 ; file handle
	mov     ah,40h                  ; write
	mov     edx,esi      		; esi : pointer of data
	int     21h                     ; write file
	jc      @@error

	ret

@@error:
	mov     ah,09h
	mov     edx,offset message02   ; "file saving error.."
	int     21h

	ret

write_file	ENDP

;-----------------------------------------------
;  input
;    al : mode    0 start point + offset
;                 1 current point + offset
;                 2 end point + offset
;    bx : file handle
;    ecx :  moving bytes
;  output
;    eax : new pointer
;-----------------------------------------------
PUBLIC move_file_pointer
move_file_pointer	PROC

	mov	dx,cx
	shr	ecx,16

	mov	ah,42h
	int	21h
	jc	@@error

	shl	eax,16
	mov	ax,dx
	rol	eax,16

	ret

@@error:
	ret

move_file_pointer	ENDP

;------------------------------------------
; esi : filemame(ASCIIZ)
; edi : pointer
; ecx : file length
;------------------------------------------
PUBLIC	load_file
load_file       PROC

	mov     ah,3dh                  ; open file
	mov     al,0                    ; read only
	mov     edx,esi
	int     21h
	jc      @@error

	mov     bx,ax                   ; file handle
	mov     ah,3fh                  ; read
	mov     edx,edi
	int     21h
	jc      @@error

	mov     ah,3eh                  ; close
	int     21h

	ret

@@error:
	mov     ah,09h
	mov     edx,offset message01   ; "file loading error.."
	int     21h

	ret

load_file       ENDP

;--------------------------------------
; esi : pointer
; edi : file name
; ecx : length
;--------------------------------------
PUBLIC	save_file
save_file	PROC

@@open:
	mov     ah,3dh                  ; open file
	mov     al,1                    ; write only
	mov     edx,edi
	int     21h
	jc      @@openerror

	mov     bx,ax                   ; file handle
	mov     ah,40h                  ; write
	mov     edx,esi      		; esi : pointer of data
	int     21h                     ; write file
	jc      @@error
	jmp     @@out

@@openerror:
	push	ecx
	mov     ah,3ch                  ; create file
	mov     cx,0                    ; write only
	mov     edx,edi                 ; edi : pointer of file name
	int     21h
	pop	ecx
	jc      @@error
	jmp     @@open

@@error:
	mov     ah,09h
	mov     edx,offset message02   ; "file save error.."
	int     21h
	ret

@@out:
	mov     ah,3eh                  ; close
	int     21h

;	mov     ah,09h
;	mov     edx,offset message03   ; "file save OK!.."
;	int     21h

	ret

save_file	ENDP

_TEXT	ENDS
	END