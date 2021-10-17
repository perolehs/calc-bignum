.data
	zero_str:	    .asciiz	"0"
	operacion_str:      .asciiz	"Introduzca el tipo de operacion suma o multiplicacion (+ o *): " 
	primer_numero_str:  .asciiz	"Introduzca el PRIMER numero (50 digitos maximo, puede ser negativo): "
	segundo_numero_str: .asciiz	"Introduzca el SEGUNDO numero (50 digitos maximo, puede ser negativo): "
	mensaje_operador_val:.asciiz	"Debe introducir un operador valido +, * : "
	mensage_numero_inv: .asciiz	"********* Debe introducir un numero valido: ?(+|-)(0-9)++ *********** \n "
	salto_linea_str:    .asciiz	"\n"
	el_resultado_es:    .asciiz	"El resultado es: "
	signo_resultante:   .word       0 # + + : 0, - +: 1, + -: 2, - -: 4
	operacion:          .space 	2
	primer_numero:      .space 	51
	primer_numero_len:  .word  	0
	segundo_numero:     .space 	51
	segundo_numero_len: .word 	0	
	resultado:          .space	101
	resultado_len:      .word 	101
	


.macro print_string(%string)
	la $a0, %string
	li $v0, 4
	syscall
.end_macro

.macro print_int(%int)
	lw $t1, %int
	add $a0, $t1, 0
	li $v0, 1
	syscall
.end_macro

.macro sec_guardar_parametro(%print, %guardar_en, %caracteres_max)
	la $a0, %print
	li $v0, 4
	syscall

	la $a0, %guardar_en
	li $a1, %caracteres_max
	li $v0, 8
	syscall
	print_string(salto_linea_str)
.end_macro

.macro limpiar_memoria(%string)
	li $t0, 51
	li $t1, 0
	loop_limpiar:
		bge $t1, $t0, fin_loop_limpiar
		lb  $zero, %string($t1)
		add $t1, $t1, 1
		j loop_limpiar
	fin_loop_limpiar:
.end_macro

.macro analisis_de_signo(%numero)
	lb  $t0, %numero($zero)
			
	bne $t0, 43, sin_signo_p
	li $t1, 48
	sb $t1, %numero($zero)	
	sin_signo_p:	
	
	bne $t0, 45, sin_signo_n
	li $t1, 48
	sb $t1, %numero($zero)
	lw $t3, signo_resultante
	add $t3, $t3, $t2		
	add $t3, $t3, 1
	sw $t3, signo_resultante
	sin_signo_n:
	
	lw $t2, signo_resultante
	add $t2, $t2, 1
.end_macro

.macro longitud_string(%string, %guardar_en)
	li $t0, 0
	loop:
    		lb  $t1, %string($t0)
		beq  $t1, $zero, fin
		beq  $t1, 10, fin
		
		add $t0, $t0, 1
    		j loop
    	fin:
	sw $t0, %guardar_en
.end_macro

.macro validar_numero(%string, %longitud)
	li $t0, 1
	lw $t1, %longitud
	
	lb $t2, %string($zero)
	beq $t2, '+', loop_validar_str
	beq $t2, '-', loop_validar_str
	blt $t2, '0', no_valido
	bgt $t2, '9', no_valido
	
	loop_validar_str:
		bgt $t0, $t1, valido
		lb $t2, %string($t0)
		beq $t2, 10, valido
		blt $t2, '0', no_valido
		bgt $t2, '9', no_valido		
		add $t0, $t0, 1		
		j loop_validar_str

	no_valido:
		li $s0, 0
		j salir_validacion
		
	valido:
		li $s0, 1
	salir_validacion:
.end_macro

.macro sumar_a_resultado(%string_1, %longitud_1, %string_2, %longitud_2)
	lw $s1, resultado_len
	# vemos que string es mas largo.
	lw $t1, %longitud_1
	lw $t2, %longitud_2
	la $t3, %string_1
	la $t4, %string_2
	
	bge $t1, $t2, saltar_cambio_longitud
	# cambiamos los valores, ahora t1 > t2
	lw $t1, %longitud_2
	lw $t2, %longitud_1
	la $t3, %string_2
	la $t4, %string_1
	saltar_cambio_longitud:
	
	li $t7, 0 # numero para llevar sobrante de la suma
	
	loop_suma_digito:
		# obtenemos el ultimo numero del string_1
		add $t1, $t1, -1
		add $t6, $t1, $t3 # vamos al final de la direcion del string
		lb $t5, 0($t6)
		add $t5, $t5, $t7 # sumamos el numero que se lleva
		li $t7, 0 # reseteamos lo que se lleva a 0	
		
		add $t2, $t2, -1
		
		li $t6, 0
		blt $t2, 0, saltar_segundo_digito
		
		# obtenemos el ultimo numero del string_2
		add $s0, $t2, $t4					
		lb $t6, 0($s0)
		add $t6, $t6, -48 # conversion de char a int
		saltar_segundo_digito:
		
		# Suma de un char + un numero
		add $t6, $t6, $t5
		
		# comprobamos si es mayor que 9
		blt $t6, 57, menor_que_9
		add $t6, $t6, -10
		li $t7, 1 # llevo 1
		menor_que_9:
		
		# guardamos el numero en string
		sb $t6, resultado($s1)
		add $t5, $t1, -1
		blt $t5, 0, fin_loop_suma_digito # vemos si es el ultimo digito de string_1
		
		add $s1, $s1, -1 # bajamos un indice en el string resultado		
		j loop_suma_digito # repetimos el loop
	fin_loop_suma_digito:
	
	# sumamos el numero que llevamos 
	ble $t7, 0, salir_de_suma
	add $t7, $t7, 48
	add $s1, $s1, -1 # bajamos un indice en el string resultado	
	sb $t7, resultado($s1)
	salir_de_suma:
	add $s4, $s1, 0
.end_macro

.macro restar_a_resultado(%string_1, %longitud_1, %string_2, %longitud_2)
	lw $s1, resultado_len
	# vemos que string es mas largo.
	lw $t1, %longitud_1
	lw $t2, %longitud_2
	la $t3, %string_1
	la $t4, %string_2
	
	# si la longitud es igual hay que ver quien es mayor
	bne $t1, $t2, saltar_quien_es_mayor
	
	add $t5, $t3, 0
	add $t6, $t4, 0
	lw $s2, %longitud_1
	
	loop_quien_es_mayor:
	blt $s2, 0, imprimir_0
	
	lb $t7, 0($t5) # agarro el primer elemento
	lb $t0, 0($t6)
	add $t5, $t5, 1
	add $t6, $t6, 1
	
	add $s2, $s2, -1	 
	
	beq $t7, $t0, loop_quien_es_mayor
	bgt $t7, $t0, saltar_cambio_longitud
	
	saltar_quien_es_mayor:
	bgt $t1, $t2, saltar_cambio_longitud
	# cambiamos los valores, ahora t1 > t2
	lw $t1, %longitud_2
	lw $t2, %longitud_1
	la $t3, %string_2
	la $t4, %string_1
	
	lw $t0, signo_resultante
	bne $t0, 2, saltar_signo
	li $a0, '-'
	li $v0, 11
	syscall 
	
	saltar_cambio_longitud:
	lw $t0, signo_resultante
	bne $t0, 1, saltar_signo
	li $a0, '-'
	li $v0, 11
	syscall 
	saltar_signo:   
	
	li $t7, 0 # numero para llevar sobrante de la suma
	
	loop_resta_digito:
		# obtenemos el ultimo numero del string_1
		add $t1, $t1, -1
		add $t6, $t1, $t3 # vamos al final de la direcion del string
		lb $t5, 0($t6)
		add $t5, $t5, $t7 # sumamos el numero que se lleva
		li $t7, 0 # reseteamos lo que se lleva a 0	
		
		add $t2, $t2, -1
		
		li $t6, 0
		blt $t2, 0, saltar_segundo_digito
		
		# obtenemos el ultimo numero del string_2
		add $s0, $t2, $t4					
		lb $t6, 0($s0)
		add $t6, $t6, -48 # conversion de char a int
		saltar_segundo_digito:
		
		# Resta de un char + un numero
		sub $t6, $t5, $t6
		
		# comprobamos si es mayor que 0
		bgt $t6, 47, mayor_que_0
		add $t6, $t6, 10
		li $t7, 1 # llevo 1
		mayor_que_0:
		
		# guardamos el numero en string
		sb $t6, resultado($s1)
		
		add $t5, $t1, -1
		blt $t5, 0, fin_loop_resta_digito # vemos si es el ultimo digito de string_1
		
		add $s1, $s1, -1 # bajamos un indice en el string resultado		
		j loop_resta_digito # repetimos el loop
	fin_loop_resta_digito:
	
	# sumamos el numero que llevamos 
	ble $t7, 0, salir_de_resta
	add $t7, $t7, 48
	add $s1, $s1, -1 # bajamos un indice en el string resultado	
	sb $t7, resultado($s1)
	salir_de_resta:	
	add $s4, $s1, 0
.end_macro

.macro multiplicar_a_resultado(%string_1, %longitud_1, %string_2, %longitud_2)
	
	# vemos que string es mas largo.
	lw $t1, %longitud_1
	lw $t2, %longitud_2
	la $t3, %string_1
	la $t4, %string_2

	bgt $t1, $t2, saltar_cambio_longitud
	# cambiamos los valores, ahora t1 > t2
	lw $t1, %longitud_2
	lw $t2, %longitud_1
	la $t3, %string_2
	la $t4, %string_1
	saltar_cambio_longitud:
	
	li $s0, 0 # sobrante
	li $s1, 0 # acumulador
	li $s2, 0 # iterador
	lw $s3, resultado_len # largo del resultado
	add $s3, $s3, -1 # llevarlo a indice
	li $s4, 0 # ultimo indice donde comienza resultado
	
	li $t5, 0 # sumador 1
	li $t6, 0 # sumador 2
	li $t7, 0 # iterador de columna
	
	# primer elemento
	# obtenemos el numero del string_1 correspondiente
	add $t1, $t1, -1 # sumando debe dar el numero de columna
	add $t0, $t3, $t1 # direccion del ultimo char 					
	lb $t5, 0($t0)
	add $t5, $t5, -48 # conversion de char a int
	
	add $t2, $t2, -1 # sumando debe dar el numero de columna
	add $t0, $t4, $t2 # direccion del ultimo char 					
	lb $t6, 0($t0)	
	add $t6, $t6, -48 # conversion de char a int
	
	mul $s1, $t5, $t6
	
	blt $s1, 10, saltar_sumar_sobrante
	rem $t5, $s1, 10 # a guardar
	sub $s0, $s1, $t5 # sobrante por 10
	div $s0, $s0, 10 # sobrante 
	add $s1, $t5, 0	
	saltar_sumar_sobrante:	
	
	# guardo el numero como string
	add $t0, $s1, 48 # numero en char
	add $s4, $s3, -1 # indice a guardar el char 
	sb $t0, resultado($s4)
	
	add $s2, $s2, 1 # itero		
	
	loop_multiplicar:
		add $s1, $s0, 0 # reseteo acumulador igual al sobrante
		li $s0, 0 # reseteo sobrante
		li $t7, 0 # reseteo iterador de columna igual al iterador
		
		
		loop_numero_columna:
			
			sub $t0, $s2, $t7
			blt $t0, 0, fin_loop_numero_columna
			
			# obtenemos el numero del string_1 correspondiente
			bgt $t0, $t1, saltar_a_iteracion_columna
			sub $t0, $t1, $t0 # indice del char
			add $t0, $t0, $t3 # direccion del char
			lb $t5, 0($t0)
			#beq $t5, 48, saltar_a_iteracion_columna
			add $t5, $t5, -48 # conversion de char a int
	
			bgt $t7, $t2, fin_loop_numero_columna
			sub $t0, $t2, $t7 # indice del char			
			add $t0, $t0, $t4 # direccion del char					
			lb $t6, 0($t0)	
			#beq $t6, 48, saltar_a_iteracion_columna
			add $t6, $t6, -48 # conversion de char a int
			
			mul $t0, $t5, $t6
			
			blt $t0, 10, saltar_sumar_sobrante_loop
			rem $t5, $t0, 10 # a guardar
			sub $t6, $t0, $t5 # sobrante * 10
			div $t6, $t6, 10 # sobrante
			add $s0, $s0, $t6 # agrego a sobrante save
			add $t0, $t5, 0
			saltar_sumar_sobrante_loop:
			
			add $s1, $s1, $t0 # agrego a acumulador
			
			saltar_a_iteracion_columna:
			add $t7, $t7, 1 # itero la columna			
			j loop_numero_columna
		fin_loop_numero_columna:
		
		add $t0, $t1,$t2 
		ble $s2, $t0, saltar_prueba_fin  
		beq $s1, 0, fin_de_loop_multiplicar	
		saltar_prueba_fin:
		
		blt $s1, 10, saltar_sumar_sobrante_
		rem $t5, $s1, 10 # a guardar
		sub $t6, $s1, $t5 # sobrante * 10
		div $t6, $t6, 10 # sobrante
		add $s0, $s0, $t6 # agrego a sobrante save
		add $s1, $t5, 0
		saltar_sumar_sobrante_:
		
		# guardo el numero como string
		add $s2, $s2, 1
		add $t0, $s1, 48 # numero en char
		sub $s4, $s3, $s2 # indice a guardar el char 
		sb $t0, resultado($s4)		
						
		j loop_multiplicar	
	fin_de_loop_multiplicar:
	ble $s0, 0, salir_multiplicar
	add $s2, $s2, 1 # itero
	# guardo el sobrante como string
	add $t0, $s0, 48 # numero en char
	sub $s4, $s3, $s2 # indice a guardar el char 
	sb $t0, resultado($s4)
	salir_multiplicar:
	
	lw $t0, signo_resultante
	beq $t0, 0, imprimir
	beq $t0, 4, imprimir
	
	li $a0, '-'
	li $v0, 11
	syscall
.end_macro




.text	
	sec_guardar_parametro(operacion_str, operacion, 2)
	
	loop_operador_valido:		
		lb $t0, operacion($zero)
		beq $t0, 43, fin_loop_operador_valido
		beq $t0, 42, fin_loop_operador_valido
		sec_guardar_parametro(mensaje_operador_val, operacion, 2)
		j loop_operador_valido
	fin_loop_operador_valido:
	
	pedir_primer_numero:
		sec_guardar_parametro(primer_numero_str, primer_numero, 51)
		
		longitud_string(primer_numero, primer_numero_len)
		
		validar_numero(primer_numero, primer_numero_len)
		bgt $s0, 0, pedir_segundo_numero
		print_string(mensage_numero_inv)
		limpiar_memoria(primer_numero)
		j pedir_primer_numero
		
	pedir_segundo_numero:	
		sec_guardar_parametro(segundo_numero_str, segundo_numero, 51)
			
		longitud_string(segundo_numero, segundo_numero_len)
		
		validar_numero(segundo_numero, segundo_numero_len)
		bgt $s0, 0, salir_pedir_numero
		print_string(mensage_numero_inv)
		limpiar_memoria(segundo_numero)
		j pedir_segundo_numero
		
	salir_pedir_numero:
	
	analisis_de_signo(primer_numero)
	analisis_de_signo(segundo_numero)
	
	print_string(el_resultado_es)
	
	lb $t0, operacion($zero)
	beq $t0, 42, multiplicacion
	lw $t0, signo_resultante
	beq $t0, 0, suma
	beq $t0, 4, suma
	
	restar_a_resultado(primer_numero, primer_numero_len, segundo_numero, segundo_numero_len)
	j imprimir
	
	suma:
	sumar_a_resultado(primer_numero, primer_numero_len, segundo_numero, segundo_numero_len)	
	j imprimir
	
	multiplicacion:
	multiplicar_a_resultado(primer_numero, primer_numero_len, segundo_numero, segundo_numero_len)
	
	## IMPRIMIR RESULTADO ##
	imprimir:
	
	
	lb $t0, resultado($s4)
	bne $t0, '0', no_empieza_por_zero
	add $s4, $s4, 1
	no_empieza_por_zero:
	
	la $a0, resultado($s4)
	li $v0, 4
	syscall
salir:
	li $v0, 10
	syscall
	
imprimir_0:
	la $a0, ($zero)
	li $v0, 1
	syscall
	j salir

	
		
	
	
		
	
	
	
