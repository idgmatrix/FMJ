                        .386
                        .MODEL FLAT

                        .CODE

PUBLIC                  RotateI_, RotateS_, RotateB_

;-- Normal  : Int -> 25, Short -> 7, Byte -> 3 Left Rotate.
;-- Reverse : Int -> 7, Short -> 9, Byte -> 5 Left Rotate.
RotateI_                PROC

                        PUSH    ECX

                        MOV     ECX, EDX
                        ROL     EAX, CL

                        POP     ECX
                        RET

RotateI_                ENDP

RotateS_                PROC

                        PUSH    ECX

                        MOV     ECX, EDX
                        ROL     AX, CL

                        POP     ECX
                        RET

RotateS_                ENDP

RotateB_                PROC

                        PUSH    ECX

                        MOV     ECX, EDX
                        ROL     AL, CL

                        POP     ECX
                        RET

RotateB_                ENDP

                        END

