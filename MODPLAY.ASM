;께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께
;                Tiny MOD Player for Watcom C/C++32 and DOS/4GW
;                      Version 2.11a  June 5th, 1994
;
;                      Copyright 1993,94 Carlos Hasan
;
;               1995. 5. 18  fatal bug fixed by Kim, Seong-Wan
;                            PIC mask
;
;께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께께

ideal
p386
model   flat,c
smart

;굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇
; EQUATES AND PUBLICS
;굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇

MAXVOICES = 8                           ; number of voices
DMABUFLEN = 1024                        ; DMA buffer length (multiple of 64)
VOLBUFLEN = 66*256                      ; volume table length
MIXBUFLEN = 2*DMABUFLEN+2048            ; mixing/boosting buffer length
TIMERRATE = 17000             		; timer interrupt rate in ticks
					;   1193180/65536 =  18.2 Hz
					;   1193180/17000 =  70.2 Hz
					;   1193180/8500  = 140.4 Hz
					;   1193180/2386  = 500.1 Hz
					;   1193180/1194  = 999.3 Hz

global  MODPlayModule:proc
global  MODStopModule:proc
global  MODPlaySample:proc
global  MODStopSample:proc
global  MODSetPeriod:proc
global  MODSetVolume:proc
global  MODSetMusicVolume:proc
global  MODSetSampleVolume:proc
global  MODDetectCard:proc
global  MODPoll:proc
global  MODVoiceTable:dword

global  TimerTicks:dword
global	InstallTimer:proc
global	DeinstallTimer:proc

;굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇
; STRUCTURES
;굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇

struc   module                          ; module structure
  numtracks     dw      ?               ; number of tracks
  orderlen      dw      ?               ; order length
  orders        db      128 dup (?)     ; order list
  patterns      dd      128 dup (?)     ; pattern addresses
  sampptr       dd      32 dup (?)      ; sample start addresses
  sampend       dd      32 dup (?)      ; sample end addresses
  samploop      dd      32 dup (?)      ; sample loop point addresses
  sampvolume    db      32 dup (?)      ; sample default volumes
ends    module

struc   sample                          ; sample structure
  period        dw      ?               ; default period
  volume        dw      ?               ; default volume
  datalen       dd      ?               ; sample data length
  dataptr       dd      ?               ; sample data address
ends    sample

struc   track                           ; track structure
  note          dw      ?               ; note index
  period        dw      ?               ; period value
  inst          db      ?               ; instrument
  volume        db      ?               ; volume
  effect        dw      ?               ; effect
  destperiod    dw      ?               ; toneporta wanted period
  tonespeed     db      ?               ; toneporta speed
  vibparm       db      ?               ; vibrato depth/rate
  vibpos        db      ?               ; vibrato wave position
  tremparm      db      ?               ; tremolo depth/rate
  trempos       db      ?               ; tremolo wave position
		db      ?               ; alignment
  arptable      dw      3 dup (?)       ; arpeggio periods
ends    track

;굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇
; DATA
;굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇

;갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚
; Module Player data
;갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚
udataseg

moduleptr       dd      ?               ; current module address
pattptr         dd      ?               ; current playing pattern address
orderpos        db      ?               ; order position
orderlen        db      ?               ; order length
pattrow         db      ?               ; pattern row
tempo           db      ?               ; tempo
tempocount      db      ?               ; tempo counter
bpm             db      ?               ; beats per minute
musicvolume     db      ?               ; music channels volume
samplevolume    db      ?               ; sample channels volume
numtracks       dw      ?               ; number of tracks
tracks          track   MAXVOICES dup (?)

pitchtable      dd      3425 dup (?)    ; period to pitch table

TimerTicks      dd      ?               ;

; Amiga period table
dataseg

periodtable     dw      0
		dw      3424,3232,3048,2880,2712,2560,2416,2280,2152,2032,1920,1812
		dw      1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,960,906
		dw      856,808,762,720,678,640,604,570,538,508,480,453
		dw      428,404,381,360,339,320,302,285,269,254,240,226
		dw      214,202,190,180,170,160,151,143,135,127,120,113
		dw      107,101,95,90,85,80,75,71,67,63,60,56
		dw      53,50,47,45,42,40,37,35,33,31,30,28

; Sinus wave table

sintable        db      0,25,50,74,98,120,142,162,180,197,212,225
		db      236,244,250,254,255,254,250,244,236,225
		db      212,197,180,162,142,120,98,74,50,25

;갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚
; Sound Blaster driver data
;갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚
udataseg

; Voices programmable parameters

label MODVoiceTable dword

voicepos        dd      MAXVOICES dup (?)
voiceend        dd      MAXVOICES dup (?)
voiceloop       dd      MAXVOICES dup (?)
voicefrac       dd      MAXVOICES dup (?)
voicepitch      dd      MAXVOICES dup (?)
voicevolume     dd      MAXVOICES dup (?)

; Internal driver data
dataseg

mixbuffer       dd      ?               ; mixing buffer address
boosttable      dd      ?               ; boosting table address
voltable        dd      ?               ; volume table address
numvoices       dw      ?               ; number of active voices
mixfreq         dw      ?               ; playback frequency
ioaddr          dw      ?               ; card I/O port address
irqnum          db      ?               ; card IRQ level
drqnum          db      ?               ; card DMA channel
timerproc       dd      ?               ; timer callback address
timeracc        dd      ?               ; timer callback accumulator
timerspeed      dd      ?               ; timer callback speed
datasel         dw      ?               ; flat model data selector
bufsel          dw      ?               ; DOS memory block selector
bufptr          dd      ?               ; DMA buffer address
bufoff          dd      ?               ; double buffer offset
oldirqoff       dd      ?               ; old IRQ vector address
oldirqsel       dw      ?
oldirqmask      dw      ?               ; old PIC mask register setting
oldtimeroff     dd      ?               ; old timer IRQ0 vector address
oldtimersel     dw      ?
oldtimeracc     dw      ?               ; old timer accumulator
manualmode      db      ?               ; timer/manual polling mode
playing         db      0               ; playing/stopped status

;굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇
; CODE
;굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇굇
codeseg

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Copyright Strings
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

;db      'Tiny MOD Player V2.11 Copyright 1993,94 Carlos Hasan',0
;db      'Compiled on: ',??date,' ',??time,0

;갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚
; Module Player stuff
;갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; MODPlayModule - start playing a music module
; In:
;  Song  = module address
;  Chans = number of channels
;  Rate  = playback rate
;  Port  = port address
;  irq   = irq number
;  dma   = dma channel
;  mode  = polling mode
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
proc    MODPlayModule Song:dword,Chans:dword,Rate:dword,Port:dword,IRQ:dword,DRQ:dword,Mode:dword
	pushad

; setup the music module address

	mov     esi,[Song]
	mov     [moduleptr],esi

; setup the sound card driver

	mov     ax,[word Rate]
	mov     bl,[byte Chans]
	mov     dx,[word Port]
	mov     cl,[byte IRQ]
	mov     ch,[byte DRQ]
	mov     bh,[byte Mode]
	call    mixinit
	jc      playmoduled0

; build the period to pitch table (16.16 fixed point values)

	movzx   ebx,ax
	mov     eax,8363*428
	xor     edx,edx
	shld    edx,eax,16
	shl     eax,16
	div     ebx
	mov     esi,eax
	lea     edi,[pitchtable]
	mov     ecx,3425
	xor     ebx,ebx
playmodulel0:
	inc     ebx
	xor     edx,edx
	mov     eax,esi
	div     ebx
	mov     [edi],eax
        add     edi,4
        loop    playmodulel0

; setup global volumes for music and sample channels

        mov     [musicvolume],255
        mov     [samplevolume],255

; clear the module player track structures

        push    es
        mov     ax,ds
	mov     es,ax
        cld
        lea     edi,[tracks]
        mov     ecx,MAXVOICES*(size track)
        xor     al,al
        rep     stosb
        pop     es

; check if there is a module to playback

        xor     eax,eax
        mov     [numtracks],ax

        mov     esi,[moduleptr]
        test    esi,esi
        clc
        je      playmoduled0

; setup player interpreter variables

	mov     esi,[moduleptr]
        mov     ax,[esi+module.orderlen]
        mov     [orderlen],al
        mov     ax,[esi+module.numtracks]
        mov     [numtracks],ax
        mov     [tempo],6
        mov     [bpm],125
        mov     [orderpos],0
        mov     [tempocount],0
        mov     [pattrow],40h

; setup the player callback timer routine

        lea     edx,[pollmodule]
        call    mixsettimerproc
        mov     dl,[bpm]
        call    mixstarttimer
        clc

playmoduled0:
	popad
        sbb     eax,eax
        ret
endp    MODPlayModule

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; MODStopModule - shut down the music system
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
proc    MODStopModule
        pushad
        call    mixstoptimer            ; stop the timer callback
        call    mixdone                 ; shutdown the SB stuff
        popad
        ret
endp    MODStopModule

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; MODPoll - polls the music system in manual mode
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
proc    MODPoll
	pushad
        cmp     [manualmode],0          ; call the polling routine only
        je      modpolld0               ; if we are using the manual
        cmp     [playing],0             ; polling mode (and if the driver
        je      modpolld0               ; is active).
        call    mixpoll
modpolld0:
        popad
        ret
endp    MODPoll

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; MODPlaySample - play sample instrument
; In:
;  voice  = voice number
;  sample = sample address
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
proc    MODPlaySample Voice:dword,SamplePtr:dword
        pushad
        cli

; get the voice number and track address

        mov     ebx,[Voice]
        mov     edi,[SamplePtr]
        mov     esi,ebx
        imul    esi,size track

; set the voice pitch value

        movzx   eax,[edi+sample.period]
        mov     eax,[4*eax+pitchtable]
        mov     [4*ebx+voicepitch],eax

; set the voice sample parameters

        mov     eax,[edi+sample.dataptr]
        mov     [4*ebx+voicepos],eax
        add     eax,[edi+sample.datalen]
        mov     [4*ebx+voiceend],eax
	mov     [4*ebx+voiceloop],eax

; set the voice and track volumes

        mov     ax,[edi+sample.volume]
        mov     [esi+tracks.volume],al
        mul     [samplevolume]
        mov     [byte 4*ebx+voicevolume],ah

        sti
        popad
        ret
endp    MODPlaySample

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; MODStopSample - stop the playing sample
; In:
;  voice = voice number
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
proc    MODStopSample Voice:dword
	pushad
        cli

; get the voice number

        mov     ebx,[Voice]
        xor     eax,eax

; clear the voice sample parameters

        mov     [4*ebx+voicepos],eax
        mov     [4*ebx+voiceend],eax
        mov     [4*ebx+voiceloop],eax

        sti
        popad
        ret
endp    MODStopSample

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; MODSetPeriod -  set the voice period value
; In:
;  voice = voice number
;  period = period value (113-856)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
proc    MODSetPeriod Voice:dword,Period:dword
        pushad
        cli

; get the voice number and period value

        mov     ebx,[Voice]
        mov     eax,[Period]

; set the voice pitch value

        mov     eax,[4*eax+pitchtable]
        mov     [4*ebx+voicepitch],eax

        sti
	popad
        ret
endp    MODSetPeriod

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; MODSetVolume -  set the voice volume level
; In:
;  voice = voice number
;  volume = volume level (0-64)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
proc    MODSetVolume Voice:dword,Volume:dword
        pushad
        cli

; get the voice number and track address

        mov     ebx,[Voice]
        mov     eax,[Volume]
        mov     esi,ebx
        imul    esi,size track

; set the voice and track volume

        mov     [esi+tracks.volume],al
        mul     [samplevolume]
        mov     [byte 4*ebx+voicevolume],ah

        sti
        popad
        ret
endp    MODSetVolume

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; MODSetMusicVolume - set the global music volume
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
proc    MODSetMusicVolume Volume:dword
        pushad
        cli

; set new music volume

        mov     eax,[Volume]
        mov     [musicvolume],al

; update all the music voices

        lea     esi,[tracks]
        xor     ebx,ebx
setmusicvolumel0:
        mov     al,[esi+track.volume]
        mul     [musicvolume]
        mov     [byte 4*ebx+voicevolume],ah
        add     esi,size track
        inc     ebx
        cmp     bx,[numtracks]
        jb      setmusicvolumel0

        sti
        popad
        ret
endp    MODSetMusicVolume

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; MODSetSampleVolume - set the global sample volume
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
proc    MODSetSampleVolume Volume:dword
        pushad
        cli

; set the sample volume

        mov     eax,[Volume]
        mov     [samplevolume],al

; update all the sample voices

        lea     esi,[tracks]
        xor     ebx,ebx
setsamplevolumel0:
        cmp     bx,[numtracks]
	jb      setsamplevolumef0
        mov     al,[esi+track.volume]
        mul     [samplevolume]
        mov     [byte 4*ebx+voicevolume],ah
setsamplevolumef0:
        add     esi,size track
        inc     ebx
        cmp     bx,MAXVOICES
        jb      setsamplevolumel0

        sti
        popad
        ret
endp    MODSetSampleVolume

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; MODDetectCard - detect the Sound Blaster configuration
; Out:
;  Port = I/O Port
;  IRQ = IRQ level
;  DRQ = DMA channel
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
proc    MODDetectCard Port:dword,IRQ:dword,DRQ:dword
        pushad

; call the lowlevel autodetection routine

        call    mixdetect

; set the parameters in the user variables

        mov     eax,[Port]
        mov     [eax],dx
        mov     eax,[IRQ]
        mov     [eax],cl
        mov     eax,[DRQ]
        mov     [eax],ch

        popad
        sbb     eax,eax
	ret
endp    MODDetectCard

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; pollmodule - polls the module player
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
pollmodule:
        pushad
        dec     [tempocount]            ; decrease the tempo counter
        jle     pollmodulef0
        lea     esi,[tracks]            ; while in the same pattern row
        xor     ebx,ebx                 ; update the track effects.
pollmodulel0:
        call    updatechannel
        add     esi,size track
        inc     ebx
        cmp     bx,[numtracks]
        jb      pollmodulel0
        popad
        ret

pollmodulef0:                           ; advance to the next pattern row.
        mov     al,[tempo]              ; update the tempo counter
        mov     [tempocount],al
        mov     edx,[moduleptr]         ; get the module and pattern address
        mov     edi,[pattptr]
        cmp     [pattrow],40h           ; need to advance to the next order?
        jb      pollmodulef2
        xor     eax,eax                 ; reset the pattern row
        mov     [pattrow],al
        mov     al,[orderpos]           ; if we are at the end of the order
        cmp     al,[orderlen]           ; list, loop to the beginning
        jb      pollmodulef1
        xor     al,al
        mov     [orderpos],al
pollmodulef1:
        inc     [orderpos]              ; get the new pattern address
        movzx   eax,[edx+eax+module.orders]
        mov     edi,[edx+4*eax+module.patterns]
pollmodulef2:
	inc     [pattrow]               ; increase pattern row number
        lea     esi,[tracks]
        xor     ebx,ebx                 ; read and interpret the next
pollmodulel1:                           ; pattern row of events
        call    readchannel
        add     esi,size track
        add     edi,4
        inc     ebx
        cmp     bx,[numtracks]
        jb      pollmodulel1
        mov     [pattptr],edi           ; save pattern row address
        popad
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; readchannel - read the next note event from the pattern sheet
; In:
;  EBX = voice number
;  ESI = track address
;  EDI = pattern address
;  EDX = module address
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
readchannel:
        pushad

; check for new sample number . . .

        mov     al,[edi+1]
        test    al,al
        je      readchannelf0
        mov     [esi+track.inst],al
        movzx   eax,al
        mov     al,[edx+eax+module.sampvolume]
        mov     [esi+track.volume],al
        mul     [musicvolume]
        mov     [byte 4*ebx+voicevolume],ah

; check for new note pitch . . .

readchannelf0:
	mov     al,[edi]
        test    al,al
        je      readchannelf1
        movzx   eax,al
        mov     [esi+track.note],ax
        cmp     [byte edi+3],03h
        je      readchannelf1
        mov     ax,[2*eax+periodtable]
        mov     [esi+track.period],ax
        mov     eax,[4*eax+pitchtable]
        mov     [4*ebx+voicepitch],eax
        movzx   eax,[esi+track.inst]
        lea     edx,[4*eax+edx]
        mov     eax,[edx+module.sampptr]
        mov     [4*ebx+voicepos],eax
        mov     eax,[edx+module.sampend]
        mov     [4*ebx+voiceend],eax
        mov     eax,[edx+module.samploop]
        mov     [4*ebx+voiceloop],eax

; check the new track effect . . .

readchannelf1:
        mov     dx,[edi+2]
        mov     [esi+track.effect],dx
        movzx   eax,dh
        and     al,0Fh
        call    [4*eax+efxtable]

        popad
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; updatechannel - update the track using the current effect
; In:
;  EBX = voice number
;  ESI = track address
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
updatechannel:
        pushad
	mov     dx,[esi+track.effect]
        movzx   eax,dh
        and     al,0Fh
        call    [4*eax+efxtable2]
        popad
        ret

;갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚
; Protracker effects stuff
;갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; Effect jump tables
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같

        align   4

label efxtable dword
        dd      efxarpeggio             ; 0 - arpeggio
        dd      efxnull                 ; 1 - porta up
	dd      efxnull                 ; 2 - porta down
        dd      efxtoneporta            ; 3 - tone porta
        dd      efxvibrato              ; 4 - vibrato
        dd      efxnull                 ; 5 - tone+slide
        dd      efxnull                 ; 6 - vibrato+slide
        dd      efxtremolo              ; 7 - tremolo
        dd      efxnull                 ; 8 - unused
        dd      efxsampoffset           ; 9 - sample offset
        dd      efxnull                 ; A - volume slide
        dd      efxpattjump             ; B - pattern jump
        dd      efxsetvolume            ; C - set volume
        dd      efxbreak                ; D - break pattern
        dd      efxnull                 ; E - extra effects
        dd      efxsetspeed             ; F - set speed

label efxtable2 dword
        dd      efxarpeggio2            ; 0 - arpeggio
        dd      efxportaup              ; 1 - porta up
        dd      efxportadown            ; 2 - porta down
        dd      efxtoneporta2           ; 3 - tone porta
	dd      efxvibrato2             ; 4 - vibrato
        dd      efxtoneslide            ; 5 - tone+slide
        dd      efxvibslide             ; 6 - vibrato+slide
        dd      efxtremolo2             ; 7 - tremolo
        dd      efxnull                 ; 8 - unused
        dd      efxnull                 ; 9 - sample offset
        dd      efxvolslide             ; A - volume slide
        dd      efxnull                 ; B - pattern jump
        dd      efxnull                 ; C - set volume
        dd      efxnull                 ; D - break pattern
        dd      efxnull                 ; E - extra effects
        dd      efxnull                 ; F - set speed

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; efxnull - dummy effect
; In:
;  EBX = voice number
;  ESI = track address
;  DL = effect parameter
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
efxnull:
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; efxarpeggio - arpeggio
; In:
;  EBX = voice number
;  ESI = track address
;  DL = effect parameter
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
efxarpeggio:
        test    dl,dl
        je      efxnull
        mov     dh,dl
        and     dl,0Fh
        shr     dh,4
        movzx   eax,[esi+track.note]
        mov     cx,[2*eax+periodtable]
        mov     [esi+track.arptable],cx
        add     al,dh
	mov     cx,[2*eax+periodtable]
        mov     [esi+2+track.arptable],cx
        sub     al,dh
        add     al,dl
        mov     cx,[2*eax+periodtable]
        mov     [esi+4+track.arptable],cx
        ret
efxarpeggio2:
        test    dl,dl
        je      efxnull
        movzx   eax,[esi+track.arptable]
        xchg    [esi+4+track.arptable],ax
        xchg    [esi+2+track.arptable],ax
        mov     [esi+track.arptable],ax
        mov     eax,[4*eax+pitchtable]
        mov     [4*ebx+voicepitch],eax
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; efxportaup - slides the pitch up
; In:
;  EBX = voice number
;  ESI = track address
;  DL = effect parameter
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
efxportaup:
        xor     dh,dh
        movzx   eax,[esi+track.period]
        sub     ax,dx
        cmp     ax,28
        jge     efxportaupf0
        mov     ax,28
efxportaupf0:
        mov     [esi+track.period],ax
        mov     eax,[4*eax+pitchtable]
        mov     [4*ebx+voicepitch],eax
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; efxportadown - slides the pitch down
; In:
;  EBX = voice number
;  ESI = track address
;  DL = effect parameter
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
efxportadown:
        xor     dh,dh
        movzx   eax,[esi+track.period]
        add     ax,dx
        cmp     ax,3424
        jle     efxportadownf0
        mov     ax,3424
efxportadownf0:
        mov     [esi+track.period],ax
        mov     eax,[4*eax+pitchtable]
        mov     [4*ebx+voicepitch],eax
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; efxtoneporta - tone portamento
; In:
;  EBX = voice number
;  ESI = track address
;  DL = effect parameter
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
efxtoneporta:
        test    dl,dl
        jne     efxtoneportaf0
        mov     dl,[esi+track.tonespeed]
efxtoneportaf0:
        mov     [esi+track.tonespeed],dl
        mov     [esi+track.effect],dx
        movzx   eax,[esi+track.note]
        mov     ax,[2*eax+periodtable]
        mov     [esi+track.destperiod],ax
        ret
efxtoneporta2:
        xor     dh,dh
        movzx   eax,[esi+track.period]
        mov     cx,[esi+track.destperiod]
	cmp     ax,cx
        je      efxnull
        jg      efxtoneportaf1
        add     ax,dx
        cmp     ax,cx
        jle     efxtoneportaf2
        mov     ax,cx
efxtoneportaf2:
        mov     [esi+track.period],ax
        mov     eax,[4*eax+pitchtable]
        mov     [4*ebx+voicepitch],eax
        ret
efxtoneportaf1:
        sub     ax,dx
        cmp     ax,cx
        jge     efxtoneportaf3
        mov     ax,cx
efxtoneportaf3:
        mov     [esi+track.period],ax
        mov     eax,[4*eax+pitchtable]
	mov     [4*ebx+voicepitch],eax
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; efxvibrato - pitch vibrato
; In:
;  EBX = voice number
;  ESI = track address
;  DL = effect parameter
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
efxvibrato:
        mov     al,[esi+track.vibparm]
        mov     ah,al
        and     ax,0F00Fh
        test    dl,0Fh
        jne     efxvibratof0
        or      dl,al
efxvibratof0:
        test    dl,0F0h
        jne     efxvibratof1
	or      dl,ah
efxvibratof1:
        mov     [esi+track.vibparm],dl
        mov     [esi+track.effect],dx
        ret
efxvibrato2:
        mov     dh,dl
        and     dx,0F00Fh
        shr     dh,2
        mov     al,[esi+track.vibpos]
        add     [esi+track.vibpos],dh
        mov     dh,al
        shr     al,2
        and     eax,1Fh
        mov     al,[eax+sintable]
        mul     dl
        shr     ax,7
        test    dh,dh
        jge     efxvibratof2
        neg     ax
efxvibratof2:
        add     ax,[esi+track.period]
        cmp     ax,28
        jge     efxvibratof3
        mov     ax,28
efxvibratof3:
        cmp     ax,3424
        jle     efxvibratof4
        mov     ax,3424
efxvibratof4:
        movzx   eax,ax
        mov     eax,[4*eax+pitchtable]
        mov     [4*ebx+voicepitch],eax
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; efxtoneslide - volume slide and continue last portamento
; In:
;  EBX = voice number
;  ESI = track address
;  DL = effect parameter
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
efxtoneslide:
        call    efxvolslide
        mov     dl,[esi+track.tonespeed]
        jmp     efxtoneporta

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; efxvibslide - volume slide and continue last pitch vibrato
; In:
;  EBX = voice number
;  ESI = track address
;  DL = effect parameter
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
efxvibslide:
        call    efxvolslide
        mov     dl,[esi+track.vibparm]
        jmp     efxvibrato2

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; efxtremolo - volume vibrato
; In:
;  EBX = voice number
;  ESI = track address
;  DL = effect parameter
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
efxtremolo:
        mov     al,[esi+track.tremparm]
        mov     ah,al
        and     ax,0F00Fh
        test    dl,0Fh
        jne     efxtremolof0
        or      dl,al
efxtremolof0:
        test    dl,0F0h
        jne     efxtremolof1
        or      dl,ah
efxtremolof1:
        mov     [esi+track.tremparm],dl
        mov     [esi+track.effect],dx
	ret
efxtremolo2:
        mov     dh,dl
        and     dx,0F00Fh
        shr     dh,2
        mov     al,[esi+track.trempos]
        add     [esi+track.trempos],dh
        mov     dh,al
        shr     al,2
        and     eax,1Fh
        mov     al,[eax+sintable]
        mul     dl
        shr     ax,6
        test    dh,dh
        jge     efxtremolof2
        neg     ax
efxtremolof2:
        add     al,[esi+track.volume]
        jge     efxtremolof3
        xor     al,al
efxtremolof3:
        cmp     al,40h
        jle     efxtremolof4
        mov     al,40h
efxtremolof4:
        mul     [musicvolume]
        mov     [byte 4*ebx+voicevolume],ah
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; efxsampoffset - set the sample offset
; In:
;  EBX = voice number
;  ESI = track address
;  DL = effect parameter
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
efxsampoffset:
        movzx   eax,[esi+track.inst]
        mov     esi,[moduleptr]
        mov     eax,[esi+4*eax+module.sampptr]
	movzx   edx,dl
        shl     edx,8
        add     eax,edx
        mov     [4*ebx+voicepos],eax
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; efxvolslide - volume slide
; In:
;  EBX = voice number
;  ESI = track address
;  DL = effect parameter
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
efxvolslide:
        mov     al,[esi+track.volume]
        mov     dh,dl
        shr     dl,4
        je      efxvolslidef0
        add     al,dl
        cmp     al,40h
	jle     efxvolslidef1
        mov     al,40h
efxvolslidef1:
        mov     [esi+track.volume],al
        mul     [musicvolume]
        mov     [byte 4*ebx+voicevolume],ah
        ret
efxvolslidef0:
        sub     al,dh
        jge     efxvolslidef2
        xor     al,al
efxvolslidef2:
        mov     [esi+track.volume],al
        mul     [musicvolume]
        mov     [byte 4*ebx+voicevolume],ah
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; efxpattjump - jump to order pattern
; In:
;  EBX = voice number
;  ESI = track address
;  DL = effect parameter
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
efxpattjump:
        mov     [orderpos],dl
        mov     [pattrow],40h
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; efxsetvolume - set volume
; In:
;  EBX = voice number
;  ESI = track address
;  DL = effect parameter
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
efxsetvolume:
        mov     al,dl
        mov     [esi+track.volume],al
        mul     [musicvolume]
	mov     [byte 4*ebx+voicevolume],ah
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; efxbreak - break pattern
; In:
;  EBX = voice number
;  ESI = track address
;  DL = effect parameter
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
efxbreak:
        mov     [pattrow],40h
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; efxsetspeed - set the tempo or BPM speed
; In:
;  EBX = voice number
;  ESI = track address
;  DL = effect parameter
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
efxsetspeed:
        test    dl,dl
        je      efxnull
        cmp     dl,20h
        jae     efxsetbpm
        mov     [tempo],dl
        mov     [tempocount],dl
        ret
efxsetbpm:
        mov     [bpm],dl
        call    mixstarttimer
        ret

;갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚
; Sound Blaster Driver highlevel stuff
;갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; mixinit - initialize the sound driver
; In:
;  AX = mixing speed in hertz
;  BL = number of voices
;  DX = I/O port address
;  CL = IRQ level
;  CH = DRQ channel
;  BH = polling mode
; Out:
;  CF = status
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
mixinit:
        pushad

        cmp     [playing],0
        stc
        jne     mixinitd0

; setup sound card parameters

        mov     [manualmode],bh
	xor     bh,bh
        mov     [mixfreq],ax
        mov     [numvoices],bx
        mov     [ioaddr],dx
        mov     [irqnum],cl
        mov     [drqnum],ch

; check if the sound card is present

        call    sbreset
        jc      mixinitd0

; setup timer and double buffer variables

        mov     [timerproc],offset nulltimer
        xor     eax,eax
        mov     [bufoff],eax
        mov     [timeracc],eax
        mov     [timerspeed],256

; clear voice parameters

        push    es
        mov     ax,ds
        mov     es,ax
        cld
        lea     edi,[voicepos]
        mov     ecx,6*MAXVOICES
        xor     eax,eax
        rep     stosd
        pop     es

; allocate conventional memory for the DMA buffer, the volume table,
; the mixing buffer and the boosting table.

        mov     ax,0100h
        mov     bx,(DMABUFLEN+VOLBUFLEN+MIXBUFLEN+15)/16
        int     31h
        jc      mixinitd0
        mov     [bufsel],dx
	movzx   eax,ax
        shl     eax,4

; set the address of the mixing buffer and boosting table

        mov     [mixbuffer],eax
        add     eax,2*DMABUFLEN
        mov     [boosttable],eax
        add     eax,2048

; get the address of the DMA buffer and volume table

        mov     ecx,DMABUFLEN
        lea     edx,[eax+ecx]

; check for cross-pages in the DMA buffer and align the Volume table

        mov     esi,eax
        add     si,cx
        jnc     mixinitf0
	mov     edx,eax
        add     eax,VOLBUFLEN
mixinitf0:
        add     edx,255
        xor     dl,dl
        mov     [bufptr],eax
        mov     [voltable],edx

; clear DMA buffer with centered samples

        push    es
        mov     ax,ds
        mov     es,ax
        cld
        mov     edi,[bufptr]
        mov     ecx,DMABUFLEN
        mov     al,80h
        rep     stosb
        pop     es

; build volume table and boosting table

        mov     cl,6
        mov     edi,[voltable]
        xor     bx,bx
mixinitl0:
        mov     al,bl
        imul    bh
        sar     ax,cl
        mov     [edi],al
        inc     edi
        inc     bl
        jne     mixinitl0
        inc     bh
        cmp     bh,40h
        jbe     mixinitl0

        push    es
        mov     ax,ds
        mov     es,ax
	cld
        mov     edi,[boosttable]
        mov     ecx,768
        xor     ax,ax
        rep     stosb
        mov     ecx,512
mixinitl1:
        mov     [edi],ah
        add     ax,80h
        inc     edi
        loop    mixinitl1
        mov     ecx,768
        dec     al
        rep     stosb
        pop     es

; initialize the sound card for output

        call    dmasetup
        call    irqsetup
	call    sbsetup

; dont use the timer interrupt for manual polling mode

        cmp     [manualmode],0
        jne     mixinitf1

; install timer interrupt to poll the driver

        push    es
        mov     ax,cs
        mov     es,ax
        lea     ebx,[mixtimer]
        mov     cl,0
        call    irqsetvect
        mov     [oldtimeroff],ebx
        mov     [oldtimersel],es
        pop     es

; set the timer frequency to 70 hertz

	cli
	mov     al,36h
	out     43h,al
	mov     ax,TIMERRATE
	out     40h,al
	mov     al,ah
	out     40h,al
	sti

; set driver playing status

mixinitf1:
	mov     [playing],1
	clc

mixinitd0:
	popad
	ret

;-------------------------------------------
;
;
;
;-------------------------------------------
proc	InstallTimer

	pushad

	mov     [datasel],ds

; install timer interrupt to poll the driver

	push    es
	mov     ax,cs
	mov     es,ax
	lea     ebx,[timer]
	mov     cl,0
	call    irqsetvect
	mov     [oldtimeroff],ebx
	mov     [oldtimersel],es
	pop     es

; set the timer frequency to 70 hertz

	cli
	mov     al,36h
	out     43h,al
	mov     ax,TIMERRATE
	out     40h,al
	mov     al,ah
	out     40h,al
	sti

	popad
	ret

endp	InstallTimer

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; mixdone - deinitialize the sound driver
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
mixdone:
	pushad

	cmp     [playing],1
	jne     mixdoned0

; the timer interrupt was modified if we are using the timer polling mode

	cmp     [manualmode],0
	jne     mixdonef0

; restore the timer frequency to 18.2 hertz

	cli
	mov     al,36h
	out     43h,al
	xor     al,al
	out     40h,al
	out     40h,al
	sti

; deinstall timer interrupt used to poll the driver

	push    es
	mov     ebx,[oldtimeroff]
	mov     es,[oldtimersel]
	mov     cl,0
	call    irqsetvect
	pop     es

; deinitialize the sound card output

mixdonef0:
	call    sbdone
	call    irqdone
	call    dmadone

; free conventional memory block used for DMA buffer, volume table,
; mixing buffer and boosting table.

	mov     ax,0101h
	mov     dx,[bufsel]
	int     31h

; set driver stopped status

	mov     [playing],0

mixdoned0:
	popad
	ret

;---------------------------------------------
;
;
;
;---------------------------------------------
proc	DeinstallTimer
	pushad
; restore the timer frequency to 18.2 hertz

	cli
	mov     al,36h
	out     43h,al
	xor     al,al
	out     40h,al
	out     40h,al
	sti

; deinstall timer interrupt used to poll the driver

	push    es
	mov     ebx,[oldtimeroff]
	mov     es,[oldtimersel]
	mov     cl,0
	call    irqsetvect
	pop     es

	popad
	ret
endp

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; mixtimer - timer interrupt routine used to poll the sound driver
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
mixtimer:
	push    eax
	push    ds
	mov     ds,[cs:datasel]
	call    mixpoll                 ; poll the sound system
	inc     [TimerTicks]            ;
	add     [oldtimeracc],TIMERRATE
	jnc     mixtimerf0              ; time to call the old IRQ0 vector?
	pop     ds                      ; yes, jump to the old IRQ0 service
	pop     eax
	jmp     [fword cs:oldtimeroff]
mixtimerf0:
	mov     al,20h                  ; nope, send PIC acknowledge and exit
	out     20h,al
	pop     ds
	pop     eax
	iretd

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; timer - timer interrupt routine used to Timer
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
timer:
	push    eax
	push    ds
	mov     ds,[cs:datasel]
;	call    mixpoll                 ; poll the sound system
	inc     [TimerTicks]            ;
	add     [oldtimeracc],TIMERRATE
	jnc     timerf0              	; time to call the old IRQ0 vector?
	pop     ds                      ; yes, jump to the old IRQ0 service
	pop     eax
	jmp     [fword cs:oldtimeroff]
timerf0:
	mov     al,20h                  ; nope, send PIC acknowledge and exit
	out     20h,al
	pop     ds
	pop     eax
	iretd

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; mixdetect - detect the sound card configuration
; Out:
;  DX = I/O Port
;  CL = IRQ level
;  CH = DMA channel
;  CF = status
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
mixdetect:
	cmp     [playing],1             ; do not try to autodetect
        stc                             ; if we are already playing
        je      mixdetectd0
        call    sbdetect
mixdetectd0:
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; mixsettimerproc - set the timer procedure
; In:
;  EDX = timer routine address
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
mixsettimerproc:
        mov     [timerproc],edx         ; set the timer callback address
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; mixstarttimer - start the timer at the specified speed
; In:
;  DL = timer speed in beats per minute (BPMs)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
mixstarttimer:
        push    eax
        push    ebx
        push    edx
        mov     bh,dl                   ; set the timer callback speed
        xor     bl,bl                   ; to 24/60*BPM hertz
        mov     ax,[mixfreq]
        mov     dx,0280h
        mul     dx
        div     bx
	movzx   eax,ax
        mov     [timerspeed],eax
        pop     edx
        pop     ebx
        pop     eax
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; mixstoptimer - stop the timer routine
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
mixstoptimer:
        mov     [timerproc],offset nulltimer
nulltimer:
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; mixvoice - mixes the voice samples
; In:
;  EBX = voice number (*4)
;  ECX = number of samples
;  EDI = buffer address
; Out:
;  EDI = buffer end address
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
mixvoice:

        macro   mixcode OPCODE
        local   mixcodel0,mixjmptable

        push    eax
        push    ebx
        push    ecx
        push    edx
        push    ebp
        push    esi

        push    ebx
        mov     esi,[ebx+voicepos]
        mov     dl,[byte ebx+3+voicefrac]
        mov     dh,[byte ebx+1+voicepitch]
	movzx   ebp,[word ebx+2+voicepitch]
        mov     ebx,[ebx+voicevolume]
        mov     bh,bl
        add     ebx,[voltable]

        movzx   eax,cl
        and     al,31
        shr     ecx,5
        lea     edi,[edi+4*eax-4*32]
        jmp     [4*eax+mixjmptable]

        align   4
mixcodel0:
        I=0
        rept    32
CODESTART=$
        mov     bl,[esi]
        add     dl,dh
        movsx   eax,[byte ebx]
        adc     esi,ebp
	OPCODE  [edi+I],eax
CODELEN=$-CODESTART
        I=I+4
        endm
        add     edi,4*32
        dec     ecx
        jge     mixcodel0

        pop     ebx
        mov     [ebx+voicepos],esi
        mov     [byte ebx+3+voicefrac],dl

        pop     esi
        pop     ebp
        pop     edx
        pop     ecx
        pop     ebx
        pop     eax
        ret

	align   4
        label mixjmptable dword
        I=CODESTART+CODELEN
        rept    32
        dd      I
        I=I-CODELEN
        endm
        endm

        test    ebx,ebx
        je      mixvoicef0
        mixcode add
mixvoicef0:
        mixcode mov

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; mixvoices - mixes all the voices
; In:
;  EDI = buffer address
;  ECX = number of samples
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
mixvoices:
        pushad

        xor     ebx,ebx
mixvoicesl0:
        push    ebx
        push    ecx
        push    edi
        shl     ebx,2
        mov     ebp,ecx

mixvoicesl1:
        mov     ecx,ebp
        mov     edx,[ebx+voicepos]
        mov     eax,[ebx+voiceend]
        cmp     edx,eax
        jb      mixvoicesf0
        sub     edx,eax
        add     edx,[ebx+voiceloop]
	cmp     edx,eax
        jae     mixvoicesc0
        mov     [ebx+voicepos],edx

mixvoicesf0:
        sub     eax,edx
        shl     eax,16
        mov     edx,[ebx+voicefrac]
        shr     edx,16
        sub     eax,edx

        mov     edx,ecx
        mov     esi,[ebx+voicepitch]
        imul    edx,esi
        cmp     edx,eax
        jbe     mixvoicesf1
        dec     eax
        xor     edx,edx
	add     eax,esi
        adc     edx,edx
	div     esi
        mov     ecx,eax

mixvoicesf1:
        call    mixvoice
        sub     ebp,ecx
        jg      mixvoicesl1

        pop     edi
        pop     ecx
        pop     ebx
        inc     ebx
        cmp     bx,[numvoices]
        jb      mixvoicesl0

        popad
        ret

mixvoicesc0:
        test    ebx,ebx
	jne     mixvoicesc1
        push    es
        mov     ax,ds
        mov     es,ax
        xor     eax,eax
        cld
        rep     stosd
        pop     es

mixvoicesc1:
        pop     edi
        pop     ecx
        pop     ebx
        inc     ebx
        cmp     bx,[numvoices]
        jb      mixvoicesl0

        popad
	ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; mixpoll - updates the output buffer
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
mixpoll:
        pushad

; get the 32 bit mixing buffer address

        mov     ecx,DMABUFLEN/2
        mov     edi,[mixbuffer]

; check if we can fill the current half buffer with samples

        call    dmagetpos
        cmp     eax,ecx
        jae     mixpollf3
        cmp     [bufoff],ecx
        je      mixpollf4
	jmp     mixpolld0
mixpollf3:
	cmp     [bufoff],ecx
        je      mixpolld0

; fill the mixing buffer and polls the timer callback routine

mixpollf4:
        mov     eax,[timeracc]
        mov     ebp,ecx
mixpolll0:
        test    eax,eax
        jg      mixpollf0
        call    [timerproc]
        add     eax,[timerspeed]
mixpollf0:
        mov     ecx,eax
        add     ecx,63
        and     cl,not 63
        cmp     ecx,ebp
	jle     mixpollf1
        mov     ecx,ebp
mixpollf1:
        call    mixvoices
        lea     edi,[edi+4*ecx]
        sub     eax,ecx
        sub     ebp,ecx
        jg      mixpolll0
        mov     [timeracc],eax

; translate 32-bit signed samples to 8-bit unsigned samples

        mov     ecx,DMABUFLEN/2
        mov     esi,[mixbuffer]
        mov     edi,[bufptr]
        add     edi,[bufoff]
        xor     [bufoff],ecx
        mov     ebx,[boosttable]
        add     ebx,1024
        shr     ecx,4
mixpolll2:
        I=0
	rept    4
        mov     eax,[esi+16*I+8]
        mov     dl,[eax+ebx]
        mov     eax,[esi+16*I+12]
        mov     dh,[eax+ebx]
        shl     edx,16
        mov     eax,[esi+16*I]
        mov     dl,[eax+ebx]
        mov     eax,[esi+16*I+4]
        mov     dh,[eax+ebx]
        mov     [edi+4*I],edx
        I=I+1
        endm
        add     esi,4*16
        add     edi,16
        dec     ecx
        jg      mixpolll2

mixpolld0:
        popad
	ret

;갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚
; Sound Blaster DSP lowlevel stuff
;갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; sbwrite - send a command/data byte to the DSP chip
; In:
;  AL = command/data byte
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
sbwrite:
        push    eax
        push    ecx
        push    edx
        mov     dx,[ioaddr]
        add     dx,0Ch
        mov     ah,al
	mov     ecx,10000h              ; wait until the write buffer
sbwritel0:                              ; status port (2XCh) bit 7 is clear
	in      al,dx
        and     al,80h
        loopnz  sbwritel0
        mov     al,ah                   ; write value in the write
        out     dx,al                   ; data port (2XCh)
        pop     edx
        pop     ecx
        pop     eax
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; sbreset - reset the Sound Blaster DSP chip
; Out:
;  CF = status
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
sbreset:
        push    eax
        push    ebx
	push    ecx
        push    edx
	mov     ebx,64                  ; try to reset upto 64 times
sbresetl1:
        mov     dx,[ioaddr]
        add     dx,06h
        mov     al,1                    ; write 1 to the reset port (2X6h)
        out     dx,al
        xor     ah,ah                   ; wait at least 3 microseconds
sbresetl2:
        in      al,dx
        dec     ah
        jne     sbresetl2
        xor     al,al                   ; write 0 to the reset port (2X6h)
        out     dx,al
        add     dx,08h
        mov     ecx,0400h               ; wait until the data available
sbresetl0:                              ; status port (2XEh) bit 7 is set
        in      al,dx
        and     al,80h
	loopz   sbresetl0
        sub     dx,04h                  ; read the read data port (2XAh)
	in      al,dx
        cmp     al,0AAh
        clc
        je      sbresetd0               ; check the ready byte value
        dec     ebx
        jne     sbresetl1
        stc
sbresetd0:
        pop     edx
        pop     ecx
        pop     ebx
        pop     eax
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; sbsetup - start the DMA output
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
sbsetup:
	push    eax
        push    edx
	mov     al,0D1h                 ; turn on the speaker
        call    sbwrite
        mov     al,40h                  ; set the playback rate
        call    sbwrite
        mov     ax,1000
        mul     ax
        div     [mixfreq]
        neg     ax
        call    sbwrite
        mov     al,14h                  ; start the lowspeed 8 bit DMA
        call    sbwrite                 ; mode transfer to the DAC
        mov     al,0FFh
        call    sbwrite
        call    sbwrite
        pop     edx
        pop     eax
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; sbdone - shut down the DMA output
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
sbdone:
        push    eax
        call    sbreset                 ; reset the DSP chip
        mov     al,0D3h
        call    sbwrite                 ; turn off the speaker
        pop     eax
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; sbdetect - Detect the Sound Blaster I/O Port, IRQ level and DMA channel
; Out:
;  DX = I/O port address
;  CL = IRQ level
;  CH = DMA channel
;  CF = status
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
sbdetect:
	mov     dx,210h                 ; scan the ports 210h..260h
sbdetectl0:
	mov     [ioaddr],dx             ; check if there is a SB card
        call    sbreset                 ; trying to reset the DSP chip
        jnc     sbdetectf0
        add     dx,10h
        cmp     dx,260h
        jbe     sbdetectl0
        xor     dx,dx
        xor     cx,cx
        stc
        ret
sbdetectf0:
        push    eax
        push    ebx
        push    ecx
        push    es

        push    eax                     ; save PIC mask register
        in      al,0A1h
	mov     ah,al
        in      al,21h
	mov     [oldirqmask],ax
        pop     eax
        
        mov     [datasel],ds

        irp     I,<2,3,5,7,10>          ; install IRQ traps
        push    cs
        pop     es
        lea     ebx,[irqtest&I]
        mov     cx,I
        call    irqsetvect
        call    irqsetmask
        push    ebx
        push    es
        endm

        mov     [irqnum],0

	mov     al,0F2h                 ; ask to the DSP to raise a IRQ
        call    sbwrite

        mov     ecx,10000h              ; wait until some IRQ occurs
sbdetectl1:
        cmp     [irqnum],0
        loope   sbdetectl1

        push    eax                     ; restore PIC mask register 
        mov     ax,[oldirqmask]
        out     21h,al
        mov     al,ah
        out     0A1h,al
        pop     eax
        
        irp     I,<10,7,5,3,2>          ; deinstall IRQ traps
        pop     es
        pop     ebx
        mov     cx,I
        call    irqsetvect
	endm

	pop     es
        pop     ecx
        pop     ebx
        pop     eax
        mov     dx,[ioaddr]             ; return the SB parameters
        mov     cl,[irqnum]
        xor     ch,ch
        sub     ch,cl
        mov     ch,1
        cmc
        ret

;갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚
; Sound Blaster DMA lowlevel stuff
;갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; dmasetup - setup the DMA buffer parameters
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
dmasetup:
	push    eax
        push    ebx
        push    ecx
        push    edx

        mov     bl,[drqnum]
        mov     al,bl
        or      al,04h                  ; reset the DMA channel
        out     0Ah,al
        out     0Ch,al                  ; clear the flip flop
        mov     al,bl
        or      al,58h                  ; set the autoinit mode
        out     0Bh,al
        movzx   dx,bl
        add     dx,dx
        mov     eax,[bufptr]            ; set the buffer address
        out     dx,al
        mov     al,ah
	out     dx,al
        inc     dx
	mov     ax,DMABUFLEN            ; set the buffer length
        dec     ax
        out     dx,al
        mov     al,ah
        out     dx,al
        mov     edx,82818387h           ; set the buffer page
        mov     cl,bl
        shl     cl,3
        shr     edx,cl
        xor     dh,dh
        shr     eax,16
        out     dx,al
        mov     al,bl                   ; unlock the DMA channel
        out     0Ah,al

        pop     edx
        pop     ecx
        pop     ebx
	pop     eax
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; dmadone - shut down the DMA controller
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
dmadone:
        push    eax
        mov     al,[drqnum]             ; reset the DMA channel
        or      al,04h
        out     0Ah,al
        pop     eax
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; dmagetpos - return the DMA buffer relative position
; Out:
;  EAX = buffer relative position
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
dmagetpos:
	push    ecx
        push    edx
	out     0Ch,al                  ; clear the flip flop
        mov     dl,[drqnum]
        xor     dh,dh
        add     dl,dl
        inc     dl
        in      al,dx                   ; read the DMA counter
        mov     ah,al
        in      al,dx
        xchg    al,ah
dmagetposl0:
        mov     cx,ax                   ; read again the DMA counter
        in      al,dx
        mov     ah,al
        in      al,dx
        xchg    al,ah
        sub     cx,ax
        cmp     cx,+16                  ; both values are near?
        jg      dmagetposl0             ; nope, try again
	cmp     cx,-16
        jl      dmagetposl0
	movzx   eax,ax                  ; get the position relative
        neg     eax                     ; to the start of the buffer
        add     eax,DMABUFLEN
        pop     edx
        pop     ecx
        ret

;갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚
; Sound Blaster IRQ lowlevel stuff
;갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚갚

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; irqsetvect - set the IRQ handler routine
; In:
;  ES:EBX = IRQ handler routine address
;  CL = IRQ level
; Out:
;  ES:EBX = previous IRQ handler address
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
irqsetvect:
	push    eax
        push    ecx
        push    edx

; get the PIC interrupt master and slave base address

        push    ebx
        push    ecx
        mov     ax,0400h
        int     31h
        pop     ecx
        pop     ebx

; get the IDT interrupt slot number for the IRQ number

        mov     al,cl
        cmp     al,08h
        jb      irqsetvectf0
	mov     dh,dl
        sub     al,08h
irqsetvectf0:
        add     al,dh

; saves and change the IRQ handler routine

        push    ds
        push    es
        push    ebx
        mov     ah,35h
        int     21h
        pop     edx
        pop     ds
        push    es
        push    ebx
        mov     ah,25h
        int     21h
        pop     ebx
        pop     es
	pop     ds

	pop     edx
        pop     ecx
        pop     eax
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; irqsetmask - enable or disable the IRQ in the interrupt mask registers
; In:
;  CL = IRQ level
;  CH = enable (=0) or disable (=1)
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
irqsetmask:
        push    eax
        push    edx

        in      al,0A1h                 ; enable or disable the specified
        mov     ah,al                   ; IRQ using the PIC interrupt
	in      al,21h                  ; mask registers

        mov     dx,1
	shl     dx,cl
        not     dx
        and     ax,dx
        
        xor     dx,dx                   ; !! BUG FIXED
        mov     dl,ch
        shl     dx,cl
        or      ax,dx
        
        out     21h,al
        mov     al,ah
        out     0A1h,al

        pop     edx
        pop     eax
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; irqsetup - install the IRQ handler routine
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
irqsetup:
        push    eax
        push    ebx
        push    ecx

; setup DS data selector used by the interrupt handler

        mov     [datasel],ds

; set the IRQ handler routine and saves the previous vector

        push    es
        mov     ax,cs
        mov     es,ax
        lea     ebx,[irqhandler]
        mov     cl,[irqnum]
        call    irqsetvect
        mov     [oldirqoff],ebx
	mov     [oldirqsel],es
        pop     es

; enable the IRQ signals in the PIC interrupt mask
        
        push    eax
        in      al,0A1h
        mov     ah,al
        in      al,21h
        mov     [oldirqmask],ax
        pop     eax
        
        mov     cl,[irqnum]
        mov     ch,0
        call    irqsetmask

        pop     ecx
        pop     ebx
        pop     eax
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; irqdone - restores the old IRQ handler routine
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
irqdone:
        push    ebx
        push    ecx

; disable IRQ signals in the PIC interrupt mask register
;        mov     cl,[irqnum]
;        mov     ch,1
;        call    irqsetmask

        push    eax                     ; restore PIC mask register 
        mov     ax,[oldirqmask]
        out     21h,al
        mov     al,ah
        out     0A1h,al
        pop     eax

; restore the old IRQ handler routine

	push    es
        mov     ebx,[oldirqoff]
        mov     es,[oldirqsel]
        mov     cl,[irqnum]
        call    irqsetvect
        pop     es

        pop     ecx
        pop     ebx
        ret

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; irqhandler - hardware IRQ handler routine
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
irqhandler:
        push    eax
        push    edx
        push    ds
	mov     ds,[cs:datasel]

; send acknowledge to the PIC controller

        mov     al,20h
        cmp     [irqnum],08h
        jb      irqhandlerf0
        out     0A0h,al
irqhandlerf0:
        out     20h,al

; send acknowledge to the DSP chip reading the 8 bit ack port (2XEh)

        mov     dx,[ioaddr]
        add     dx,0Eh
        in      al,dx

; restart the 8 bit DMA mode playback transfer

        mov     al,14h
	call    sbwrite
        mov     al,0FFh
	call    sbwrite
        call    sbwrite

        pop     ds
        pop     edx
        pop     eax
        iretd

;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
; irqtest - testing hardware IRQ handler routine
;같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같같
irqtest:
        push    edx                     ; common IRQ test handler code
        push    ds                      ; used for autodetection
        mov     ds,[cs:datasel]
        mov     [irqnum],al             ; save the IRQ level number
        mov     dx,[ioaddr]             ; send acknowledge signal to the
        add     dx,0Eh                  ; DSP reading the ack port (2XEh)
	in      al,dx
        mov     al,20h                  ; send acknowledge to the PIC
	cmp     [irqnum],08h            ; controllers
        jb      irqtestf0
        out     0A0h,al
irqtestf0:
        out     20h,al
        pop     ds
        pop     edx
        pop     eax
        iretd

        irp     I,<2,3,5,7,10>          ; IRQ test handlers for each
irqtest&I:                              ; possible IRQ levels
        push    eax
        mov     ax,I
        jmp     irqtest
        endm

end
