	global _start
	extern long_mode_start

	section .text
	bits 32
_start:
	mov esp, stack_top

	call check_multiboot
	call check_cpuid
	call check_long_mode

	call set_up_page_tables
	call enable_paging
	call set_up_SSE

	lgdt [gdt64.pointer]

	;; uodate gdt selectors
	mov ax, 16
	mov ss, ax
	mov ds, ax
	mov es, ax

	jmp gdt64.code:long_mode_start

	;; print 'OK' to screen
	mov dword [0xb8000], 0x2f4b2f4f
	hlt

error:
	mov dword [0xb8000], 0x4f524f45
	mov dword [0xb8004], 0x4f3a4f52
	mov dword [0xb8008], 0x4f204f20
	mov byte  [0xb800a], al
	hlt

check_multiboot:	
	cmp eax, 0x36d76289
	jne .no_multiboot
	ret
.no_multiboot:
	mov al, "0"
	jmp error

check_cpuid:
	pushfd
	pop eax

	mov ecx, eax

	xor eax, 1 << 21

	push eax
	popfd

	pushfd
	pop eax

	push ecx
	popfd

	xor eax, ecx
	jz .no_cpuid
	ret
.no_cpuid:
	mov al, "1"
	jmp error

check_long_mode:
	;; test if extended processor into in available
	mov eax, 0x80000000
	cpuid
	cmp eax, 0x80000001
	jb .no_long_mode

	;; use extended info to test if long mode is available
	mov eax, 0x80000001
	cpuid
	test edx, 1 << 29
	jz .no_long_mode
	ret
.no_long_mode:
	mov al, "2"
	jmp error

set_up_page_tables:
	mov eax, p3_table
	or eax, 11b
	mov [p4_table], eax

	mov eax, p2_table
	or eax, 11b
	mov [p3_table], eax

	mov ecx, 0


.map_p2_table:
	mov eax, 0x200000
	mul ecx
	or eax, 10000011b
	mov [p2_table + ecx * 8], eax

	inc ecx
	cmp ecx, 512
	jne .map_p2_table

	ret

enable_paging:
	mov eax, p4_table
	mov cr3, eax

	mov eax, cr4
	or eax, 1 << 5
	mov cr4, eax

	mov ecx, 0xC0000080
	rdmsr
	or eax, 1 << 8
	wrmsr

	;; enable paging in cr0
	mov eax, cr0
	or eax, 1 << 31
	mov cr0, eax

	ret

set_up_SSE:
	;; check
	mov eax, 0x1
	cpuid
	test edx, 1<<25
	jz .no_SSE

	;; enable
	mov eax, cr0
	and ax, 0xFFFB
	or ax, 0x2
	mov cr0, eax
	mov eax, cr4
	or ax, 3 << 9
	mov cr4, eax

	ret
.no_SSE:
	mov al, "a"
	jmp error
	
	section .bss
	align 4096
p4_table:
	resb 4096
p3_table:
	resb 4096
p2_table:
	resb 4096
stack_bottom:
	resb 64
stack_top:	


	section .rodata
gdt64:
	dq 0
.code: equ $ - gdt64
	dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53)
.data: equ $ - gdt64
	dq (1<<44) | (1<<47) | (1<<41)
.pointer:
	dw $ - gdt64 - 1
	dq gdt64
