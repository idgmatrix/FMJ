/*  modplay.h - Tiny MOD Player V2.11 for Watcom C/C++ and DOS/4GW

    Module player for Sound Blaster and compatibles header file.

    Copyright 1993,94 Carlos Hasan
*/

#ifndef __MODPLAY_H
#define __MODPLAY_H

#ifdef __BORLANDC__
#ifndef __LARGE__
#error Must use large memory model.
#endif
#endif

#define PM_TIMER    0
#define PM_MANUAL   1

typedef unsigned char byte;
typedef unsigned short word;
typedef unsigned long dword;
typedef byte *pointer;

typedef struct {
    word    NumTracks;
    word    OrderLength;
    byte    Orders[128];
    pointer Patterns[128];
    pointer SampPtr[32];
    pointer SampEnd[32];
    pointer SampLoop[32];
    byte    SampVolume[32];
} Module;

typedef struct {
    word    Period;
    word    Volume;
    dword   Length;
    pointer Data;
} Sample;

#ifdef __WATCOMC__
#pragma aux MODDetectCard "_*" parm caller [];
#pragma aux MODPlayModule "_*" parm caller [];
#pragma aux MODStopModule "_*" parm caller [];
#pragma aux MODPlaySample "_*" parm caller [];
#pragma aux MODStopSample "_*" parm caller [];
#pragma aux MODSetPeriod  "_*" parm caller [];
#pragma aux MODSetVolume  "_*" parm caller [];
#pragma aux MODSetMusicVolume  "_*" parm caller [];
#pragma aux MODSetSampleVolume "_*" parm caller [];
#pragma aux MODPoll "_*" parm caller [];
#endif

extern int  MODDetectCard(word *Port, byte *IRQ, byte *DRQ);
extern int  MODPlayModule(Module *Modulefile,word Chans,word Rate,word Port,byte IRQ,byte DRQ,byte Mode);
extern void MODStopModule(void);
extern void MODPlaySample(byte Voice,Sample *Instr);
extern void MODStopSample(byte Voice);
extern void MODSetPeriod(byte Voice,word Period);
extern void MODSetVolume(byte Voice,byte Volume);
extern void MODSetMusicVolume(byte Volume);
extern void MODSetSampleVolume(byte Volume);
extern void MODPoll(void);

extern Module *MODLoadModule(char *Path);
extern void MODFreeModule(Module *Song);
extern Sample *MODLoadSample(char *Path);
extern void MODFreeSample(Sample *Instr);

#endif

