/*****************************************************
  FULL METAL JACKET start up C code
******************************************************/
#include <stdlib.h>
#include <stdio.h>
#include <conio.h>
#include <malloc.h>
#include <io.h>
#include <fcntl.h>
#include <i86.h>
#include <dos.h>

#include "modplay.h"

#define MAXFX 20

struct config_data {
		short sound_card;
		short addr;
		short IRQ;
		short DMA;
		char  dummy1;
		short dummy2;
}config = {0,0x220,5,1,0,0};

static struct rminfo {
    long EDI;
    long ESI;
    long EBP;
    long reserved_by_system;
    long EBX;
    long EDX;
    long ECX;
    long EAX;
    short flags;
    short ES,DS,FS,GS,IP,CS,SP,SS;
} RMI;

extern  int mission_no;
extern  int replay;
extern  int startASM(void);
extern  int FindSqrt(int);

extern  int ResolutionAdjust;               // 해상도 조절 변수.(외부에서 사용함)
extern  int ScreenSizeAdjust;               // 화면 크기 조절 변수.(외부에서 사용함)
extern  int BrightAdjust;                   // 밝기 조절 변수.(외부에서 사용함)
extern  int EffectAdjust;                   // 효과음 조절 변수.(외부에서 사용함)
extern  int MusicAdjust;                    // 음악 조절 변수.(외부에서 사용함)

extern	void vid_mode(int);

unsigned curdisk, CD_disk, drives;
void SoundFX(unsigned number);
extern  Module * SONGptr_;

int SOUND;
int channel = 4;

unsigned char *wavfn[MAXFX] ={"fmj01.wav",   // 0  _VALCAN_
			  "fmj02.wav",       // 1  _DING_
			  "fmj03.wav",       // 2  _EXPLO0_
			  "click3.wav",      // 3  _ARROW_
			  "click10.wav",     // 4  _ESC_
			  "sfx01.wav",       // 5  _ENTER_
			  "siren1.wav",      // 6  _SIREN_
			  "band.wav",        // 7  _BAND_
			  "sld.wav",         // 8  _SLD_
			  "gundry.wav",      // 9  _GUNDRY_
			  "explo1.wav",      // 10 _EXPLO1_
			  "explo2.wav",      // 11  _EXPLO2_
			  "sgunsh.wav",      // 12  _SGUNSH_
			  "sgunac.wav",      // 13  _SGUNAC_
			  "cannon.wav",      // 14  _CANNON_
			  "fthrow.wav",      // 15  _FTHROW_
			  "mchgun.wav",      // 16  _MGUN_
			  "drop.wav",        // 17  _DROP_
			  "buston.wav",      // 18  _BUSTON_
			  "bust.wav"};       // 19  _BUST_

Sample *FX[MAXFX];
word Port;
byte IRQ,DRQ;

void Intro(void)
{
	vid_mode(0x03);

	printf("FULL METAL JACKET Version 1.02e\n");
	printf("Action Simulation Game.\n");
	printf("Copyright (c) 1995, 1996 MIRINAE Software, Inc.\n\n");
}

void LoadFX(void)
{
    int i;

    for(i = 0 ; i < MAXFX ; i++){
	if ( (FX[i] = MODLoadSample(wavfn[i])) != NULL ) {
	} else printf("\nWAVE file loading Error\n!");
    }
}

void LoadCFG(void)
{
	FILE * fp;
	int buffer[5];

	fp = fopen("fmj.cfg","rb");

	if(fp == NULL)
	{
		ResolutionAdjust = 0;
		ScreenSizeAdjust = 0;
		BrightAdjust = 0;
		EffectAdjust = 0;
		MusicAdjust = 0;
		return;
	}

	fread(buffer,4,5,fp);

	ResolutionAdjust = buffer[0];
	ScreenSizeAdjust = buffer[1];
	BrightAdjust = buffer[2];
	EffectAdjust = buffer[3];
	MusicAdjust = buffer[4];

	fclose(fp);

}

void LoadConfig(void)
{
	FILE * fp;

	fp = fopen("config.cfg","rb");

	if(fp == NULL)
	{
		config.sound_card = 1;
		return;
	}

	fread(&config,sizeof(config),1,fp);

	fclose(fp);

}

void SaveCFG(void)
{
	FILE * fp;
	int buffer[5];

	fp = fopen("fmj.cfg","wb");

	buffer[0] = ResolutionAdjust;
	buffer[1] = ScreenSizeAdjust;
	buffer[2] = BrightAdjust;
	buffer[3] = EffectAdjust;
	buffer[4] = MusicAdjust;

	fwrite(buffer,4,5,fp);

	fclose(fp);

}

void SoundFX(unsigned number)
{
	if(SOUND)
	{
		MODPlaySample(channel,FX[number]);
		channel++;
		if( channel >= 8 ) channel = 4;
	}
}

PlayBGM(Module *Modulefile)
{
	if(SOUND)
	MODPlayModule(Modulefile,8,11111,Port,IRQ,DRQ,PM_TIMER);
}

int check_CD(void)
{
    union REGS regs;
    struct SREGS sregs;
    int interrupt_no=0x31;
    short selector;
    short segment;
    char *str;

    /* DPMI call 100h allocates DOS memory */
    memset(&sregs,0,sizeof(sregs));
    regs.w.ax=0x0100;
    regs.w.bx=0x0003;    // 16 * 3 = 48 bytes
    int386x( interrupt_no, &regs, &regs, &sregs);
    segment=regs.w.ax;
    selector=regs.w.dx;

    /* make linear address */
    str = (char *)(((long)segment) << 4);

    /* Set up real-mode call structure */
    memset(&RMI,0,sizeof(RMI));
    RMI.EAX=0x00001500; /* CD-ROM installation check ax=1500 */
    RMI.EBX=0;

    /* Use DMPI call 300h to issue the DOS interrupt */
    regs.w.ax = 0x0300;
    regs.h.bl = 0x2F;
    regs.h.bh = 0;
    regs.w.cx = 0;
    sregs.es = FP_SEG(&RMI);
    regs.x.edi = FP_OFF(&RMI);
    int386x( interrupt_no, &regs, &regs, &sregs );

    if ( regs.w.cflag ) printf("CD-ROM function call failed\n");

    if ( !RMI.EBX ) printf("CD-ROM drive not installed\n");
    else printf("CD-ROM drive is %c:\n", 'A'+ (unsigned char)RMI.ECX );

    CD_disk = RMI.ECX;

    /* Set up real-mode call structure */
    memset(&RMI,0,sizeof(RMI));
    RMI.EAX=0x00001502; /* call service ax=1502 */
    RMI.ES=segment;     /* put DOS seg:off into ES:BX*/
    RMI.EBX=0;          /* DOS ignores EBX high word */
    RMI.ECX=CD_disk;    /* drive number */

    /* Use DMPI call 300h to issue the DOS interrupt */
    regs.w.ax = 0x0300;
    regs.h.bl = 0x2F;
    regs.h.bh = 0;
    regs.w.cx = 0;
    sregs.es = FP_SEG(&RMI);
    regs.x.edi = FP_OFF(&RMI);
    int386x( interrupt_no, &regs, &regs, &sregs );
    if ( regs.w.cflag ) printf("CD-ROM function call failed\n");
    if ( RMI.flags & 0x01 ) printf("not CD-ROM\n");
//    printf("   Copyright:");
//    printf(str); printf("\n");
    if ( strcmp(str,"FMJ102C") != 0 ) return -1;

    return 0;

}

main(int argc, char *argv[])
{
    Module *Song;
    int i;

    if( argc > 1 )
    {
	if( argv[1][0] == 'r' || argv[1][0] == 'R')
		replay = 1;
	else    replay = 0;

    }
    else {

	replay = 0;
    }

    Intro();

    LoadCFG();

    Loadconfig();
/*
    if ( check_CD() != 0 ) printf("F.M.J. CD found\n");
    else {
	printf("F.M.J. CD not found\n");
	printf("Insert F.M.J. CD in the CD-ROM drive!!\n");
	exit(1);
    }
*/
    switch(config.sound_card) {

	case 0 :
		SOUND = 0;
		printf("NO Sound!\n");
		delay(2000);
//		vid_mode(0x03);
//		system("logo.exe");

		startASM();
		break;

	case 1 :
		Port = (word)config.addr;
		IRQ = (byte)config.IRQ;
		DRQ = (byte)config.DMA;
		SOUND = 1;
		LoadFX();
		printf("Sound Blaster set\n");
		printf("Addr:%03x\n",Port);
		printf("IRQ:%d\n",IRQ);
		printf("DMA:%d\n",DRQ);
		delay(2000);
//		vid_mode(0x03);
//		system("logo.exe");

		startASM();
		break;

	case 2 :
		if (MODDetectCard(&Port,&IRQ,&DRQ))
		{
			SOUND = 0;
			printf("Sound Blaster not detected.\n");
			printf("NO Sound!\n");
			delay(2000);
//			vid_mode(0x03);
//			system("logo.exe");

			startASM();
		}
		else {
			SOUND = 1;
			LoadFX();
			printf("Sound Blaster detected\n");
			printf("Addr:%03x\n",Port);
			printf("IRQ:%d\n",IRQ);
			printf("DMA:%d\n",DRQ);
			delay(2000);
//			vid_mode(0x03);
//			system("logo.exe");

			startASM();
		}
		break;

    }

    SaveCFG();
    printf("\nThanks for playing FULL METAL JACKET Version 1.02e \n");

}

