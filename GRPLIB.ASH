_DATA	SEGMENT	PUBLIC DWORD USE32 'DATA'

extrn	StartOffset	: dword
extrn	PageOffset	: dword
extrn	map_mask	: byte
extrn	GAMMA           : dword
extrn	gammano         : dword
extrn	pcxfilename     : byte

_DATA	ENDS

_BSS	SEGMENT	PUBLIC DWORD USE32 'BSS'

extrn	pcx_buffer      :byte
extrn	erase_flag	:byte

_BSS	ENDS

_TEXT   SEGMENT PUBLIC USE32 DWORD 'CODE'

extrn	vid_mode_	:near
extrn	xmode		:near
extrn	mode320X240     :near
extrn	SCROFF        	:near
extrn	SCRON        	:near
extrn	wait_vrt        :near
extrn	clean           :near
extrn	erase           :near
extrn	showp           :near
extrn	show_p          :near
extrn	set_palette     :near
extrn	gamma_correction:near
extrn	put_pixel       :near
extrn	load_put_PCX    :near
extrn	load_put_PCXX   :near
extrn	put_pic   	:near
extrn	decoding_PCX    :near
extrn	put_ch       	:near
extrn	put_string      :near

_TEXT   ENDS
