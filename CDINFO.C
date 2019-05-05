/*
    CDINFO.C - Shows how to issue a real-mode interrupt
    from protected mode using DPMI call 300h. Any buffers
    to be passed to DOS must be allocated in DOS memory
    This can be done with DPMI call 100h.  This program
    will call DOS int 2F, CD-ROM functions 1500h, 1502h,
    1503h, 1504h.

    Compile & Link: wcl386 /l=dos4g cdinfo

    이건 CD-ROM의 정보를 읽어오는 프로그램입니다.
    이 정보는 일반적인 도스상에서는 볼 수도 카피 할 수 도 없습니다.
    물론 요 서비스를 이용하면 읽을 수 있지요.
    INT 2F  AX=1500h 이후의 서비스 들입니다.
    물론 CD-ROM 이 인스톨 되어 있어야 사용할 수 있는 서비스이죠.
    AX=1500h : CD-ROM 드라이브의 존재 여부와 드라이브 번호를 알 수 있습니다.
    AX=1502h : CD-ROM 에 새겨진 Copyright string을 읽어줍니다.
    AX=1503h :                  Abstract
    AX=1504h :                  Bibliography


    프로그램의 형식은 보호모드 프로그램내에서 DPMI 서비스 300h를 사용해서
    리얼모드 인터럽트 서비스를 호출하는 것입니다.
    그리고 리얼모드 인터럽트중에 반환 값을 버퍼를 통해서 넘겨주는
    게 있으므로  미리 DPMI 서비스 100h 를 이용해서 도스에서 엑세스
    할 수 있는 도스 메모리를 잡아놓아야 하지요.

*/

#include <i86.h>
#include <dos.h>
#include <stdio.h>
#include <string.h>

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

void main()
{
    union REGS regs;
    struct SREGS sregs;
    int interrupt_no=0x31;
    int CD_disk;
    short selector;
    short segment;
    char *str;

    /* DPMI call 100h allocates DOS memory */
    memset(&sregs,0,sizeof(sregs));
    regs.w.ax=0x0100;
    regs.w.bx=0x0003;           // 3 pragraph(16 bytes) dos memory 
    int386x( interrupt_no, &regs, &regs, &sregs);
    segment=regs.w.ax;
    selector=regs.w.dx;

    /* Make 32bit linear address for buffer */
    str = (char *)(((long)segment) << 4);

    /* Set up real-mode call structure */
    memset(&RMI,0,sizeof(RMI));
    RMI.EAX=0x00001500; /* CD-ROM installation check ax=1500  */
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
    RMI.EAX=0x00001502; /* call service ax=1502 get Copyright string */
    RMI.ES=segment;     /* put DOS seg:off into ES:BX*/
    RMI.EBX=0;          /* DOS ignores EBX high word */
    RMI.ECX=CD_disk;          /* drive number */

    /* Use DMPI call 300h to issue the DOS interrupt */
    regs.w.ax = 0x0300;
    regs.h.bl = 0x2F;
    regs.h.bh = 0;
    regs.w.cx = 0;
    sregs.es = FP_SEG(&RMI);
    regs.x.edi = FP_OFF(&RMI);
    int386x( interrupt_no, &regs, &regs, &sregs );
    if ( regs.w.cflag ) printf("CD-ROM function call failed\n");
    if ( RMI.flags & 0x01 ) printf("not CD-ROM drive\n");
    printf("CD-ROM Info.\n");
    printf("   Copyright:");
    printf(str); printf("\n");
    
    /* Set up real-mode call structure */
    memset(&RMI,0,sizeof(RMI));
    RMI.EAX=0x00001503; /* call service ax=1503 get abstract string */
    RMI.ES=segment;     /* put DOS seg:off into ES:BX*/
    RMI.EBX=0;          /* DOS ignores EBX high word */
    RMI.ECX=CD_disk;    /* CD-ROM drive number */

    /* Use DMPI call 300h to issue the DOS interrupt */
    regs.w.ax = 0x0300;
    regs.h.bl = 0x2F;
    regs.h.bh = 0;
    regs.w.cx = 0;
    sregs.es = FP_SEG(&RMI);
    regs.x.edi = FP_OFF(&RMI);
    int386x( interrupt_no, &regs, &regs, &sregs );
    printf("    Abstract:");
    printf(str); printf("\n");

    /* Set up real-mode call structure */
    memset(&RMI,0,sizeof(RMI));
    RMI.EAX=0x00001504; /* call service ax=1504 get bibliography string */
    RMI.ES=segment;     /* put DOS seg:off into ES:BX*/
    RMI.EBX=0;          /* DOS ignores EBX high word */
    RMI.ECX=CD_disk;    /* CD-ROM drive number */

    /* Use DMPI call 300h to issue the DOS interrupt */
    regs.w.ax = 0x0300;
    regs.h.bl = 0x2F;
    regs.h.bh = 0;
    regs.w.cx = 0;
    sregs.es = FP_SEG(&RMI);
    regs.x.edi = FP_OFF(&RMI);
    int386x( interrupt_no, &regs, &regs, &sregs );
    printf("Bibliography:");
    printf(str); printf("\n");
    
}
