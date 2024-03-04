
RESET:					; DATA XREF: ROM:009Dw	ROM:00F7w ...
		ei			; Enable INT why?
		ld	a, 80h ; 'Ç'
		cp	d		; D = $80 (DE pointed to RAM)?
		jr	z, loc_A	; Yes, warm reset
		exx
		ld	de, 8000h	; Cold RESET, then DE point to RAM

loc_A:					; CODE XREF: ROM:0004j
		exx
		ld	h, 9		; Interface Control Code (CTRL+I)
		exx

loc_E:					; CODE XREF: ROM:0345j
		ld	(5000h), a	; Clear	FLAG_FW
		ld	iy, 8000h	; IY is	Buffer Write Address
		ld	hl, 8000h	; HL is	Buffer Read Address
		exx
		and	b
		ld	b, a
		res	1, c		; Clear	flag ISASCII
		res	4, c		; Clear	flag NOACCENT
		ld	a, 0A5h	; 'Ñ'
		cp	d
		cpl
		jr	nz, loc_28
		cp	e
		jr	z, loc_30

loc_28:					; CODE XREF: ROM:0023j
		ld	bc, 8000h
		ld	h, 9
		ld	e, a
		cpl
		ld	d, a

loc_30:					; CODE XREF: ROM:0026j
		exx
		ld	(hl), a		; Test if exist	RAM
		cp	(hl)
		jp	nz, loc_54	; No RAM
		cpl
		ld	(6800h), a	; Set FF_HIGH32K
		ld	(hl), a
		ld	(6000h), a	; Clear	FF_HIGH32K
		cpl
		cp	(hl)		; Has second bank of 32K?
		exx
		jr	nz, loc_4E	; No, only one RAM bank, jump
		exx
		cpl
		ld	(6800h), a	; Set FF_HIGH32K
		cp	(hl)		; Check	if second RAM bank is working
		exx
		jr	nz, loc_4E	; Not working, jump
		set	4, b		; Set flag RAM64

loc_4E:					; CODE XREF: ROM:0041j	ROM:004Aj
		set	3, b		; Set flag RAM
		exx
		ld	a, (6000h)	; Do what?

loc_54:					; CODE XREF: ROM:0033j	ROM:0066j ...
		ld	b, 1Fh

loc_56:					; CODE XREF: ROM:005Ej
		xor	a
		in	a, (0)		; Read flags
		bit	7, a		; Have data sended by FW?
		jp	z, ReadA2Data	; Yes, jump
		djnz	loc_56
		ld	a, i
		xor	1
		ld	i, a
		jp	loc_54
; ---------------------------------------------------------------------------

loc_69:					; CODE XREF: ROM:021Aj
		jp	z, MODE_mode
		bit	3, b		; We have RAM?
		jp	z, loc_156	; No, jump

IsAscii:				; CODE XREF: ROM:090Bj
		set	1, c		; Set flag ISASCII

TestAndPutInBuffer:			; CODE XREF: ROM:0146j	ROM:018Cj ...
		bit	2, b		; Buffer full?
		jr	z, PutInBuffer	; No, jump

loc_77:					; CODE XREF: ROM:0082j	ROM:008Aj
		xor	a
		in	a, (0)		; Read flags
		bit	6, a		; Bit 6	= 1 => Busy
		jr	nz, loc_8C
		ld	a, r
		cp	8
		jr	nc, loc_77
		ld	a, i
		xor	1
		ld	i, a
		jr	loc_77
; ---------------------------------------------------------------------------

loc_8C:					; CODE XREF: ROM:007Cj
		bit	4, b		; We have RAM64?
		jp	z, loc_F5	; No, jump
		bit	6, b		; Is second page of RAM?
		ld	(6000h), a	; Clear	FF_HIGH32K
		jr	z, loc_9B	; No, jump
		ld	(6800h), a	; Set FF_HIGH32K

loc_9B:					; CODE XREF: ROM:0096j
		exx
		ld	a, (hl)		; Read next byte from buffer
		ld	(RESET), a	; LPT Latch data
		ld	(4000h), a	; Pulse	LPT_STROBE
		inc	hl
		ld	a, h		; RAM address overlapped to 0000?
		or	a
		jr	nz, PutInBuffer2 ; No, jump
		ld	hl, 8000h	; Reset	RAM address
		exx
		ld	a, b
		xor	40h ; '@'       ; Invert bit 6 of B (Toggle RAM page)
		ld	b, a

PutInBuffer:				; CODE XREF: ROM:0075j
		exx

PutInBuffer2:				; CODE XREF: ROM:00A6j	ROM:0102j ...
		ld	a, c
		exx
		bit	1, b		; Is second page of RAM?
		ld	(6000h), a	; Clear	FF_HIGH32K
		jr	z, loc_BD	; No, jump
		ld	(6800h), a	; Set FF_HIGH32K

loc_BD:					; CODE XREF: ROM:00B8j	ROM:06A4j
		bit	1, c		; Test if data is ASCII
		res	1, c		; Clear	flag ISASCII
		jr	nz, loc_CD	; If not ASCII,	jump
		bit	2, c		; Force	clean BIT7?
		jr	nz, loc_CB	; Yes, jump

loc_C7:					; CODE XREF: ROM:0690j	ROM:0695j ...
		bit	0, c		; BIT7 enabled?
		jr	nz, loc_CD	; Yes, jump

loc_CB:					; CODE XREF: ROM:00C5j
		and	7Fh ; ''       ; Clear bit 7

loc_CD:					; CODE XREF: ROM:00C1j	ROM:00C9j
		ld	(iy+0),	a	; Save to Buffer

loc_D0:					; CODE XREF: ROM:067Dj
					; DATA XREF: ROM:0548w	...
		ld	a, i
		xor	1
		ld	i, a
		inc	iy		; Inc Buffer address
		bit	4, b		; We have RAM64?
		ld	a, yh
		jr	z, loc_10B	; No, jump
		or	a
		jr	nz, loc_E9
		ld	iy, 8000h	; Reset	Buffer address
		ld	a, b
		xor	2
		ld	b, a

loc_E9:					; CODE XREF: ROM:00DFj
		bit	6, b		; Is second page of RAM?
		jp	nz, loc_384	; Yes, jump
		bit	1, b		; Is second page of RAM?
		jr	z, loc_113	; No, jump
		jp	loc_389
; ---------------------------------------------------------------------------

loc_F5:					; CODE XREF: ROM:008Ej
		exx
		ld	a, (hl)
		ld	(RESET), a	; Latch	LPT data
		ld	(4000h), a	; Pulse	LPT_STROBE
		inc	hl
		ld	a, h
		xor	0C0h ; '└'      ; We arrived at $C000 RAM address?
		or	a
		jp	nz, PutInBuffer2 ; Nop,	jump
		ld	hl, 8000h	; Yes, reset RAM address
		jp	PutInBuffer2
; ---------------------------------------------------------------------------

loc_10B:				; CODE XREF: ROM:00DCj
		xor	0C0h ; '└'      ; IY arrived at $C000?
		jr	nz, loc_113	; No, jump
		ld	iy, 8000h	; Reset	RAM address

loc_113:				; CODE XREF: ROM:00F0j	ROM:010Dj ...
		exx
		ld	a, yh
		cp	h
		jp	nz, loc_38A
		ld	a, yl
		cp	l
		jp	nz, loc_38A
		exx
		set	2, b		; Set Buffer Full flag
		jp	loc_1FA
; ---------------------------------------------------------------------------

loc_126:				; CODE XREF: ROM:02CFj
		set	5, b		; Set flag UPPERCASE
		exx
		ld	a, i
		xor	1
		ld	i, a
		ld	bc, 5

loc_132:				; CODE XREF: ROM:013Aj	ROM:013Dj
		xor	a
		in	a, (0)		; Read flags
		bit	7, a		; Have data sended by FW?
		jp	z, ReadA2Data	; Yes, jump
		djnz	loc_132
		dec	c
		jr	nz, loc_132
		ld	c, 0BEh	; '¥'   ; NASC(">")
		exx
		res	5, b		; Clear	flag UPPERCASE
		bit	3, b		; We have RAM?
		jp	nz, TestAndPutInBuffer ; Yes, jump

loc_149:				; CODE XREF: ROM:0189j	ROM:02E8j
		exx
		ld	a, c

loc_14B:				; CODE XREF: ROM:0433j	ROM:04F2j ...
		exx
		bit	2, c		; Force	clean BIT7?
		jr	nz, loc_154	; Yes, jump
		bit	0, c		; BIT7 enabled?
		jr	nz, loc_156	; Yes, jump

loc_154:				; CODE XREF: ROM:014Ej
		and	7Fh ; ''

loc_156:				; CODE XREF: ROM:006Ej	ROM:0152j
		exx
		ld	c, a

loc_158:				; CODE XREF: ROM:015Dj	ROM:090Fj
		xor	a
		in	a, (0)		; Read flags
		bit	6, a		; Bit 6	= 1 => Busy
		jr	z, loc_158
		ld	a, c
		ld	(RESET), a	; Latch	LPT data
		ld	a, (4000h)	; Pulse	LPT_STROBE
		jp	loc_54
; ---------------------------------------------------------------------------

loc_169:				; CODE XREF: ROM:02D4j
		set	4, c		; Set flag NOACCENT
		exx
		ld	a, i
		xor	1
		ld	i, a
		ld	bc, 5

loc_175:				; CODE XREF: ROM:017Dj	ROM:0180j
		xor	a
		in	a, (0)		; Read flags
		bit	7, a		; Have data sended by FW?
		jp	z, ReadA2Data	; Yes, jump
		djnz	loc_175
		dec	c
		jr	nz, loc_175
		ld	c, 0BCh	; '╝'   ; NASC("<")
		exx
		res	4, c		; Clear	flag NOACCENT
		bit	3, b		; We have RAM?
		jp	z, loc_149	; No, jump
		jp	TestAndPutInBuffer
; ---------------------------------------------------------------------------

loc_18F:				; CODE XREF: ROM:0288j	ROM:02AEj
		bit	2, b		; Buffer full?
		jr	z, loc_1D3	; No, jump
		exx
		ld	b, 2

loc_196:				; CODE XREF: ROM:01A1j	ROM:01A9j ...
		xor	a
		in	a, (0)		; Read flags
		bit	6, a		; Bit 6	= 1 => Busy
		jr	nz, loc_1AB
		ld	a, r
		cp	8
		jr	nc, loc_196
		ld	a, i
		xor	1
		ld	i, a
		jr	loc_196
; ---------------------------------------------------------------------------

loc_1AB:				; CODE XREF: ROM:019Bj
		exx
		bit	4, b		; We have RAM64?
		jr	z, loc_1E4	; No, jump
		bit	6, b		; Is second page of RAM?
		ld	(6000h), a	; Clear	FF_HIGH32K
		jr	z, loc_1BA	; No, jump
		ld	(6800h), a	; Set FF_HIGH32K

loc_1BA:				; CODE XREF: ROM:01B5j
		exx
		ld	a, (hl)
		ld	(RESET), a	; Latch	LPT data
		ld	(4000h), a	; Pulse	LPT_STROBE
		inc	hl
		ld	a, h
		or	a		; HL overlapped	to 0000?
		jr	nz, loc_1D0	; No, jump
		ld	hl, 8000h	; Reset	RAM address
		exx
		ld	a, b
		xor	40h ; '@'       ; Invert bit 6 of B (Toggle RAM page)
		ld	b, a
		exx

loc_1D0:				; CODE XREF: ROM:01C5j	ROM:01F1j ...
		djnz	loc_196
		exx

loc_1D3:				; CODE XREF: ROM:0191j
		ld	a, l
		bit	2, c		; Force	clean BIT7?
		jr	nz, loc_1DC	; Yes, jump
		bit	0, c		; BIT7 enabled?
		jr	nz, loc_1DE	; Yes, jump

loc_1DC:				; CODE XREF: ROM:01D6j
		and	7Fh ; ''

loc_1DE:				; CODE XREF: ROM:01DAj
		ld	(iy+0),	a
		jp	loc_5CD
; ---------------------------------------------------------------------------

loc_1E4:				; CODE XREF: ROM:01AEj
		exx
		ld	a, (hl)
		ld	(RESET), a	; Latch	LPT data
		ld	(4000h), a	; Pulse	LPT_STROBE
		inc	hl
		ld	a, h
		xor	0C0h ; '└'      ; HL arrived $C000?
		or	a
		jp	nz, loc_1D0	; No, jump
		ld	hl, 8000h	; Yes, reset address
		jp	loc_1D0
; ---------------------------------------------------------------------------

loc_1FA:				; CODE XREF: ROM:0123j
		exx
		ld	a, i
		xor	1
		ld	i, a
		xor	a
		in	a, (0)		; Read flags
		jp	loc_39F
; ---------------------------------------------------------------------------

ReadA2Data:				; CODE XREF: ROM:005Bj	ROM:0137j ...
		jp	loc_A12		; Test if MODE key is changing?
					; The MODE key is used to clear	Buffer
; ---------------------------------------------------------------------------

loc_20A:				; CODE XREF: ROM:0A21j
		ld	a, (7000h)	; Read data sended by Apple2
		ld	c, a
		ld	(5000h), a	; Clear	FLAG_FW
		xor	a
		in	a, (0)		; Read flags
		bit	5, a		; Bit 5	= MODE key
		rla			; Bit 7	(Busy/ACK) to Carry
		ld	a, c
		exx
		ld	l, a
		jp	c, loc_69	; If LPT not busy, jump
		ld	(5000h), a	; Clear	FLAG_FW
		jr	z, MODE_mode	; MODE mode enabled
		bit	3, c		; ABICOMP enabled?
		jp	z, loc_2D7	; No, jump

MODE_mode:				; CODE XREF: ROM:loc_69j ROM:0220j
		and	7Fh ; ''       ; Clear bit 7
		cp	40h ; '@'       ; á
		jp	z, loc_83C
		cp	60h ; '`'       ; é
		jp	z, loc_884
		cp	7Bh ; '{'       ; í
		jp	z, loc_8A2
		cp	7Eh ; '~'       ; ó
		jp	z, loc_8C0
		cp	7Ch ; '|'       ; ú
		jp	z, loc_8DE
		cp	5Fh ; '_'       ; à
		jp	z, loc_7F9
		cp	5Bh ; '['       ; ã
		jp	z, loc_7DB
		cp	23h ; '#'       ; õ
		jp	z, loc_798
		cp	5Ch ; '\'       ; â
		jp	z, loc_77A
		cp	26h ; '&'       ; ê
		jp	z, loc_75C
		cp	7Dh ; '}'       ; ô
		jp	z, loc_719
		cp	5Dh ; ']'       ; ç
		jp	z, loc_4B3
		cp	3Fh ; '?'       ; ?
		jp	z, loc_9C2
		cp	25h ; '%'       ; %
		jp	z, loc_9D2
		cp	21h ; '!'       ; !
		jp	z, loc_9E2
		cp	3Bh ; ';'       ; ;
		jp	z, loc_9F2
		cp	3Ah ; ':'       ; :
		jp	z, loc_A02
		bit	4, c		; Check	flag NOACCENT
		jr	z, loc_2A4	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		ld	l, 0BCh	; '╝'   ; NASC("<")
		bit	3, b		; We have RAM?
		jp	nz, loc_18F	; Yes, jump

loc_28B:				; CODE XREF: ROM:0290j
		xor	a
		in	a, (0)		; Read flags
		bit	6, a		; Bit 6	= 1 => Busy
		jr	z, loc_28B
		ld	a, 0BCh	; '╝'   ; NASC("<")
		bit	2, c		; Force	clean BIT7?
		jr	nz, loc_29C	; Yes, jump
		bit	0, c		; BIT7 enabled?
		jr	nz, loc_29E	; Yes, jump

loc_29C:				; CODE XREF: ROM:0296j
		and	7Fh ; ''

loc_29E:				; CODE XREF: ROM:029Aj
		ld	(RESET), a	; Latch	LPT data
		ld	a, (4000h)	; Pulse	LPT_STROBE

loc_2A4:				; CODE XREF: ROM:0280j	ROM:0684j ...
		bit	5, b		; Is UPPERCASE?
		jr	z, loc_2CA	; No, jump
		res	5, b		; Clear	flag Uppercase
		ld	l, 0BEh	; '¥'   ; NASC(">")
		bit	3, b		; We have RAM?
		jp	nz, loc_18F	; Yes, jump

loc_2B1:				; CODE XREF: ROM:02B6j
		xor	a
		in	a, (0)		; Read flags
		bit	6, a		; Bit 6	= 1 => Busy
		jr	z, loc_2B1
		ld	a, 0BEh	; '¥'   ; NASC(">")
		bit	2, c		; Force	clean BIT7?
		jr	nz, loc_2C2	; Yes, jump
		bit	0, c		; BIT7 enabled?
		jr	nz, loc_2C4	; Yes, jump

loc_2C2:				; CODE XREF: ROM:02BCj
		and	7Fh ; ''

loc_2C4:				; CODE XREF: ROM:02C0j
		ld	(RESET), a	; Latch	LPT data
		ld	a, (4000h)	; Pulse	LPT_STROBE

loc_2CA:				; CODE XREF: ROM:02A6j	ROM:068Bj
		ld	a, l
		and	7Fh ; ''
		cp	3Eh ; '>'       ; Is UPPERCASE indicator?
		jp	z, loc_126	; Yes, jump
		cp	3Ch ; '<'       ; Is NOACCENT indicator?
		jp	z, loc_169	; Yes, jump

loc_2D7:				; CODE XREF: ROM:0224j
		and	7Fh ; ''       ; Clear bit 7
		cp	0Dh		; Is CR?
		jp	z, SetCRFlag	; Yes, jump
		cp	20h ; ' '       ; Is < 32 (control code)?
		jr	c, loc_2EE	; Yes, jump
		bit	0, b		; Check	flag INTFCTRLCODE
		jr	nz, loc_308	; Yes, jump

loc_2E6:				; CODE XREF: ROM:02FCj	ROM:0306j ...
		bit	3, b		; We have RAM?
		jp	z, loc_149	; No, jump
		jp	TestAndPutInBuffer
; ---------------------------------------------------------------------------

loc_2EE:				; CODE XREF: ROM:02E0j
		cp	h		; Is Interface Control Code?
		jr	nz, loc_2FA	; No, jump
		bit	0, b		; There	is a previous Interface	Control	Code?
		jr	nz, loc_304	; Yes, jump
		set	0, b		; Set flag INTFCTRLCODE
		jp	loc_3CF
; ---------------------------------------------------------------------------

loc_2FA:				; CODE XREF: ROM:02EFj
		bit	0, b		; Check	flag INTFCTRLCODE
		jr	z, loc_2E6	; No, jump
		res	0, b		; Clear	flag INTFCTRLCODE
		ld	h, a		; Replace Interface Control Code
		jp	loc_3CF
; ---------------------------------------------------------------------------

loc_304:				; CODE XREF: ROM:02F3j
		res	0, b		; Clear	flag INTFCTRLCODE
		jr	loc_2E6
; ---------------------------------------------------------------------------

loc_308:				; CODE XREF: ROM:02E4j
		cp	':'             ; Char is >= ':'?
		jr	nc, loc_311	; Yes, jump
		cp	'0'             ; Char is >= '0'?
		jp	nc, loc_3CF	; Yes, jump

loc_311:				; CODE XREF: ROM:030Aj
		res	0, b		; Clear	flag INTFCTRLCODE
		cp	49h ; 'I'       ; Enable 40-col video and LF?
		jp	z, loc_3CF	; Yes, jump
		cp	4Eh ; 'N'       ; Line length?
		jp	z, loc_3CF	; Yes, jump
		cp	41h ; 'A'       ; Enable AUTO-LF?
		jr	z, loc_348	; Yes, jump
		cp	4Bh ; 'K'       ; Disable AUTO-LF?
		jr	z, loc_34D	; Yes, jump
		cp	52h ; 'R'       ; Clear buffer?
		jr	z, loc_342	; Yes, jump
		cp	4Dh ; 'M'       ; Toggle NOACCENT?
		jr	z, loc_35E	; Yes, jump
		cp	50h ; 'P'       ; Toggle ABICOMP?
		jr	z, loc_36C	; Yes, jump
		cp	48h ; 'H'       ; Enable bit7?
		jr	z, loc_352	; Yes, jump
		cp	58h ; 'X'       ; Disable bit7?
		jr	z, loc_357	; Yes, jump
		cp	5Ah ; 'Z'       ; Disable interpretation of Interface Command Codes?
		jr	z, loc_37E	; Yes, jump
		cp	40h ; '@'       ; Master reset?
		jr	nz, loc_2E6	; No, jump

loc_341:				; CODE XREF: ROM:083Ej
		ld	d, a		; Master reset

loc_342:				; CODE XREF: ROM:0327j	ROM:0A47j
		exx
		ld	a, 80h ; 'Ç'    ; Reset buffer
		jp	loc_E
; ---------------------------------------------------------------------------

loc_348:				; CODE XREF: ROM:031Fj
		set	7, b		; Enable AUTO-LF
		jp	loc_3CF
; ---------------------------------------------------------------------------

loc_34D:				; CODE XREF: ROM:0323j
		res	7, b		; Disable AUTO-LF
		jp	loc_3CF
; ---------------------------------------------------------------------------

loc_352:				; CODE XREF: ROM:0333j
		set	0, c		; Enable BIT7
		jp	loc_3CF
; ---------------------------------------------------------------------------

loc_357:				; CODE XREF: ROM:0337j
		res	0, c		; Disable BIT7
		res	2, c		; No force clean BIT7
		jp	loc_3CF
; ---------------------------------------------------------------------------

loc_35E:				; CODE XREF: ROM:032Bj
		ld	a, c
		xor	8		; Invert bit 4 of C: Toggle NOACCENT
		ld	c, a
		bit	3, c		; ABICOMP enabled?
		jp	nz, loc_3CF	; Yes, jump
		res	2, c		; No force clean BIT7
		jp	loc_3CF
; ---------------------------------------------------------------------------

loc_36C:				; CODE XREF: ROM:032Fj
		ld	a, c
		xor	4		; Invert bit 3 of C: Toggle ABICOMP
		ld	c, a
		res	0, c		; Disable BIT7
		bit	2, c		; Force	clean BIT7?
		jp	z, loc_3CF	; No, jump
		set	3, c		; Set ABICOMP flag
		set	0, c		; Enable BIT7
		jp	loc_3CF
; ---------------------------------------------------------------------------

loc_37E:				; CODE XREF: ROM:033Bj
		set	7, h		; Disable interpretation of Interface Control Codes permanently
		ld	d, a
		jp	loc_3CF
; ---------------------------------------------------------------------------

loc_384:				; CODE XREF: ROM:00EBj
		bit	1, b		; Is second page of RAM?
		jp	nz, loc_113	; Yes, jump

loc_389:				; CODE XREF: ROM:00F2j
		exx

loc_38A:				; CODE XREF: ROM:0117j	ROM:011Dj ...
		ld	a, i
		xor	1
		ld	b, 0
		ld	i, a

loc_392:				; CODE XREF: ROM:03A1j
		xor	a
		in	a, (0)		; Read flags
		bit	7, a		; Have data sended by FW?
		jp	z, ReadA2Data	; Yes, jump
		inc	b
		bit	4, b
		jr	nz, loc_38A

loc_39F:				; CODE XREF: ROM:0204j
		bit	6, a		; Bit 6	= 1 => Busy
		jr	z, loc_392
		jp	loc_A24
; ---------------------------------------------------------------------------

loc_3A6:				; CODE XREF: ROM:0A52j
		exx
		res	2, b		; Reset	Buffer Full flag
		bit	4, b		; We have RAM64?
		jp	z, loc_3F0	; No, jump
		bit	6, b		; Is second page of RAM?
		ld	(6000h), a	; Clear	FF_HIGH32K
		jr	z, loc_3B8	; No, jump
		ld	(6800h), a	; Set FF_HIGH32K

loc_3B8:				; CODE XREF: ROM:03B3j
		exx
		ld	a, (hl)
		ld	(RESET), a	; Latch	LPT data
		ld	(4000h), a	; Pulse	LPT_STROBE
		inc	hl
		ld	a, h		; RAM address overlapped to 0000?
		or	a
		exx
		ld	a, b
		jr	nz, loc_3CF	; No overlapped, jump
		exx
		ld	hl, 8000h	; Overlapped, reset RAM	address
		xor	40h ; '@'       ; And invert bit 6 of B
		exx
		ld	b, a

loc_3CF:				; CODE XREF: ROM:02F7j	ROM:0301j ...
		bit	1, b		; Is second page of RAM?
		jr	nz, loc_3E8	; Yes, jump
		bit	6, b		; Is second page of RAM?
		exx
		jp	nz, loc_38A	; Yes, jump

loc_3D9:				; CODE XREF: ROM:03EEj	ROM:03FDj ...
		ld	a, yh		; Check	if write and read buffer point is the same
		cp	h
		jp	nz, loc_38A	; Not, jump
		ld	a, yl
		cp	l
		jp	nz, loc_38A	; Not, jump
		jp	loc_54		; Is the same, jump
; ---------------------------------------------------------------------------

loc_3E8:				; CODE XREF: ROM:03D1j
		bit	6, b		; Is second page of RAM?
		exx
		jp	z, loc_38A	; No, jump
		jr	loc_3D9
; ---------------------------------------------------------------------------

loc_3F0:				; CODE XREF: ROM:03ABj
		exx
		ld	a, (hl)
		ld	(RESET), a	; Latch	LPT data
		ld	(4000h), a	; Pulse	LPT_STROBE
		inc	hl
		ld	a, h
		xor	0C0h ; '└'
		or	a
		jr	nz, loc_3D9
		ld	hl, 8000h
		jp	loc_3D9
; ---------------------------------------------------------------------------

SetCRFlag:				; CODE XREF: ROM:02DBj
		bit	0, b		; Check	flag INTFCTRLCODE
		res	0, b		; Clear	flag INTFCTRLCODE
		jp	nz, loc_3CF	; Yes, jump
		bit	7, b		; AUTO-LF enabled?
		jp	z, loc_2E6	; No, jump
		bit	3, b		; We have RAM?
		jr	nz, loc_436	; Yes, jump
		ld	a, 8Dh ; 'ì'    ; Produces an adicional CR
		bit	2, c		; Force	clean BIT7?
		jr	nz, loc_41F	; Yes, jump
		bit	0, c		; BIT7 enabled?
		jr	nz, loc_421	; Yes, jump

loc_41F:				; CODE XREF: ROM:0419j
		and	7Fh ; ''

loc_421:				; CODE XREF: ROM:041Dj
		exx
		ld	c, a

loc_423:				; CODE XREF: ROM:0428j
		xor	a
		in	a, (0)		; Read flags
		bit	6, a		; Bit 6	= 1 => Busy
		jr	z, loc_423
		ld	a, c
		ld	(RESET), a	; Latch	LPT data
		ld	a, (4000h)	; Pulse	LPT_STROBE
		ld	a, 8Ah ; 'è'
		jp	loc_14B
; ---------------------------------------------------------------------------

loc_436:				; CODE XREF: ROM:0413j
		bit	2, b		; Buffer full?
		jr	z, loc_47B	; No, jump
		exx
		ld	b, 2

loc_43D:				; CODE XREF: ROM:0448j	ROM:0450j ...
		xor	a
		in	a, (0)		; Read flags
		bit	6, a		; Bit 6	= 1 => Busy
		jr	nz, loc_452
		ld	a, r
		cp	8
		jr	nc, loc_43D
		ld	a, i
		xor	1
		ld	i, a
		jr	loc_43D
; ---------------------------------------------------------------------------

loc_452:				; CODE XREF: ROM:0442j
		exx
		bit	4, b		; We have RAM64?
		jp	z, loc_49D	; No, jump
		bit	6, b		; Is second page of RAM?
		ld	(6000h), a	; Clear	FF_HIGH32K
		jr	z, loc_462	; No, jump
		ld	(6800h), a	; Set FF_HIGH32K

loc_462:				; CODE XREF: ROM:045Dj
		exx
		ld	a, (hl)
		ld	(RESET), a	; Latch	LPT data
		ld	(4000h), a	; Pulse	LPT_STROBE
		inc	hl
		ld	a, h		; RAM address overlapped to 0000?
		or	a
		jr	nz, loc_478	; No, jump
		ld	hl, 8000h	; Reset	Buffer address
		exx
		ld	a, b
		xor	40h ; '@'       ; Invert bit 6 of B
		ld	b, a
		exx

loc_478:				; CODE XREF: ROM:046Dj	ROM:04AAj ...
		djnz	loc_43D
		exx

loc_47B:				; CODE XREF: ROM:0438j
		ld	a, 8Dh ; 'ì'    ; NASC(CR)
		bit	1, b		; Is second page of RAM?
		ld	(6000h), a	; Clear	FF_HIGH32K
		jr	z, loc_487	; No, jump
		ld	(6800h), a	; Set FF_HIGH32K

loc_487:				; CODE XREF: ROM:0482j
		bit	2, c		; Force	clean BIT7?
		jr	nz, loc_48F	; Yes, jump
		bit	0, c		; BIT7 enabled?
		jr	nz, loc_491	; Yes, jump

loc_48F:				; CODE XREF: ROM:0489j
		and	7Fh ; ''

loc_491:				; CODE XREF: ROM:048Dj
		ld	(iy+0),	a
		ld	a, i
		xor	1
		ld	i, a
		jp	loc_5CD
; ---------------------------------------------------------------------------

loc_49D:				; CODE XREF: ROM:0455j
		exx
		ld	a, (hl)
		ld	(RESET), a	; Latch	LPT data
		ld	(4000h), a	; Pulse	LPT_STROBE
		inc	hl
		ld	a, h
		xor	0C0h ; '└'      ; RAM address arrived to C000?
		or	a
		jp	nz, loc_478	; No, jump
		ld	hl, 8000h	; Reset	Buffer Address
		jp	loc_478
; ---------------------------------------------------------------------------

loc_4B3:				; CODE XREF: ROM:0262j
		ld	a, b
		bit	4, c		; Check	flag NOACCENT
		jr	z, loc_4BD	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		jp	loc_2E6
; ---------------------------------------------------------------------------

loc_4BD:				; CODE XREF: ROM:04B6j
		bit	2, c		; Force	clean BIT7?
		jp	nz, loc_8FC	; Yes, jump
		bit	5, b		; Is UPPERCASE?
		res	5, b		; Clear	UPPERCASE flag
		exx
		ld	c, 0E3h	; 'Ò'
		jp	z, loc_4CE	; No, jump
		ld	c, 0C3h	; '├'

loc_4CE:				; CODE XREF: ROM:04C9j
		bit	3, a
		jr	nz, loc_4F5
		ld	b, 2

loc_4D4:				; CODE XREF: ROM:04EEj
		ld	a, c
		exx
		bit	0, c		; BIT7 enabled?
		exx
		jr	nz, loc_4DE	; Yes, jump
		and	7Fh ; ''
		ld	c, a

loc_4DE:				; CODE XREF: ROM:04D9j	ROM:04E3j
		xor	a
		in	a, (0)		; Read flags
		bit	6, a		; Bit 6	= 1 => Busy
		jr	z, loc_4DE
		ld	a, c
		ld	(RESET), a	; Latch	LPT data
		ld	a, (4000h)	; Pulse	LPT_STROBE
		ld	c, 88h ; 'ê'    ; NASC(BACKSPACE)
		djnz	loc_4D4
		ld	a, 0ACh	; '¼'   ; NASC(",")?
		jp	loc_14B
; ---------------------------------------------------------------------------

loc_4F5:				; CODE XREF: ROM:04D0j	ROM:0736j ...
		bit	2, a
		jp	z, loc_539
		ld	b, 3

loc_4FC:				; CODE XREF: ROM:0507j	ROM:050Fj ...
		xor	a
		in	a, (0)		; Read flags
		bit	6, a		; Bit 6	= 1 => Busy
		jr	nz, loc_511
		ld	a, r
		cp	8
		jr	nc, loc_4FC
		ld	a, i
		xor	1
		ld	i, a
		jr	loc_4FC
; ---------------------------------------------------------------------------

loc_511:				; CODE XREF: ROM:0501j
		exx
		bit	4, b		; We have RAM64?
		jp	z, loc_6A7	; No, jump
		bit	6, b		; Is second page of RAM?
		ld	(6000h), a	; Clear	FF_HIGH32K
		jr	z, loc_521	; No, jump
		ld	(6800h), a	; Set FF_HIGH32K

loc_521:				; CODE XREF: ROM:051Cj
		exx
		ld	a, (hl)
		ld	(RESET), a	; Latch	LPT data
		ld	(4000h), a	; Pulse	LPT_STROBE
		inc	hl
		ld	a, h		; RAM address overlapped?
		or	a
		jr	nz, loc_537	; No, jump
		ld	hl, 8000h	; Yes, reset RAM address
		exx
		ld	a, b
		xor	40h ; '@'       ; Invert bit 6 of B
		ld	b, a
		exx

loc_537:				; CODE XREF: ROM:052Cj	ROM:06B4j ...
		djnz	loc_4FC

loc_539:				; CODE XREF: ROM:04F7j
		ld	a, i
		xor	1
		ld	i, a
		ld	a, c
		exx
		bit	1, b		; Is second page of RAM?
		ld	(TestAndPutInBuffer), a
		jr	z, loc_54B	; No, jump
		ld	(loc_D0), a

loc_54B:				; CODE XREF: ROM:0546j
		bit	0, c		; BIT7 enabled?
		jr	nz, loc_551	; Yes, jump
		and	7Fh ; ''

loc_551:				; CODE XREF: ROM:054Dj
		ld	(iy+0),	a
		inc	iy
		bit	4, b		; We have RAM64?
		ld	a, yh
		jp	z, loc_6BD	; No, jump
		or	a		; RAM address overlapped to 0000?
		jr	nz, loc_568	; No, jump
		ld	iy, 8000h	; Reset	RAM Address
		ld	a, b
		xor	2		; Invert bit 1
		ld	b, a

loc_568:				; CODE XREF: ROM:055Ej	ROM:06C0j ...
		bit	6, b		; Is second page of RAM?
		jp	nz, loc_6D7	; Yes, jump
		bit	1, b		; Is second page of RAM?
		jp	nz, loc_5C6	; Yes, jump

loc_572:				; CODE XREF: ROM:06D9j
		ld	a, yh
		exx
		cp	h
		jp	nz, loc_5BE
		ld	a, yl
		cp	l
		jp	nz, loc_5BE
		ld	b, 2

loc_581:				; CODE XREF: ROM:058Cj	ROM:0594j ...
		xor	a
		in	a, (0)		; Read flags
		bit	6, a		; Bit 6	= 1 => Busy
		jr	nz, loc_596
		ld	a, r
		cp	8
		jr	nc, loc_581
		ld	a, i
		xor	1
		ld	i, a
		jr	loc_581
; ---------------------------------------------------------------------------

loc_596:				; CODE XREF: ROM:0586j
		exx
		bit	4, b		; We have RAM64?
		jp	z, loc_6E2	; No, jump
		bit	6, b		; Is second page of RAM?
		ld	(6000h), a	; Clear	FF_HIGH32K
		jr	z, loc_5A6	; No, jump
		ld	(6800h), a	; Set FF_HIGH32K

loc_5A6:				; CODE XREF: ROM:05A1j
		exx
		ld	a, (hl)
		ld	(RESET), a	; Latch	LPT data
		ld	(4000h), a	; Pulse	LPT_STROBE
		inc	hl
		ld	a, h
		or	a
		jr	nz, loc_5BC
		ld	hl, 8000h
		exx
		ld	a, b
		xor	40h ; '@'
		ld	b, a
		exx

loc_5BC:				; CODE XREF: ROM:05B1j	ROM:06EFj ...
		djnz	loc_581

loc_5BE:				; CODE XREF: ROM:0576j	ROM:057Cj
		exx
		bit	1, b		; Is second page of RAM?
		ld	(TestAndPutInBuffer), a
		jr	z, loc_5C9	; No, jump

loc_5C6:				; CODE XREF: ROM:056Fj
		ld	(loc_D0), a

loc_5C9:				; CODE XREF: ROM:05C4j	ROM:06DFj
		ld	(iy+0),	8

loc_5CD:				; CODE XREF: ROM:01E1j	ROM:049Aj
		inc	iy
		bit	4, b		; We have RAM64?
		ld	a, yh
		jp	z, loc_6CA	; No, jump
		or	a		; RAM address overlapped to 0000?
		jr	nz, loc_5E1	; No, jump
		ld	iy, 8000h	; Reset	RAM Address
		ld	a, b
		xor	2		; Invert bit 1
		ld	b, a

loc_5E1:				; CODE XREF: ROM:05D7j	ROM:06CDj ...
		bit	6, b		; Is second page of RAM?
		jp	nz, loc_6F8	; Yes, jump
		bit	1, b		; Is second page of RAM?
		jp	nz, loc_63B	; Yes, jump

loc_5EB:				; CODE XREF: ROM:06FAj
		ld	a, yh
		exx
		cp	h
		jp	nz, loc_633
		ld	a, yl
		cp	l
		jp	nz, loc_633

loc_5F8:				; CODE XREF: ROM:0603j	ROM:060Bj
		xor	a
		in	a, (0)		; Read flags
		bit	6, a		; Bit 6	= 1 => Busy
		jr	nz, loc_60D
		ld	a, r
		cp	8
		jr	nc, loc_5F8
		ld	a, i
		xor	1
		ld	i, a
		jr	loc_5F8
; ---------------------------------------------------------------------------

loc_60D:				; CODE XREF: ROM:05FDj
		exx
		bit	4, b		; We have RAM64?
		jp	z, loc_703	; No, jump
		bit	6, b		; Is second page of RAM?
		ld	(6000h), a	; Clear	FF_HIGH32K
		jr	z, loc_61D	; No, jump
		ld	(6800h), a	; Set FF_HIGH32K

loc_61D:				; CODE XREF: ROM:0618j
		exx
		ld	a, (hl)
		ld	(RESET), a	; Latch	LPT data
		ld	(4000h), a	; Pulse	LPT_STROBE
		inc	hl
		ld	a, h
		or	a
		jr	nz, loc_633
		ld	hl, 8000h
		exx
		ld	a, b
		xor	40h ; '@'
		ld	b, a
		exx

loc_633:				; CODE XREF: ROM:05EFj	ROM:05F5j ...
		exx
		bit	1, b		; Is second page of RAM?
		ld	(TestAndPutInBuffer), a
		jr	z, loc_63E	; No, jump

loc_63B:				; CODE XREF: ROM:05E8j
		ld	(loc_D0), a

loc_63E:				; CODE XREF: ROM:0639j	ROM:0700j
		ld	a, l
		and	7Fh ; ''       ; Clear bit 7
		cp	0Dh
		jr	z, loc_6A2
		cp	3Ch ; '<'
		jr	z, loc_680
		cp	3Eh ; '>'
		jr	z, loc_687
		cp	40h ; '@'
		jr	z, loc_68E
		cp	60h ; '`'
		jr	z, loc_68E
		cp	7Bh ; '{'
		jr	z, loc_68E
		cp	7Eh ; '~'
		jr	z, loc_68E
		cp	7Ch ; '|'
		jr	z, loc_68E
		cp	5Fh ; '_'
		jr	z, loc_693
		cp	5Bh ; '['
		jr	z, loc_698
		cp	23h ; '#'
		jr	z, loc_698
		cp	5Ch ; '\'
		jr	z, loc_69D
		cp	26h ; '&'
		jr	z, loc_69D
		cp	7Dh ; '}'
		jr	z, loc_69D
		ld	(iy+0),	2Ch ; ','
		jp	loc_D0
; ---------------------------------------------------------------------------

loc_680:				; CODE XREF: ROM:0647j
		exx
		ld	a, c
		exx
		ld	l, a
		jp	loc_2A4
; ---------------------------------------------------------------------------

loc_687:				; CODE XREF: ROM:064Bj
		exx
		ld	a, c
		exx
		ld	l, a
		jp	loc_2CA
; ---------------------------------------------------------------------------

loc_68E:				; CODE XREF: ROM:064Fj	ROM:0653j ...
		ld	a, 0A7h	; 'º'
		jp	loc_C7
; ---------------------------------------------------------------------------

loc_693:				; CODE XREF: ROM:0663j
		ld	a, 0E0h	; 'Ó'
		jp	loc_C7
; ---------------------------------------------------------------------------

loc_698:				; CODE XREF: ROM:0667j	ROM:066Bj
		ld	a, 0FEh	; '■'
		jp	loc_C7
; ---------------------------------------------------------------------------

loc_69D:				; CODE XREF: ROM:066Fj	ROM:0673j ...
		ld	a, 0DEh	; 'Ì'
		jp	loc_C7
; ---------------------------------------------------------------------------

loc_6A2:				; CODE XREF: ROM:0643j
		ld	a, 8Ah ; 'è'
		jp	loc_BD
; ---------------------------------------------------------------------------

loc_6A7:				; CODE XREF: ROM:0514j
		exx
		ld	a, (hl)
		ld	(RESET), a	; Latch	LPT data
		ld	(4000h), a	; Pulse	LPT_STROBE
		inc	hl
		ld	a, h
		xor	0C0h ; '└'
		or	a
		jp	nz, loc_537
		ld	hl, 8000h
		jp	loc_537
; ---------------------------------------------------------------------------

loc_6BD:				; CODE XREF: ROM:055Aj
		xor	0C0h ; '└'
		or	a
		jp	nz, loc_568
		ld	iy, 8000h
		jp	loc_568
; ---------------------------------------------------------------------------

loc_6CA:				; CODE XREF: ROM:05D3j
		xor	0C0h ; '└'
		or	a
		jp	nz, loc_5E1
		ld	iy, 8000h
		jp	loc_5E1
; ---------------------------------------------------------------------------

loc_6D7:				; CODE XREF: ROM:056Aj
		bit	1, b		; Is second page of RAM?
		jp	nz, loc_572	; Yes, jump
		ld	(TestAndPutInBuffer), a
		jp	loc_5C9
; ---------------------------------------------------------------------------

loc_6E2:				; CODE XREF: ROM:0599j
		exx
		ld	a, (hl)
		ld	(RESET), a	; Latch	LPT data
		ld	(4000h), a	; Pulse	LPT_STROBE
		inc	hl
		ld	a, h
		xor	0C0h ; '└'
		or	a
		jp	nz, loc_5BC
		ld	hl, 8000h
		jp	loc_5BC
; ---------------------------------------------------------------------------

loc_6F8:				; CODE XREF: ROM:05E3j
		bit	1, b		; Is second page of RAM?
		jp	nz, loc_5EB	; Yes, jump
		ld	(TestAndPutInBuffer), a
		jp	loc_63E
; ---------------------------------------------------------------------------

loc_703:				; CODE XREF: ROM:0610j
		exx
		ld	a, (hl)
		ld	(RESET), a	; Latch	LPT data
		ld	(4000h), a	; Pulse	LPT_STROBE
		inc	hl
		ld	a, h
		xor	0C0h ; '└'
		or	a
		jp	nz, loc_633
		ld	hl, 8000h
		jp	loc_633
; ---------------------------------------------------------------------------

loc_719:				; CODE XREF: ROM:025Dj
		ld	a, b
		bit	4, c		; Check	flag NOACCENT
		jr	z, loc_723	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		jp	loc_2E6
; ---------------------------------------------------------------------------

loc_723:				; CODE XREF: ROM:071Cj
		bit	2, c		; Force	clean BIT7?
		jp	nz, loc_912	; Yes, jump
		bit	5, a		; UPPERCASE flag enabled? (B is	copied to A)
		res	5, b		; Reset	UPPERCASE flag
		exx
		ld	c, 0EFh	; '´'
		jp	z, loc_734	; No UPPERCASE,	jump
		ld	c, 0CFh	; '¤'

loc_734:				; CODE XREF: ROM:072Fj	ROM:0772j ...
		bit	3, a
		jp	nz, loc_4F5
		ld	b, 2

loc_73B:				; CODE XREF: ROM:0755j
		ld	a, c
		exx
		bit	0, c		; BIT7 enabled?
		exx
		jr	nz, loc_745	; Yes, jump
		and	7Fh ; ''
		ld	c, a

loc_745:				; CODE XREF: ROM:0740j	ROM:074Aj
		xor	a
		in	a, (0)		; Read flags
		bit	6, a		; Bit 6	= 1 => Busy
		jr	z, loc_745
		ld	a, c
		ld	(RESET), a	; Latch	LPT data
		ld	a, (4000h)	; Pulse	LPT_STROBE
		ld	c, 88h ; 'ê'
		djnz	loc_73B
		ld	a, 0DEh	; 'Ì'
		jp	loc_14B
; ---------------------------------------------------------------------------

loc_75C:				; CODE XREF: ROM:0258j
		ld	a, b
		bit	4, c		; Check	flag NOACCENT
		jr	z, loc_766	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		jp	loc_2E6
; ---------------------------------------------------------------------------

loc_766:				; CODE XREF: ROM:075Fj
		bit	2, c		; Force	clean BIT7?
		jp	nz, loc_922	; Yes, jump
		bit	5, a		; UPPERCASE flag enabled? (B is	copied to A)
		res	5, b		; Reset	UPPERCASE flag
		exx
		ld	c, 0E5h	; 'Õ'
		jp	z, loc_734	; No UPPERCASE,	jump
		ld	c, 0C5h	; '┼'
		jp	loc_734
; ---------------------------------------------------------------------------

loc_77A:				; CODE XREF: ROM:0253j
		ld	a, b
		bit	4, c		; Check	flag NOACCENT
		jr	z, loc_784	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		jp	loc_2E6
; ---------------------------------------------------------------------------

loc_784:				; CODE XREF: ROM:077Dj
		bit	2, c		; Force	clean BIT7?
		jp	nz, loc_932
		bit	5, a		; UPPERCASE flag enabled? (B is	copied to A)
		res	5, b		; Reset	UPPERCASE flag
		exx
		ld	c, 0E1h	; 'ß'
		jp	z, loc_734	; No UPPERCASE,	jump
		ld	c, 0C1h	; '┴'
		jp	loc_734
; ---------------------------------------------------------------------------

loc_798:				; CODE XREF: ROM:024Ej
		ld	a, b
		bit	4, c		; Check	flag NOACCENT
		jr	z, loc_7A2	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		jp	loc_2E6
; ---------------------------------------------------------------------------

loc_7A2:				; CODE XREF: ROM:079Bj
		bit	2, c		; Force	clean BIT7?
		jp	nz, loc_942	; Yes, jump
		bit	5, a		; UPPERCASE flag enabled? (B is	copied to A)
		res	5, b		; Reset	UPPERCASE flag
		exx
		ld	c, 0EFh	; '´'
		jp	z, loc_7B3	; No UPPERCASE,	jump
		ld	c, 0CFh	; '¤'

loc_7B3:				; CODE XREF: ROM:07AEj	ROM:07F1j ...
		bit	3, a
		jp	nz, loc_4F5
		ld	b, 2

loc_7BA:				; CODE XREF: ROM:07D4j
		ld	a, c
		exx
		bit	0, c		; BIT7 enabled?
		exx
		jr	nz, loc_7C4	; Yes, jump
		and	7Fh ; ''
		ld	c, a

loc_7C4:				; CODE XREF: ROM:07BFj	ROM:07C9j
		xor	a
		in	a, (0)		; Read flags
		bit	6, a		; Bit 6	= 1 => Busy
		jr	z, loc_7C4
		ld	a, c
		ld	(RESET), a	; Latch	LPT data
		ld	a, (4000h)	; Pulse	LPT_STROBE
		ld	c, 88h ; 'ê'
		djnz	loc_7BA
		ld	a, 0FEh	; '■'
		jp	loc_14B
; ---------------------------------------------------------------------------

loc_7DB:				; CODE XREF: ROM:0249j
		ld	a, b
		bit	4, c		; Check	flag NOACCENT
		jr	z, loc_7E5	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		jp	loc_2E6
; ---------------------------------------------------------------------------

loc_7E5:				; CODE XREF: ROM:07DEj
		bit	2, c		; Force	clean BIT7?
		jp	nz, loc_952	; Yes, jump
		bit	5, a		; UPPERCASE flag enabled? (B is	copied to A)
		res	5, b		; Reset	UPPERCASE flag
		exx
		ld	c, 0E1h	; 'ß'
		jp	z, loc_7B3	; No UPPERCASE,	jump
		ld	c, 0C1h	; '┴'
		jp	loc_7B3
; ---------------------------------------------------------------------------

loc_7F9:				; CODE XREF: ROM:0244j
		ld	a, b
		bit	4, c		; Check	flag NOACCENT
		jr	z, loc_803	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		jp	loc_2E6
; ---------------------------------------------------------------------------

loc_803:				; CODE XREF: ROM:07FCj
		bit	2, c		; Force	clean BIT7?
		jp	nz, loc_962	; Yes, jump
		bit	5, a		; UPPERCASE flag enabled? (B is	copied to A)
		res	5, b		; Reset	UPPERCASE flag
		exx
		ld	c, 0E1h	; 'ß'
		jp	z, loc_814	; No UPPERCASE,	jump
		ld	c, 0C1h	; '┴'

loc_814:				; CODE XREF: ROM:080Fj
		bit	3, a
		jp	nz, loc_4F5
		ld	b, 2

loc_81B:				; CODE XREF: ROM:0835j
		ld	a, c
		exx
		bit	0, c		; BIT7 enabled?
		exx
		jr	nz, loc_825	; Yes
		and	7Fh ; ''
		ld	c, a

loc_825:				; CODE XREF: ROM:0820j	ROM:082Aj
		xor	a
		in	a, (0)		; Read flags
		bit	6, a		; Bit 6	= 1 => Busy
		jr	z, loc_825
		ld	a, c
		ld	(RESET), a	; Latch	LPT data
		ld	a, (4000h)	; Pulse	LPT_STROBE
		ld	c, 88h ; 'ê'
		djnz	loc_81B
		ld	a, 0E0h	; 'Ó'
		jp	loc_14B
; ---------------------------------------------------------------------------

loc_83C:				; CODE XREF: ROM:022Bj
		bit	0, b		; Check	flag INTFCTRLCODE
		jp	nz, loc_341	; Yes, jump
		ld	a, b
		bit	4, c		; Check	flag NOACCENT
		jr	z, loc_84B	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		jp	loc_2E6
; ---------------------------------------------------------------------------

loc_84B:				; CODE XREF: ROM:0844j
		bit	2, c		; Force	clean BIT7?
		jp	nz, loc_972	; Yes, jump
		bit	5, a		; UPPERCASE flag enabled? (B is	copied to A)
		res	5, b		; Reset	UPPERCASE flag
		exx
		ld	c, 0E1h	; 'ß'   ; NASC('a')
		jp	z, loc_85C	; No UPPERCASE,	jump
		ld	c, 0C1h	; '┴'   ; NASC('A')

loc_85C:				; CODE XREF: ROM:0857j	ROM:089Aj ...
		bit	3, a
		jp	nz, loc_4F5
		ld	b, 2		; Emit two backspace

loc_863:				; CODE XREF: ROM:087Dj
		ld	a, c
		exx
		bit	0, c		; BIT7 enabled?
		exx
		jr	nz, loc_86D	; Yes, jump
		and	7Fh ; ''
		ld	c, a

loc_86D:				; CODE XREF: ROM:0868j	ROM:0872j
		xor	a
		in	a, (0)		; Read flags
		bit	6, a		; Bit 6	= 1 => Busy
		jr	z, loc_86D
		ld	a, c
		ld	(RESET), a	; Latch	LPT data
		ld	a, (4000h)	; Pulse	LPT_STROBE
		ld	c, 88h ; 'ê'    ; NASC(BS)
		djnz	loc_863
		ld	a, 0A7h	; 'º'   ; NASC("'")
		jp	loc_14B
; ---------------------------------------------------------------------------

loc_884:				; CODE XREF: ROM:0230j
		ld	a, b
		bit	4, c		; Check	flag NOACCENT
		jr	z, loc_88E	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		jp	loc_2E6
; ---------------------------------------------------------------------------

loc_88E:				; CODE XREF: ROM:0887j
		bit	2, c		; Force	clean BIT7?
		jp	nz, loc_982	; Yes, jump
		bit	5, a		; UPPERCASE flag enabled? (B is	copied to A)
		res	5, b		; Reset	UPPERCASE flag
		exx
		ld	c, 0E5h	; 'Õ'   ; NASC('e')
		jp	z, loc_85C	; No UPPERCASE,	jump
		ld	c, 0C5h	; '┼'   ; NASC('E')
		jp	loc_85C
; ---------------------------------------------------------------------------

loc_8A2:				; CODE XREF: ROM:0235j
		ld	a, b
		bit	4, c		; Check	flag NOACCENT
		jr	z, loc_8AC	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		jp	loc_2E6
; ---------------------------------------------------------------------------

loc_8AC:				; CODE XREF: ROM:08A5j
		bit	2, c		; Force	clean BIT7?
		jp	nz, loc_992	; Yes, jump
		bit	5, a		; UPPERCASE flag enabled? (B is	copied to A)
		res	5, b		; Reset	UPPERCASE flag
		exx
		ld	c, 0E9h	; 'Ú'   ; NASC('i')
		jp	z, loc_85C	; No UPPERCASE,	jump
		ld	c, 0C9h	; '╔'   ; NASC('I')
		jp	loc_85C
; ---------------------------------------------------------------------------

loc_8C0:				; CODE XREF: ROM:023Aj
		ld	a, b
		bit	4, c		; Check	flag NOACCENT
		jr	z, loc_8CA	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		jp	loc_2E6
; ---------------------------------------------------------------------------

loc_8CA:				; CODE XREF: ROM:08C3j
		bit	2, c		; Force	clean BIT7?
		jp	nz, loc_9A2	; Yes, jump
		bit	5, a		; UPPERCASE flag enabled? (B is	copied to A)
		res	5, b		; Reset	UPPERCASE flag
		exx
		ld	c, 0EFh	; '´'   ; NASC('o')
		jp	z, loc_85C	; No UPPERCASE,	jump
		ld	c, 0CFh	; '¤'   ; NASC('O')
		jp	loc_85C
; ---------------------------------------------------------------------------

loc_8DE:				; CODE XREF: ROM:023Fj
		ld	a, b
		bit	4, c		; Check	flag NOACCENT
		jr	z, loc_8E8	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		jp	loc_2E6
; ---------------------------------------------------------------------------

loc_8E8:				; CODE XREF: ROM:08E1j
		bit	2, c		; Force	clean BIT7?
		jp	nz, loc_9B2	; Yes, jump
		bit	5, a		; UPPERCASE flag enabled? (B is	copied to A)
		res	5, b		; Reset	UPPERCASE flag
		exx
		ld	c, 0F5h	; '§'   ; NASC('u')
		jp	z, loc_85C	; No UPPERCASE,	jump
		ld	c, 0D5h	; 'ı'   ; NASC('U')
		jp	loc_85C
; ---------------------------------------------------------------------------

loc_8FC:				; CODE XREF: ROM:04BFj
		bit	5, b		; Is UPPERCASE?
		res	5, b		; Reset	UPPERCASE flag
		ld	a, b
		exx
		ld	c, 0C6h	; 'ã'   ; ABICOMP: ç
		jr	z, loc_908	; No Uppercase,	jump
		ld	c, 0A6h	; 'ª'   ; ABICOMP: Ç

loc_908:				; CODE XREF: ROM:0904j	ROM:091Aj ...
		exx
		bit	3, b		; We have RAM?
		jp	nz, IsAscii	; Yes, jump
		exx
		jp	loc_158
; ---------------------------------------------------------------------------

loc_912:				; CODE XREF: ROM:0725j
		bit	5, b		; Is UPPERCASE?
		res	5, b		; Reset	UPPERCASE flag
		ld	a, b
		exx
		ld	c, 0D2h	; 'Ê'   ; ABICOMP: ô
		jp	z, loc_908	; No, jump
		ld	c, 0B2h	; '▓'   ; ABICOMP: Ô
		jp	loc_908
; ---------------------------------------------------------------------------

loc_922:				; CODE XREF: ROM:0768j
		bit	5, b		; Is UPPERCASE?
		res	5, b		; Reset	UPPERCASE flag
		ld	a, b
		exx
		ld	c, 0C9h	; '╔'   ; ABICOMP: ê
		jp	z, loc_908	; No, jump
		ld	c, 0A9h	; '®'   ; ABICOMP: Ê
		jp	loc_908
; ---------------------------------------------------------------------------

loc_932:				; CODE XREF: ROM:0786j
		bit	5, b		; Is UPPERCASE?
		res	5, b		; Reset	UPPERCASE flag
		ld	a, b
		exx
		ld	c, 0C3h	; '├'   ; ABICOMP: â
		jp	z, loc_908	; No, jump
		ld	c, 0A3h	; 'ú'   ; ABICOMP: Â
		jp	loc_908
; ---------------------------------------------------------------------------

loc_942:				; CODE XREF: ROM:07A4j
		bit	5, b		; Is UPPERCASE?
		res	5, b		; Reset	UPPERCASE flag
		ld	a, b
		exx
		ld	c, 0D3h	; 'Ë'   ; ABICOMP: õ
		jp	z, loc_908	; No, jump
		ld	c, 0B3h	; '│'   ; ABICOMP: Õ
		jp	loc_908
; ---------------------------------------------------------------------------

loc_952:				; CODE XREF: ROM:07E7j
		bit	5, b		; Is UPPERCASE?
		res	5, b		; Reset	UPPERCASE flag
		ld	a, b
		exx
		ld	c, 0C4h	; '─'   ; ABICOMP: ã
		jp	z, loc_908	; No, jump
		ld	c, 0A4h	; 'ñ'   ; ABICOMP: Ã
		jp	loc_908
; ---------------------------------------------------------------------------

loc_962:				; CODE XREF: ROM:0805j
		bit	5, b		; Is UPPERCASE?
		res	5, b		; Reset	UPPERCASE flag
		ld	a, b
		exx
		ld	c, 0C1h	; '┴'   ; ABICOMP: à
		jp	z, loc_908	; No
		ld	c, 0A1h	; 'í'   ; ABICOMP: À
		jp	loc_908
; ---------------------------------------------------------------------------

loc_972:				; CODE XREF: ROM:084Dj
		bit	5, b		; Is UPPERCASE?
		res	5, b		; Reset	UPPERCASE flag
		ld	a, b
		exx
		ld	c, 0C2h	; '┬'   ; ABICOMP: á
		jp	z, loc_908	; No
		ld	c, 0A2h	; 'ó'   ; ABICOMP: Á
		jp	loc_908
; ---------------------------------------------------------------------------

loc_982:				; CODE XREF: ROM:0890j
		bit	5, b		; Is UPPERCASE?
		res	5, b		; Reset	UPPERCASE flag
		ld	a, b
		exx
		ld	c, 0C8h	; '╚'   ; ABICOMP: é
		jp	z, loc_908	; No, jump
		ld	c, 0A8h	; '¿'   ; ABICOMP: É
		jp	loc_908
; ---------------------------------------------------------------------------

loc_992:				; CODE XREF: ROM:08AEj
		bit	5, b		; Is UPERCASE?
		res	5, b		; Reset	UPPERCASE flag
		ld	a, b
		exx
		ld	c, 0CCh	; '╠'   ; ABICOMP: í
		jp	z, loc_908	; No
		ld	c, 0ACh	; '¼'   ; ABICOMP: Í
		jp	loc_908
; ---------------------------------------------------------------------------

loc_9A2:				; CODE XREF: ROM:08CCj
		bit	5, b		; Is UPPERCASE?
		res	5, b		; Reset	UPPERCASE flag
		ld	a, b
		exx
		ld	c, 0D1h	; 'Ð'   ; ABICOMP: ó
		jp	z, loc_908	; No, jump
		ld	c, 0B1h	; '▒'   ; ABICOMP: Ó
		jp	loc_908
; ---------------------------------------------------------------------------

loc_9B2:				; CODE XREF: ROM:08EAj
		bit	5, b		; Is UPPERCASE?
		res	5, b		; Reset	UPPERCASE flag
		ld	a, b
		exx
		ld	c, 0D7h	; 'Î'   ; ABICOMP: ú
		jp	z, loc_908	; No, jump
		ld	c, 0B7h	; 'À'   ; ABICOMP: Ú
		jp	loc_908
; ---------------------------------------------------------------------------

loc_9C2:				; CODE XREF: ROM:0267j
		bit	4, c		; Check	flag NOACCENT
		jp	z, loc_2A4	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		set	2, c		; Force	clean BIT7
		ld	a, b
		exx
		ld	c, 0BEh	; '¥'   ; ABICOMP: §
		jp	loc_908
; ---------------------------------------------------------------------------

loc_9D2:				; CODE XREF: ROM:026Cj
		bit	4, c		; Check	flag NOACCENT
		jp	z, loc_2A4	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		set	2, c		; Force	clean BIT7
		ld	a, b
		exx
		ld	c, 0DDh	; '¦'   ; ABICOMP: º
		jp	loc_908
; ---------------------------------------------------------------------------

loc_9E2:				; CODE XREF: ROM:0271j
		bit	4, c		; Check	flag NOACCENT
		jp	z, loc_2A4	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		set	2, c		; Force	clean BIT7
		ld	a, b
		exx
		ld	c, 0DCh	; '▄'   ; ABICOMP: ª
		jp	loc_908
; ---------------------------------------------------------------------------

loc_9F2:				; CODE XREF: ROM:0276j
		bit	4, c		; Check	flag NOACCENT
		jp	z, loc_2A4	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		set	2, c		; Force	clean BIT7
		ld	a, b
		exx
		ld	c, 0D9h	; '┘'   ; ABICOMP: ü
		jp	loc_908
; ---------------------------------------------------------------------------

loc_A02:				; CODE XREF: ROM:027Bj
		bit	4, c		; Check	flag NOACCENT
		jp	z, loc_2A4	; No flag, jump
		res	4, c		; Clear	flag NOACCENT
		set	2, c		; Force	clean BIT7
		ld	a, b
		exx
		ld	c, 0B9h	; '╣'   ; ABICOMP: Ü
		jp	loc_908
; ---------------------------------------------------------------------------

loc_A12:				; CODE XREF: ROM:ReadA2Dataj
		xor	a		; Test if MODE key is changing?
					; The MODE key is used to clear	Buffer
		in	a, (0)		; Read flags
		and	20h ; ' '       ; Isolate bit 5: MODE key
		sla	a		; Shift	bit 5 to bit 6
		exx
		ld	l, a		; Copy MODE key	state on bit 6 of L
		ld	a, c
		and	0BFh ; '┐'      ; Clear bit 6 of C
		or	l		; Copy MODE key	to bit 6 of C
		ld	c, a
		exx
		jp	loc_20A
; ---------------------------------------------------------------------------

loc_A24:				; CODE XREF: ROM:03A3j
		exx
		ld	a, c
		and	40h ; '@'       ; Filter bit 6 of C
		ld	l, a
		xor	a
		in	a, (0)		; Read flags
		and	20h ; ' '       ; Isolate bit 5: MODE key
		sla	a		; Shift	bit 5 to bit 6
		cp	l		; Compare with last MODE flag?
		jr	z, loc_A4B
		ld	l, 80h ; 'Ç'
		xor	a

loc_A36:				; CODE XREF: ROM:0A37j	ROM:0A3Aj
		dec	a
		jr	nz, loc_A36
		dec	l
		jr	nz, loc_A36
		in	a, (0)		; Read flags
		and	20h ; ' '
		sla	a
		ld	l, a
		ld	a, c
		and	40h ; '@'
		cp	l
		jp	z, loc_342
		ld	a, l

loc_A4B:				; CODE XREF: ROM:0A31j
		ld	l, a
		ld	a, c
		and	0BFh ; '┐'
		or	l
		ld	c, a
		exx
		jp	loc_3A6
; ---------------------------------------------------------------------------
		db 0A4h, 2, 0CBh, 0A1h,	0CBh, 0D1h, 78h, 0D9h, 0Eh, 0DDh, 0C3h,	8, 9, 0CBh, 61h, 0CAh ;	Dead code
		db 0A4h, 2, 0CBh, 0A1h,	0CBh, 0D1h, 78h, 0D9h, 0Eh, 0DCh, 0C3h,	8, 9, 0CBh, 61h, 0CAh
		db 0A4h, 2, 0CBh, 0A1h,	0CBh, 0D1h, 78h, 0D9h, 0Eh, 0D9h, 0C3h
; end of 'ROM'


		end
