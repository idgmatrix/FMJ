_DATA   SEGMENT PUBLIC USE32 DWORD 'DATA'
_DATA   ENDS

_BSS	SEGMENT PUBLIC USE32 DWORD 'BSS'
_BSS	ENDS

_TEXT   SEGMENT PUBLIC USE32 DWORD 'CODE'

extrn	open_file	: near
extrn	close_file	: near
extrn	read_file	: near
extrn	write_file	: near
extrn	move_file_pointer: near
extrn	load_file	: near
extrn	save_file	: near

_TEXT   ENDS
