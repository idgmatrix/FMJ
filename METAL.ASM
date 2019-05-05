;==========================================================
;   Subject : FULL METAL JACKET
;   File : METAL.ASM ( main assembly module for F.M.J. )
;
;   32 bits protected mode program under DOS4GW
;   graphics : VGA non-standard 320 * 240 256 color mode
;
;   Copyright (c) 1995 MIRINAE Software, Inc.
;
;   coded by KIM SEONG-WAN
;
;  1995. 6. 10  First created
;  1995. 6. 14  Full 32 bits fixed point calculation
;  1995. 6. 24  Shadow
;=========================================================
	.386

	LOCALS

	include keyscan.inc             ; keyboard scan code defnition
	include VGA.INC                 ; VGA register and etc..

_GOTO           equ     230
DSPEED          equ     5
BSPEED          equ     8
LASAPOSX        equ     64+128-13
LASAPOSY        equ     200-14
RECLEN          equ     2048

LBOUND  equ     64
RBOUND  equ     319
UBOUND  equ     0
DBOUND  equ     239

STAY    equ     00000b    ;    0
FORW    equ     00001b    ;    1
BACK    equ     00011b    ;    3
LEFT    equ     00100b    ;    4
RIGH    equ     01100b    ;   12
FIRE    equ     10000b    ;   16
BUST    equ    100000b    ;   32
ACCL    equ   1000000b    ;
SHFT    equ  10000000b    ;

_VALCAN_        equ     0
_PING_          equ     1
_EXPLO0_        equ     2
_ARROW_         equ     3
_ESC_           equ     4
_ENTER_         equ     5
_SIREN_         equ     6
_BAND_          equ     7
_SLD_           equ     8
_GUNDRY_        equ     9
_EXPLO1_        equ     10
_EXPLO2_        equ     11
_SGUNSH_        equ     12
_SGUNAC_        equ     13
_CANNON_        equ     14
_FTHROW_        equ     15
_MGUN_          equ     16
_DROP_          equ     17
_BUSTON_        equ     18
_BUST_          equ     19

MAXOBJ  equ     150
OBJNO   equ     3
OBJWID  equ     49

OBJECT  struc

	obj_no          dd      ?       ;4 1

	x_              dd      ?       ;4 2 0 - 2047 coordinate
	y_              dd      ?       ;4 3 0 - 2047
	z               dw      ?       ;2 4
	vth             db      ?       ;1 5 0 - 255 anngle of viewing
	dvth            db      ?       ;1 6 delta angle of viewing

	mth             db      ?       ;1 7 angle of moving
	dmth            db      ?       ;1 8 angle of moving
	dth             db      ?       ;1
	ddir            dw      ?       ;2 9 direction
	dspeed          dw      ?       ;2 10
	dlz             dw      ?       ;2 11 delta z

	dis             dw      ?       ;2 12 displacement
	theta           db      ?       ;1 13 angle
	freem           db      ?       ;1 14

	spr_no          dd      ?       ;4 15 sprite number
	spr_data        dd      ?       ;4 16 pointer of sprite data
	crs_pointer     dd      ?       ;4 17 pointer of course data

	stat            dd      ?       ;4 18 status
	energy          dw      ?       ;2 19
	xc              db      ?       ;1 20
	yc              db      ?       ;1 21
					;  total 50 bytes
OBJECT  ends

HostWeapon      struc
	ArmsFlag        dw      ?       ;
	ArmsCnt         dw      ?       ;
HostWeapon      ends

DGROUP  GROUP _DATA,_BSS

PUBLIC  _mission_no
PUBLIC  _replay
PUBLIC  eye_x
PUBLIC  eye_x_
PUBLIC  eye_y
PUBLIC  eye_y_
PUBLIC  eye_z
PUBLIC  eye_zd

PUBLIC  eye_th
PUBLIC  d_th
PUBLIC  dif

PUBLIC  shadow_d
PUBLIC  shadow_dx
PUBLIC  shadow_dy

PUBLIC  pers

PUBLIC  mapw_z
PUBLIC  mapw_zd

PUBLIC  read_plane

PUBLIC  Lbound
PUBLIC  Rbound
PUBLIC  Ubound
PUBLIC  Dbound

PUBLIC  SIN

PUBLIC  xx

PUBLIC  ey1
PUBLIC  ey2

PUBLIC  x1
PUBLIC  y1
PUBLIC  z1
PUBLIC  x2
PUBLIC  y2
PUBLIC  z2

PUBLIC  xx_
PUBLIC  yy_
PUBLIC  zz_

PUBLIC  ey1_
PUBLIC  ey2_

PUBLIC  x1_
PUBLIC  y1_
PUBLIC  z1_
PUBLIC  x2_
PUBLIC  y2_
PUBLIC  z2_

PUBLIC  xa_
PUBLIC  ya_

PUBLIC  lstart

PUBLIC  sine
PUBLIC  cosine

PUBLIC  sined
PUBLIC  cosined

PUBLIC  TIL_load
PUBLIC  PAL
;PUBLIC ATTR
PUBLIC  TIL

PUBLIC  PALtmp

PUBLIC  MAP_load
PUBLIC  TEXMAP
PUBLIC  TEXMAPADD

PUBLIC  DARKER_TABLE
PUBLIC  key_hit

PUBLIC  _XC_
PUBLIC  _YC_
PUBLIC  _SONGptr_

	include GRPLIB.ASH              ; graphics lib. header file
	include FILES.ASH               ; file
	include FLI.ASH                 ; flic file player

_DATA   SEGMENT PUBLIC USE32 DWORD 'DATA'

extrn   AP_spr_data: dword
extrn   holo_spr_data: dword

extrn   danger_spr_data: word
extrn   panel_spr_data: word
extrn   compas_spr_data: word
extrn   mfd1_spr_data: word
extrn   mfd2_spr_data: word
extrn   mfd3_spr_data: word
extrn   curse_spr_data: word

extrn   lamp1_spr_data: dword
extrn   lamp2_spr_data: dword
extrn   noise_spr_data: dword
extrn   flm1_spr_data: dword
extrn   flm2_spr_data: dword
extrn   flm3_spr_data: dword
extrn   flm4_spr_data: dword
extrn   chip1_spr_data: dword
extrn   chip2_spr_data: dword
extrn   dust1_spr_data: dword
extrn   smk1_spr_data: dword
extrn   tbomb_spr_data: dword
extrn   mine_spr_data: dword

extrn   en1_spr_data: dword
extrn   en2_spr_data: dword
extrn   en3_spr_data: dword
extrn   en4_spr_data: dword
extrn   tank1_spr_data: dword
extrn   tank2_spr_data: dword
extrn   tank3_spr_data: dword
extrn   ttop1_spr_data: dword
extrn   ttop2_spr_data: dword
extrn   ttop3_spr_data: dword

_DATA   ENDS

_BSS    SEGMENT PUBLIC USE32 DWORD 'BSS'

extrn   _SOUND:dword
extrn   _TimerTicks:dword
extrn   obj_x_:dword
extrn   obj_y_:dword

extrn   _HostW:HostWeapon    ; pointer of weapon structure

extrn   _MissionNumber:dword   ;
extrn   _SuccessFlag:dword   ;
extrn   _FirstMission:dword   ;

extrn   _FMJTotalScore:dword            ;16000

extrn   _ResolutionAdjust:dword;               // 해상도 조절 변수.(외부에서 사용함)
extrn   _ScreenSizeAdjust:dword;               // 화면 크기 조절 변수.(외부에서 사용함)
extrn   _BrightAdjust:dword;                   // 밝기 조절 변수.(외부에서 사용함)
extrn   _EffectAdjust:dword;                   // 효과음 조절 변수.(외부에서 사용함)
extrn   _MusicAdjust:dword;                    // 음악 조절 변수.(외부에서 사용함)

_BSS    ENDS

_DATA   SEGMENT PUBLIC USE32 DWORD 'DATA'

_XC_    dd      0
_YC_    dd      0

eye_x   dw      50;1020                    ;observer's X coordinates
eye_x_  dd      50 SHL 16;1020 SHL 16             ;32 bits fixed point coordinate
eye_y   dw      80;1024                    ;observer's Y coordinates
eye_y_  dd      80 SHL 16; 1024 SHL 16             ;32 bits fixed point coordinate
eye_z   dw      128                     ;view hight
eye_zd  dd      128                     ;

holo_x_ dd      0
holo_y_ dd      0
holo_stat       db      0

eye_th  db      0                       ;observer's viewing direction
d_th    db      64 * 3                  ;observer's moving direction
dif     dw      0                       ;observer's moving speed

AP_energy       dd      300
weapon_no       dd      0
weapon_rounds   dd      0, 0, 0, 0  ; valcan, minigun, shotgun, utan
		dd      0, 0, 0     ; Time-bomb, Holo-mine, mine
		dd      0, 0        ; missiles, guided missile
shiled          dd      0
buster          dd      0

weapon_power    dw        3,   2,   4,  25
		dw      100,  80, 150
		dw       80,  60

weapon_range    dw      0,0, 20,20, 80,80,40, 15,15

;;     1800,  100, 1350,  80, 3150, 200, 3800,  300,   Guns
;;       60,   95,   50,                               Bombs
;;     2500,   30, 3200,  30,                          Missiles
;;      900, 1000,                                     Shildes
;;     4500, 4700, 5000                                Busters

Armsno  label   dword
	dd 0, 0, 1, 1, 2, 2, 3, 3
	dd 4, 5, 6
	dd 7, 7, 8, 8
	dd 9, 9
	dd 10,10,10

ArmsPower       label   dword     ; number of rounds
	dd 0, 800, 0, 500, 0, 100, 0, 20
	dd 1, 1, 1
	dd 0, 1, 0, 1
	dd 150, 280
	dd 30, 40, 60

		;;;;;
FIRE_delay      dw      0
FIRE_delay_table label word
		dw      0, 0, 5, 6, 6, 6, 6, 8, 8

shadow_d        dw      5
shadow_dx       dw      0
shadow_dy       dw      0

pers    dw      128                     ;perspective factor

mapw_z   dw      1500                   ;map window view hight
mapw_zd  dd      1500                   ;

read_plane      db      0
th_flag         db      0

Lbound          dd      64
Rbound          dd      319
Ubound          dd      0
Dbound          dd      239

SIN     label   word                    ;sine function table
	include sine.inc                ;

_mission_no     dd   1         ; (1 - 15)
mission_number  dd   8,10,3,1,12, 11,0,4,14,9, 13,5,7,2,6
mission_type    dd   1, 2,3,9, 8, 10,5,9,8,13, 5,8,1,12,7

mission_goal    db   1,0,0, 0
		db   1,0,1, 0
		db   0,1,0, 0
		db   0,1,1, 0
		db   1,1,0, 0

		db   1,1,1, 0
		db   1,2,0, 0
		db   1,2,2, 0
		db   0,2,0, 0
		db   0,2,1, 0

		db   0,2,2, 0
		db   2,0,0, 0
		db   1,0,2, 0
		db   0,1,2, 0

mission_goal_ok db   0,0,0

target_destruction      db      0

kill_enemy      db   10,0,0,0,0, 0,20,0,0,0, 20,0,25,30,25
;kill_enemy     db    1,0,0,0,0, 0,20,0,0,0, 20,0,25,30,25

time_counter1   dd   2000
time_counter2   dd   2000
time_counter3   dd   2000

return_pos_x_   dd   0
return_pos_y_   dd   0
return_dis      dw   0
return_theta    db   0

enemy_gold      db   35,35,40,40,30,35,30,25,20,25
enemy_score     dw   0

BONUS           dw   600,700,800,850,900,1200,1250,1350,1400,1500
		dw   1600,1700,2000,2000,0

mapfilename     db   "fmjk1   .map",0     ;0
		db   "fmjk2   .map",0     ;1
		db   "fmjk3   .map",0     ;2
		db   "fmjk4   .map",0     ;3
		db   "fmjk5   .map",0     ;4
		db   "fmjk6   .map",0     ;5
		db   "fmjk7   .map",0     ;6
		db   "fmjk8   .map",0     ;7
		db   "fmjk9   .map",0     ;8
		db   "fmjk10  .map",0     ;9
		db   "fmjk11  .map",0     ;10
		db   "fmjk12  .map",0     ;11
		db   "fmjk13  .map",0     ;12
		db   "fmjk14  .map",0     ;13
		db   "fmjk15  .map",0     ;14

tilefilename    db   "fmj5    .til",0     ;0
		db   "fmj6    .til",0     ;1
		db   "fmj7    .til",0     ;2
		db   "fmj8    .til",0     ;3
		db   "fmj9    .til",0     ;4
		db   "fmj10   .til",0     ;5
		db   "fmje1   .til",0     ;6
		db   "fmjx1   .til",0     ;7
		db   "fmj2-2  .til",0     ;8
		db   "fmje2   .til",0     ;9
		db   "fmje2   .til",0     ;10
		db   "fmje2   .til",0     ;11
		db   "fmje4   .til",0     ;12
		db   "fmje4   .til",0     ;13
		db   "fmje4   .til",0     ;14

tilefilenameD   db   "fmj5d   .til",0
		db   "fmj6d   .til",0
		db   "fmj7d   .til",0
		db   "fmj8d   .til",0
		db   "fmj9d   .til",0
		db   "fmj10d  .til",0
		db   "fmje1d  .til",0
		db   "fmjx1d  .til",0
		db   "fmj2-2d .til",0
		db   "fmje2-d1.til",0
		db   "fmje2-d1.til",0
		db   "fmje2-d1.til",0
		db   "fmje4-d1.til",0
		db   "fmje4-d1.til",0
		db   "fmje4-d1.til",0

;; file name table
filename02      db   "fmj.pal",0
filename03      db   "record.sav",0
filename04      db   "mire.fli",0
filename041     db   "title.dat",0
filename051     db   "fmjopen1.fli",0
filename052     db   "fmjopen2.fli",0
filename053     db   "fmjopen3.fli",0
filename054     db   "fmjopen4.fli",0
filename06      db   "tit-end.GRP",0
filename07      db   "credit.GRP",0
filename08      db   "end1.dat",0
filename09      db   "end2.dat",0   ; password image data

SONG    label   dword
	dd      SONG01,SONG02,SONG03,SONG04,SONG05
	dd      SONG06,SONG07,SONG08,SONG09,SONG10
	dd      SONG11,SONG12,SONG13,SONG14,SONG15

SONG_OPEN       db   "fm001.mod",0   ;
SONG_MENU       db   "fm017.mod",0   ;
SONG_END        db   "fm015.mod",0  ;

SONG01          db   "fm002.mod",0   ; 1 desert
SONG02          db   "fm000.mod",0   ; 2 jungle
SONG03          db   "fm003.mod",0   ; 3 desert
SONG04          db   "fm004.mod",0   ; 4
SONG05          db   "fm008.mod",0   ; 5 iceland
SONG06          db   "fm005.mod",0   ; 6 jungle
SONG07          db   "fm007.mod",0   ; 7
SONG08          db   "fm010.mod",0   ; 8 desert
SONG09          db   "fm008.mod",0   ; 9 iceland
SONG10          db   "fm013.mod",0   ;10 jungle
SONG11          db   "fm008.mod",0   ;11 iceland
SONG12          db   "fm002.mod",0   ;12 desert
SONG13          db   "fm014.mod",0   ;13
SONG14          db   "fm018.mod",0   ;14
SONG15          db   "fm101.mod",0   ;15

TITLES          db   "FULL METAL JACKET 1.0",0
TARGETS         db   "TARGETS DETECTED",0
RETURNS         db   "RETURN POSITION DETECTED",0
MISSION_ACCOM   db   "MISSION ACCOMPLISHED",0
EN_KILLED       db   "ENEMY DESTROYED",0
GOLDS           db   "GOLDS",0
MISSION_BONUS   db   "MISSION BONUS",0
TOTAL_GOLDS     db   "TOTAL GOLDS",0
PRESS           db   "PRESS [ENTER] KEY",0
STRING          db   10 dup(0)

VAC     db      "V-T103",0
MIG     db      "MIG-M01",0
STG     db      "ST-WK5",0
UTG     db      "SM-50G",0
BOM1    db      "B-TSB",0
BOM2    db      "H-MSB",0
BOM3    db      "M-MSB",0
FFAR    db      "FFAR",0
HFAR    db      "HFAR",0
WP_name dd      VAC, MIG, STG, UTG, BOM1, BOM2, BOM3, FFAR, HFAR

DANGER          db   "DANGER",0
ROUNDS          db   "R:",0
BU              db   "BU:",0
PW              db   "PW:",0

align 4
;; function table
draw_F  dd      draw_floor
floor_no        dd      0
floor   dd      draw_floorLL, draw_floorL, draw_floor

draw_DISP1      dd      draw_map
disp1_no        dd      0
disp1   dd      draw_map, draw_noise

GREEN_TABLE     label   byte
	db      144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159
	db      144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159
	db      144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159
	db      144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159
	db      144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159
	db      144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159
	db      144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159
	db      144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159
	db      144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159
	db      144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159

	db      144,144,145,145,146,146,147,147,148,148,149,149,150,150,151,151
	db      152,152,153,153,154,154,155,155,156,156,157,157,158,158,159,159

	db      144,144,145,145,146,146,147,147,148,148,149,149,150,150,151,151
	db      152,152,153,153,154,154,155,155,156,156,157,157,158,158,159,159

	db      144,144,145,145,146,146,147,147,148,148,149,149,150,150,151,151
	db      152,152,153,153,154,154,155,155,156,156,157,157,158,158,159,159

obj_type1       label  ; walker
OBJECT <001h, 1024 SHL 16, 850 SHL 16,0, 0, 0, 64,3,3,  4,4,0, 0,0,0, 0, OFFSET en1_spr_data, OFFSET walk1_crs_data, 1,140, 16,16>
OBJECT <002h, 1024 SHL 16, 850 SHL 16,0, 0, 0, 64,4,4,  3,3,0, 0,0,0, 0, OFFSET en1_spr_data, OFFSET walk1_crs_data, 1,140, 16,16>
OBJECT <003h, 1024 SHL 16, 900 SHL 16,0, 0, 0, 32,2,2,  3,3,0, 0,0,0, 0, OFFSET en3_spr_data, OFFSET walk3_crs_data, 1,150, 16,16>
OBJECT <004h, 1024 SHL 16, 900 SHL 16,0, 0, 0, 32,2,2,  3,3,0, 0,0,0, 0, OFFSET en3_spr_data, OFFSET walk3_crs_data, 1,150, 16,16>
OBJECT <005h, 1024 SHL 16, 900 SHL 16,0, 0, 0, 32,3,3,  3,3,0, 0,0,0, 0, OFFSET en2_spr_data, OFFSET walk1_crs_data, 1,100, 16,16>
OBJECT <006h, 1024 SHL 16, 900 SHL 16,0, 0, 0, 32,3,3,  3,3,0, 0,0,0, 0, OFFSET en2_spr_data, OFFSET walk1_crs_data, 1,120, 16,16>
OBJECT <007h, 1024 SHL 16, 900 SHL 16,0, 0, 0, 32,4,4,  5,5,0, 0,0,0, 0, OFFSET en4_spr_data, OFFSET walk4_crs_data, 1,100, 16,16>

obj_type2       label  ; tank
OBJECT <208h,  900 SHL 16,1000 SHL 16,0, 0, 0,  0,2,2,  2,2,0, 0,0,0, 0, OFFSET tank1_spr_data, OFFSET tank_crs_data, 1,80, 16,15>
OBJECT <408h,  900 SHL 16,1000 SHL 16,0, 0, 0,  0,2,2,  0,0,0, 0,0,0, 0, OFFSET ttop1_spr_data, 0, 1,70, 16,10>
OBJECT <209h, 1500 SHL 16, 950 SHL 16,0, 0, 0,  0,2,2,  2,2,0, 0,0,0, 0, OFFSET tank2_spr_data, OFFSET tank_crs_data, 1,80, 16,15>
OBJECT <409h, 1500 SHL 16, 950 SHL 16,0, 0, 0,  0,2,2,  0,0,0, 0,0,0, 0, OFFSET ttop2_spr_data, 0, 1,70, 16,10>
OBJECT <20Ah, 1600 SHL 16, 900 SHL 16,0, 0, 0,  0,2,2,  1,1,0, 0,0,0, 0, OFFSET tank3_spr_data, OFFSET tank_crs_data, 1,90, 16, 9>
OBJECT <40Ah, 1600 SHL 16, 900 SHL 16,0, 0, 0,  0,2,2,  0,0,0, 0,0,0, 0, OFFSET ttop3_spr_data, 0, 1,70, 16,15>

flm_type        label
OBJECT <101h, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,OFFSET flm1_spr_data, OFFSET flm1_crs_data, 1,0,0,0>
OBJECT <102h, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,OFFSET flm2_spr_data, OFFSET flm2_crs_data, 1,0,0,0>
OBJECT <103h, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,OFFSET flm3_spr_data, OFFSET flm3_crs_data, 1,0,0,0>
OBJECT <104h, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,OFFSET flm4_spr_data, OFFSET flm4_crs_data, 1,0,0,0>
dust_type       label
OBJECT <105h, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,OFFSET dust1_spr_data, OFFSET dust1_crs_data, 1,0,0,0>

chip_type       label
OBJECT <104h, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,OFFSET chip1_spr_data, OFFSET chip1_crs_data, 1,0,0,0>
OBJECT <105h, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,OFFSET chip2_spr_data, OFFSET chip2_crs_data, 1,0,0,0>
smk_type        label
OBJECT <106h, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,OFFSET smk1_spr_data, OFFSET smk1_crs_data, 1,0,0,0>

bullet_type     label
OBJECT <502h, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,OFFSET flm1_spr_data, OFFSET blt1_crs_data, 1,4,0,0>
OBJECT <503h, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,OFFSET flm1_spr_data, OFFSET blt1_crs_data, 1,25,0,0>

OBJECT <504h, 0,0,0,0,0,0,0,0,0,0,0,0,0,60,0,OFFSET tbomb_spr_data, OFFSET blt2_crs_data, 1,100,0,0>
OBJECT <605h, 0,0,0,0,0,0,0,0,0,0,0,0,0,60,0,OFFSET holo_spr_data, OFFSET blt2_crs_data, 1,80,16,16>
OBJECT <506h, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,OFFSET mine_spr_data, OFFSET blt2_crs_data, 1,150,0,0>

OBJECT <507h, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,OFFSET flm1_spr_data, OFFSET missile1_crs_data, 1,80,0,0>
OBJECT <508h, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,OFFSET flm1_spr_data, OFFSET missile1_crs_data, 1,60,0,0>

target_type     label
OBJECT <800h, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,                   0,                       0, 1, 1,0,0>

walk1_crs_data  label   word
	dw      232,0
	dd      walkdead
	dw      0, 1, 2, 3, 4, 5
	dw      231
	dd      2,walk3
walk1   label
	dw      232,0
	dd      walkdead
	dw      6, 7, 8, 9,10,11
	dw      231
	dd      2,walk2
	dw      _GOTO
	dd      walk1_crs_data
walk2   label
	dw      232,0
	dd      walkdead
;       dw      200,0
	dw      12,13,14,15,16,17
	dw      231
	dd      1,walk1
walk3   label
	dw      232,0
	dd      walkdead
;       dw      200,0
	dw      18,19,20,21,22,23
	dw      231
	dd      1,walk1_crs_data
	dw      _GOTO
	dd      walk2
walkdead        label
	dw      210,2
	dw      24,-1

walk3_crs_data  label   word
	dw      232,0
	dd      walkdead3
	dw      0, 1, 2, 3, 4, 5
	dw      231
	dd      2,walk31
walk31  label
	dw      232,0
	dd      walkdead3
	dw      6, 7, 8, 9, 10, 11
	dw      231
	dd      2,walk32
	dw      _GOTO
	dd      walk3_crs_data
walk32  label
	dw      232,0
	dd      walkdead3
;       dw      200,0
	dw      0, 1, 2, 3, 4, 5
	dw      231
	dd      1,walk31
walk33  label
	dw      232,0
	dd      walkdead3
;       dw      200,0
	dw      6, 7, 8, 9, 10, 11
	dw      231
	dd      1,walk3_crs_data
	dw      _GOTO
	dd      walk32
walkdead3       label
	dw      210,2
	dw      12,-1

walk4_crs_data  label   word
	dw      232,0
	dd      walkdead4
	dw      0, 1, 2, 3
	dw      231
	dd      2,walk41
walk41  label
	dw      232,0
	dd      walkdead4
	dw      4, 5, 6, 7
	dw      231
	dd      2,walk42
	dw      _GOTO
	dd      walk4_crs_data
walk42  label
	dw      232,0
	dd      walkdead4
;       dw      200,0
	dw      8, 9, 10, 11
	dw      231
	dd      1,walk41
walk43  label
	dw      232,0
	dd      walkdead4
;       dw      200,0
	dw      12, 13, 14, 15
	dw      231
	dd      1,walk4_crs_data
	dw      _GOTO
	dd      walk42
walkdead4       label
	dw      210,2
	dw      16,-1

tank_crs_data   label   word
	dw      0,1
	dw      232,0
	dd      tank00
	dw      _GOTO
	dd      tank_crs_data
tank00  label
	dw      210,2
	dw      2,-1

flm1_crs_data   label   word
	dw      0,1,2,3,4,5,209

flm2_crs_data   label   word
	dw      0,1,2,3,4,5,6,7,209

flm3_crs_data   label   word
	dw      200,_EXPLO1_,0,1,2,3,4,5,6,7,8,9,10,11,209

flm4_crs_data   label   word
	dw      0,1,2,3,4,5,6,209

dust1_crs_data  label   word
	dw      0,1,2,3,4,5,209

smk1_crs_data   label   word
	dw      0,1,2,3,4,5,6,7,8,9,209

chip1_crs_data  label   word
	dw      0,1,2,3,4,5,6,0,1,2,3,4,5,6, 210,4, 209

chip2_crs_data  label   word
	dw      0,1,2,3,4,5,0,1,2,3,4,5, 210,4, 209

blt1_crs_data   label   word
	dw      0,1,0,1,0,1,0,1,0,1,0,1,0,1
	dw      0,1,0,1,0,1,0,1,0,1,0,1,0,1
	dw      200,_EXPLO0_, 210,1, 209

blt3_crs_data   label   word
	dw      0,1,0,1,0,1,0,1,0,1,0,1,0,1
	dw      0,1,0,1,0,1,0,1,0,1,0,1,0,1
	dw      0,1,0,1,0,1,0,1,0,1,0,1,0,1
	dw      0,1,0,1,0,1,0,1,0,1,0,1,0,1
	dw      0,1,0,1,0,1,0,1,0,1,0,1,0,1
	dw      200,_EXPLO0_, 210,2, 209

blt2_crs_data   label   word
	dw      0,1,0,1,0,1,0,1,0,1,0,1,0,1
	dw      _GOTO
	dd      blt2_crs_data

missile1_crs_data       label   word
	dw      210,3 ,0,  210,3 ,1,  210,3 ,0,  210,3 ,1
	dw      210,3 ,0,  210,3 ,1,  210,3 ,0,  210,3 ,1
	dw      210,3 ,0,  210,3 ,1,  210,3 ,0,  210,3 ,1
	dw      210,3 ,0,  210,3 ,1,  210,3 ,0,  210,3 ,1
	dw      210,3 ,0,  210,3 ,1,  210,3 ,0,  210,3 ,1
	dw      210,3 ,0,  210,3 ,1,  210,3 ,0,  210,3 ,1
	dw      210,3 ,0,  210,3 ,1,  210,3 ,0,  210,3 ,1
	dw      210,2, 200,_EXPLO1_, 209

pass_ok         db      0
passtry         dd      3
passinput       dd      0,0,0
passinputX      dd      0
passon          dd      0
passtable       label   byte
	include pass.inc

_DATA   ENDS

_BSS    SEGMENT PUBLIC USE32 DWORD 'BSS'

obj_ptr         label   dword
		dd      MAXOBJ dup(0)
obj_table       label
		db      MAXOBJ * OBJWID dup(0)

AP_stat         db      0
bust_stat       db      0
AP_frame        dd      0
chit_god	dd	0
chit_wep	dd	0

dirmap  db      0,0,0,0,0,0,0,0
MX      dd      0
MY      dd      0
MXS     dd      0
MYS     dd      0

obj_energy      dw      0

align 2
xx      dw      0

ey1     dw      0
ey2     dw      0

x1      dw      0
y1      dw      0
z1      dw      0
x2      dw      0
y2      dw      0
z2      dw      0

align 4
xx_     dd      0
yy_     dd      0
zz_     dd      0

ey1_    dd      0
ey2_    dd      0

x1_     dd      0
y1_     dd      0
z1_     dd      0
x2_     dd      0
y2_     dd      0
z2_     dd      0

xa_     dd      0
ya_     dd      0

lstart  dd      0

sine    dw      0
cosine  dw      0

sined   dd      0
cosined dd      0

flm_x_  dd      0
flm_y_  dd      0
flm_th  db      0
flm_dir dw      0
fire_d  dw      0
f_range dw      0

seed    dd      ?

; frames per second
Tstart  dw      0, 0
Tend    dw      0, 0
frames  dd      0
fps     db      0, 0    ; frames per second

; keyboard interrupt vector save
int09seg        dw      ?
int09off        dd      ?

key_hit         db      ?
extended_key    db      ?
keyboard        db      128 dup (?)
key_edge        db      128 dup (?)
key_string	db	4 dup (?)

PALtmp  db      768 dup(?)
PALtmp2 db      768 dup(?)

; texture tile loading pointer
TIL_load        label   byte
	db      12 dup(?)               ; tile header
PAL     db      768 dup(?)              ; palette
;ATTR   dd      3000 dup(?)             ; 3000 attribute
TIL     db      3000 * (8*8) dup(?)     ; 8 * 8 tile data

DTIL_load       label   byte
;       db      12 dup(?)               ; tile header
;       db      768 dup(?)              ; palette
;       dd      3000 dup(?)             ; 3000 attribute
DTIL    db      3000 * (8*8) dup(?)     ; 8 * 8 tile data

align 4
MAP_load        label   byte            ; map data
	db      8 dup(?)
TEXMAP          label   dword
	dd      256 * 256 dup(?)
TEXCFG          label   dword
HEADER          label   dword
	dd      ?,?,?,?,?,?
ENNUM   dd      ?
NPCNUM  dd      ?
	dd      10 dup(?)
;GATEINFO       label   dword
;       dd      30 * 19 dup(?)
;EVENTINFO      label   dword
;       dd      30 * 16 dup(?)
;ITEMINFO       label   dword
;       dd      30 * 16 dup(?)
;BARRINFO       label   dword
;       dd      30 * 16 dup(?)
ENINFO          label   dword
	dd      30 * 14 dup(?)
NPCINFO         label   dword
	dd      30 * 15 dup(?)

TEXMAPADD       label   dword
	dd      256 * 256 dup(?)

;TEXMAPADD2     label   dword
;       dd      256 * 256 dup(?)


DARKER_TABLE    label   byte
	db      256 dup(?)

COLLISION_MAP   label   byte
	db      256 * 256 dup(?)

DIRECTION_MAP   label   word
	dw      256 * 256 dup(?)

_RECORD_        label   byte
	db      ?
	dd      11 dup(?)
RECORDING       label   byte
	dw      RECLEN dup(?)

_replay dd      ?

SqrTable        dd      3000 dup(?)

_SONGptr_       dd      0

file_number     db      0,0,0

bullet_mem      db      0

total_enemy_num db      0
kill_enemy_num  db      0
target_destruction_counter      db      0

out_delay       db      0
out_delay_flag  db      0

_BSS    ENDS

_TEXT   SEGMENT PUBLIC USE32 DWORD 'CODE'
	ASSUME  cs:_TEXT,ds:DGROUP,es:DGROUP,ss:DGROUP

extrn   put_spr:        near
extrn   put_shadow:     near
extrn   put_sprR:       near
extrn   put_shadowR:    near
extrn   put_sprSC:      near
extrn   put_shadowSC:   near
extrn   world2eye:      near
extrn   world2map:      near
extrn   draw_compas:    near
extrn   draw_floor3:    near

extrn   FMJMenu_:       near            ; C register call
extrn   SoundFX_:       near            ; C register call
extrn   PlayBGM_:       near            ; C register call
extrn   MODLoadModule_: near            ; C register call
extrn   MODFreeModule_: near            ; C register call
extrn   _MODStopModule: near            ; C stack call ( no parameter )
extrn   _MODSetMusicVolume: near        ; C stack call ( byte volume )
extrn   _MODSetSampleVolume: near       ; C stack call ( byte volume )
extrn   _InstallTimer:  near            ; C stack call ( no parameter )
extrn   _DeinstallTimer:near            ; C stack call ( no parameter )

extrn   itoa_:          near            ; C std. LIB function

;--------------------;-------------------------------------------------------
;  table of routine  ;
;--------------------;
ObjMoveRoutine  label   dword
	dd      omr00, omr01, omr02, omr03, omr04, omr05, omr06, omr08, omr08

FireRoutine     label   dword
	dd      APW00, APW01, APW02, APW03, APW04, APW05
	dd      APW06, APW07, APW08

CourseRoutine   label dword
	dd      cos200, cos201, cos202, cos203, cos204, cos205, cos206, cos207, cos208, cos209
	dd      cos210, cos211, cos212, cos213, cos214, cos215, cos216, cos217, cos218, cos219
	dd      cos220, cos221, cos222, cos223, cos224, cos225, cos226, cos227, cos228, cos229
	dd      cos230, cos231, cos232, cos233, cos234, cos235, cos236, cos237, cos238, cos239

;----------------------------------------------------------------------------

set_border Macro color
       mov  dx,03dah            ; Used for speed test
       in   al,dx
       nop
       nop
       nop
       mov  dx,03c0h
       mov  al,11h+32
       out  dx,al
       mov  al,color
       out  dx,al
       EndM

wait_key&time   MACRO   key,time
	LOCAL   @@repeat,@@gogogo
	mov     [_TimerTicks],0
@@repeat:
	cmp     key_hit,key
	jnz     @@gogogo
	mov     eax,[_TimerTicks]
	cmp     eax,70*time
	jb      @@repeat
@@gogogo:
	ENDM
;-------------------------------------------
;
;-------------------------------------------
MakeSqrTable    PROC

	mov     ecx,0
@@next:
	mov     eax,ecx
	mov     ebx,ecx
	mul     ebx
	mov     SqrTable[ecx*4],eax
	inc     ecx
	cmp     ecx,3000
	jb      SHORT @@next

	ret

MakeSqrTable    ENDP

;-------------------------------
;
;-------------------------------
PUBLIC  FindSqrt_
FindSqrt_       proc

	push    ebx
	push    edx
	push    esi
	push    edi

	mov     edx,1500
	mov     esi,0
	mov     edi,2999
@@sss:
	cmp     eax,SqrTable[edx*4]
	je      SHORT @@out
	ja      SHORT @@aaa
	jb      SHORT @@bbb
@@aaa:
	mov     esi,edx
	mov     ebx,edi
	sub     ebx,esi
	shr     ebx,1
	jz      SHORT @@out
	add     edx,ebx

	jmp     SHORT @@sss
@@bbb:
	mov     edi,edx
	mov     ebx,edi
	sub     ebx,esi
	shr     ebx,1
	jz      SHORT @@out
	sub     edx,ebx

	jmp     SHORT @@sss
@@out:
	mov     eax,edx

	pop     edi
	pop     esi
	pop     edx
	pop     ebx

	ret

FindSqrt_       endp

;-----------------------------------------
;
;-----------------------------------------
FindTheta1      proc

	push    ebx
	push    edx
	push    esi
	push    edi

	mov     edx,64
	mov     esi,0
	mov     edi,127
@@sss:
	cmp     ax,SIN[edx*2+64*2]
	je      SHORT @@out
	jl      SHORT @@aaa
	jg      SHORT @@bbb
@@aaa:
	mov     esi,edx
	mov     ebx,edi
	sub     ebx,esi
	shr     ebx,1
	jz      SHORT @@out
	add     edx,ebx

	jmp     SHORT @@sss
@@bbb:
	mov     edi,edx
	mov     ebx,edi
	sub     ebx,esi
	shr     ebx,1
	jz      SHORT @@out
	sub     edx,ebx

	jmp     SHORT @@sss
@@out:
	mov     eax,edx

	pop     edi
	pop     esi
	pop     edx
	pop     ebx

	ret

FindTheta1      endp

FindTheta2      proc

	push    ebx
	push    edx
	push    esi
	push    edi

	mov     edx,192
	mov     esi,128
	mov     edi,255
@@sss:
	cmp     ax,SIN[edx*2+64*2]
	je      SHORT @@out
	jg      SHORT @@aaa
	jl      SHORT @@bbb
@@aaa:
	mov     esi,edx
	mov     ebx,edi
	sub     ebx,esi
	shr     ebx,1
	jz      SHORT @@out
	add     edx,ebx

	jmp     SHORT @@sss
@@bbb:
	mov     edi,edx
	mov     ebx,edi
	sub     ebx,esi
	shr     ebx,1
	jz      SHORT @@out
	sub     edx,ebx

	jmp     SHORT @@sss
@@out:
	mov     eax,edx

	pop     edi
	pop     esi
	pop     edx
	pop     ebx

	ret

FindTheta2      endp

;------------------------------------------
;  eax :
;
;------------------------------------------
make_DARKER_TABLE       PROC

;       mov     esi,OFFSET PAL
;       mov     edi,OFFSET DARKER_TABLE

	xor     esi,esi
	xor     edi,edi
	xor     ebp,ebp
	mov     ecx,256
@@next:
	mov     ebx,ebp
	mov     DARKER_TABLE[edi],bl

	mov     bl,PAL[esi]             ;R
	add     bl,PAL[esi+1]           ;G
	add     bl,PAL[esi+2]           ;B

	push    ecx
	mov     ecx,eax
	push    eax
	xor     edx,edx
@@nextp:
;       mov     eax,esi
;       add     eax,edx
;       cmp     eax,254*3
;       ja      @@lout

	mov     bh,PAL[esi+edx+3]       ;R
	add     bh,PAL[esi+edx+4]       ;G
	add     bh,PAL[esi+edx+5]       ;B

	cmp     bh,bl
	ja      SHORT @@lout

	mov     bl,bh
	add     DARKER_TABLE[edi],1

	add     edx,3

	dec     ecx
	jnz     @@nextp
@@lout:
	pop     eax

	add     esi,3
	inc     edi
	inc     ebp

	pop     ecx
	dec     ecx
	jnz     @@next
	mov     [DARKER_TABLE],254

	ret

make_DARKER_TABLE       ENDP

;---------------------------------------
;
;---------------------------------------
init_obj_ptr    proc

	mov     ecx,MAXOBJ
	mov     eax,offset obj_table
	mov     ebx,offset obj_ptr
@@next:
	mov     ds:dword ptr[ebx],eax

	add     eax,OBJWID
	add     ebx,4

	loop    @@next

	ret

init_obj_ptr    endp

;---------------------------------
;
;---------------------------------
depth_sort      proc

	xor     esi,esi
@@nbeam:
	mov     edi,esi
	inc     edi
@@nobj:
	mov     ebx,obj_ptr[esi*4]
	mov     ax,[ebx].dis
	mov     ebp,obj_ptr[edi*4]
	cmp     ax,[ebp].dis
	jle     @@nchg
	xchg    ebx,obj_ptr[edi*4]
	mov     obj_ptr[esi*4],ebx
@@nchg:
	inc     edi
	cmp     edi,MAXOBJ-1
	jbe     @@nobj
@@here:
	inc     esi
	cmp     esi,MAXOBJ-2
	jbe     @@nbeam
@@quit:
	ret

depth_sort      endp

;--------------------------------------
;
;--------------------------------------
init_map        PROC

	xor     ebx,ebx
	mov     ecx,256*256
@@next:
	mov     eax,TEXMAP[ebx*4]       ; load tile index
	and     eax,0FFFh               ; tile number
	shl     eax,6                   ; eax * 64, 64 = 8*8
	add     eax,offset TIL          ;
	mov     TEXMAPADD[ebx*4],eax    ; save addr.
	inc     ebx

	dec     ecx
	jnz     @@next

;       xor     ebx,ebx
;       mov     ecx,256*256
;@@next2:
;       mov     eax,TEXMAP[ebx*4]       ; load tile index
;       and     eax,0FFFh               ; tile number
;       shl     eax,6                   ; eax * 64, 64 = 8*8
;       add     eax,offset DTIL          ;
;       mov     TEXMAPADD2[ebx*4],eax    ; save addr.

;       inc     ebx

;       dec     ecx
;       jnz     @@next2

	ret

init_map        ENDP

;=================================================
;-------------------------------------------------
; save orignal key int. handler & set new handler
;-------------------------------------------------
keyint_on       PROC

	; key-intr. handler 09h
	push    es                     ; save es
	mov     ax,3509h               ; get interrupt vector ah = 35h
	int     21h                    ; al = int No.
	mov     ax,es                  ; ret  es:ebx
	mov     int09seg,ax            ; get original int. vector
	mov     int09off,ebx           ; and store
	pop     es

	push    ds                     ; save ds reg.
	mov     ax,2509h               ; set interrupt vector ah = 25h
	mov     edx,offset newint09    ; ds:edx  =  cs:eip
	mov     bx,cs                  ; al = int No.
	mov     ds,bx                  ; set new int. handler
	int     21h                    ;
	pop     ds

	ret
keyint_on       ENDP

;-----------------------------------
;  restore original key-int. vector
;-----------------------------------
keyint_off      PROC

	mov     ax,2509h               ; set int. vector ah = 25h
	mov     edx,int09off           ; ds:edx
	push    ds                     ;
	mov     bx,int09seg            ;
	mov     ds,bx
	int     21h
	pop     ds

	ret

keyint_off      ENDP

clear_key_buffer        PROC

	mov     edi,OFFSET keyboard
	mov     ecx,(128+128)/4 + 1
	xor     eax,eax
	cld
	rep     stosd
	mov     key_hit,0

	ret

clear_key_buffer        ENDP


;---------------------------
; key-interrupt handler
;---------------------------
newint09        PROC    far

	push    es
	push    eax                    ; save used reg.
	push    ebx                    ;

	sti

	mov     bx,DGROUP              ; es = dgroup
	mov     es,bx                  ;

	in      al,60h                 ; read pressed key
	cmp     al,127                 ; from I/O port 60h
	ja      @up

	xor     ebx,ebx                ; which key?
	and     al,127                 ;

	cmp     ES:extended_key,1
	jne     @@nochk
	mov     ES:extended_key,0
	cmp     al,2Ah                 ; Left Shift
	je      @eoi
	cmp     al,36h                 ; Right Shift
	je      @eoi
@@nochk:

	mov     es:key_hit,al          ;
	mov     bl,al                  ; Don't forget to remember
	cmp     es:keyboard[ebx],0     ; es segment overriding
	jne     SHORT @keys            ; data acsessed in int. handler
	mov     es:key_edge[ebx],1     ; needs ES segment overriding
@keys:                                 ; under DOS/4G FLAT model
	mov     es:keyboard[ebx],1
	jmp     SHORT @eoi
@up:
	cmp     al,0E0h
	jne     SHORT @normal
	mov     es:extended_key,1
	jmp     SHORT @eoi
@normal:
	mov     es:key_hit,0          ;
	xor     ebx,ebx
	and     al,127

	cmp     ES:extended_key,1
	jne     @@nochkb
	mov     ES:extended_key,0
	cmp     al,2Ah                 ; Left Shift
	je      @eoi
	cmp     al,36h                 ; Right Shift
	je      @eoi
@@nochkb:

	mov     bl,al
	mov     es:keyboard[ebx],0     ;

@eoi:
	mov     al,20h                 ; EOI to 8259-1
	out     20h,al                 ; (interrupt controller)

	pop     ebx                    ;
	pop     eax
	pop     es

	iretd

newint09        ENDP
;============================================================================
;------------------------------------
;
;------------------------------------
AP_ani  PROC

	test    AP_stat,BUST
	jz      @@off
	cmp     buster,0
	jle     @@off

	cmp     AP_frame,32
	jge     @@good
	mov     AP_frame,32

	mov     eax,_BUSTON_
	call    SoundFX_

@@good:
	inc     AP_frame
	cmp     AP_frame,32+5
	jle     @@okf
	mov     AP_frame,32+4
@@okf:
	sub     buster,1
	jnc     @@bustok
	mov     buster,0
@@bustok:
	add     eye_z,5
	add     eye_zd,5
	cmp     eye_z,128+5*15
	jle     @@flying
	mov     eye_z,128+5*15
	mov     eye_zd,128+5*15

@@flying:
	test    frames,1
	jz      @@quit
	mov     eax,_BUST_
	call    SoundFX_

	jmp     @@quit

@@off:
	cmp     eye_z,128
	jle     @@earth
	sub     eye_z,5
	sub     eye_zd,5
	dec     AP_frame
	cmp     AP_frame,32
	jae     @@quit
	mov     AP_frame,33
	jmp     @@quit

@@earth:
	cmp     AP_frame,32
	jb      @@ground
	mov     AP_frame,0

@@ground:
	mov     ebx,weapon_no
	inc     ebx
	cmp     ebx,3
	jbe     @@valid
	mov     ebx,3
@@valid:
	imul    ebx,8
	mov     ecx,ebx
	add     ecx,8

	test    AP_stat,1111b
	jz      @@nomov

@@star:
	inc     AP_frame
	mov     eax,AP_frame
	cmp     eax,8
	jne     @@conti
	mov     AP_frame,0
@@conti:
	cmp     eax,ecx;32;24;16
	jne     @@contim
	mov     AP_frame,ebx;24;16;8
	jmp     @@contim

@@nomov:
	mov     eax,AP_frame
	and     eax,3
	jz      @@contim
	jmp     @@star

@@contim:

	test    AP_stat,FIRE
	jz      @@nofire

	mov     eax,weapon_no
	cmp     weapon_rounds[eax * 4],0
	jle     SHORT @@nofire

@@fireyes:

	mov     eax,AP_frame
	cmp     eax,8
	jae     @@nomovchk
	add     AP_frame,ebx;24;16;8
	jmp     @@quit

@@nofire:

	mov     eax,AP_frame
	cmp     eax,8
	jb      @@quit

	sub     AP_frame,ebx;24;16;8
	jmp     @@quit

@@nomovchk:
	test    AP_stat,1111b
	jnz     @@quit
	sub     AP_frame,ebx;24;16;8

@@quit:
	cmp     AP_frame,45
	jl      @@frameok
	mov     AP_frame,44
	jmp     @@out
@@frameok:
	cmp     AP_frame,0
	jge     @@out
	mov     AP_frame,0
@@out:

	ret

AP_ani  ENDP


;-------------------------------------------
;
;-------------------------------------------
obj_course      proc

	push    ebp

	mov     ebp,OFFSET obj_table
	mov     ecx,MAXOBJ

@@nexto:
	cmp     [ebp].stat,0
	jz      @@here

@@rcos:
	mov     esi,[ebp].crs_pointer
	cmp     esi,0
	je      @@here
	cmp     esi,-1
	je      @@here

	movsx   eax,word ptr[esi]       ; sprite no
	cmp     eax,-1                  ; end of course
	jne     @@checkcos
	mov     [ebp].crs_pointer,-1
	jmp     @@here

@@checkcos:
	cmp     eax,200                 ;
	jl      @@normal                ; normal course

	sub     eax,200                 ; script course
	jmp     CourseRoutine[eax * 4]  ;

cos200:
;-----> SFX [200,SFX_no]
;------------------------------------------;
	movzx   eax,word ptr[esi + 2]
	call    SoundFX_

	add     [ebp].crs_pointer,4
	jmp     @@rcos

cos201:
cos202:
;-----------> sprite No. change [202,no]
;-----------------------------------------;
	movzx   eax,word ptr[esi + 2]
	mov     [ebp].spr_no,eax

	add     [ebp].crs_pointer,4
	jmp     @@here

cos203:
cos204:
cos205:
cos206:
cos207:
cos208:
cos209:
;-----------> kill obj.[209]
;-----------------------------------------;
	mov     [ebp].stat,0
	mov     eax,[ebp].obj_no
	shr     eax,8
	cmp     eax,6h
	jne     @@here
	mov     holo_stat,0
	jmp     @@here

cos210:
;-----------> sprite No. change [210,no]
;-----------------------------------------;
	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax
	movzx   eax,word ptr[esi + 2]
	call    crea_flm

	add     [ebp].crs_pointer,4
	jmp     @@rcos
cos211:
cos212:
cos213:
cos214:
cos215:
cos216:
cos217:
cos218:
cos219:
cos220:
cos221:
cos222:
cos223:
cos224:
cos225:
cos226:
cos227:
cos228:
cos229:

;--------- JUMP STYLE COURSE ------------------;
;----------------------------------------------;
cos230:
;------------> _GOTO [230,addr]
;----------------------------------------------;
	mov     eax,dword ptr[esi + 2]
	mov     [ebp].crs_pointer,eax
	jmp     @@rcos

cos231:
;------------> _GOTO if stat EQU value [231,stat,addr]
;----------------------------------------------;
	mov     eax,dword ptr[esi + 2]
	cmp     eax,[ebp].stat
	jne     @@nojump
	mov     eax,dword ptr[esi + 6]
	mov     [ebp].crs_pointer,eax
	jmp     @@rcos
@@nojump:
	add     [ebp].crs_pointer,10
	jmp     @@rcos

cos232:
;------------> _GOTO if energy less or EQU [232,energy,addr]
;----------------------------------------------;
	mov     ax,word ptr[esi + 2]
	cmp     [ebp].energy,ax
	jg      @@nojmp
	mov     eax,dword ptr[esi + 4]
	mov     [ebp].crs_pointer,eax
	jmp     @@rcos
@@nojmp:
	add     [ebp].crs_pointer,8
	jmp     @@rcos

cos233:
cos234:
cos235:
cos236:
cos237:
cos238:
cos239:

;-------------------------------------------;
;----- NORMAL COURSE -----------------------;
@@normal:
	mov     [ebp].spr_no,eax
	add     [ebp].crs_pointer,2

@@here:
	add     ebp,OBJWID
	dec     ecx
	jnz     @@nexto

@@quit:
	pop     ebp
	ret

obj_course      endp

;-----------------------------------
;  main charactor moving direction
;-----------------------------------
dirf    PROC

	movzx   ebx,d_th                ;
	shl     ebx,1                   ;
	mov     ax,SIN[ebx]             ; sin(d_th)
	movsx   eax,ax                  ;
	mov     sined,eax               ;

	mov     bl,d_th                 ;
	add     bl,64                   ;
	movzx   ebx,bl                  ;
	shl     ebx,1                   ;
	mov     ax,SIN[ebx]             ; cos(d_th)
	movsx   eax,ax                  ;
	mov     cosined,eax             ;

	mov     ax,dif                  ; rx * cos(d_th)
	cmp     ax,0
	jge     @@ppp

	shl     eax,16                  ;
	neg     eax                     ;
	imul    cosined                 ;
	shld    edx,eax,17              ; rx * cos(d_th) / 32768
	sub     eye_x_,edx              ;

	mov     ax,dif                  ;
	shl     eax,16                  ;
	neg     eax                     ;
	imul    sined                   ; rz * sin(d_th)
	shld    edx,eax,17              ; rz * sin(d_th) / 32768
	sub     eye_y_,edx              ;

	and     eye_x_,7FFFFFFh
	mov     eax,eye_x_              ;
	shr     eax,16                  ;
	mov     eye_x,ax                ;
	and     eye_x,7FFh

	and     eye_y_,7FFFFFFh
	mov     eax,eye_y_              ;
	shr     eax,16                  ;
	mov     eye_y,ax                ;
	and     eye_y,7FFh

	ret

@@ppp:
	shl     eax,16                  ;
	imul    cosined                 ;
	shld    edx,eax,17              ;rx * cos(d_th) / 32768
	add     eye_x_,edx              ;

	mov     ax,dif                  ;
	shl     eax,16                  ;
	imul    sined                   ;rz * sin(d_th)
	shld    edx,eax,17              ;rz * sin(d_th) / 32768
	add     eye_y_,edx              ;

	and     eye_x_,7FFFFFFh
	mov     eax,eye_x_
	shr     eax,16
	mov     eye_x,ax
	and     eye_x,7FFh              ; 7FFh = 2047

	and     eye_y_,7FFFFFFh
	mov     eax,eye_y_
	shr     eax,16
	mov     eye_y,ax
	and     eye_x,7FFh

	ret

dirf    ENDP

;-----------------------------------
;  object moving direction
; eax : object no
;-----------------------------------
obj_dirf    PROC

	movzx   ebx,[ebp].mth           ;
	shl     ebx,1                   ;
	mov     ax,SIN[ebx]             ; sin(d_th)
	movsx   eax,ax                  ;
	mov     sined,eax               ;

	mov     bl,[ebp].mth            ;
	add     bl,64                   ;
	movzx   ebx,bl                  ;
	shl     ebx,1                   ;
	mov     ax,SIN[ebx]             ; cos(d_th)
	movsx   eax,ax                  ;
	mov     cosined,eax             ;

	mov     ax,[ebp].ddir           ; rx * cos(d_th)
	cmp     ax,0
	jge     @@ppp

	shl     eax,16                  ;
	neg     eax                     ;
	imul    cosined                 ;
	shld    edx,eax,17              ; rx * cos(d_th) / 32768
	sub     [ebp].x_,edx              ;

	mov     ax,[ebp].ddir           ;
	shl     eax,16                  ;
	neg     eax                     ;
	imul    sined                   ; rz * sin(d_th)
	shld    edx,eax,17              ; rz * sin(d_th) / 32768
	sub     [ebp].y_,edx              ;
	jmp     @@mmm

@@ppp:
	shl     eax,16                  ;
	imul    cosined                 ;
	shld    edx,eax,17              ;rx * cos(d_th) / 32768
	add     [ebp].x_,edx              ;

	mov     ax,[ebp].ddir           ;
	shl     eax,16                  ;
	imul    sined                   ;rz * sin(d_th)
	shld    edx,eax,17              ;rz * sin(d_th) / 32768
	add     [ebp].y_,edx              ;
@@mmm:
	ret

obj_dirf    ENDP

;-------------------------------
;  valcan of enemy
;-------------------------------
obj_fire        PROC

	push    ecx
	push    [ebp].x_
	push    [ebp].y_
	push    [ebp].ddir

;;      test    frames,3
;;      jz      @@quit

	mov     eax,[ebp].obj_no  ; if tank no fire
	shr     eax,8             ;
	cmp     eax,2             ;
	je      @@quit            ;

	cmp     eye_z,128+5
	ja      @@quit

	mov     ax,[ebp].dis
	cmp     ax,180
	ja      @@quit

	push    eax
	mov     eax,_MGUN_
	call    SoundFX_
	pop     eax

	cwd
	mov     bx,8
	div     bx

	mov     [ebp].ddir,8

	movzx   ecx,ax
@@ntile:
	call    obj_dirf

	mov     eax,[ebp].y_
	shr     eax,16+3
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,[ebp].x_
	shr     ebx,16+3
	and     ebx,255                 ;

	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	cmp     COLLISION_MAP[eax],0     ;load attrib of tile data
	jnz     SHORT @@bingo

	dec     ecx
	jnz     @@ntile

@@bingo:
	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax
	mov     eax,0
	call    crea_flm

	mov     eax,_EXPLO0_
	call    SoundFX_

	mov     eax,[ebp].x_
	sub     eax,eye_x_
	shr     eax,16
	cmp     ax,0
	jge     SHORT @@noneg1
	neg     ax
@@noneg1:
	cmp     ax,10
	ja      SHORT @@quit

	mov     eax,[ebp].y_
	sub     eax,eye_y_
	shr     eax,16
	cmp     ax,0
	jge     SHORT @@noneg2
	neg     ax
@@noneg2:
	cmp     ax,10
	ja      SHORT @@quit

	mov     disp1_no,1
	cmp	chit_god,1	;
	je	@@quit          ;
	sub     AP_energy,1
	jnc     SHORT @@quit
	mov     AP_energy,0

@@quit:
	pop     [ebp].ddir
	pop     [ebp].y_
	pop     [ebp].x_
	pop     ecx

	ret

obj_fire        ENDP

;------------------------------------------
;
;------------------------------------------
fire_FFAR       PROC

	cmp     [ebp].freem,0
	jnz     @@quit

	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax
	mov     al,[ebp].theta
	mov     flm_th,al
	mov     flm_dir,8
	mov     eax,5           ; FFAR missile
	mov     edx,307h        ; enemy fire
	call    crea_bullet ;

	mov     eax,_FTHROW_
	call    SoundFX_

	mov     [ebp].freem,16
@@quit:
	ret

fire_FFAR       ENDP

fire_SHOT       PROC

	cmp     [ebp].freem,0
	jnz     @@quit

	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax
	mov     flm_dir,16

	mov     al,[ebp].theta
	mov     flm_th,al
	mov     eax,0
	mov     edx,302h        ; enemy fire
	call    crea_bullet ;

	mov     al,[ebp].theta
	add     al,2
	mov     flm_th,al
	mov     eax,0
	mov     edx,302h        ; enemy fire
	call    crea_bullet ;

	mov     al,[ebp].theta
	sub     al,2
	mov     flm_th,al
	mov     eax,0
	mov     edx,302h        ; enemy fire
	call    crea_bullet ;

	mov     eax,_SGUNSH_
	call    SoundFX_

	mov     [ebp].freem,8
@@quit:
	ret

fire_SHOT       ENDP

;----------------------------
;
;----------------------------
all_demage      PROC

	pushad

	mov     eax,[ebp].x_
	shr     eax,16+3
	and     eax,255
	mov     MX,eax
	sub     MX,5

	mov     ecx,10
@@nextX:

	mov     ebx,[ebp].y_
	shr     ebx,16+3
	and     ebx,255
	mov     MY,ebx
	sub     MY,5

	push    ecx
	mov     ecx,10
@@nextY:

	mov     eax,MX
	and     eax,255
	mov     ebx,MY
	and     ebx,255
	shl     ebx,8
	add     eax,ebx

	mov     ebx,TEXMAP[eax*4]       ; load tile index
	and     ebx,0FFFh               ; tile number
	shl     ebx,6                   ; eax * 64, 64 = 8*8
	add     ebx,offset DTIL         ;
	mov     TEXMAPADD[eax*4],ebx

	inc     MY

	dec     ecx
	jnz     @@nextY

	inc     MX

	pop     ecx
	dec     ecx
	jnz     @@nextX

	popad

	ret

all_demage      ENDP

;-----------------------------------
; object moving
;-----------------------------------
obj_move    PROC

	push    ebp

	mov     ebp,OFFSET obj_table

	mov     ecx,MAXOBJ
@nexto_:
	cmp     [ebp].stat,0            ; 0 or -1
	jg      @@proced_                   ;

	cmp     [ebp].obj_no,800h
	je      @@goon
	jmp     @nnn_

@@proced_:
	cmp     [ebp].obj_no,508h
	je      @@goon
	sub     [ebp].freem,1
	jnc     @@goon
	mov     [ebp].freem,0
@@goon:

	mov     eax,[ebp].obj_no
	shr     eax,8
	jmp     ObjMoveRoutine[eax*4]

	;--------------------------
	;   enemy AI routine
	;--------------------------
omr02:  ; TANK
	add     ebp,OBJWID
	cmp     [ebp].stat,0    ; if has no top
	jz      SHORT @@smoke   ; create smoke
	sub     ebp,OBJWID
	jmp     SHORT omr00
@@smoke:
	sub     ebp,OBJWID
	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax
	mov     eax,4
	call    crea_flm

omr00:
	cmp     [ebp].energy,0
	jle     @@kill2
	cmp     [ebp].dis,300
	ja      @nnn1_
	push    [ebp].x_
	push    [ebp].y_

	mov     ax,[ebp].dspeed
	mov     [ebp].ddir,ax

	call    obj_dirf

	mov     eax,[ebp].y_
	shr     eax,16+3
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,[ebp].x_
	shr     ebx,16+3
	and     ebx,255                 ;

	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	cmp     COLLISION_MAP[eax],0     ;load attrib of tile data
	jz      @@ggg

	;--------------------------
	;  forward moving impossible
	;--------------------------
	;
	pop     [ebp].y_
	pop     [ebp].x_

	mov     eax,[ebp].y_
	shr     eax,16+3
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,[ebp].x_
	shr     ebx,16+3
	and     ebx,255                 ;

	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ax,DIRECTION_MAP[eax*2] ;

	push    ecx                     ; check turn right
	mov     cl,[ebp].mth            ;
	shr     cl,4                    ;

	add     cl,4                    ;
	and     cl,15

	add     cl,1                    ;
	and     cl,15

	mov     bx,11111b               ;
	rol     bx,cl                   ;
	pop     ecx                     ;
					;
	test    ax,bx                   ;
	jz      @@rrr                   ;


	push    ecx                     ; check turn left
	mov     cl,[ebp].mth            ;
	shr     cl,4                    ;

	add     cl,4                    ;
	and     cl,15

	mov     bx,1111100000000000b    ;
	rol     bx,cl                   ;
	pop     ecx                     ;
					;
	test    ax,bx                   ;
	jnz     SHORT @@rrr             ;

@@lll:
	mov     [ebp].ddir,0

;       cmp     [ebp].dmth,0
;       jl      SHORT @@yyy

;       mov     al,[ebp].dth
;       mov     [ebp].dmth,al
;       jmp     SHORT @@add
@@yyy:
	mov     al,[ebp].dth
	neg     al
	mov     [ebp].dmth,al
@@add:
	mov     al,[ebp].dmth
	add     [ebp].mth,al

	mov     [ebp].stat,1
	jmp     @nnn_
  ;--------------------
@@rrr:
	mov     [ebp].ddir,0

	mov     al,[ebp].dth
	mov     [ebp].dmth,al
@@add1:
	mov     al,[ebp].dmth
	add     [ebp].mth,al

	mov     [ebp].stat,1
	jmp     @nnn_

	;--------------------------
	;--------------------------
	;  forward moving possible
	;--------------------------
@@ggg:
	mov     ax,0
	cmp     [ebp].dis,60
	ja      SHORT @@skip0
	cmp     [ebp].energy,30
	jle     SHORT @@skip0

	pop     [ebp].y_
	pop     [ebp].x_
	mov     ax,0
	jmp     SHORT @@skip1

@@skip0:
	pop     eax
	pop     eax
	mov     ax,[ebp].dspeed

@@skip1:
	mov     [ebp].ddir,ax

	mov     [ebp].dmth,0

	mov     al,[ebp].theta
	sub     al,[ebp].mth
	jz      @@chk00
	ja      SHORT @@pp
	cmp     al,128
	jb      @@pp
@@mm:
	mov     [ebp].stat,1

	cmp     al,-4
	jl      @@nofirem

	mov     [ebp].stat,2
	mov     eax,[ebp].obj_no
	and     eax,0FFh
	cmp     eax,2
	je      @FFAR__
	cmp     eax,3
	je      @SHOT__
	cmp     eax,4
	je      @FFAR__

	call    obj_fire
	jmp     @@nofirem

@FFAR__:
	call    fire_FFAR
	jmp     @@nofirem

@SHOT__:
	call    fire_SHOT

@@nofirem:

	mov     al,[ebp].dth
	neg     al
	mov     [ebp].dmth,al

	cmp     [ebp].energy,30
	jge     SHORT @@norun1

	mov     al,[ebp].dth
	mov     [ebp].dmth,al

@@norun1:
	mov     al,[ebp].dmth
	add     [ebp].mth,al

	jmp     @nnn_

@@pp:
	cmp     al,128
	jae     @@mm
	mov     [ebp].stat,1
	cmp     al,4
	jg      @@nofirep

	mov     [ebp].stat,2
	mov     eax,[ebp].obj_no
	and     eax,0FFh
	cmp     eax,2
	je      @FFAR_
	cmp     eax,3
	je      @SHOT_
	cmp     eax,4
	je      @FFAR_

	call    obj_fire
	jmp     @@nofirep

@FFAR_:
	call    fire_FFAR
	jmp     @@nofirep

@SHOT_:
	call    fire_SHOT

@@nofirep:
	mov     al,[ebp].dth
	mov     [ebp].dmth,al

	cmp     [ebp].energy,30
	jge     SHORT @@norun2

	mov     al,[ebp].dth
	neg     al
	mov     [ebp].dmth,al

@@norun2:
	mov     al,[ebp].dmth
	add     [ebp].mth,al
	jmp     @nnn_


@@chk00:
	mov     [ebp].stat,2            ; FIRE!!

	mov     eax,[ebp].obj_no
	and     eax,0FFh
	cmp     eax,2
	je      @FFAR
	cmp     eax,3
	je      @SHOT
	cmp     eax,4
	je      @FFAR

	call    obj_fire
	jmp     @nnn_

@FFAR:
	call    fire_FFAR
	jmp     @nnn_

@SHOT:
	call    fire_SHOT
	jmp     @nnn_

	;--------------------------
	;    TANK TOP
	;--------------------------
omr04:
	cmp     [ebp].energy,0
	jle     @@kill

	sub     ebp,OBJWID
	cmp     [ebp].energy,0
	jg      @@proced

	add     ebp,OBJWID
	jmp     @@kill

@@proced:
	push    [ebp].x_
	push    [ebp].y_

	add     ebp,OBJWID
	pop     [ebp].y_
	pop     [ebp].x_

	mov     al,[ebp].theta
	add     al,128
	mov     [ebp].mth,al

	mov     eax,frames
	and     eax,15
	jnz     @nnn_

	mov     ax,[ebp].dis
	cmp     ax,180
	ja      @nnn_

	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax
	mov     al,[ebp].theta
	mov     flm_th,al
	mov     flm_dir,16
	mov     eax,1
	mov     edx,303h        ; enemy fire
	call    crea_bullet ;;;; tank fire!!

	mov     eax,_CANNON_
	call    SoundFX_

	jmp     @nnn_

@@kill:
	mov     [ebp].stat,0   ; tank top
	jmp     SHORT @@kill3
@@kill2:
	add     kill_enemy_num,1
	mov     eax,[ebp].obj_no
	and     eax,0FFh
	dec     eax
	movzx   ax,enemy_gold[eax]
	add     enemy_score,ax

	mov     [ebp].stat,-1
@@kill3:
	mov     eax,_EXPLO2_
	call    SoundFX_

	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax
	mov     eax,1
	call    crea_flm

	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax

	mov     flm_th,0
	mov     flm_dir,5
	mov     eax,0
	call    crea_chip
	mov     flm_th,23
	mov     flm_dir,4
	mov     eax,1
	call    crea_chip
	mov     flm_th,120
	mov     flm_dir,5
	mov     eax,0
	call    crea_chip
	mov     flm_th,190
	mov     flm_dir,5
	mov     eax,1
	call    crea_chip

	jmp     @nnn_

	;-------------------------
	; bullet of enemy
	;-------------------------
omr03:
	cmp     [ebp].dis,300
	ja      @@godir

	cmp     eye_z,128+5
	ja      @@godir

	mov     eax,[ebp].x_
	sub     eax,eye_x_
	shr     eax,16
	cmp     ax,0
	jge     SHORT @@noneg1
	neg     ax
@@noneg1:
	cmp     ax,10
	ja      SHORT @@tilechk

	mov     eax,[ebp].y_
	sub     eax,eye_y_
	shr     eax,16
	cmp     ax,0
	jge     SHORT @@noneg2
	neg     ax
@@noneg2:
	cmp     ax,10
	ja      SHORT @@tilechk

	mov     disp1_no,1

	cmp	chit_god,1
	je	@@boom
	movzx   eax,[ebp].energy
	sub     AP_energy,eax
	jnc     @@boom
	mov     AP_energy,0

	jmp     @@boom

@@tilechk:
	mov     eax,[ebp].x_
	shr     eax,16+3
	and     eax,255
	mov     ebx,[ebp].y_
	shr     ebx,16+3
	and     ebx,255
	shl     ebx,8
	add     eax,ebx

	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      SHORT @@godir
@@boom:
	mov     ebx,TEXMAP[eax*4]       ; load tile index
	and     ebx,0FFFh               ; tile number
	shl     ebx,6                   ; eax * 64, 64 = 8*8
	add     ebx,offset DTIL          ;
;;      mov     ebx,TEXMAPADD2[eax*4]
	mov     TEXMAPADD[eax*4],ebx

	mov     [ebp].stat,0

	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax
	mov     eax,1
	call    crea_flm

@@godir:
	call    obj_dirf

	jmp     @nnn_


	;--------------------
	;  bullet of AP
	;--------------------
omr05   PROC

	cmp     [ebp].obj_no,504h       ; time bomb
	je      omr504

	mov     eax,[ebp].obj_no
	and     eax,0FFh
	mov     ax,weapon_range[eax*2]
	mov     f_range,ax

	mov     eax,[ebp].x_
	shr     eax,16+3
	and     eax,255

	mov     ebx,[ebp].y_
	shr     ebx,16+3
	and     ebx,255
	shl     ebx,8
	add     eax,ebx

	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      SHORT @@godir_

	mov     ebx,TEXMAP[eax*4]       ; load tile index
	and     ebx,0FFFh               ; tile number
	shl     ebx,6                   ; eax * 64, 64 = 8*8
	add     ebx,offset DTIL          ;
;;      mov     ebx,TEXMAPADD2[eax*4]
	mov     TEXMAPADD[eax*4],ebx

	mov     [ebp].stat,0

	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax
	mov     eax,1
	call    crea_flm

	jmp     @nnn_

@@godir_:
	push    ebp
	push    ecx

	mov     eax,[ebp].x_
	mov     obj_x_,eax

	mov     eax,[ebp].y_
	mov     obj_y_,eax

	mov     ax,[ebp].energy
	mov     obj_energy,ax

	xor     ecx,ecx
@@nexto_:
	mov     ebp,obj_ptr[ecx*4]
	cmp     [ebp].stat,0
	jle     @@nchk
	mov     eax,[ebp].obj_no
	shr     eax,8
	cmp     eax,1h
	je      @@nchk
	cmp     eax,3h
	je      @@nchk
	cmp     eax,5h
	je      @@nchk
	cmp     eax,6h
	je      @@nchk
	cmp     [ebp].obj_no,800h
	je      @@nchk

	mov     eax,[ebp].x_
	sub     eax,obj_x_
	shr     eax,16
	cmp     ax,0
	jge     SHORT @@noneg1_
	neg     ax
@@noneg1_:
	cmp     ax,f_range
	ja      SHORT @@nchk

	mov     eax,[ebp].y_
	sub     eax,obj_y_
	shr     eax,16
	cmp     ax,0
	jge     SHORT @@noneg2_
	neg     ax
@@noneg2_:
	cmp     ax,f_range
	ja      SHORT @@nchk

	mov     ax,obj_energy
	sub     [ebp].energy,ax
	cmp     [ebp].energy,0
	jge     SHORT @@no0
	mov     [ebp].energy,0
@@no0:
	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax
	mov     eax,1
	call    crea_flm

	mov     eax,_EXPLO0_
	call    SoundFX_

	jmp     @@lout

@@nchk:
	inc     ecx
	cmp     ecx,MAXOBJ
	jb      @@nexto_

	pop     ecx
	pop     ebp
	jmp     @@gogodir

@@lout:
	pop     ecx
	pop     ebp

	mov     [ebp].stat,0

	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax
	mov     eax,2
	call    crea_flm

@@gogodir:
	mov     eax,[ebp].obj_no
	cmp     eax,508h         ;; guided missile
	jne     @@__dirf

	movzx   eax,[ebp].freem
	cmp     al,-1
	je      @@__dirf
	imul    eax,OBJWID
	add     eax,OFFSET obj_table
	mov     ebx,eax

	mov     eax,[ebx].x_
	mov     obj_x_,eax
	mov     eax,[ebx].y_
	mov     obj_y_,eax

	mov     eax,obj_x_
	sub     eax,[ebp].x_
	sar     eax,16
	imul    eax,eax

	mov     ebx,obj_y_
	sub     ebx,[ebp].y_
	sar     ebx,16
	imul    ebx,ebx
	add     eax,ebx

	call    FindSqrt_

	mov     [ebp].dis,ax

	mov     eax,obj_x_
	sub     eax,[ebp].x_
	sar     eax,16

	mov     ebx,obj_y_
	sub     ebx,[ebp].y_
	sar     ebx,16

	cmp     ebx,0
	jle     SHORT @@2
@@1:
	mov     ebx,32767
	imul    ebx
	movzx   ebx,[ebp].dis
	idiv    ebx
	call    FindTheta1
	mov     [ebp].theta,al
	jmp     SHORT @@3
@@2:
	mov     ebx,32767
	imul    ebx
	movzx   ebx,[ebp].dis
	idiv    ebx
	call    FindTheta2
	mov     [ebp].theta,al
@@3:
	mov     al,[ebp].theta
	sub     al,[ebp].mth
	jz      @@__dirf
	cmp     al,128
	ja      @@__mmm
	jb      @@__ppp
@@__mmm:
	add     [ebp].mth,-4
	jmp     SHORT @@__dirf
@@__ppp:
	add     [ebp].mth,4

@@__dirf:
	call    obj_dirf

	jmp     @nnn_

omr05   ENDP


	;-------------------
	; Time Bomb
	;-------------------
omr504  PROC

	mov     f_range,50
	cmp     [ebp].freem,0
	jg      @nnn_

	push    ebp
	push    ecx

	mov     eax,[ebp].x_
	mov     obj_x_,eax

	mov     eax,[ebp].y_
	mov     obj_y_,eax

	mov     ax,[ebp].energy
	mov     obj_energy,ax
	mov     [ebp].energy,0

	xor     ecx,ecx
@@nexto_:
	mov     ebp,obj_ptr[ecx*4]
	cmp     [ebp].stat,0
	jle     @@nchk
	mov     eax,[ebp].obj_no
	shr     eax,8
	cmp     eax,1h
	je      @@nchk
	cmp     eax,3h
	je      @@nchk
	cmp     eax,5h
	je      @@nchk
	cmp     eax,6h
	je      @@nchk

	mov     eax,[ebp].x_
	sub     eax,obj_x_
	shr     eax,16
	cmp     ax,0
	jge     SHORT @@noneg1_
	neg     ax
@@noneg1_:
	cmp     ax,f_range
	ja      SHORT @@nchk

	mov     eax,[ebp].y_
	sub     eax,obj_y_
	shr     eax,16
	cmp     ax,0
	jge     SHORT @@noneg2_
	neg     ax
@@noneg2_:
	cmp     ax,f_range
	ja      SHORT @@nchk

	mov     ax,obj_energy
	sub     [ebp].energy,ax
	cmp     [ebp].energy,0
	jge     SHORT @@no0
	mov     [ebp].energy,0
@@no0:
	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax
	mov     eax,2
	call    crea_flm

@@nchk:
	inc     ecx
	cmp     ecx,MAXOBJ
	jb      @@nexto_

	pop     ecx
	pop     ebp

	mov     [ebp].stat,0

	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax
	mov     eax,2
	call    crea_flm

	jmp     @nnn_

omr504  ENDP

	;-------------------
	; Hologram Mine
	;-------------------
omr06   PROC              ;; hologram mine

	mov     f_range,80
	cmp     [ebp].freem,0
	jg      @nnn_

	push    ebp
	push    ecx

	mov     eax,[ebp].x_
	mov     obj_x_,eax

	mov     eax,[ebp].y_
	mov     obj_y_,eax

	mov     ax,[ebp].energy
	mov     obj_energy,ax
	mov     [ebp].energy,0

	xor     ecx,ecx
@@nexto_:
	mov     ebp,obj_ptr[ecx*4]
	cmp     [ebp].stat,0
	jle     @@nchk
	mov     eax,[ebp].obj_no
	shr     eax,8
	cmp     eax,1h
	je      @@nchk
	cmp     eax,3h
	je      @@nchk
	cmp     eax,5h
	je      @@nchk
	cmp     eax,6h
	je      @@nchk
	cmp     [ebp].obj_no,800h
	je      @@nchk

	mov     eax,[ebp].x_
	sub     eax,obj_x_
	shr     eax,16
	cmp     ax,0
	jge     SHORT @@noneg1_
	neg     ax
@@noneg1_:
	cmp     ax,f_range
	ja      SHORT @@nchk

	mov     eax,[ebp].y_
	sub     eax,obj_y_
	shr     eax,16
	cmp     ax,0
	jge     SHORT @@noneg2_
	neg     ax
@@noneg2_:
	cmp     ax,f_range
	ja      SHORT @@nchk

	mov     ax,obj_energy
	sub     [ebp].energy,ax
	cmp     [ebp].energy,0
	jge     SHORT @@no0
	mov     [ebp].energy,0
@@no0:
	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax
	mov     eax,2
	call    crea_flm

@@nchk:
	inc     ecx
	cmp     ecx,MAXOBJ
	jb      @@nexto_

	pop     ecx
	pop     ebp

	mov     [ebp].stat,0

	mov     holo_stat,0

	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax
	mov     eax,2
	call    crea_flm

	jmp     SHORT @nnn_

omr06   ENDP

	;--------------------
	;  target
	;--------------------
omr08:
	cmp     [ebp].energy,0
	jg      omr01

	cmp     [ebp].stat,-1
	je      @@creasmk

	inc     target_destruction_counter
	mov     [ebp].stat,-1

	mov     eax,_EXPLO0_
	call    SoundFX_

	mov     eax,_EXPLO1_
	call    SoundFX_

	call    all_demage

	jmp     SHORT @nnn_

@@creasmk:
	test    frames,1
	jnz     SHORT @nnn_

	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax

	mov     eax,frames
	mov     flm_th,al
	mov     flm_dir,3
	mov     eax,2
	call    crea_chip

	jmp     SHORT @nnn_


omr01:
	call    obj_dirf
	jmp     SHORT @nnn_

@nnn1_:
	mov     [ebp].stat,1            ; No fire!

@nnn_:
	add     ebp,OBJWID
	dec     ecx
	jnz     @nexto_

	pop     ebp
	ret

obj_move    ENDP

;-----------------------------------
;
;-----------------------------------
AP_move PROC

	cmp     eye_z,128+5
	jle     SHORT @@chk

	call    dirf

	ret

@@chk:
	push    eye_x_
	push    eye_y_

	push    dif
	movzx   eax,d_th
	push    eax

	test    AP_stat,SHFT
	jz      @@noshft
	mov     al,AP_stat
	and     al,RIGH
	cmp     al,LEFT
	jne     @@right
	sub     d_th,64
	mov     dif,5
	jmp     @@noshft
@@right:
	cmp     al,RIGH
	jne     @@noshft
	add     d_th,64
	mov     dif,5

@@noshft:
	call    dirf

	pop     eax
	mov     d_th,al
	pop     dif

	mov     eax,eye_y_
	shr     eax,16+3
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,eye_x_
	shr     ebx,16+3
	and     ebx,255                 ;

	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	cmp     COLLISION_MAP[eax],0     ;load attrib of tile data
	jz      @@ggg

	;--------------------------
	;  forward moving impossible
	;--------------------------
	;
	pop     eye_y_
	pop     eye_x_

	mov     eax,eye_y_
	shr     eax,16+3
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,eye_x_
	shr     ebx,16+3
	and     ebx,255                 ;

	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ax,DIRECTION_MAP[eax*2] ;

	mov     cl,d_th                 ;check right
	shr     cl,4                    ;16 degree

	add     cl,4
	and     cl,15

	mov     bx,1111100000000000b    ;
	rol     bx,cl                   ;
					;
	test    ax,bx                   ;
	jnz     SHORT @@rrr             ;

	mov     cl,d_th                 ;check right
	shr     cl,4                    ;16 degree

	add     cl,4
	and     cl,15
	add     cl,1
	and     cl,15

	mov     bx,11111b               ;
	rol     bx,cl                   ;
					;
	test    ax,bx                   ;
	jz      SHORT @@rrr             ;

@@lll:
	cmp     dif,0
	jl      SHORT @@rrr1
@@lll1:
	mov     dif,0
	add     d_th,254

	ret

@@rrr:
	cmp     dif,0
	jl      @@lll1
@@rrr1:
	mov     dif,0
	add     d_th,2

	ret

@@ggg:
	pop     eax
	pop     eax

	ret


AP_move ENDP


;------------------------------------------
;
;------------------------------------------
AP_fire PROC

	cmp     eye_z,128+5
	ja      @@quit

	mov     al,AP_stat
	and     al,FIRE
	jz      @@quit

	mov     eax,weapon_no
	cmp     weapon_rounds[eax*4],0
	jle     @@quit2
	dec     weapon_rounds[eax*4]

	mov     eax,weapon_no
	jmp     FireRoutine[eax*4]

APW02:  ; shot gun
APW03:  ; utan
	mov     eax,_SGUNSH_
	call    SoundFX_
	jmp     SHORT @@samething
APW07:
	mov     eax,_FTHROW_
	call    SoundFX_
@@samething:
	mov     eax,eye_x_
	mov     flm_x_,eax
	mov     eax,eye_y_
	mov     flm_y_,eax
	mov     al,d_th
	mov     flm_th,al
	mov     flm_dir,16
	cmp     weapon_no,7
	jb      @@speedok
	mov     flm_dir,8
@@speedok:
	mov     eax,weapon_no
	mov     edx,500h
	or      edx,eax
	sub     eax,2
	call    crea_bullet      ;; AP fire!!

	cmp     weapon_no,2;    Shot Gun
	jne     @@quit

	mov     al,d_th
	add     al,2
	mov     flm_th,al
	mov     eax,weapon_no
	mov     edx,500h
	or      edx,eax
	sub     eax,2
	call    crea_bullet      ;; AP fire!!

	mov     al,d_th
	sub     al,2
	mov     flm_th,al
	mov     eax,weapon_no
	mov     edx,500h
	or      edx,eax
	sub     eax,2
	call    crea_bullet      ;; AP fire!!

	jmp     @@quit

	;-----------------
	;
APW08:  ; guided misssile
	;
	;-----------------
	mov     eax,_FTHROW_
	call    SoundFX_

	xor     ecx,ecx

@@nextobject:

	mov     ebp,obj_ptr[ecx*4]

	cmp     [ebp].stat,0
	jle     @@nnn_
	test    [ebp].obj_no,100h
	jnz     @@nnn_

	mov     al,[ebp].theta
	add     al,128
	sub     al,d_th
	cmp     al,0
	jl      SHORT @@minus_
@@plus_:
	cmp     al,32
	jg      @@nnn_
	jmp     SHORT @@done_
@@minus_:
	cmp     al,-32
	jl      @@nnn_
@@done_:
	jmp     @@fireGM


@@nnn_:
	inc     ecx
	cmp     ecx,MAXOBJ
	jb      @@nextobject

	mov     bullet_mem,-1

	jmp     SHORT @@fireGM2

@@fireGM:
	mov     eax,ebp
	sub     eax,OFFSET obj_table
	cdq
	mov     ebx,OBJWID
	div     ebx
	mov     bullet_mem,al

@@fireGM2:
	mov     eax,eye_x_
	mov     flm_x_,eax
	mov     eax,eye_y_
	mov     flm_y_,eax
	mov     al,d_th
	mov     flm_th,al
	mov     flm_dir,8

	mov     eax,weapon_no
	sub     eax,2
	mov     edx,508h         ;; guided missile
	call    crea_bullet      ;; AP fire!!

	jmp     @@quit

APW04:
APW06:
	mov     edx,500h
	jmp     SHORT APW051

APW05:  ; Hologram mine
	mov     edx,600h
	mov     eax,eye_x_
	mov     holo_x_,eax
	mov     eax,eye_y_
	mov     holo_y_,eax
	mov     holo_stat,1
APW051:
	mov     eax,_DROP_
	call    SoundFX_
	mov     eax,eye_x_
	mov     flm_x_,eax
	mov     eax,eye_y_
	mov     flm_y_,eax
	mov     al,d_th
	mov     flm_th,al
	mov     flm_dir,0
	mov     eax,weapon_no
;;;     mov     edx,500h
	or      edx,eax
	sub     eax,2
	call    crea_bullet      ;; AP fire!!

	jmp     @@quit

APW00:
	mov     eax,_VALCAN_
	call    SoundFX_
	jmp     SHORT @@APW011
APW01:
	mov     eax,_MGUN_
	call    SoundFX_
@@APW011:
	push    eye_x_
	push    eye_y_
	push    eye_x
	push    eye_y
	push    dif

	mov     fire_d,8
	mov     dif,8
	mov     ecx,24
@@ntile:
	call    dirf
	mov     ax,eye_x
	shr     ax,3
	mov     bx,eye_y
	shr     bx,3
	shl     bx,8
	add     ax,bx
	movzx   eax,ax
	mov     ebx,TEXMAP[eax*4]
	test    ebx,00100000h
	jz      @@chknext

;;	and	ebx,11111111111011111111111111111111b ;;;;;
;;	mov	TEXMAP[eax*4],ebx                     ;;;;;

;	push	eax
;	push	ecx

;	movzx   eax,eye_x
;	shr	eax,3
;	mov	MXS,eax

;	movzx   eax,eye_y
;	shr	eax,3
;	mov	MYS,eax

;;	call	change_COLLISION_MAP
;;	call	change_DIRECTION_MAP

;	pop	ecx
;	pop	eax

	mov     ebx,TEXMAP[eax*4]       ; load tile index
	and     ebx,0FFFh               ; tile number
	shl     ebx,6                   ; eax * 64, 64 = 8*8
	add     ebx,offset DTIL          ;
;;      mov     ebx,TEXMAPADD2[eax*4]
	mov     TEXMAPADD[eax*4],ebx

	mov     eax,eye_x_
	mov     flm_x_,eax
	mov     eax,eye_y_
	mov     flm_y_,eax
	mov     eax,3
	call    crea_flm

	jmp     @@chkout

@@chknext:
	add     fire_d,8
	dec     ecx
	jnz     @@ntile

@@chkout:
	pop     dif
	pop     eye_y
	pop     eye_x
	pop     eye_y_
	pop     eye_x_

	;-----------------------
	;
	;-----------------------

;;      mov     ebp,OFFSET obj_table
	xor     ebp,ebp

	mov     ecx,MAXOBJ
@@nexto:
	push    ebp

	mov     ebp,obj_ptr[ebp*4]

	cmp     [ebp].stat,0
	jle     @@nnn
	cmp     [ebp].energy,0
	jle     @@nnn
	test    [ebp].obj_no,100h
	jnz     @@nnn
	cmp     [ebp].dis,190
	ja      @@nnn
	mov     ax,fire_d
	cmp     [ebp].dis,ax
	ja      @@nnn

	mov     al,[ebp].theta
	add     al,128
	sub     al,d_th
	cmp     al,0
	jl      @@minus
@@plus:
	cmp     al,8
	jg      @@nnn
	jmp     @@done
@@minus:
	cmp     al,-8
	jl      @@nnn
@@done:

	mov     eax,weapon_no
	mov     ax,weapon_power[eax*2]
	sub     [ebp].energy,ax
	cmp     [ebp].energy,0
	jge     SHORT @@no00
	mov     [ebp].energy,0
@@no00:

	mov     [ebp].ddir,0

	mov     eax,[ebp].x_
	mov     flm_x_,eax
	mov     eax,[ebp].y_
	mov     flm_y_,eax

	mov     eax,frames
	and     eax,7
	shl     eax,16
	add     flm_x_,eax
	sub     flm_y_,eax

	mov     eax,0
	call    crea_flm

;       mov     eax,_EXPLO1_
;       call    SoundFX_

	pop     ebp
	jmp     SHORT @@quit

@@nnn:
	pop     ebp
	inc     ebp
	dec     ecx
	jnz     @@nexto

@@quit:
	ret

@@quit2:
	mov     eax,_GUNDRY_
	call    SoundFX_

	ret

AP_fire ENDP

;---------------------------------------
; eax : flm type no
;---------------------------------------
crea_flm        PROC

	push    ebp
	push    ecx
	push    esi
	push    edi

	mov     esi,OFFSET flm_type
	imul    eax,OBJWID
	add     esi,eax

	mov     ebp,OFFSET obj_table

	mov     ecx,MAXOBJ
@@nexto:
	cmp     [ebp].stat,0
	jnz     @@nnn

	mov     eax,[ebp].obj_no
	shr     eax,8
	cmp     eax,4h
	je      @@nnn

	mov     edi,ebp

	push    ecx
	cld
	mov     ecx,OBJWID
	rep     movsb
	pop     ecx

	mov     eax,flm_x_
	mov     [ebp].x_,eax
	mov     eax,flm_y_
	mov     [ebp].y_,eax

	mov     [ebp].stat,1

	jmp     @@out

@@nnn:
	add     ebp,OBJWID
	dec     ecx
	jnz     @@nexto

@@out:
	pop     edi
	pop     esi
	pop     ecx
	pop     ebp

	ret

crea_flm        ENDP

;---------------------------------------
; eax : chip type no
;
;---------------------------------------
crea_chip       PROC

	push    ebp
	push    ecx
	push    esi
	push    edi

	mov     esi,OFFSET chip_type
	imul    eax,OBJWID
	add     esi,eax

	mov     ebp,OFFSET obj_table

	mov     ecx,MAXOBJ
@@nexto:
	cmp     [ebp].stat,0
	jnz     @@nnn

	mov     eax,[ebp].obj_no
	shr     eax,8
	cmp     eax,4h
	je      @@nnn

	mov     edi,ebp

	push    ecx
	cld
	mov     ecx,OBJWID
	rep     movsb
	pop     ecx

	mov     eax,flm_x_
	mov     [ebp].x_,eax
	mov     eax,flm_y_
	mov     [ebp].y_,eax
	mov     al,flm_th
	mov     [ebp].mth,al
	mov     ax,flm_dir
	mov     [ebp].ddir,ax
;       mov     ax,power
;       mov     [ebp].energy,ax

	mov     [ebp].stat,1

	jmp     @@out

@@nnn:
	add     ebp,OBJWID
	dec     ecx
	jnz     @@nexto

@@out:
	pop     edi
	pop     esi
	pop     ecx
	pop     ebp

	ret

crea_chip       ENDP

;---------------------------------------
; eax : bullet type no
; edx : enemy or AP    300h or 500h
;---------------------------------------
crea_bullet     PROC

	push    ebp
	push    ecx
	push    esi
	push    edi

	push    edx
	mov     esi,OFFSET bullet_type
	imul    eax,OBJWID
	add     esi,eax
	pop     edx

	mov     ebp,OFFSET obj_table

	mov     ecx,MAXOBJ
@@nexto:
	cmp     [ebp].stat,0
	jnz     @@nnn

	mov     eax,[ebp].obj_no
	shr     eax,8
	cmp     eax,4h
	je      @@nnn

	mov     edi,ebp

	push    ecx
	cld
	mov     ecx,OBJWID
	rep     movsb
	pop     ecx

	cmp     [ebp].obj_no,508h       ;; guided missile
	jne     @@skiiip
	mov     al,bullet_mem
	mov     [ebp].freem,al
@@skiiip:
	mov     eax,flm_x_
	mov     [ebp].x_,eax
	mov     eax,flm_y_
	mov     [ebp].y_,eax
	mov     al,flm_th
	mov     [ebp].mth,al
	mov     ax,flm_dir
	mov     [ebp].ddir,ax

	mov     [ebp].obj_no,edx           ;;;;;

	mov     [ebp].stat,1

	jmp     @@out

@@nnn:
	add     ebp,OBJWID
	dec     ecx
	jnz     @@nexto

@@out:
	pop     edi
	pop     esi
	pop     ecx
	pop     ebp

	ret

crea_bullet     ENDP

;--------------------------------
;  shadow direction
;--------------------------------
shadow_dir      PROC

	movzx   ebx,eye_th              ;
	add     ebx,96
	and     ebx,255
	shl     ebx,1                   ;
	mov     ax,SIN[ebx]             ; sin(eye_th)
	mov     sine,ax               ;

	movzx   ebx,eye_th         ;
	add     ebx,64                  ; cosine
	and     ebx,255                 ;
	add     ebx,96
	and     ebx,255
	shl     ebx,1                   ;
	mov     ax,SIN[ebx]             ; dx = cos(eye_th)
	mov     cosine,ax

	mov     ax,shadow_d             ;
	imul    eye_z
	idiv    pers
	imul    cosine                   ;
	shld    dx,ax,1                 ; rx * cos(eye_th) / 32768
	mov     shadow_dx,dx            ;

	mov     ax,shadow_d             ;
	imul    eye_z
	idiv    pers
	imul    sine                   ; rz * sin(eye_th)
	shld    dx,ax,1              ; rz * sin(eye_th) / 32768
	mov     shadow_dy,dx           ;

	ret

shadow_dir    ENDP

;-----------------------------------
;
;-----------------------------------
make_DIRECTION_MAP      PROC

	mov     MY,0
@@Y:
	mov     MX,0
@@X:
	mov     dx,0
	mov     bp,1

	;; 0 -> 0
	mov     eax,MY
	sub     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go1
	or      dx,bp
@@go1:
	shl     bp,1

	;;; 1->16
	mov     eax,MY
	sub     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go2
	or      dx,bp
@@go2:
	shl     bp,1

	;;;2->32
	mov     eax,MY
	sub     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go3
	or      dx,bp
@@go3:
	shl     bp,1

	;;; 3->48
	mov     eax,MY
	sub     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go4
	or      dx,bp
@@go4:
	shl     bp,1

	;;;4->64
	mov     eax,MY
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go5
	or      dx,bp
@@go5:
	shl     bp,1

	;;;5->80
	mov     eax,MY
	add     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go6
	or      dx,bp
@@go6:
	shl     bp,1

	;;;6->96
	mov     eax,MY
	add     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go7
	or      dx,bp
@@go7:
	shl     bp,1

	;;;7->112
	mov     eax,MY
	add     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go8
	or      dx,bp
@@go8:
	shl     bp,1

	;; 8 -> 128
	mov     eax,MY
	add     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go9
	or      dx,bp
@@go9:
	shl     bp,1

	;;;9->144
	mov     eax,MY
	add     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go10
	or      dx,bp
@@go10:
	shl     bp,1

	;;;10->160
	mov     eax,MY
	add     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go11
	or      dx,bp
@@go11:
	shl     bp,1

	;;;11->176
	mov     eax,MY
	add     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go12
	or      dx,bp
@@go12:
	shl     bp,1

	;;;12->192
	mov     eax,MY
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go13
	or      dx,bp
@@go13:
	shl     bp,1

	;;;13->208
	mov     eax,MY
	sub     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go14
	or      dx,bp
@@go14:
	shl     bp,1

	;;;14->224
	mov     eax,MY
	sub     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go15
	or      dx,bp
@@go15:
	shl     bp,1

	;;;15->240
	mov     eax,MY
	sub     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go16
	or      dx,bp
@@go16:

	mov     eax,MY
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     eax,ebx                 ;eax : offset of map data

	mov     DIRECTION_MAP[eax*2],dx

	inc     MX
	cmp     MX,256
	jb      @@X

	inc     MY
	cmp     MY,256
	jb      @@Y

	ret

make_DIRECTION_MAP      ENDP

;
;
;
make_COLLISION_MAP      PROC

	mov     MY,0
@@Y:
	mov     MX,0
@@X:
	;;;     CENTER
	mov     eax,MY
	shl     eax,8                   ;mapy * 256
	mov     ebx,MX
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     @@quit

	mov     eax,MY
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     @@quit

	;;;     32
	mov     eax,MY
	sub     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     @@quit

	;;;     64
	mov     eax,MY
	sub     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     @@quit

	;;;     96
	mov     eax,MY
	sub     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     @@quit

	;;;     128
	mov     eax,MY
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     @@quit

	;;;     160
	mov     eax,MY
	add     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     @@quit

	;;;     192
	mov     eax,MY
	add     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     @@quit

	;;;     224
	mov     eax,MY
	add     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     SHORT @@quit

	jmp     SHORT @@out
@@quit:
	mov     eax,MX
	mov     ebx,MY
	shl     ebx,8
	add     eax,ebx
	mov     COLLISION_MAP[eax],1
	jmp     @@out2
@@out:
	mov     eax,MX
	mov     ebx,MY
	shl     ebx,8
	add     eax,ebx
	mov     COLLISION_MAP[eax],0
@@out2:
	inc     MX
	cmp     MX,256
	jb      @@X

	inc     MY
	cmp     MY,256
	jb      @@Y

	ret

make_COLLISION_MAP      ENDP

;-----------------------------------
;  change map
;-----------------------------------
change_DIRECTION_MAP      PROC

	mov     MY,0
	mov	eax,MYS
	sub	eax,2
	and	eax,255
	add	eax,MY
	and	eax,255
	mov	MY,eax

	mov	ecx,5
@@Y:
	mov     MX,0
	mov	eax,MXS
	sub	eax,2
	and	eax,255
	add	eax,MX
	and	eax,255
	mov	MX,eax

	push	ecx
	mov	ecx,5
@@X:
	mov     dx,0
	mov     bp,1

	;; 0 -> 0
	mov     eax,MY
	sub     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go1
	or      dx,bp
@@go1:
	shl     bp,1

	;;; 1->16
	mov     eax,MY
	sub     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go2
	or      dx,bp
@@go2:
	shl     bp,1

	;;;2->32
	mov     eax,MY
	sub     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go3
	or      dx,bp
@@go3:
	shl     bp,1

	;;; 3->48
	mov     eax,MY
	sub     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go4
	or      dx,bp
@@go4:
	shl     bp,1

	;;;4->64
	mov     eax,MY
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go5
	or      dx,bp
@@go5:
	shl     bp,1

	;;;5->80
	mov     eax,MY
	add     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go6
	or      dx,bp
@@go6:
	shl     bp,1

	;;;6->96
	mov     eax,MY
	add     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go7
	or      dx,bp
@@go7:
	shl     bp,1

	;;;7->112
	mov     eax,MY
	add     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go8
	or      dx,bp
@@go8:
	shl     bp,1

	;; 8 -> 128
	mov     eax,MY
	add     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go9
	or      dx,bp
@@go9:
	shl     bp,1

	;;;9->144
	mov     eax,MY
	add     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go10
	or      dx,bp
@@go10:
	shl     bp,1

	;;;10->160
	mov     eax,MY
	add     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go11
	or      dx,bp
@@go11:
	shl     bp,1

	;;;11->176
	mov     eax,MY
	add     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go12
	or      dx,bp
@@go12:
	shl     bp,1

	;;;12->192
	mov     eax,MY
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go13
	or      dx,bp
@@go13:
	shl     bp,1

	;;;13->208
	mov     eax,MY
	sub     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go14
	or      dx,bp
@@go14:
	shl     bp,1

	;;;14->224
	mov     eax,MY
	sub     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,2
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go15
	or      dx,bp
@@go15:
	shl     bp,1

	;;;15->240
	mov     eax,MY
	sub     eax,2
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jz      @@go16
	or      dx,bp
@@go16:

	mov     eax,MY
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     eax,ebx                 ;eax : offset of map data

	mov     DIRECTION_MAP[eax*2],dx

	inc	MX
	dec	ecx
	jnz	@@X

	inc	MY
	pop	ecx
	dec	ecx
	jnz	@@Y

	ret

change_DIRECTION_MAP      ENDP

;
;
;
change_COLLISION_MAP      PROC

	mov     MY,0
	mov	eax,MYS
	sub	eax,1
	and	eax,255
	add	eax,MY
	and	eax,255
	mov	MY,eax

	mov	ecx,3
@@Y:
	mov     MX,0
	mov	eax,MXS
	sub	eax,1
	and	eax,255
	add	eax,MX
	and	eax,255
	mov	MX,eax

	push	ecx
	mov	ecx,3
@@X:
	;;;     CENTER
	mov     eax,MY
	shl     eax,8                   ;mapy * 256
	mov     ebx,MX
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     @@quit

	mov     eax,MY
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     @@quit

	;;;     32
	mov     eax,MY
	sub     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     @@quit

	;;;     64
	mov     eax,MY
	sub     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     @@quit

	;;;     96
	mov     eax,MY
	sub     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     @@quit

	;;;     128
	mov     eax,MY
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     @@quit

	;;;     160
	mov     eax,MY
	add     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	sub     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     @@quit

	;;;     192
	mov     eax,MY
	add     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     @@quit

	;;;     224
	mov     eax,MY
	add     eax,1
	and     eax,255
	shl     eax,8                   ;mapy * 256

	mov     ebx,MX
	add     ebx,1
	and     ebx,255
	add     eax,ebx                 ;eax : offset of map data

	;calculate tile coordinator
	mov     ebx,TEXMAP[eax * 4]     ;load attrib of tile data
	test    ebx,00100000h
	jnz     SHORT @@quit

	jmp     SHORT @@out
@@quit:
	mov     eax,MX
	mov     ebx,MY
	shl     ebx,8
	add     eax,ebx
	mov     COLLISION_MAP[eax],1
	jmp     @@out2
@@out:
	mov     eax,MX
	mov     ebx,MY
	shl     ebx,8
	add     eax,ebx
	mov     COLLISION_MAP[eax],0
@@out2:
	inc	MY
	dec	ecx
	jnz	@@X

	inc	MY
	pop	ecx
	dec	ecx
	jnz	@@Y

	ret

change_COLLISION_MAP      ENDP

;---------------------------------------
;
;---------------------------------------
draw_noise      PROC

	mov     eax,frames
	and     eax,3
	mov     esi,noise_spr_data[eax*4]
	mov     eax,3
	mov     edx,3
	call    put_spr

	ret

draw_noise      ENDP

;-----------------------
; vertical draw
;-----------------------
vline   PROC

	push    ebp
	push    ecx

	mov     eax,ebp
	shl     eax,16
	imul    eye_zd
	mov     ebx,128
	idiv    ebx
	mov     xx_,eax

	mov     eax,-200
	shl     eax,16
	imul    eye_zd
;       mov     ebx,128
	idiv    ebx
	mov     ey1_,eax

	mov     eax,39
	shl     eax,16
	imul    eye_zd
;       mov     ebx,128
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
	mov     eax,eye_x_
	add     x1_,eax
	add     x2_,eax

	mov     eax,eye_y_
	add     y1_,eax
	add     y2_,eax
;;;
	mov     eax,x2_
	sub     eax,x1_
	cdq
	mov     ebx,240
	idiv    ebx
	mov     xa_,eax

	mov     eax,y2_
	sub     eax,y1_
	cdq
	idiv    ebx
	mov     ya_,eax

	mov     edi,lstart

	mov     esi,x1_
	mov     ebp,y1_

	mov     ecx,240
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
	mov     ebx,ebp
	shr     ebx,16
	and     ebx,7  ;;;;;;
	shl     ebx,3   ;;;;;     ;y * 8

	mov     edx,TEXMAPADD[eax * 4]     ;load pointer of tile data

	mov     eax,esi
	shr     eax,16
	and     eax,7  ;;;;;;;
	add     ebx,eax                 ;ebx : offset of tile data

	add     esi,xa_
	add     ebp,ya_

	mov     al,byte ptr[edx][ebx]   ;load color
	mov     byte ptr [edi],al        ;


	add     edi,80

	dec     ecx
	jnz     @@nextp

	pop     ecx
	pop     ebp

	ret

vline   ENDP

;------------------------------
; high detail
;------------------------------
draw_floor      PROC

	mov     dx,SC_INDEX             ;Let's prepare SC_INDEX
	mov     al,MAP_MASK             ;For the MAP_MASK
	out     dx,al                   ;.....

	mov     edi,SCREEN_OFF          ;Calculate Init Pixel on dest.
	add     edi,PageOffset          ;

	mov     eax,Lbound
	shr     eax,2
	mov     lstart,eax
	add     lstart,edi

	mov     map_mask,11h

	mov     eax,Rbound
	inc     eax
	sub     eax,Lbound
	mov     ecx,eax
	shr     eax,1
	neg     eax
	mov     ebp,eax
@@nextx:
	mov     dx,SC_INDEX + 1
	mov     al,map_mask
	out     dx,al

	call    vline

	add     ebp,1
	rol     map_mask,1
	adc     lstart,0

	dec     ecx
	jnz     @@nextx

	ret

draw_floor      ENDP

;------------------------------
; low detail
;------------------------------
draw_floorL     PROC

	mov     dx,SC_INDEX             ;Let's prepare SC_INDEX
	mov     al,MAP_MASK             ;For the MAP_MASK
	out     dx,al                   ;.....

	mov     edi,SCREEN_OFF          ;Calculate Init Pixel on dest.
	add     edi,PageOffset          ;

	mov     eax,Lbound
	shr     eax,2
	mov     lstart,eax
	add     lstart,edi

	mov     map_mask,33h

	mov     eax,Rbound
	inc     eax
	sub     eax,Lbound
	shr     eax,1
	mov     ecx,eax
	neg     eax
	mov     ebp,eax
;       mov     bp,-128                 ; start x
;       mov     ecx,128
@@nextx:
	mov     dx,SC_INDEX + 1
	mov     al,map_mask
	out     dx,al

	call    vline

	add     ebp,2

	rol     map_mask,2
	adc     lstart,0

	dec     ecx
	jnz     @@nextx

	ret

draw_floorL     ENDP

;------------------------------
; low detail
;------------------------------
draw_floorLL    PROC

	mov     dx,SC_INDEX             ;Let's prepare SC_INDEX
	mov     al,MAP_MASK             ;For the MAP_MASK
	out     dx,al                   ;.....

	mov     edi,SCREEN_OFF          ;Calculate Init Pixel on dest.
	add     edi,PageOffset          ;

	mov     eax,Lbound
	shr     eax,2
	mov     lstart,eax
	add     lstart,edi

	mov     map_mask,0FFh

	mov     eax,Rbound
	inc     eax
	sub     eax,Lbound
	shr     eax,1
	mov     ecx,eax
	shr     ecx,1
	neg     eax
	mov     ebp,eax
;       mov     bp,-128                 ; start x
;       mov     ecx,128
@@nextx:
	mov     dx,SC_INDEX + 1
	mov     al,map_mask
	out     dx,al

	call    vline

	add     ebp,4

	rol     map_mask,4
	adc     lstart,0

	dec     ecx
	jnz     @@nextx

	ret

draw_floorLL    ENDP

;-----------------------
; vertical draw
;-----------------------
vline2  PROC

	push    ebp
	push    ecx

	mov     eax,ebp
	shl     eax,16
	imul    eye_zd
	mov     ebx,128
	idiv    ebx
	mov     xx_,eax

	mov     eax,-17
	shl     eax,16
	imul    eye_zd
;       mov     ebx,128
	idiv    ebx
	mov     ey1_,eax

	mov     eax,15
	shl     eax,16
	imul    eye_zd
;       mov     ebx,128
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
	mov     eax,eye_x_
	add     x1_,eax
	add     x2_,eax

	mov     eax,eye_y_
	add     y1_,eax
	add     y2_,eax
;;;
	mov     eax,x2_
	sub     eax,x1_
	cdq
	mov     ebx,32
	idiv    ebx
	mov     xa_,eax

	mov     eax,y2_
	sub     eax,y1_
	cdq
	idiv    ebx
	mov     ya_,eax

	mov     edi,lstart
	add     edi,80*184

	mov     esi,x1_
	mov     ebp,y1_

	mov     ecx,32
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

	test    ebx,00200000h
	jz      SHORT @@skip

	test    ebx,00400000h
	jz      SHORT @@skip_

	shr     ebx,12
	and     ebx,0FFh
	shl     ebx,6
	add     ebx,offset TIL
	mov     eax,ebx     ;load pointer of tile data
	jmp     SHORT @@skip__
@@skip_:
	mov     eax,TEXMAPADD[eax * 4]
@@skip__:
	mov     ebx,esi
	shr     ebx,16
	and     ebx,7  ;;;;;;;
	add     ebx,edx                 ;ebx : offset of tile data

	mov     al,byte ptr[eax][ebx]   ;load color
	cmp     al,0
	jz      SHORT @@skip
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

vline2  ENDP

;------------------------------
;
;------------------------------
draw_floor2     PROC

	cmp     eye_z,128+5
	jg      @@quit

	mov     dx,SC_INDEX             ;Let's prepare SC_INDEX
	mov     al,MAP_MASK             ;For the MAP_MASK
	out     dx,al                   ;.....

	mov     edi,SCREEN_OFF          ;Calculate Init Pixel on dest.
	add     edi,PageOffset          ;

	mov     map_mask,11h

	mov     lstart,44               ; addr.  x/4, X = 176
	add     lstart,edi

	mov     ebp,-16                 ; start x
	mov     ecx,32
@@nextx:
	mov     dx,SC_INDEX + 1
	mov     al,map_mask
	out     dx,al

	call    vline2

	add     ebp,1

	rol     map_mask,1
	adc     lstart,0

	dec     ecx
	jnz     @@nextx
@@quit:
	ret

draw_floor2     ENDP

;-----------------------
;
;-----------------------
vlinem  PROC

	push    ebp
	push    ecx

	movsx   eax,bp
	shl     eax,16
	imul    mapw_zd
	mov     ebx,128
	idiv    ebx
	mov     xx_,eax

	mov     eax,-29
	shl     eax,16
	imul    mapw_zd
;       mov     ebx,128
	idiv    ebx
	mov     ey1_,eax

	mov     eax,29
	shl     eax,16
	imul    mapw_zd
;       mov     ebx,128
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

; x1, z1
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

; x2, z2
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
	mov     eax,eye_x_
;;      add     eax,29 SHL 16
	add     x1_,eax
	add     x2_,eax

	mov     eax,eye_y_
;;      add     eax,29 SHL 16
	add     y1_,eax
	add     y2_,eax
;;;
	mov     eax,x2_
	sub     eax,x1_
	cdq
	mov     ebx,58
	idiv    ebx
	mov     xa_,eax

	mov     eax,y2_
	sub     eax,y1_
	cdq
	idiv    ebx
	mov     ya_,eax

	mov     edi,lstart
	add     edi,80*3

	mov     esi,x1_
	mov     ebp,y1_

	mov     ecx,57
	align 4
@@nextp:
	;calculate map coordinator
	mov     edx,ebp
	shr     edx,16+3
	and     edx,255
	shl     edx,8                   ;mapy * 256

	mov     eax,esi
	shr     eax,16+3
	and     eax,255                   ;
	add     eax,edx

	;calculate tile coordinator
	mov     edx,ebp
	shr     edx,16
	and     edx,7  ;;;;;;
	shl     edx,3   ;;;;;     ;y * 8

	mov     eax,TEXMAPADD[eax * 4]

	mov     ebx,esi
	shr     ebx,16
	and     ebx,7  ;;;;;;;
	add     ebx,edx

	xor     edx,edx
	mov     dl,byte ptr[eax][ebx]
	mov     al,GREEN_TABLE[edx]
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

vlinem  ENDP

;------------------------------
;
;------------------------------
draw_map        PROC

	mov     dx,SC_INDEX                 ;Let's prepare SC_INDEX
	mov     al,MAP_MASK                 ;For the MAP_MASK
	out     dx,al                       ;.....

	mov     edi,SCREEN_OFF           ;Calculate Init Pixel on dest.
	add     edi,PageOffset           ;

	mov     lstart,0                    ; addr.   x/4
	add     lstart,edi

	mov     map_mask,11h
	rol     map_mask,3

	mov     bp,-29                      ; x
	mov     ecx,58
@@nextx:
	mov     dx,SC_INDEX + 1
	mov     al,map_mask
	out     dx,al

	call    vlinem

	add     bp,1

	rol     map_mask,1
	adc     lstart,0

	dec     ecx
	jnz     @@nextx

	call    put_en_pos

	mov     eax,32
	mov     edx,31
	mov     bl,84
	call    put_pixel

	mov     eax,32
	mov     edx,33
	mov     bl,84
	call    put_pixel

	mov     eax,31
	mov     edx,32
	mov     bl,84
	call    put_pixel

	mov     eax,33
	mov     edx,32
	mov     bl,84
	call    put_pixel

	ret

draw_map        ENDP

;--------------------------------------
;
;--------------------------------------
mission_load    PROC

	mov     esi,offset tilefilename
	mov     eax,_mission_no
	dec     eax
	mov     eax,mission_number[eax*4]            ;;;;
	imul    eax,13
	add     esi,eax
	mov     al,0
	call    open_file
	push    eax
	mov     edi,offset TIL_load
	mov     ecx,12+768
	call    read_file  ;;;;;

	pop     ebx
	push    ebx
	mov     al,1
	mov     ecx,12000
	call    move_file_pointer

	pop     eax
	push    eax
	mov     edi,offset TIL
	mov     ecx,64*3000
	call    read_file  ;;;;;

	pop     eax
	call    close_file

;       mov     edi,offset TIL_load
;       mov     ecx,12+768+12000+64*3000
;       call    load_file

	mov     esi,offset tilefilenameD
	mov     eax,_mission_no
	dec     eax
	mov     eax,mission_number[eax*4]            ;;;;
	imul    eax,13
	add     esi,eax
	mov     al,0
	call    open_file
	mov     ebx,eax
	push    eax
	mov     al,0
	mov     ecx,12+768+12000
	call    move_file_pointer

	pop     eax
	push    eax
	mov     edi,offset DTIL
	mov     ecx,64*3000
	call    read_file  ;;;;

	pop     eax
	call    close_file

;       mov     edi,offset DTIL_load
;       mov     ecx,12+768+12000+64*3000
;       call    load_file

;       mov     esi,offset mapfilename
;       mov     eax,_mission_no
;       dec     eax
;       mov     eax,mission_number[eax*4]            ;;;;
;       imul    eax,13
;       add     esi,eax
;       mov     edi,offset MAP_load
;       mov     ecx,8 + (256*256*4) + (2898*4)
;       call    load_file

	mov     esi,offset mapfilename
	mov     eax,_mission_no
	dec     eax
	mov     eax,mission_number[eax*4]            ;;;;
	imul    eax,13
	add     esi,eax
	mov     al,0
	call    open_file
	push    eax
	mov     edi,offset MAP_load
	mov     ecx,8 + (256*256*4) + (18*4)
	call    read_file  ;;;;

	pop     ebx
	push    ebx
	mov     al,1
	mov     ecx,(30*67*4)
	call    move_file_pointer

	pop     eax
	push    eax
	mov     edi,offset ENINFO
	mov     ecx,(30*14*4) + (30*15*4)
	call    read_file   ;;;;

	pop     eax
	call    close_file

	mov     esi,offset filename02
	mov     edi,offset PAL
	mov     ecx,16 * 3
	call    load_file

	ret

mission_load    ENDP

;-------------------------------------
;
;-------------------------------------
crea_enemy      PROC

	mov     target_destruction,0

	mov     edi,OFFSET obj_table

	mov     ecx,ENNUM
	cmp     ecx,60
	jbe     @@numok
	mov     ecx,60
	mov     ENNUM,60
@@numok:
	cmp     ecx,0
	jz      @@quit

	xor     ebx,ebx
@@next:
	mov     eax,ENINFO[ebx+8]  ; type
	cmp     eax,7
	ja      @@targetcheck
;;      ja      @@skip
	cmp     eax,0
	jnz     @@gogo

@@startpos:
	mov     eax,ENINFO[ebx]
	shl     eax,3
	add     eax,4
	shl     eax,16
	mov     eye_x_,eax

	mov     eax,ENINFO[ebx+4]
	shl     eax,3
	add     eax,4
	shl     eax,16
	mov     eye_y_,eax

	jmp     @@skip

@@gogo:
	dec     eax
	imul    eax,OBJWID
	mov     esi,OFFSET obj_type1
	add     esi,eax

	push    edi
	push    ecx

	cld
	mov     ecx,OBJWID
	rep     movsb

	pop     ecx
	pop     edi

	mov     eax,ENINFO[ebx]
	shl     eax,3
	add     eax,4
	shl     eax,16
	mov     [edi].x_,eax

	mov     eax,ENINFO[ebx+4]
	shl     eax,3
	add     eax,4
	shl     eax,16
	mov     [edi].y_,eax

	add     edi,OBJWID

	jmp     @@skip

@@targetcheck:
	cmp     eax,20
	jne     @@returncheck

	mov     esi,OFFSET target_type

	push    edi
	push    ecx

	cld
	mov     ecx,OBJWID
	rep     movsb

	pop     ecx
	pop     edi

	mov     eax,ENINFO[ebx]
	shl     eax,3
	add     eax,4
	shl     eax,16
	mov     [edi].x_,eax

	mov     eax,ENINFO[ebx+4]
	shl     eax,3
	add     eax,4
	shl     eax,16
	mov     [edi].y_,eax

	inc     target_destruction

	add     edi,OBJWID

	jmp     @@skip

@@returncheck:
	cmp     eax,99
	jne     @@skip

	mov     eax,ENINFO[ebx]
	shl     eax,3
	add     eax,4
	shl     eax,16
	mov     return_pos_x_,eax

	mov     eax,ENINFO[ebx+4]
	shl     eax,3
	add     eax,4
	shl     eax,16
	mov     return_pos_y_,eax

@@skip:
	add     ebx,14*4

	dec     ecx
	jnz     @@next

	;----------------
	;
	;----------------

	xor     ebx,ebx

	mov     ecx,ENNUM
@@next2:
	mov     eax,ENINFO[ebx+8]  ; type
	cmp     eax,7
	jbe     @@skip2
	cmp     eax,20
	jae     @@skip2

	sub     eax,8
	imul    eax,OBJWID*2
	mov     esi,OFFSET obj_type2
	add     esi,eax

	push    edi
	push    ecx

	cld
	mov     ecx,OBJWID
	rep     movsw

	pop     ecx
	pop     edi

	mov     eax,ENINFO[ebx]
	shl     eax,3
	add     eax,4
	shl     eax,16
	mov     [edi].x_,eax

	mov     eax,ENINFO[ebx+4]
	shl     eax,3
	add     eax,4
	shl     eax,16
	mov     [edi].y_,eax

	add     edi,OBJWID*2
@@skip2:
	add     ebx,14*4

	dec     ecx
	jnz     @@next2

@@quit:
	ret

crea_enemy      ENDP

;-----------------------------------
; input
;       eax : x
;       edx : y
;-----------------------------------
put_en_pos      PROC

	push    ebp

	mov     ebp,OFFSET obj_table
	mov     ecx,MAXOBJ
@@nexto:
	cmp     [ebp].stat,0
	jz      @@skip
	test    [ebp].obj_no,100h
	jnz     @@skip

	cmp     [ebp].obj_no,800h
	jne     @@normal

	cmp     mission_goal_ok,1
	jne     @@skip
	mov     eax,_mission_no
	dec     eax
	mov     eax,mission_type[eax*4]
	cmp     mission_goal[eax*4+1],0
	jz      @@skip
	cmp     mission_goal[eax*4+1],1
	je      @@gogo1
	cmp     time_counter2,0
	jnz     @@skip

@@gogo1:
	xor     eax,eax
	xor     edx,edx
	mov     eax,[ebp].x_
;       shr     eax,16
	mov     edx,[ebp].y_
;       shr     edx,16
	call    world2map
	sar     eax,16
	sar     edx,16
	add     eax,32
	add     edx,32

	cmp     [ebp].energy,0
	jle     SHORT @@dead_
	mov     bl,9
	jmp     SHORT @@live_
@@dead_:
	mov     bl,11
@@live_:

	cmp     eax,3
	jl      @@skip
	cmp     eax,60
	jg      @@skip
	cmp     edx,3
	jl      @@skip
	cmp     edx,59
	jg      @@skip

	test    frames,1
	jnz     @@skip
	call    put_pixel

	jmp     @@skip

@@normal:
	xor     eax,eax
	xor     edx,edx
	mov     eax,[ebp].x_
	mov     edx,[ebp].y_
	call    world2map
	sar     eax,16
	sar     edx,16
	add     eax,32
	add     edx,32

	cmp     [ebp].energy,0
	jle     SHORT @@dead
	mov     bl,9
	jmp     SHORT @@live
@@dead:
	mov     bl,11
@@live:

	cmp     eax,3
	jl      @@skip
	cmp     eax,60
	jg      @@skip
	cmp     edx,3
	jl      @@skip
	cmp     edx,59
	jg      @@skip

	call    put_pixel

@@skip:
	add     ebp,OBJWID
	dec     ecx
	jnz     @@nexto

	;
	;
	;
	cmp     mission_goal_ok,1
	jne     @@out
	cmp     mission_goal_ok[1],1
	jne     @@out
	mov     eax,_mission_no
	dec     eax
	mov     eax,mission_type[eax*4]
	cmp     mission_goal[eax*4+2],0
	jz      @@out
	cmp     mission_goal[eax*4+2],1
	je      @@gogo2
	cmp     time_counter3,0
	jnz     @@out

@@gogo2:
	mov     eax,return_pos_x_
	mov     edx,return_pos_y_
	call    world2map
	sar     eax,16
	sar     edx,16
	add     eax,32
	add     edx,32

	mov     bl,9

	cmp     eax,3
	jl      @@out
	cmp     eax,60
	jg      @@out
	cmp     edx,3
	jl      @@out
	cmp     edx,59
	jg      @@out

	test    frames,1
	jnz     @@out
	call    put_pixel

@@out:
	pop     ebp

	ret

put_en_pos      ENDP

;---------------------------------------
;
;---------------------------------------
edge_correction PROC

	push    ebp

	mov     ebp,OFFSET obj_table

	and     eye_x_,7FFFFFFh
	and     eye_y_,7FFFFFFh

	mov     ecx,MAXOBJ
@@nexto:
	cmp     [ebp].stat,0
	jz      @@3

	and     [ebp].x_,7FFFFFFh
	and     [ebp].y_,7FFFFFFh

	cmp     eye_x_,(2048 SHL 16) - (500 SHL 16)
	jl      @@XB
@@XA:
	cmp     [ebp].x_,500 SHL 16
	jge     @@YY
	add     [ebp].x_,2048 SHL 16
	jmp     @@YY
@@XB:
	cmp     eye_x_,500 SHL 16
	jge     @@YY

	cmp     [ebp].x_,(2048 SHL 16) - (500 SHL 16)
	jl      @@YY
	sub     [ebp].x_,2048 SHL 16

@@YY:
	cmp     eye_y_,(2048 SHL 16) - (500 SHL 16)
	jl      @@YB
@@YA:
	cmp     [ebp].y_,500 SHL 16
	jge     SHORT @@QQ
	add     [ebp].y_,2048 SHL 16
	jmp     SHORT @@QQ
@@YB:
	cmp     eye_y_,500 SHL 16
	jge     SHORT @@QQ

	cmp     [ebp].y_,(2048 SHL 16) - (500 SHL 16)
	jl      @@QQ
	sub     [ebp].y_,2048 SHL 16
@@QQ:
	cmp     holo_stat,0
	jnz     @@noholo
	mov     eax,eye_x_
	mov     holo_x_,eax
	mov     eax,eye_y_
	mov     holo_y_,eax
@@noholo:
	test    [ebp].obj_no,100h
	jnz     @@3

	mov     eax,holo_x_
	sub     eax,[ebp].x_
	sar     eax,16
	imul    eax,eax

	mov     ebx,holo_y_
	sub     ebx,[ebp].y_
	sar     ebx,16
	imul    ebx,ebx
	add     eax,ebx

	call    FindSqrt_

	mov     [ebp].dis,ax

	mov     eax,holo_x_
	sub     eax,[ebp].x_
	sar     eax,16

	mov     ebx,holo_y_
	sub     ebx,[ebp].y_
	sar     ebx,16

	cmp     ebx,0
	jle     SHORT @@2
@@1:
	mov     ebx,32767
	imul    ebx
	movzx   ebx,[ebp].dis
	idiv    ebx
	call    FindTheta1
	mov     [ebp].theta,al
	jmp     SHORT @@3
@@2:
	mov     ebx,32767
	imul    ebx
	movzx   ebx,[ebp].dis
	idiv    ebx
	call    FindTheta2
	mov     [ebp].theta,al
@@3:

	add     ebp,OBJWID
	dec     ecx
	jnz     @@nexto

	;---------------
	;
	;---------------
@@return_pos:

	and     return_pos_x_,7FFFFFFh
	and     return_pos_y_,7FFFFFFh

	cmp     eye_x_,(2048 SHL 16) - (500 SHL 16)
	jl      @@XB_
@@XA_:
	cmp     return_pos_x_,500 SHL 16
	jge     @@YY_
	add     return_pos_x_,2048 SHL 16
	jmp     @@YY_
@@XB_:
	cmp     eye_x_,500 SHL 16
	jge     @@YY_

	cmp     return_pos_x_,(2048 SHL 16) - (500 SHL 16)
	jl      @@YY_
	sub     return_pos_x_,2048 SHL 16

@@YY_:
	cmp     eye_y_,(2048 SHL 16) - (500 SHL 16)
	jl      @@YB_
@@YA_:
	cmp     return_pos_y_,500 SHL 16
	jge     SHORT @@QQ_
	add     return_pos_y_,2048 SHL 16
	jmp     SHORT @@QQ_
@@YB_:
	cmp     eye_y_,500 SHL 16
	jge     SHORT @@QQ_

	cmp     return_pos_y_,(2048 SHL 16) - (500 SHL 16)
	jl      @@QQ_
	sub     return_pos_y_,2048 SHL 16
@@QQ_:

	mov     eax,eye_x_
	sub     eax,return_pos_x_
	sar     eax,16
	imul    eax,eax

	mov     ebx,eye_y_
	sub     ebx,return_pos_y_
	sar     ebx,16
	imul    ebx,ebx

	add     eax,ebx

	call    FindSqrt_

	mov     return_dis,ax

	mov     eax,eye_x_
	sub     eax,return_pos_x_
	sar     eax,16

	mov     ebx,eye_y_
	sub     ebx,return_pos_y_
	sar     ebx,16

	cmp     ebx,0
	jle     SHORT @@2_
@@1_:
	mov     ebx,32767
	imul    ebx
	movzx   ebx,return_dis
	idiv    ebx
	call    FindTheta1
	mov     return_theta,al
	jmp     SHORT @@3_
@@2_:
	mov     ebx,32767
	imul    ebx
	movzx   ebx,return_dis
	idiv    ebx
	call    FindTheta2
	mov     return_theta,al
@@3_:

	pop     ebp

	ret

edge_correction ENDP

;---------------------------------------
;
;---------------------------------------
sprites PROC

	push    ebp

	cmp     AP_energy,50
	ja      @@nosound
	mov     eax,frames
	and     eax,15
	jnz     @@nosound
	mov     eax,_SIREN_
	call    SoundFX_
@@nosound:

	call    shadow_dir
	;
	;----------------------------
	;
	mov     ebp,OFFSET obj_table
	mov     ecx,MAXOBJ
@@nexto:
	cmp     [ebp].stat,0
	jz      @@nnn
	test    [ebp].obj_no,100h
	jnz     @@noR
	cmp     [ebp].obj_no,800h
	je      @@nnn

	push    ecx

	mov     al,[ebp].mth            ;
	add     al,64                   ;
	mov     [ebp].vth,al            ;

	movzx   eax,[ebp].xc
	shl     eax,16
	mov     _XC_,eax
	movzx   eax,[ebp].yc
	shl     eax,16
	mov     _YC_,eax

	mov     eax,[ebp].spr_no
	mov     esi,[ebp].spr_data
	mov     esi,[esi][eax*4]
	mov     eax,[ebp].x_
	mov     edx,[ebp].y_
	movzx   ebx,[ebp].vth
	call    put_shadowR

	movzx   eax,[ebp].xc
	shl     eax,16
	mov     _XC_,eax
	movzx   eax,[ebp].yc
	shl     eax,16
	mov     _YC_,eax

	mov     eax,[ebp].spr_no
	mov     esi,[ebp].spr_data
	mov     esi,[esi][eax*4]
	mov     eax,[ebp].x_
	mov     edx,[ebp].y_
	movzx   ebx,[ebp].vth
	call    put_sprR

	mov     eax,[ebp].x_
	mov     edx,[ebp].y_
	call    draw_floor3

	pop     ecx

	jmp     @@nnn

@@noR:
	mov     eax,[ebp].spr_no
	mov     esi,[ebp].spr_data
	mov     esi,[esi][eax*4]
	mov     eax,[ebp].x_
	mov     edx,[ebp].y_
	push    ecx
	call    world2eye
	sar     eax,16
	sar     edx,16
	add     eax,64+128
	add     edx,200
	xor     ecx,ecx
	movzx   ebx,eye_z
	call    put_sprSC
	pop     ecx

@@nnn:
	add     ebp,OBJWID
	dec     ecx
	jnz     @@nexto
	;
	;--------------------------------
	;   AP
	;-------------------------------
	;
	mov     eax,AP_frame
	mov     esi,AP_spr_data[eax*4]
	mov     eax,LASAPOSX
	add     eax,13
	add     ax,shadow_dx
	mov     edx,LASAPOSY
	add     edx,14
	add     dx,shadow_dy
	xor     ecx,ecx
	movzx   ebx,eye_z
	call    put_shadowSC

	mov     eax,AP_frame
	mov     esi,AP_spr_data[eax*4]
	mov     eax,LASAPOSX
	mov     edx,LASAPOSY
	call    put_spr

	pop     ebp

	ret

sprites ENDP

main_menu       PROC

	ret

main_menu       ENDP

;----------------------------------------
;
;
;----------------------------------------
key_input       PROC

	and     AP_stat,BUST

	cmp     AP_energy,0
	jle     @nextk8

	cmp     keyboard[_UPKEY],1               ; UP key
	jne     @nextk1
	or      AP_stat,FORW
@nextk1:
	cmp     keyboard[_DNKEY],1               ; DN key
	jne     @nextk2
	or      AP_stat,BACK
@nextk2:
@nextk3:
@nextk4:
	cmp     keyboard[_LTKEY],1             ; <- key
	jne     SHORT @nextk5
	or      AP_stat,LEFT
@nextk5:
	cmp     keyboard[_RTKEY],1             ; -> key
	jne     SHORT @nextk51
	or      AP_stat,RIGH

@nextk51:
	sub     FIRE_delay,1
	jnc     @@nocarry
	mov     FIRE_delay,0
@@nocarry:
	cmp     keyboard[_CTRL],1             ; Ctrl key
	jne     SHORT @nextk52
	cmp     FIRE_delay,0
	jnz     @nextk52
	or      AP_stat,FIRE
	mov     eax,weapon_no
	mov     ax,FIRE_delay_table[eax*2]
	mov     FIRE_delay,ax

@nextk52:
	cmp     key_edge[_SPACE],1             ; space key
	jne     SHORT @nextk53
	mov     key_edge[_SPACE],0             ; space key
	test    AP_stat,BUST
	jnz     SHORT @@off
	or      AP_stat,BUST
	jmp     SHORT @nextk53
@@off:
	and     AP_stat,NOT BUST

@nextk53:
	cmp     keyboard[_LSHIFT],1             ; L shift key
	jne     SHORT @@acoff
	or      AP_stat,ACCL
	jmp     SHORT @nextk6
@@acoff:
	and     AP_stat,NOT ACCL

@nextk54:
	cmp     keyboard[_RSHIFT],1             ; R shift key
	jne     SHORT @@acoffr
	or      AP_stat,ACCL
	jmp     SHORT @nextk6
@@acoffr:
	and     AP_stat,NOT ACCL

@nextk6:
	cmp     keyboard[_ALT],1               ; Alt key
	jne     SHORT @@shft
	or      AP_stat,SHFT
	jmp     SHORT @nextk7
@@shft:
	and     AP_stat,NOT SHFT

@nextk7:
@nextk71:
@nextk8:
	cmp     key_edge[_F11],1               ; F11 key
	jne     SHORT @nextk9
	mov     key_edge[_F11],0
	add     gammano,1
	cmp     gammano,7
	jbe     @@contigm
	mov     gammano,0
@@contigm:
	mov     ebx,gammano
	mov     edx,GAMMA[ebx * 4]
	mov     esi,offset PAL
	mov     edi,offset PALtmp
	call    gamma_correction

@nextk9:
	cmp     key_edge[_F5],1               ; F5 key
	jne     SHORT @nextk10
	mov     key_edge[_F5],0
	sub     floor_no,1
	cmp     floor_no,0
	jge     @@contifl
	mov     floor_no,2
@@contifl:
	mov     ebx,floor_no
	mov     eax,floor[ebx * 4]
	mov     draw_F,eax

@nextk10:
;       cmp     key_edge[_F6],1               ; F6 key
;       jne     SHORT @nextk11
;       mov     key_edge[_F6],0
;       add     disp1_no,1
;       cmp     disp1_no,2
;       jb      @@contidisp1
;       mov     disp1_no,0
;@@contidisp1:

@nextk11:
	cmp     key_edge[_PRTSCR],1           ; Print Screen key
	jne     @nextk111
	mov     key_edge[_PRTSCR],0

	push    ecx
	xor     ecx,ecx
@@rename:

	mov     edi,OFFSET pcxfilename
	mov     byte ptr[edi],'F'
	mov     byte ptr[edi+1],'M'
	mov     byte ptr[edi+2],'J'

	mov     eax,_mission_no
	cmp     eax,10
	jae     @@twoch

	mov     edx,OFFSET pcxfilename
	add     edx,3
	mov     ebx,10
	call    itoa_
	mov     edi,OFFSET pcxfilename
	add     edi,4
	jmp     @@decode
@@twoch:
	mov     edx,OFFSET pcxfilename
	add     edx,3
	mov     ebx,10
	call    itoa_
	mov     edi,OFFSET pcxfilename
	add     edi,5
@@decode:
	mov     eax,ecx

	cwd
	mov     bx,10
	div     bx
	mov     [file_number],dl
	cwd
	div     bx
	mov     [file_number+1],dl
	cwd
	div     bx
	mov     [file_number+2],dl

	mov     bl,[file_number+2]
	mov     [edi],bl
	add     byte ptr[edi],'0'
	inc     edi

	mov     bl,[file_number+1]
	mov     [edi],bl
	add     byte ptr[edi],'0'
	inc     edi

	mov     bl,[file_number]
	mov     [edi],bl
	add     byte ptr[edi],'0'
	inc     edi

	mov     byte ptr[edi],'.'
	mov     byte ptr[edi+1],'P'
	mov     byte ptr[edi+2],'C'
	mov     byte ptr[edi+3],'X'
	mov     byte ptr[edi+4],0

	push    edi
	mov     ah,3dh                  ; open file
	mov     al,0                    ; read only
	mov     edx,OFFSET pcxfilename
	int     21h
	pop     edi
	jc      @@noexit

	mov     bx,ax

	mov     ah,3eh                  ; close
	int     21h

	inc     ecx

	jmp     @@rename


@@noexit:
	call    decoding_PCX

	pop     ecx

@nextk111:
	cmp     keyboard[_MINUS],1      ; - key
	jne     SHORT @nextk12
	cmp     Rbound,319-64
	jbe     SHORT @nextk12
	sub     Rbound,4
	add     Lbound,4
	mov     erase_flag,2
@nextk12:
	cmp     keyboard[_EQUAL],1      ; + key
	jne     SHORT @nextk13
	cmp     Rbound,319
	jae     SHORT @nextk13
	add     Rbound,4
	sub     Lbound,4
@nextk13:

	cmp     keyboard[_1],1          ; 1 key
	jne     SHORT @nextn2
	mov     weapon_no,0
	mov     eax,_SLD_
	call    SoundFX_
@nextn2:
	cmp     keyboard[_2],1          ; 2 key
	jne     SHORT @nextn3
	mov     weapon_no,1
	mov     eax,_SLD_
	call    SoundFX_
@nextn3:
	cmp     keyboard[_3],1          ; 3 key
	jne     SHORT @nextn4
	mov     weapon_no,2
	mov     eax,_SGUNAC_
	call    SoundFX_
@nextn4:
	cmp     keyboard[_4],1          ; 4 key
	jne     SHORT @nextn5
	mov     weapon_no,3
	mov     eax,_SGUNAC_
	call    SoundFX_
@nextn5:
	cmp     keyboard[_5],1          ; 5 key
	jne     SHORT @nextn6
	mov     weapon_no,4
	mov     eax,_SLD_
	call    SoundFX_
@nextn6:
	cmp     keyboard[_6],1          ; 6 key
	jne     SHORT @nextn7
	mov     weapon_no,5
	mov     eax,_SLD_
	call    SoundFX_
@nextn7:
	cmp     keyboard[_7],1          ; 7 key
	jne     SHORT @nextn8
	mov     weapon_no,6
	mov     eax,_SLD_
	call    SoundFX_
@nextn8:
	cmp     keyboard[_8],1          ; 8 key
	jne     SHORT @nextn9
	mov     weapon_no,7
	mov     eax,_BAND_
	call    SoundFX_
@nextn9:
	cmp     keyboard[_9],1          ; 9 key
	jne     SHORT @nextn10
	mov     weapon_no,8
	mov     eax,_BAND_
	call    SoundFX_
@nextn10:


	cmp     keyboard[_ESC],1                 ; ESC key
	jne     SHORT @@quit

	cmp     frames,5
	jb      SHORT @@quit

	mov     _SuccessFlag,0
	mov     _FirstMission,2

	cmp     _replay,1
	jne     SHORT @@out_loop

	pop     eax
	jmp     @fine2

@@out_loop:
	pop     eax
	jmp     @fine                           ; out loop

@@quit:
	ret

key_input       ENDP

;-------------------------------------
;
;-------------------------------------
obj_table_clear PROC

	mov     edi,OFFSET obj_table
	xor     eax,eax
	mov     ecx,MAXOBJ*OBJWID
	cld
	rep     stosb

	ret
obj_table_clear ENDP

;-------------------------------------
;
;-------------------------------------
weapon_set      PROC

	mov     edi,OFFSET weapon_rounds   ; clear all weapon rounds
	mov     ecx,11                     ;
	xor     eax,eax                    ;
	cld                                ;
	rep     stosd                      ;

	mov     weapon_no,0

	xor     esi,esi

	mov     ecx,20
@@next:
	cmp     _HostW[esi*4].ArmsFlag,0
	jz      SHORT @@skip
	mov     edi,Armsno[esi*4]
	mov     eax,ArmsPower[esi*4]
	movzx   ebx,_HostW[esi*4].ArmsCnt
	imul    ebx,eax
	add     weapon_rounds[edi*4],ebx
	jmp     SHORT @@nnn
@@skip:
	cmp     esi,0
	je      SHORT @@gonext
	cmp     esi,2
	je      SHORT @@gonext
	cmp     esi,4
	je      SHORT @@gonext
	cmp     esi,6
	je      SHORT @@gonext
	cmp     esi,11
	je      SHORT @@gonext
	cmp     esi,13
	je      SHORT @@gonext
	jmp     SHORT @@nnn
@@gonext:
	inc     esi
	dec     ecx
@@nnn:
	inc     esi
	dec     ecx
	jnz     @@next

	mov     eax,buster
	imul    eax,10
	mov     buster,eax

@@out:
	ret

weapon_set      ENDP

;------------------------------------
;
;
;------------------------------------
weapon_and_money        PROC

	mov     esi,0
@@next1:
	mov     eax,weapon_rounds[esi*4]
	cdq
	mov     ebx,ArmsPower[esi * 8 + 4]
	div     ebx
	mov     _HostW[esi * 8 + 4].ArmsCnt,ax
	or      eax,eax
	jnz     @@noflag1
	mov     _HostW[esi * 8 + 4].ArmsFlag,ax    ;; if 0
@@noflag1:

	inc     esi
	cmp     esi,3
	jbe     @@next1

	mov     edi,8
@@next2:
	mov     eax,weapon_rounds[esi*4]
	mov     _HostW[edi * 4].ArmsCnt,ax
	or      eax,eax
	jnz     @@noflag2
	mov     _HostW[edi * 4].ArmsFlag,ax
@@noflag2:

	inc     esi
	inc     edi
	cmp     esi,6
	jbe     @@next2

	mov     eax,weapon_rounds[esi*4]          ; esi = 7
	mov     _HostW[12 * 4].ArmsCnt,ax
	or      eax,eax
	jnz     @@noflag3
	mov     _HostW[12 * 4].ArmsFlag,ax
@@noflag3:

	inc     esi

	mov     eax,weapon_rounds[esi*4]          ; esi = 8
	mov     _HostW[14 * 4].ArmsCnt,ax
	or      eax,eax
	jnz     @@noflag4
	mov     _HostW[14 * 4].ArmsFlag,ax
@@noflag4:

	ret

weapon_and_money        ENDP

;-----------------------------------------
;
;
;-----------------------------------------
mission_clear_check     PROC

	mov     esi,_mission_no
	dec     esi
	mov     ebx,mission_type[esi*4]

	cmp     mission_goal_ok,1
	je      @@timer_2
	cmp     mission_goal[ebx*4],0   ; enemy
	jz      @@ok1
	mov     al,kill_enemy_num
	cmp     al,kill_enemy[esi]
	jb      @@nextcheck1
@@ok1:
	mov     mission_goal_ok,1

@@timer_2:
	;-----------------------
	;    timer 2
	;-----------------------
	sub     time_counter2,1
	jnc     @@decok1
	mov     time_counter2,0
@@decok1:

	;-----------------------
	;    target
	;-----------------------
@@nextcheck1:
	cmp     mission_goal_ok,0
	jz      @@nextcheck3
	cmp     mission_goal_ok[1],1
	je      @@timer_3

	cmp     mission_goal[ebx*4+1],0 ; target
	jz      @@ok2
	cmp     mission_goal[ebx*4+1],1 ; only number check
	jne     @@timecheck2

@@numcheck1:
	pushad

	mov     esi,lamp1_spr_data[4]
	mov     eax,6
	mov     edx,63
	call    put_spr

	test    frames,3
	jz      @@skipmessage1
	mov     eax,100
	mov     edx,50
	mov     ebx,OFFSET TARGETS
	mov     cl,80
	call    put_string
@@skipmessage1:

	xor     ecx,ecx
@@nextobject:
	mov     ebp,obj_ptr[ecx*4]

	cmp     [ebp].stat,0
	jle     @@nnn
	cmp     [ebp].obj_no,800h
	jne     @@nnn

	mov     al,[ebp].theta
	add     al,128
	sub     al,d_th
	cmp     al,0
	jl      SHORT @@minus
@@plus:
	cmp     al,4
	jg      @@nnn
	jmp     SHORT @@done
@@minus:
	cmp     al,-4
	jl      @@nnn
@@done:
	jmp     @@blink1

@@nnn:
	inc     ecx
	cmp     ecx,MAXOBJ
	jb      @@nextobject

	jmp     SHORT @@blinkout1

@@blink1:
	mov     eax,frames
	and     eax,1
	mov     esi,lamp1_spr_data[eax*4]
	mov     eax,6
	mov     edx,63
	call    put_spr

@@blinkout1:

	popad

	mov     al,target_destruction_counter
	cmp     al,target_destruction
	jb      @@nextcheck2
	jmp     SHORT @@ok2

@@timecheck2:

	cmp     time_counter2,0
	jnz     @@nextcheck2
	jmp     @@numcheck1

@@ok2:
	mov     mission_goal_ok[1],1


@@timer_3:
	sub     time_counter3,1
	jnc     @@decok2
	mov     time_counter3,0
@@decok2:

	;-----------------------
	;    return position
	;-----------------------
@@nextcheck2:
	cmp     mission_goal_ok[1],0    ; targets
	jz      @@nextcheck3
	cmp     mission_goal[ebx*4+2],0 ; return point
	jz      @@ok3
	cmp     mission_goal[ebx*4+2],1 ; only position check
	jne     @@timecheck3

@@poscheck:
	pushad

	mov     esi,lamp2_spr_data[4]
	mov     eax,6
	mov     edx,63
	call    put_spr

	test    frames,7
	jz      @@skipmessage2
	mov     eax,100
	mov     edx,50
	mov     ebx,OFFSET RETURNS
	mov     cl,80
	call    put_string
@@skipmessage2:

	mov     al,return_theta
	add     al,128
	sub     al,d_th
	cmp     al,0
	jl      SHORT @@minus_
@@plus_:
	cmp     al,4
	jg      @@nnn_
	jmp     SHORT @@done_
@@minus_:
	cmp     al,-4
	jl      @@nnn_

@@done_:
	mov     eax,frames
	and     eax,1
	mov     esi,lamp2_spr_data[eax*4]
	mov     eax,6
	mov     edx,63
	call    put_spr

@@nnn_:
	popad

	mov     eax,eye_x_
	sub     eax,return_pos_x_
	sar     eax,16+3
	cmp     eax,0
	jge     @@plus1
	neg     eax
@@plus1:
	cmp     eax,2
	ja      @@nextcheck3

	mov     eax,eye_y_
	sub     eax,return_pos_y_
	sar     eax,16+3
	cmp     eax,0
	jge     @@plus2
	neg     eax
@@plus2:
	cmp     eax,2
	ja      @@nextcheck3

	cmp     eye_z,128+5
	jg      @@nextcheck3

	jmp     SHORT @@ok3

@@timecheck3:
	cmp     time_counter3,0
	jnz     SHORT @@nextcheck3
	jmp     @@poscheck

@@ok3:
	mov     mission_goal_ok[2],1

	;----------------------
	;
	;----------------------
@@nextcheck3:
	cmp     mission_goal_ok,0
	jz      @@out
	cmp     mission_goal_ok[1],0
	jz      @@out
	cmp     mission_goal_ok[2],0
	jz      @@out

	mov     _SuccessFlag,1
	call    turn2blue

@@out:

	ret

mission_clear_check     ENDP


;-----------------------------------
;
; Main
;
;-----------------------------------
PUBLIC  startASM_
startASM_       PROC

	pushad

	call    _InstallTimer

	call    MakeSqrTable
	call    init_obj_ptr

	cmp     _replay,0
	jz      @@noload
	mov     edi,OFFSET _RECORD_
	mov     esi,OFFSET filename03
	mov     ecx,RECLEN * 2 + 1 + 11 * 4
	call    load_file
@@noload:

;	mov     ax,13h
;	int     10h
	mov	eax,13h
	call	vid_mode_

	call    keyint_on                ; install key interrupt handler

	mov     eax,_BrightAdjust
	mov     gammano,eax

	CALL    VRAMCLS
	MOV     EDX,OFFSET filename04    ;  Mirinae LOGO
	CALL    FLI_FILE_RUN             ;

	;-----------
	; FMJ TITLE
	;-----------
;	call    SCROFF
;	mov     esi,OFFSET filename041
;	call    load_put_PCX
;	call    SCRON

;	mov     [_TimerTicks],0
@@repeat___:
;	cmp     key_hit,0
;	jnz     @@gogogo___
;	mov     eax,[_TimerTicks]
;	cmp     eax,70*3
;	jb      @@repeat___
@@gogogo___:

	call    _DeinstallTimer

	cmp     _SOUND,0
	jnz     @@oksound
	call    _InstallTimer
@@oksound:
	;--------------------------------------
	;
	;
	;--------------------------------------
@@restart:

	; Opening Viz
	;
	;
	mov     eax,OFFSET SONG_OPEN      ; play Opening music
	call    MODLoadModule_
	mov     _SONGptr_,eax
	call    PlayBGM_

	mov     eax,_EffectAdjust
	push    eax
	call    _MODSetSampleVolume
	pop     eax
	mov     eax,_MusicAdjust
	push    eax
	call    _MODSetMusicVolume
	pop     eax

;	mov     ax,13h
;	int     10h
	mov	eax,13h
	call	vid_mode_

	MOV     EDX,OFFSET filename051   ;
	CALL    FLI_FILE_RUN             ;

	cmp     key_hit,_ESC
	je      SHORT @@title

	MOV     EDX,OFFSET filename052
	CALL    FLI_FILE_RUN

	cmp     key_hit,_ESC
	je      SHORT @@title

	MOV     EDX,OFFSET filename053
	CALL    FLI_FILE_RUN

	cmp     key_hit,_ESC
	je      SHORT @@title

	MOV     EDX,OFFSET filename054
	CALL    FLI_FILE_RUN

@@title:
	;---------
	; TITLE
	;---------
	mov     esi,OFFSET filename06
	call    load_put_PCX

	mov     [_TimerTicks],0
@@repeat:
	cmp     key_hit,0
	jnz     @@gogogo
	mov     eax,[_TimerTicks]
	cmp     eax,70*2
	jb      @@repeat
@@gogogo:

;;      call    ending
	;------------------
	;  MAIN MENU
	;------------------
@mainmenu:
	call    _MODStopModule          ; stop Last music
	mov     eax,_SONGptr_           ;
	call    MODFreeModule_          ;

	mov     eax,OFFSET SONG_MENU      ; play menu music
	call    MODLoadModule_
	mov     _SONGptr_,eax
	call    PlayBGM_

	mov     eax,_EffectAdjust
	push    eax
	call    _MODSetSampleVolume
	pop     eax
	mov     eax,_MusicAdjust
	push    eax
	call    _MODSetMusicVolume
	pop     eax

	call    keyint_off

	cmp     _replay,1
	je      SHORT @@replay_

	call    FMJMenu_
	cmp     eax,1                   ; quit to DOS
	je      @fine2                  ;

@@replay_:

	call    keyint_on
	call    clear_key_buffer
	call    clear_key_buffer

	call    mode320X240

	call    weapon_set

	cmp     _replay,1
	je      SHORT @@norec__
	mov     eax,_MissionNumber
	inc     eax
	mov     _RECORD_,al
	mov     esi,OFFSET weapon_rounds
	mov     edi,OFFSET _RECORD_+1
	cld
	mov     ecx,11
	rep     movsd
	jmp     @@normal_play

@@norec__:

	xor     eax,eax
	mov     al,_RECORD_
	dec     al
	mov     _MissionNumber,eax
	mov     esi,OFFSET _RECORD_+1
	mov     edi,OFFSET weapon_rounds
	cld
	mov     ecx,11
	rep     movsd

@@normal_play:
	mov     eax,_MissionNumber
;;	mov     eax,4
	inc     eax
	cmp     eax,15
	ja      @ending
	mov     _mission_no,eax
	call    mission_load
	call    init_map
	call    make_COLLISION_MAP
	call    make_DIRECTION_MAP

	mov     eax,_ResolutionAdjust
	mov     floor_no,eax
	mov     eax,floor[eax * 4]
	mov     draw_F,eax

	mov     eax,_ScreenSizeAdjust
	mov     Rbound,eax
	add     Rbound,255
	mov     Lbound,128
	sub     Lbound,eax

	mov     eax,_BrightAdjust
	mov     gammano,eax

	mov     PAL,0
	mov     PAL+1,0
	mov     PAL+2,0
	mov     esi,offset PAL
	call    set_palette

	mov     ebx,gammano
	mov     edx,GAMMA[ebx * 4]
	mov     esi,offset PAL
	mov     edi,offset PALtmp
	call    gamma_correction

;;;;    call    password          ;  CD Version
;;;;    or      eax,eax           ;  no password checking
;;;;    jnz     @fine2            ;

	mov     eax,7
	call    make_DARKER_TABLE

	mov     PageOffset,0
	mov     esi,OFFSET panel_spr_data
	mov     eax,0
	mov     edx,0
	call    put_spr

	mov     esi,OFFSET mfd1_spr_data
	mov     eax,11
	mov     edx,79
	call    put_spr

	mov     esi,OFFSET mfd2_spr_data
	mov     eax,10
	mov     edx,130
	call    put_spr

	mov     esi,OFFSET mfd3_spr_data
	mov     eax,13
	mov     edx,189
	call    put_spr

	mov     PageOffset,4B00h

	mov     esi,OFFSET panel_spr_data
	mov     eax,0
	mov     edx,0
	call    put_spr

	mov     esi,OFFSET mfd1_spr_data
	mov     eax,11
	mov     edx,79
	call    put_spr

	mov     esi,OFFSET mfd2_spr_data
	mov     eax,10
	mov     edx,130
	call    put_spr

	mov     esi,OFFSET mfd3_spr_data
	mov     eax,13
	mov     edx,189
	call    put_spr

	;;---------------------------------------
	;;
	;;   mission initial
	;;
	;;---------------------------------------
	mov     eye_z,128                     ;view hight
	mov     eye_zd,128                     ;

	mov     eye_th,0                       ;observer's viewing direction
	mov     d_th,64 * 3                  ;observer's moving direction
	mov     dif,0                       ;observer's moving speed
	mov     AP_energy,300
	mov     eax,shiled
	add     AP_energy,eax

	mov     kill_enemy_num,0
	mov     target_destruction,0
	mov     target_destruction_counter,0

	mov     time_counter1,2000
	mov     time_counter2,2000
	mov     time_counter3,2000

	mov     mission_goal_ok,0
	mov     mission_goal_ok[1],0
	mov     mission_goal_ok[2],0

	mov     out_delay,0
	mov     out_delay_flag,0

	call    obj_table_clear
	call    crea_enemy

	call    _MODStopModule
	mov     eax,_SONGptr_
	call    MODFreeModule_

	mov     eax,_mission_no
	dec     eax
	mov     eax,SONG[eax*4]
	call    MODLoadModule_
	mov     _SONGptr_,eax
	call    PlayBGM_
	mov     eax,_EffectAdjust
	push    eax
	call    _MODSetSampleVolume
	pop     eax
	mov     eax,_MusicAdjust
	push    eax
	call    _MODSetMusicVolume
	pop     eax

	mov     ah,0
	int     1Ah
	mov     word ptr[Tstart+2],cx
	mov     word ptr[Tstart],dx

	mov     frames,0

	cli
	mov     [_TimerTicks],0
	sti
@frame:
	inc     frames
	call    key_input

	;---------------------------------------------------
	cmp     _replay,1
	je      SHORT @@norec
	mov     eax,frames
	cmp     eax,RECLEN-1
	ja      SHORT @@norec
	mov     bl,AP_stat
	mov     RECORDING[eax*2],bl
	mov     ebx,weapon_no
	mov     RECORDING[eax*2+1],bl
@@norec:

	cmp     _replay,0
	jz      SHORT @@noply
	mov     eax,frames
	cmp     eax,RECLEN-1
	ja      SHORT @@noply
	mov     bl,RECORDING[eax*2]
	mov     AP_stat,bl
	xor     ebx,ebx
	mov     bl,RECORDING[eax*2+1]
	mov     weapon_no,ebx
@@noply:
	;---------------------------------------
	mov     al,AP_stat
	and     al,3
	cmp     al,FORW
	jne     SHORT @@test1
	mov     al,AP_stat
	and     al,BUST
	jnz     SHORT @@bspeed
	mov     dif,DSPEED
	jmp     SHORT @@test1
@@bspeed:
	cmp     buster,0
	jle     SHORT @@nospd
	mov     dif,BSPEED
	jmp     SHORT @@test1
@@nospd:
	mov     dif,DSPEED

@@test1:
	mov     al,AP_stat
	and     al,3
	cmp     al,BACK
	jne     SHORT @@test2
;       mov     al,AP_stat
;       and     al,BUST
;       jnz     SHORT @@bspeed2
	mov     dif,-DSPEED
;       jmp     SHORT @@test2
@@bspeed2:
;       mov     dif,-BSPEED

@@test2:
	test    AP_stat,SHFT
	jnz     @@test4
	mov     al,AP_stat
	and     al,RIGH
	cmp     al,LEFT
	jne     SHORT @@test3
	test    AP_stat,ACCL
	jnz     SHORT @@ddd1
	add     d_th,254
	jmp     SHORT @@test3
@@ddd1:
	add     d_th,252

@@test3:
	mov     al,AP_stat
	and     al,RIGH
	cmp     al,RIGH
	jne     SHORT @@test4
	test    AP_stat,ACCL
	jnz     SHORT @@ddd2
	add     d_th,2
	jmp     SHORT @@test4
@@ddd2:
	add     d_th,4

@@test4:

	mov     al,d_th
	mov     bl,0
	sub     bl,al
	add     bl,64 *3
	mov     eye_th,bl

	mov     map_mask,11h

	call    AP_move
	call    AP_ani

	;--------------------
	; main
	;--------------------
	call    obj_course
	call    obj_move
	call    edge_correction
	call    depth_sort
	call    AP_fire

	call    wait_vrt
	call    erase
	call    [draw_F]
	call    sprites
	call    draw_floor2

	call    mission_clear_check

	cmp	key_hit,_F
	jne	@@nogod
	cmp	chit_god,1
	jne	@@yesgod
	mov	chit_god,0
	jmp	@@nogod
@@yesgod:
	mov	chit_god,1
	jmp	@@disp
@@nogod:

@@disp:
	; display1
	mov     ebx,disp1_no
	mov     eax,disp1[ebx * 4]
	mov     draw_DISP1,eax
	call    [draw_DISP1]
	mov     disp1_no,0
	; compas
	mov     esi,OFFSET compas_spr_data
	mov     eax,16                  ; (16,65)
	mov     edx,65                  ;
	call    draw_compas
	; MFD1
	mov     esi,OFFSET mfd1_spr_data ;(11,79)
	mov     eax,11
	mov     edx,79
	call    put_spr
	; MFD2
	mov     esi,OFFSET mfd2_spr_data ;(10,130)
	mov     eax,10
	mov     edx,130
	call    put_spr
	;;
	cmp     AP_energy,50
	ja      @@nodanger
	mov     eax,11 + 3
	mov     edx,79 + 10
	mov     ebx,OFFSET DANGER
	mov     ecx,frames
	and     ecx,4
	add     cl,88
	call    put_string
@@nodanger:

	mov     eax,10+2
	mov     edx,130+1+6
	mov     ebx,OFFSET ROUNDS
	mov     cl,9
	call    put_string

	mov     eax,10+2
	mov     edx,130+1+6*4
	mov     ebx,OFFSET BU
	mov     cl,9
	call    put_string

	mov     eax,10+2
	mov     edx,130+1+6*5
	mov     ebx,OFFSET PW
	mov     cl,9
	call    put_string

	mov     eax,weapon_no
	mov     ebx,WP_name[eax*4]
	mov     eax,10+1
	mov     edx,130+1
	mov     cl,9
	call    put_string

	mov     eax,weapon_no
	mov     eax,weapon_rounds[eax*4]
	mov     edx,OFFSET STRING
	mov     ebx,10
	call    itoa_
	mov     eax,10+1+2*6
	mov     edx,130+1+6
	mov     ebx,OFFSET STRING
	mov     cl,9
	call    put_string

	mov     eax,buster
	mov     edx,OFFSET STRING
	mov     ebx,10
	call    itoa_
	mov     eax,10+1+3*6
	mov     edx,130+1+6*4
	mov     ebx,OFFSET STRING
	mov     cl,9
	call    put_string

	mov     eax,AP_energy
	mov     edx,OFFSET STRING
	mov     ebx,10
	call    itoa_
	mov     eax,10+1+3*6
	mov     edx,130+1+6*5
	mov     ebx,OFFSET STRING
	mov     cl,9
	call    put_string

	cmp     _replay,0
	jz      SHORT @@norestart
	cmp     frames,RECLEN
	jbe     @@norestart

	call    _MODStopModule          ; stop Last music
	mov     eax,_SONGptr_           ;
	call    MODFreeModule_          ;
	jmp     @@restart

@@norestart:

	mov     dif,0

	cmp     AP_energy,0
	jg      @@success

	cmp     out_delay_flag,1
	je      @@nodelayset
	call    turn2red

	mov     eax,eye_x_
	mov     flm_x_,eax
	mov     eax,eye_y_
	mov     flm_y_,eax
	mov     eax,2
	call    crea_flm

	mov     eax,_EXPLO2_
	call    SoundFX_

	mov     out_delay,12
	mov     out_delay_flag,1
@@nodelayset:

	sub     out_delay,1
	jnc     @@success
	mov     out_delay,0
	mov     _SuccessFlag,-1

	jmp     @fine

@@success:
	cmp     _SuccessFlag,1
	jne     SHORT @@timechk

	mov     eax,_mission_no
	dec     eax
	movzx   eax,BONUS[eax * 2]
	add     _FMJTotalScore,eax
	movzx   eax,enemy_score
	add     _FMJTotalScore,eax

	call    mission_accomplished

	jmp     @fine

@@timechk:
	mov     eax,[_TimerTicks]
	cmp     eax,4
	ja      SHORT @@goodtime
	jmp     SHORT @@timechk
@@goodtime:
	mov     [_TimerTicks],0

	call    showp

	jmp     @frame

	;-------------------
@fine:  ;
	;
	;-------------------
	mov     ah,0
	int     1Ah
	mov     word ptr[Tend+2],cx
	mov     word ptr[Tend],dx

	mov     eax,floor_no
	mov     _ResolutionAdjust,eax

	mov     eax,Rbound
	sub     eax,255
	mov     _ScreenSizeAdjust,eax

	mov     eax,gammano
	mov     _BrightAdjust,eax

	;_EffectAdjust
	;_MusicAdjust

	cmp     _SuccessFlag,1      ;; Mission completed
	jne     @mainmenu          ;;

	call    weapon_and_money

	cmp     _mission_no,15
	jb      @mainmenu

@ending:
	call    ending

	call    _MODStopModule          ; stop Last music
	mov     eax,_SONGptr_           ;
	call    MODFreeModule_          ;

	mov     _FirstMission,0
	mov     _SuccessFlag,-1

	jmp     @@restart

	;-------------------
@fine2: ;  Quit to DOS  ( from main menu )
	;-------------------
;       mov     ax,13h
;       int     10h

;       call    SCROFF
;       mov     esi,OFFSET filename071
;       call    load_put_PCX
;       call    SCRON
;       wait_key&time 0,4
;       mov     esi,OFFSET filename072
;       call    load_put_PCX
;       wait_key&time 0,4
;       mov     esi,OFFSET filename073
;       call    load_put_PCX
;       wait_key&time 0,4
;       mov     esi,OFFSET filename074
;       call    load_put_PCX
;       wait_key&time 0,4
;       mov     esi,OFFSET filename075
;       call    load_put_PCX
;       wait_key&time 0,4
;       mov     esi,OFFSET filename076
;       call    load_put_PCX

	call    keyint_off

;	mov     ax,03h
;	int     10h
	mov	eax,03h
	call	vid_mode_

	cmp     _replay,1
	je      SHORT @@nosave
	mov     esi,OFFSET _RECORD_
	mov     edi,OFFSET filename03
	mov     ecx,RECLEN * 2 + 1 + 11 * 4
	call    save_file
@@nosave:

	call    _MODStopModule
	mov     eax,_SONGptr_
	call    MODFreeModule_

	cmp     _SOUND,0
	jnz     @@oksound_
	call    _DeinstallTimer
@@oksound_:

	popad

	ret

startASM_       ENDP

;-------------------------------------
;
;-------------------------------------
mission_accomplished    PROC

	mov     eax,100
	mov     edx,100
	mov     ebx,OFFSET MISSION_ACCOM
	mov     cl,80
	call    put_string

	mov     eax,100
	mov     edx,110
	mov     ebx,OFFSET EN_KILLED
	mov     cl,80
	call    put_string

	mov     eax,100
	mov     edx,120
	mov     ebx,OFFSET MISSION_BONUS
	mov     cl,80
	call    put_string

	mov     eax,100
	mov     edx,130
	mov     ebx,OFFSET TOTAL_GOLDS
	mov     cl,80
	call    put_string

	mov     eax,100
	mov     edx,150
	mov     ebx,OFFSET PRESS
	mov     cl,80
	call    put_string

	movzx   eax,kill_enemy_num
	mov     edx,OFFSET STRING
	mov     ebx,10
	call    itoa_
	mov     eax,200
	mov     edx,110
	mov     ebx,OFFSET STRING
	mov     cl,80
	call    put_string

	mov     eax,230
	mov     edx,110
	mov     ebx,OFFSET GOLDS
	mov     cl,80
	call    put_string

	movzx   eax,enemy_score
	mov     edx,OFFSET STRING
	mov     ebx,10
	call    itoa_
	mov     eax,270
	mov     edx,110
	mov     ebx,OFFSET STRING
	mov     cl,80
	call    put_string

	mov     eax,_mission_no
	movzx   eax,BONUS[eax * 2]
	mov     edx,OFFSET STRING
	mov     ebx,10
	call    itoa_
	mov     eax,200
	mov     edx,120
	mov     ebx,OFFSET STRING
	mov     cl,80
	call    put_string

	mov     eax,_FMJTotalScore
	mov     edx,OFFSET STRING
	mov     ebx,10
	call    itoa_
	mov     eax,200
	mov     edx,130
	mov     ebx,OFFSET STRING
	mov     cl,80
	call    put_string

	call    showp
@@rol:
	cmp     key_hit,_ENTER
	jne     @@rol

	ret

mission_accomplished    ENDP

;-------------------------------------
;
;-------------------------------------
lost_in_mission PROC

	mov     eax,100
	mov     edx,100
	mov     ebx,OFFSET MISSION_ACCOM
	mov     cl,80
	call    put_string

	mov     eax,100
	mov     edx,110
	mov     ebx,OFFSET EN_KILLED
	mov     cl,80
	call    put_string

	mov     eax,100
	mov     edx,120
	mov     ebx,OFFSET MISSION_BONUS
	mov     cl,80
	call    put_string

	mov     eax,100
	mov     edx,130
	mov     ebx,OFFSET TOTAL_GOLDS
	mov     cl,80
	call    put_string

	movzx   eax,kill_enemy_num
	mov     edx,OFFSET STRING
	mov     ebx,10
	call    itoa_
	mov     eax,200
	mov     edx,110
	mov     ebx,OFFSET STRING
	mov     cl,80
	call    put_string

	mov     eax,230
	mov     edx,110
	mov     ebx,OFFSET GOLDS
	mov     cl,80
	call    put_string

	movzx   eax,enemy_score
	mov     edx,OFFSET STRING
	mov     ebx,10
	call    itoa_
	mov     eax,270
	mov     edx,110
	mov     ebx,OFFSET STRING
	mov     cl,80
	call    put_string

	mov     eax,_mission_no
	movzx   eax,BONUS[eax * 2]
	mov     edx,OFFSET STRING
	mov     ebx,10
	call    itoa_
	mov     eax,200
	mov     edx,120
	mov     ebx,OFFSET STRING
	mov     cl,80
	call    put_string

	mov     eax,_FMJTotalScore
	mov     edx,OFFSET STRING
	mov     ebx,10
	call    itoa_
	mov     eax,200
	mov     edx,130
	mov     ebx,OFFSET STRING
	mov     cl,80
	call    put_string

	call    showp
@@rol:
	cmp     key_hit,_ENTER
	jne     @@rol

	ret

lost_in_mission ENDP

;-------------------------------------
;  PASSWORD CHECK
;-------------------------------------
password        PROC

	push    ebx
	push    ecx
	push    edx
	push    esi
	push    edi

	cmp     _MissionNumber,3
	jne     @@passOK

	mov     eax,_TimerTicks
	mov     seed,eax

	mov     esi,OFFSET filename09
	mov     edi,OFFSET pcx_buffer
	mov     ecx,16320
	call    load_file

	mov     passtry,3

@@reinput:

	mov     eax,30
	call    rand
	movzx   eax,ax
	mov     passon,eax               ; password table index

	mov     eax,40
	call    rand
	movzx   eax,ax
	mov     passinput,eax

	mov     eax,40
	call    rand
	movzx   eax,ax
	mov     passinput+4,eax

	mov     eax,40
	call    rand
	movzx   eax,ax
	mov     passinput+8,eax

	mov     passinputX,0


	mov     frames,0
@@nextf:
	call    wait_vrt

	inc     frames

	call    clean

	cmp     key_edge[_ENTER],1
	jne     @@key0
	mov     key_edge[_ENTER],0
	jmp     @@yess

@@key0:
	cmp     key_edge[_UPKEY],1
	jne     @@key1
	mov     key_edge[_UPKEY],0
	mov     eax,passinputX
	sub     passinput[eax*4],1
	jnc     @@key1
	mov     passinput[eax*4],39
@@key1:
	cmp     key_edge[_DNKEY],1
	jne     @@key2
	mov     key_edge[_DNKEY],0
	mov     eax,passinputX
	add     passinput[eax*4],1
	cmp     passinput[eax*4],39
	jle     @@key2
	mov     passinput[eax*4],0
@@key2:
	cmp     key_edge[_LTKEY],1
	jne     @@key3
	mov     key_edge[_LTKEY],0
	sub     passinputX,1
	jmp     @@key4
@@key3:
	cmp     key_edge[_RTKEY],1
	jne     @@key4
	mov     key_edge[_RTKEY],0
	add     passinputX,1
@@key4:

	cmp     passinputX,0
	jge     @@skip1
	mov     passinputX,0
@@skip1:
	cmp     passinputX,2
	jle     @@skip2
	mov     passinputX,2
@@skip2:

	mov     eax,passon
	cdq
	mov     ebx,3
	div     ebx
	push    edx

	mov     eax,eax
	inc     eax
	mov     edx,OFFSET STRING
	mov     ebx,10
	call    itoa_
	mov     eax,103
	mov     edx,57
	mov     ebx,OFFSET STRING
	mov     cl,80
	call    put_string

	pop     eax
	inc     eax
	mov     edx,OFFSET STRING
	mov     ebx,10
	call    itoa_
	mov     eax,150
	mov     edx,40
	mov     ebx,OFFSET STRING
	mov     cl,80
	call    put_string

	mov     eax,passinput
	mov     esi,dword ptr pcx_buffer[eax*4]
	add     esi,OFFSET pcx_buffer
	mov     eax,118
	mov     edx,50
	call    put_spr

;       mov     eax,passinput
;       mov     edx,OFFSET STRING
;       mov     ebx,10
;       call    itoa_
;       mov     eax,118
;       mov     edx,50
;       mov     ebx,OFFSET STRING
;       mov     cl,80
;       call    put_string

	mov     eax,passinput+4
	mov     esi,dword ptr pcx_buffer[eax*4]
	add     esi,OFFSET pcx_buffer
	mov     eax,118+25
	mov     edx,50
	call    put_spr

;       mov     eax,passinput+4
;       mov     edx,OFFSET STRING
;       mov     ebx,10
;       call    itoa_
;       mov     eax,118+25
;       mov     edx,50
;       mov     ebx,OFFSET STRING
;       mov     cl,80
;       call    put_string

	mov     eax,passinput+8
	mov     esi,dword ptr pcx_buffer[eax*4]
	add     esi,OFFSET pcx_buffer
	mov     eax,118+25*2
	mov     edx,50
	call    put_spr

;       mov     eax,passinput+8
;       mov     edx,OFFSET STRING
;       mov     ebx,10
;       call    itoa_
;       mov     eax,118+25*2
;       mov     edx,50
;       mov     ebx,OFFSET STRING
;       mov     cl,80
;       call    put_string

	test    frames,1
	jz      @@skipcurse
	mov     esi,OFFSET curse_spr_data
	mov     eax,passinputX
	mov     edx,25
	mul     edx
	add     eax,116
	mov     edx,48
	call    put_spr
@@skipcurse:

	call    showp

	jmp     @@nextf

@@yess:
	mov     eax,passon

	mov     bl,byte ptr[passinput]
	cmp     byte ptr[passtable][eax][eax*2],bl
	jne     SHORT @@trial

	mov     bl,byte ptr[passinput+4]
	cmp     byte ptr[passtable][eax][eax*2+1],bl
	jne     SHORT @@trial

	mov     bl,byte ptr[passinput+8]
	cmp     byte ptr[passtable][eax][eax*2+2],bl
	jne     SHORT @@trial

	jmp     @@passOK

@@trial:
	mov     eax,_PING_
	call    SoundFX_
	dec     passtry
	jnz     @@reinput

	mov     eax,-1
	mov     pass_ok,0
	jmp     SHORT @@quit

@@passOK:
	mov     pass_ok,1
	xor     eax,eax

@@quit:
	pop     edi
	pop     esi
	pop     edx
	pop     ecx
	pop     ebx

	ret

password        ENDP

;---------------------------
;
;---------------------------
ending  PROC

	call    _MODStopModule          ; stop Last music
	mov     eax,_SONGptr_           ;
	call    MODFreeModule_          ;

	mov     eax,OFFSET SONG_END    ; play ending music
	call    MODLoadModule_
	mov     _SONGptr_,eax
	call    PlayBGM_

	mov     eax,_EffectAdjust
	push    eax
	call    _MODSetSampleVolume
	pop     eax
	mov     eax,_MusicAdjust
	push    eax
	call    _MODSetMusicVolume
	pop     eax

	call    xmode                  ; 320 * 200 xmode
				       ;
	mov     StartOffset,0          ;
	mov     PageOffset,4000h

	mov     Lbound,0
	mov     Rbound,319
	mov     Ubound,0
	mov     Dbound,199

;       call    SCROFF
	mov     esi,OFFSET filename07
	call    load_put_PCXX
;       call    SCRON

	mov     esi,OFFSET filename08
	mov     edi,OFFSET pcx_buffer
	mov     ecx,30495
	call    load_file

	mov     ebp,220
	mov     [_TimerTicks],0
@@nextf:
	call    wait_vrt
	call    put_pic

	mov     ecx,15
@@nnn:
	push    ecx

	mov     eax,15
	sub     eax,ecx
	mov     esi,dword ptr pcx_buffer[eax*4]
	add     esi,OFFSET pcx_buffer
	shl     eax,5
	mov     edx,eax
	add     edx,ebp
	mov     eax,160
	xor     ecx,ecx
	mov     ebx,128
	call    put_sprSC

	pop     ecx

	dec     ecx
	jnz     @@nnn

	cmp     key_hit,_ESC
	je      SHORT @@out

	sub     ebp,1
	cmp     ebp,-500
	jl      SHORT @@out

@@timechk:
	mov     eax,[_TimerTicks]
	cmp     eax,4
	ja      SHORT @@goodtime
	jmp     SHORT @@timechk
@@goodtime:
	mov     [_TimerTicks],0

	call    show_p

	jmp     @@nextf
@@out:
	;  return to 320 * 240
	;
	mov     StartOffset,0
	mov     PageOffset,4B00h

	mov     Lbound,64
	mov     Rbound,319
	mov     Ubound,0
	mov     Dbound,239

	ret

ending  ENDP

;--------------------------------------
; ax: random number range ( 0 ... N-1 )
;--------------------------------------
rand    PROC

	push    edx
	push    ebx

	mov     bx,ax

	mov     eax,1107030247
	mul     seed
	add     eax,97177
	mov     seed,eax
	shr     eax,15
	xor     dx,dx
	div     bx
	mov     ax,dx

	pop     ebx
	pop     edx

	ret

rand    ENDP

;---------------------------
;  RED OUT
;---------------------------
turn2red        PROC

	mov     esi,offset PALtmp
	mov     edi,offset PALtmp2

	xor     eax,eax
	cld
	mov     ecx,768/4
	rep     stosd

	mov     edi,offset PALtmp2

	xor     eax,eax                 ; RED
	add     esi,eax
	add     edi,eax
	mov     ecx,768/3
@@next:
	mov     al,[esi]
	mov     [edi],al
	add     esi,3
	add     edi,3

	loop    @@next

	mov     esi,offset PALtmp2
	call    set_palette

	ret

turn2red        ENDP

;---------------------------
;  blue OUT
;---------------------------
turn2blue       PROC

	mov     esi,offset PALtmp
	mov     edi,offset PALtmp2

	xor     eax,eax
	cld
	mov     ecx,768/4
	rep     stosd

	mov     edi,offset PALtmp2

	mov     eax,2                   ; BLUE
	add     esi,eax
	add     edi,eax
	mov     ecx,768/3
@@next:
	mov     al,[esi]
	mov     [edi],al
	add     esi,3
	add     edi,3

	loop    @@next

	mov     esi,offset PALtmp2
	call    set_palette

	ret

turn2blue       ENDP

_TEXT   ENDS

	END
