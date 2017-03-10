;========1=========2=========3=========4=========5=========6=========7=========8=========9=========0=========1=========2=========3=========4=========5=========6=========7**
;Author information
;  Author name: Sina Amini  
;  Author email: sinamindev@gmail.com
;Project information
;  Project title: The Power of e
;  Purpose: This program reads two floats and an integer to compute a Taylor Series algorithm using a while loop and outputs runtime
;  Status: No known errors
;  Project files: conversion-driver.cpp, conversion.asm
;Module information
;  This module's call name: hexconversion
;  Language: X86-64
;  Syntax: Intel
;  Date last modified: 2014-Oct-13
;  Purpose: This module will perform the calculations of a Taylor series using 2 given floats and an integer by the user. 
;  File name: conversion.asm
;  Status: This module functions as expected.
;  Future enhancements: None planned
;Translator information
;  Linux: nasm -f elf64 -l conversion.lis -o conversion.o conversion.asm 
;References and credits
;  Seyfarth
;  Professor Holliday public domain programs
;Format information
;  Page width: 172 columns
;  Begin comments: 61
;  Optimal print specification: Landscape, 7 points or smaller, monospace, 8½x11 paper
;
;===== Begin code area ====================================================================================================================================================
extern printf                                               ;External C++ function for writing to standard output device

extern scanf                                                ;External C++ function for reading from the standard input device

global hexconversion                                        ;This makes amortization_schedule callable by functions outside of this file.

segment .data                                               ;Place initialized data here

;===== Declare some messages ==============================================================================================================================================

initialmessage          db "This program will compute e^x for two values of x.", 10
						db "Vector processing will be used to compute both results concurrently.", 10, 10, 0
			
promptmessage1          db "Please enter two values for exponents and press enter: ", 0

echoformat              db "You entered 0x%.16lx and 0x%.16lx", 10, 0

promptmessage2          db "Enter an integer for epsilon: ", 0

echostart               db 10, "The Taylor series algorithm has begun. Please be patient. ", 10, 0

echosuccess             db 10, "The algorithm has completed successfully. The computed values are these. ", 10, 0

taylorvalues            db "exp(%.8lf)  =  %.18lf ", 10, 0

seriesterms             db 10, "The number of terms in the Taylor series is %lf", 10, 0

clockbefore             db 10, "The clock before the algorithm began was %ld ", 10, 0

clockafter              db "The clock when the algorithm ended was %ld ", 10, 0

clockruntime            db 10, "The run time of the algorithm alone was", 10
						db "%ld tics = ", 0
			
timeformat      db "%ld ns = 0.%09ld seconds.",10,0

goodbye         db 10, "This program will now return the number of tics to the driver. Enjoy your exponents. ", 10,0            

xsavenotsupported.notsupportedmessage db "The xsave instruction and the xrstor instruction are not supported in this microprocessor.", 10
									  db "However, processing will continue without backing up state component data", 10, 0

stringformat        db "%s", 0                              ;general string format

xsavenotsupported.stringformat db "%s", 0

eight_byte_format   db "%lf", 0                             ;general 8-byte float format

integer_format      db "%ld",0                              ;general integer format

fourfloatformat     db "%lf %lf %lf %lf", 0                 ;general four float format

hexformat           db "0x%016lx",0

segment .bss                                                ;Place un-initialized data here.

align 64                                                    ;Insure that the inext data declaration starts on a 64-byte boundar.
backuparea resb 832                                         ;Create an array for backup storage having 832 bytes.

localbackuparea resb 832                                    ;reserve space for backup

segment .text   
mov rdx, 0                                                  ;prepare rdx
mov rax, 7                                                  ;machine supports avx
xsave  [localbackuparea]                                    ;backup area

;===== Begin executable instructions here =================================================================================================================================

segment .text                                               ;Place executable instructions in this segment.

hexconversion:                                              ;Entry point.  Execution begins here.

;=========== Back up all the GPRs whether used in this program or not =====================================================================================================

push       rbp                                              ;Save a copy of the stack base pointer
mov        rbp, rsp                                         ;We do this in order to be 100% compatible with C and C++.
push       rbx                                              ;Back up rbx
push       rcx                                              ;Back up rcx
push       rdx                                              ;Back up rdx
push       rsi                                              ;Back up rsi
push       rdi                                              ;Back up rdi
push       r8                                               ;Back up r8
push       r9                                               ;Back up r9
push       r10                                              ;Back up r10
push       r11                                              ;Back up r11
push       r12                                              ;Back up r12
push       r13                                              ;Back up r13
push       r14                                              ;Back up r14
push       r15                                              ;Back up r15
pushf                                                       ;Back up rflags

;==========================================================================================================================================================================
;===== Begin State Component Backup =======================================================================================================================================
;==========================================================================================================================================================================

;=========== Before proceeding verify that this computer supports xsave and xrstor ========================================================================================
;Bit #26 of rcx, written rcx[26], must be 1; otherwise xsave and xrstor are not supported by this computer.
;Preconditions: rax holds 1.
mov        rax, 1

;Execute the cpuid instruction
cpuid

;Postconditions: If rcx[26]==1 then xsave is supported.  If rcx[26]==0 then xsave is not supported.

;=========== Extract bit #26 and test it ==================================================================================================================================
and        rcx, 0x0000000004000000                          ;The mask 0x0000000004000000 has a 1 in position #26.  Now rcx is either all zeros or
															;has a single 1 in position #26 and zeros everywhere else.
cmp        rcx, 0                                           ;Is (rcx == 0)?
je         xsavenotsupported                                ;Skip the section that backs up state component data.

;========== Call the function to obtain the bitmap of state components ====================================================================================================

;Preconditions
mov        rax, 0x000000000000000d                          ;Place 13 in rax.  This number is provided in the Intel manual
mov        rcx, 0                                           ;0 is parameter for subfunction 0

;Call the function
cpuid                                                       ;cpuid is an essential function that returns information about the cpu

;Postconditions (There are 2 of these):

;1.  edx:eax is a bit map of state components managed by xsave.  At the time this program was written (2014 June) there were exactly 3 state components.  Therefore, bits
;    numbered 2, 1, and 0 are important for current cpu technology.
;2.  ecx holds the number of bytes required to store all the data of enabled state components. [Post condition 2 is not used in this program.]
;This program assumes that under current technology (year 2014) there are at most three state components having a maximum combined data storage requirement of 832 bytes.
;Therefore, the value in ecx will be less than or equal to 832.

;Precaution: As an insurance against a future time when there will be more than 3 state components in a processor of the X86 family the state component bitmap is masked to
;allow only 3 state components maximum.

mov        r15, 7                                           ;7 equals three 1 bits.
and        rax, r15                                         ;Bits 63-3 become zeros.
mov        r15, 0                                           ;0 equals 64 binary zeros.
and        rdx, r15                                         ;Zero out rdx.

;========== Save all the data of all three components except GPRs =========================================================================================================

;The instruction xsave will save those state components with on bits in the bitmap.  At this point edx:eax continues to hold the state component bitmap.

;Precondition: edx:eax holds the state component bit map.  This condition has been met by the two pops preceding this statement.
xsave      [backuparea]                                     ;All the data of state components managed by xsave have been written to backuparea.

push qword -1                                               ;Set a flag (-1 = true) to indicate that state component data were backed up.
jmp        startapplication

;========== Show message xsave is not supported on this platform ==========================================================================================================
xsavenotsupported:

mov        rax, 0
mov        rdi, .stringformat
mov        rsi, .notsupportedmessage                        ;"The xsave instruction is not suported in this microprocessor.
call       printf

push qword 0                                                ;Set a flag (0 = false) to indicate that state component data were not backed up.

;==========================================================================================================================================================================
;===== End of State Component Backup ======================================================================================================================================
;==========================================================================================================================================================================


;==========================================================================================================================================================================
startapplication: ;===== Begin the application here: Amortization Schedule ================================================================================================
;==========================================================================================================================================================================

vzeroall                            ;place binary zeros in all components of all vector register in SSE
push rdx                            ;push starting time onto stack

;==== Show the initial message ============================================================================================================================================

mov qword  rax, 0                                           ;No data from SSE will be printed
mov        rdi, stringformat                                ;"%s"
mov        rsi, initialmessage                              ;"This program will compute e^x for two values of x."
															;"Vector processing will be used to compute both results concurrently."
call       printf                                           ;Call a library function to make the output

;==== Prompt for two floating point numbers ===============================================================================================================================

mov qword  rax, 0                                           ;No data from SSE will be printed
mov        rdi, stringformat                                ;"%s"
mov        rsi, promptmessage1                              ;"Please enter two values for exponents and press enter: "
call       printf                                           ;Call a library function to make the output

;==== Obtain a floating point number from the standard input device and store a copy in xmm15 =============================================================================

push qword 0                                                ;Reserve 8 bytes of storage for the incoming number
mov qword  rax, 0                                           ;SSE is not involved in this scanf operation
mov        rdi, eight_byte_format                           ;"%lf"
mov        rsi, rsp                                         ;Give scanf a point to the reserved storage
call       scanf                                            ;Call a library function to do the input work
movsd xmm15, [rsp]                                          ;move first float number from stack into xmm15
pop rax                                                     ;Make free the storage that was used by scanf

;==== Obtain a floating point number from the standard input device and store a copy in xmm14 =============================================================================

push qword 0                                                ;Reserve 8 bytes of storage for the incoming number
mov qword  rax, 0                                           ;SSE is not involved in this scanf operation
mov        rdi, eight_byte_format                           ;"%lf"
mov        rsi, rsp                                         ;Give scanf a point to the reserved storage
call       scanf                                            ;Call a library function to do the input work
movsd xmm14, [rsp]                                          ;move second float number from stack into xmm14
pop rax                                                     ;Make free the storage that was used by scanf

;======== Output two hex conversions ======================================================================================================================================

movupd xmm0, xmm15                                          ;move value into xmm0 from xmm15
movupd xmm1, xmm14                                          ;move value into xmm0 from xmm15

push qword 0                                                ;Reserve 4 bytes of storage for the incoming float
push qword 0                                                ;Reserve 4 bytes of storage for the incoming float

movsd [rsp], xmm0                                           ;moves the value in xmm0 onto the stack
movsd [rsp+8], xmm1                                         ;moves the value in xmm1 onto the stack

mov        rax, 2                                           ;4 floating point numbers will be outputted
mov        rdi, echoformat                                  ;"you entered 0x%016lx and 0x%016lx"
mov        rsi, [rsp]                                       ;moves value from stack into rsi for print
mov        rdx, [rsp+8]                                     ;moves second value from stack into rdx for print
call       printf                                           ;Call a library function to do the hard work

pop rax                                                     ;Make free the storage that was used by printf
pop rax                                                     ;Make free the storage that was used by printf

;==== Prompt for integer number ===========================================================================================================================================

mov qword  rax, 0                                           ;No data from SSE will be printed
mov        rdi, stringformat                                ;"%s"
mov        rsi, promptmessage2                              ;"Enter an integer for epsilon: "
call       printf                                           ;Call a library function to make the output

;==== Obtain an integer number from the standard input device and store a copy in r15 =====================================================================================

push dword 0                                                ;Reserve 4 bytes of storage for the incoming integer
mov qword  rax, 0                                           ;SSE is not involved in this scanf operation                                          
mov        rdi, integer_format                              ;"%d"
mov        rsi,rsp                                          ;Give scanf a point to the reserved storage
call       scanf                                            ;Call a library function to do the input work
mov        r14, [rsp]                                       ;move the time of loans as an integer into the gpr r14
pop rax                                                     ;Make free the storage that was used by scanf

;====== read and save clock time into stack ===============================================================================================================================

mov rdx, 0                                                  ;move 0 to prepare for backup
mov rax, 0                                                  ;move 0 to prepare for backup

rdtsc                                                       ;copies counter to edx:eax
shl rdx, 32                                                 ;shift the values

or rdx, rax                                                 ;fills the values in rax to the end of the rdx register; mov rdx, rax
mov r13, rdx                                                ;move starting time into r11

;==== Confirm computation start ===========================================================================================================================================

mov qword  rax, 0                                           ;No data from SSE will be printed
mov        rdi, stringformat                                ;"%s"
mov        rsi, echostart                                   ;"The Taylor series algorithm has begun. Please be patient.  "
call       printf                                           ;Call a library function to make the output

;==== Taylor Series loop ==================================================================================================================================================
;xmm13 =term || xmm12 = xmm8 = sum || r14 = xmm11 = inputted integer || r12 = count

mov rax, 0x3ff0000000000000                                 ;move the bias number 1023 into rax
movq xmm13, rax                                             ;set the term to be in xmm13
movlhps xmm13, xmm13                                        ;set all of xmm13 to hold the term value

movq xmm12, rax                                             ;set the sum of the first value to be in xmm12
movlhps xmm12, xmm12                                        ;set all of xmm12 to hold the sum value

movq xmm8, rax ;sum                                         ;set the sum of the second value to be in xmm8
movlhps xmm8, xmm8                                          ;set all of xmm8 to hold the sum value
mov rbx, 0                                                  ;set the count to zero and store within rbx

;====== Hex conversion , finding series bounds using n ====================================================================================================================

mov r15, 0x00000000000003FF                                 ;move 1023 into r15
sub r15, r14                                                ;3FF -n ; subtract the r15 value 1023 by the integer value n
shl r15, 52                                                 ;shift to the left r15

mov [rsp], r15                                              ;move the comparison value from r15 into stack for the Taylor series 
movsd xmm11, [rsp]                                          ;move the comparison value from the stack into xmm11
movlhps xmm11, xmm11                                        ;fill the xmm11 register with the comparison value 

;====== Start of Tayler series while loop =================================================================================================================================

mov rax, 0x0000000000000000                                 ;move the value 0 into the register rax
movq xmm10, rax                                             ;move 0 from rax into xmm10 to be used as the count
movlhps xmm10, xmm10                                        ;move the value within xmm10 through out xmm10 register
movlhps xmm15, xmm14                                        ;move value from xmm14 into high location of xmm15

taylorseriesstart:                                          ;starting point of while loop to determine taylor series

mulpd xmm13, xmm15                                          ;multiply xmm13 by xmm15 and store the value into xmm13
addpd xmm10, xmm8                                           ;add the sum in xmm8 into xmm10 being the count
divpd xmm13, xmm10                                          ;divide xmm13 by the xmm10 register being the count
addpd xmm12, xmm13                                          ;add the value in the xmm13 register into the xmm12 register

pabsd xmm9, xmm13                                           ;Stores absolute value of xmm13 into xmm9
ucomisd xmm9, xmm11                                         ;compare the low double-precision floating point values in xmm9 and xmm11

jb secondcomparison                                         ;checks to jump to the secondcoomparison portion of the loop
ja taylorseriesstart                                        ;checks to jump to the start of the taylor series loop

secondcomparison:                                           ;start of the second comparison of the loop

movhlps xmm8, xmm13                                         ;move the values within xmm13 into the xmm8 register

pabsd xmm9, xmm8                                            ;Stores absolute value of xmm8 into xmm9
ucomisd xmm9, xmm11                                         ;compare the low double-precision floating point values in xmm9 and xmm11

jb outofloop                                                ;checks to jump out of the loop
ja taylorseriesstart                                        ;checks to jump to the top of loop

outofloop:                                                  ;point in which the loop will jump to when it stops looping

;==== Confirm computation success =========================================================================================================================================
mov rdx, 0                                                  ;move 0 to prepare for backup
mov rax, 7                                                  ;machine supports avx registers to backup
xsave  [localbackuparea]                                    ;backup registers to localbackuparea

mov qword  rax, 0                                           ;No data from SSE will be printed
mov        rdi, stringformat                                ;"%s"
mov        rsi, echosuccess                                 ;"The algorithm has completed successfully. The computed values are these.  "
call       printf                                           ;Call a library function to make the output

mov rdx, 0                                                  ;prepare to restore
mov rax, 7                                                  ;machine should restore up to ymm registers
xrstor  [localbackuparea]                                   ;restore backed up registers

;===== Output computed values for the Taylor Series =======================================================================================================================

movsd xmm0,xmm15                        ;moves the first float number from xmm15 into xmm0 for output
movsd xmm1,xmm12                        ;moves the first computed value from xmm12 into xmm1 for output

mov rdx, 0                          ;move 0 to prepare for backup
mov rax, 7                          ;move 0 to prepare for backup
xsave  [localbackuparea]                    ;backup registers to localbackuparea

mov rdi, taylorvalues                           ;"exp(%1.8lf)  =  %1.18lf "
mov rax, 2                          ;prepares for 2 values to be output 
call printf                         ;Call a library function to make the output

mov rdx, 0                          ;prepare to restore
mov rax, 7                              ;machine should restore up to ymm registers
xrstor  [localbackuparea]                       ;restore backed up registers

movsd xmm0, xmm14                       ;moves the second float number from xmm14 into xmm0 for output
movhlps xmm1, xmm12                     ;moves the second computed value from xmm12 into xmm1 for output

mov rdx, 0                          ;move 0 to prepare for backup
mov rax, 7                          ;machine supports avx registers to backup
xsave  [localbackuparea]                    ;backup registers to localbackuparea

mov rdi, taylorvalues                           ;"exp(%1.8lf)  =  %1.18lf "
mov rax, 2                          ;prepares for 2 values to be output 
call printf                         ;Call a library function to do the hard work

mov rdx, 0                          ;prepare to restore
mov rax, 7                              ;machine should restore up to ymm registers
xrstor  [localbackuparea]                       ;restore backed up registers

;======= Output the number of terms into Taylor Series ====================================================================================================================

movsd xmm0, xmm10                       ;moves the number of terms from xmm10 into xmm0 for output
mov rdi, seriesterms                            ;"The number of terms in the Taylor series is %lf."
mov rax, 1                          ;one value will be outputted to moniter
call printf                         ;Call a library function to do the hard work

;====== read clock and show time ==========================================================================================================================================

pop rcx                             ;pop starting tome off of stack and into rcx register

mov        rax, 0                       ;0 numbers will be outputted
mov        rsi , r13                                        ;move the starting clock value into rsi from r13 for outputting
mov        rdi, clockbefore                                 ;"The clock before the algorithm began was  %ld  "
call       printf                                           ;Call a library function to do the hard work

mov rdx, 0                          ;set rdx register to 0
mov rax, 0                          ;set rax register to 0

rdtsc                               ;copies counter to edx:eax
shl rdx, 32                         ;shift the values

or rdx, rax                         ;fills the values in rax to the end of the rdx register; mov rdx, rax

mov r14, rdx                            ;move end time into r14

mov        rax, 0                       ;0 numbers will be outputted
mov        rsi ,  r14                                       ;move the end time value into rsi from r14
mov        rdi, clockafter                                  ;"The clock when the algorithm ended was %ld  "
call       printf                                           ;Call a library function to do the hard work

sub r14, r13 ;                          ;subtract the endtime by the start time and store in rdx

mov        rax, 0                       ;0 numbers will be outputted
mov        rsi , r14                                        ;move the run time value into rsi from r14
mov        rdi, clockruntime                                ;"The run time of the algorithm alone was"
								;"%ld tics = "
call       printf                                           ;Call a library function to do the hard work

mov rax, r14                            ;move the r14 value into the rax register
cqo                             ;convert quadnumber to octal number 
mov r12, 3                          ;moves 3.00 GHz speed into r12
div r12                             ;devides r14 value by r12 and stores the value into rax and the remainder into rdx

push    qword   0                                           ;Reserve 8 bytes of storage
mov     [rsp], r14                                          ;Place a backup copy of the quotient in the reserved storage

mov rdi, timeformat                     ;" %ld ns = 0.%09ld seconds."
mov rsi, rax                            ;move the computed nanoseconds value into rsi for output
mov rdx, rax                            ;move the computed seconds value into rdx for output
mov rax, 0                          ;fills the rax register with the value 0
call printf                         ;Call a library function to do the hard work

;rcx holds the start time and rdx holds the final time. make sure to out put them before you do the subtraction. 

;===== Conclusion message =================================================================================================================================================

mov qword  rax, 0                                           ;No data from SSE will be printed
mov        rdi, stringformat                                ;"%s"
mov        rsi, goodbye                                     ;"This program will now return the number of tics to the driver. Enjoy your exponents."                              
call       printf                                           ;Call a llibrary function to do the hard work.

;===== Retrieve a copy of the quotient that was backed up earlier =========================================================================================================

pop        r14                                              ;A copy of the last interest value  within r14 (temporary storage)

;Now the stack is in the same state as when the application area was entered.  It is safe to leave this application area.

;==========================================================================================================================================================================
;===== Begin State Component Restore ======================================================================================================================================
;==========================================================================================================================================================================

;===== Check the flag to determine if state components were really backed up ==============================================================================================

pop        rbx                                              ;Obtain a copy of the flag that indicates state component backup or not.
cmp        rbx, 0                                           ;If there was no backup of state components then jump past the restore section.
je         setreturnvalue                                   ;Go to set up the return value.

;Continue with restoration of state components;

;Precondition: edx:eax must hold the state component bitmap.  Therefore, go get a new copy of that bitmap.

;Preconditions for obtaining the bitmap from the cpuid instruction
mov        rax, 0x000000000000000d                          ;Place 13 in rax.  This number is provided in the Intel manual
mov        rcx, 0                                           ;0 is parameter for subfunction 0

;Call the function
cpuid                                                       ;cpuid is an essential function that returns information about the cpu

;Postcondition: The bitmap in now in edx:eax

;Future insurance: Make sure the bitmap is limited to a maximum of 3 state components.
mov        r15, 7
and        rax, r15
mov        r15, 0
and        rdx, r15

xrstor     [backuparea]

;==========================================================================================================================================================================
;===== End State Component Restore ========================================================================================================================================
;==========================================================================================================================================================================


setreturnvalue: ;=========== Set the value to be returned to the caller ===================================================================================================

push       r14                                              ;r15 continues to hold the first computed floating point value.
movsd      xmm0, [rsp]                                      ;That first computed floating point value is copied to xmm0[63-0]
pop        r14                                              ;Reverse the push of two lines earlier.

;=========== Restore GPR values and return to the caller ==================================================================================================================

popf                                                        ;Restore rflags
pop        r15                                              ;Restore r15
pop        r14                                              ;Restore r14
pop        r13                                              ;Restore r13
pop        r12                                              ;Restore r12
pop        r11                                              ;Restore r11
pop        r10                                              ;Restore r10
pop        r9                                               ;Restore r9
pop        r8                                               ;Restore r8
pop        rdi                                              ;Restore rdi
pop        rsi                                              ;Restore rsi
pop        rdx                                              ;Restore rdx
pop        rcx                                              ;Restore rcx
pop        rbx                                              ;Restore rbx
pop        rbp                                              ;Restore rbp

ret                                                         ;No parameter with this instruction.  This instruction will pop 8 bytes from
															;the integer stack, and jump to the address found on the stack.
;========== End of program amortization-schedule.asm =======================================================================================================================
;========1=========2=========3=========4=========5=========6=========7=========8=========9=========0=========1=========2=========3=========4=========5=========6=========7**
