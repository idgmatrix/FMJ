/*  modload.c - Tiny MOD Player V2.11 for Watcom C/C++ and DOS/4GW

    Module and Sample file loader routines.

    Copyright 1993,94 Carlos Hasan
*/

#include <stdio.h>
#include <conio.h>
#include <malloc.h>
#include <io.h>
#include <fcntl.h>
#include "modplay.h"

/* MOD FileFormat */

#define ID_MK   0x2E4B2E4D
#define ID_FLT4 0x34544C46
#define ID_6CHN 0x4E484336
#define ID_8CHN 0x4E484338

typedef struct {
    byte        SampleName[22];
    word        Length;
    byte        FineTune;
    byte        Volume;
    word        LoopStart;
    word        LoopLength;
} MODSample;

typedef struct {
    byte        SongName[20];
    MODSample   Samples[31];
    byte        OrderLength;
    byte        ReStart;
    byte        Orders[128];
    dword       Sign;
} MODHeader;

/* MOD PeriodTable */
static word PeriodTable[12*7] = {
    3424,3232,3048,2880,2712,2560,2416,2280,2152,2032,1920,1812,
    1712,1616,1524,1440,1356,1280,1208,1140,1076,1016,960,906,
    856,808,762,720,678,640,604,570,538,508,480,453,
    428,404,381,360,339,320,302,285,269,254,240,226,
    214,202,190,180,170,160,151,143,135,127,120,113,
    107,101,95,90,85,80,75,71,67,63,60,56,
    53,50,47,45,42,40,37,35,33,31,30,28 };

/* WAV fileformat */

#define ID_RIFF 0x46464952
#define ID_WAVE 0x45564157
#define ID_FMT  0x20746D66
#define ID_DATA 0x61746164

typedef struct {
    dword   RIFFMagic;
    dword   FileLength;
    dword   FileType;
    dword   FormMagic;
    dword   FormLength;
    word    SampleFormat;
    word    NumChannels;
    dword   PlayRate;
    dword   BytesPerSec;
    word    Pad;
    word    BitsPerSample;
    dword   DataMagic;
    dword   DataLength;
} WAVHeader;


/* MOD Loader Routine */

#define Swap(w) (((dword)(w&0xff))<<8|((dword)(w>>8)))

Module *MODLoadModule(char *Path)
{
    int handle,NumTracks,NumPatts,i,j;
    word Note,Period,Inst,Effect;
    dword Length,LoopStart,LoopLength;
    MODHeader Header;
    MODSample *Sample;
    Module *Song;
    byte *Patt;

    if ((handle = open(Path,O_RDONLY | O_BINARY)) == -1)
        return NULL;

    if (read(handle,&Header,sizeof(Header)) != sizeof(Header)) {
        close(handle);
        return NULL;
    }

    if ((Header.Sign == ID_MK) || (Header.Sign == ID_FLT4))
        NumTracks = 4;
    else if (Header.Sign == ID_6CHN)
        NumTracks = 6;
    else if (Header.Sign == ID_8CHN)
        NumTracks = 8;
    else {
        close(handle);
        return NULL;
    }

    if ((Song = calloc(1,sizeof(Module))) == NULL) {
        close(handle);
        return NULL;
    }

    Song->NumTracks = NumTracks;
    Song->OrderLength = Header.OrderLength;
    for (NumPatts = i = 0; i < 128; i++) {
        Song->Orders[i] = Header.Orders[i];
        if (NumPatts < Header.Orders[i])
            NumPatts = Header.Orders[i];
    }
    NumPatts++;

    for (i = 0; i < NumPatts; i++) {
        if ((Song->Patterns[i] = malloc(256*NumTracks)) == NULL) {
            MODFreeModule(Song);
            close(handle);
            return NULL;
        }
        if (read(handle,Song->Patterns[i],256*NumTracks) != 256*NumTracks) {
            MODFreeModule(Song);
            close(handle);
            return NULL;
        }
        for (Patt = Song->Patterns[i], j = 0; j < 64*NumTracks; Patt += 4, j++) {
            Period = ((word)(Patt[0] & 0x0F) << 8) | (Patt[1]);
            Inst = (Patt[0] & 0xF0) | (Patt[2] >> 4);
            Effect = ((word)(Patt[2] & 0x0F) << 8) | (Patt[3]);
            for (Note = 0; Note < 12*7; Note++)
                if (Period >= PeriodTable[Note]) break;
            if (Note == 12*7) Note = 0; else Note++;
            Patt[0] = Note;
            Patt[1] = Inst;
            Patt[2] = Effect & 0xFF;
            Patt[3] = Effect >> 8;
        }
    }

    for (i = 1; i <= 31; i++) {
        Sample = &Header.Samples[i-1];
        if (Sample->Length) {
            Length = Swap(Sample->Length) << 1;
            LoopStart = Swap(Sample->LoopStart) << 1;
            LoopLength = Swap(Sample->LoopLength) << 1;
            if ((Song->SampPtr[i] = malloc(Length)) == NULL) {
                MODFreeModule(Song);
                close(handle);
                return NULL;
            }
            if ((unsigned)read(handle,Song->SampPtr[i],Length) != Length) {
                MODFreeModule(Song);
                close(handle);
                return NULL;
            }
            if (LoopLength <= 2) {
                Song->SampLoop[i] = Song->SampPtr[i] + Length;
                Song->SampEnd[i] = Song->SampLoop[i];
            }
            else {
                Song->SampLoop[i] = Song->SampPtr[i] + LoopStart;
                Song->SampEnd[i] = Song->SampLoop[i] + LoopLength;
            }
            Song->SampVolume[i] = Sample->Volume;
        }
    }

    close(handle);
    return Song;
}

void MODFreeModule(Module *Song)
{
    int i;
    if (Song) {
        for (i = 0; i < 128; i++)
            if (Song->Patterns[i]) free(Song->Patterns[i]);
        for (i = 1; i <= 31; i++)
            if (Song->SampPtr[i]) free(Song->SampPtr[i]);
        free(Song);
    }
}


/* RIFF/WAV Loader Routine */

Sample *MODLoadSample(char *Path)
{
    int handle;
    WAVHeader Header;
    Sample *Instr;
    byte *ptr;
    dword len;

    if ((handle = open(Path,O_RDONLY | O_BINARY)) == -1)
        return NULL;
    if (read(handle,&Header,sizeof(Header)) != sizeof(Header)) {
        close(handle);
        return NULL;
    }
    if (Header.RIFFMagic != ID_RIFF || Header.FileType != ID_WAVE ||
        Header.FormMagic != ID_FMT || Header.DataMagic != ID_DATA ||
        Header.SampleFormat != 1 || Header.NumChannels != 1 ||
        Header.BitsPerSample != 8) {
        close(handle);
        return NULL;
    }
    if ((Instr = malloc(sizeof(Sample)+Header.DataLength)) == NULL) {
        close(handle);
        return NULL;
    }
    Instr->Period = (8363L*428L)/Header.PlayRate;
    Instr->Volume = 64;
    Instr->Length = Header.DataLength;
    Instr->Data = (byte*)(Instr+1);
    if ((unsigned)read(handle,Instr->Data,Instr->Length) != Instr->Length) {
        free(Instr);
        close(handle);
        return NULL;
    }
    close(handle);

    for (ptr = Instr->Data, len = Instr->Length; len; len--)
        *ptr++ ^= 0x80;

    return Instr;
}

void MODFreeSample(Sample *Instr)
{
    if (Instr) free(Instr);
}

