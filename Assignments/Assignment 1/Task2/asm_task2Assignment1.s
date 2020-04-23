section	.rodata						; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	; format string/

section .bss						; we define (global) uninitialized variables in .bss section
	an: resb 12						; enough to store integer in [-2,147,483,648 (-2^31) : 2,147,483,647 (2^31-1)]

section .text
	global convertor
	extern printf

convertor:
	push ebp
	mov ebp, esp	
	pushad			
	mov ecx, dword [ebp+8]			; get function argument (pointer to string)
	mov eax, 0						; set the decimal value of the converted string to 0
getIntLoop: 
	movzx edx, byte [ecx]			; move the char value of the i-th char ro edx register
	cmp edx, '0'					; check if edx value equal to the char '0'
	jb hexaConventor				; if edx value is below '0' jump to hexaConventor
	cmp edx, '9'					; check if edx value equal to the char '9'
	ja hexaConventor				; if edx value is above '9' jump to hexaConventor
	sub edx, '0'					; convert the char to the integer value
	imul eax, 10					; multiply "result so far" by 10
	add eax, edx					; add in current digit
	inc ecx							; increament the ecx by one for iterate the next char in the string
	jmp getIntLoop					; jump to getIntLoop

hexaConventor:
	mov ebx, 16						; divisor can be any register or memory
	mov ecx, 10						; set ecx to 10 for the first cell that will insert in hexa digits array an

hexaConventorLoop:
	mov edx, 0             			; dividend high half = 0.  prefer  xor edx,edx
	div ebx     	  				; Divides eax by 10.
        							; EDX =   4 = 1234 % 10  quotient
        							; EAX = 123 = 1234 / 10  remainder
hexaDigit:
	cmp edx, 9						; check if edx value equal to the char '9'
	ja hexaLetter					; if edx value is above '9' jump to hexaLetter
	add edx, '0'					; set the ascii decimal number of the integer to edx
	jmp hexaDigitBottom				; jump to hexaDigitBottom
hexaLetter:
	sub edx, 10						; substrat 10 from edx register to get the hexa digit letter
	add edx, 'A'					; add 'A' value to edx register to get the hexa digit letter
hexaDigitBottom:
	mov byte [an + ecx], dl			; insert the hexa digit char into array an, from the lsb to the msb
	dec ecx							; decrease ecx register for pass to the next cell in an array
	cmp eax, 0						; check if edx value equal to 0, so an array is full
	jne hexaConventorLoop			; if not equal jump to hexaConventorLoop

	add ecx, 1						; increase ecx register by one to return to the msb digit in the array
	mov ebx, 12						; set ebx register to 12
	sub ebx, ecx					; calculate how many time call the loop
	mov eax, 0						; int i = 0

moveLoop:
	cmp eax, ebx					; check if i == ebx
	je bottom						; if equal jump to bottom
	mov dx, [an + eax + ecx]		; mov the char at i + ecx in an to dx
	mov [an + eax], dx				; mov dx to an in place i
	inc eax							; i++
	jmp moveLoop					; jump to moveLoop

bottom:
	push an							; call printf with 2 arguments
	push format_string				; pointer to str and pointer to format string
	call printf						; call printf method from c
	add esp, 8						; clean up stack after call

	popad			
	mov esp, ebp	
	pop ebp
	ret