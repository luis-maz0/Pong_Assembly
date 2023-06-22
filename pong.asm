.8086
.model small
.stack 100h

.data
;Tiempo
time_aux db 0

;Pelota
ball_x dw 1Eh;posición x (columna)
ball_y dw 1Eh;posición y (fila)
ball_size dw 04h;tamaño pelota -> alto(height) y ancho(width)
ball_restart_position_x dw 0a0h ;160 px
ball_restart_position_Y dw 64h ;100 px

;Velocidad pelota
ball_velocity_x dw 05h ;Velocidad de pelota en x
ball_velocity_y dw 02h ;Velocidad de pelota en y

;Paleta
paddle_left_x dw 0ah  ;posición origen x paleta izq -> 10px
paddle_left_y dw 0ah  ;posición origen y paleta izq -> 10px

paddle_right_x dw 136h  ;posición origen x paleta izq -> 10px
paddle_right_y dw 0ah  ;posición origen y paleta izq -> 10px

paddle_width dw 05h   ;ancho paleta -> 5px
paddle_height dw 1Fh  ;alto paleta -> 31px

;Velocidad de paleta
paddle_velocity dw 05h


;Dimensiones de la pantalla (limites)
window_width dw 140h  ;ancho de la ventana (320 px)
window_height dw 0c8h ;alto de la ventana (200 px)
window_bounce dw 06h  ;Valor borde ventana (para que la pelota no se pase de los limites)

.code
    main proc
        mov ax, @data
        mov ds, ax
        
        call clear_screen

        ;Obtenemos la hora actual del sistema.
        ;ah: servicio 2ch -> obtiene la hora del sistema 
        ;ch = hora
        ;cl = minuto
        ;dh = segundo
        ;dl = 1/100 segundos
        check_time:
            mov ah, 2ch
            int 21h

            cmp dl, time_aux; 
            je check_time

            mov time_aux, dl ;actualizamos la hora
            
            call clear_screen
            call move_ball
            call draw_ball
            call move_paddle
            call draw_paddle
            jmp check_time 

        mov ax, 4c00h
        int 21h
    main endp

    move_paddle proc
        ;Interrupción 16h y servicio 1 -> Va a obtener el estado del teclado. ZF = 0 si se presiono una tecla. 
        mov ah, 01h
        int 16h 
        jz check_rigth_paddle_movement

        ;Interrupción 16h y servicio 0 -> Va a esperar a que una tecla se oprima y lee el caracter de la misma. 
        ;Al -> Caracter ASCII. 
        mov ah, 00h 
        int 16h 

        ;Verificamos si se presiono la tecla w -> arriba 
        cmp al, 'w' 
        je move_left_paddle_up
        cmp al, 'W' 
        je move_left_paddle_up

        ;Verificamos si se presiono la tecla s -> abajo 
        cmp al, 's' 
        je move_left_paddle_down
        cmp al, 'S' 
        je move_left_paddle_down

        jmp check_rigth_paddle_movement 

        move_left_paddle_up:
            mov ax, paddle_velocity
            sub paddle_left_y, ax 
            jmp check_rigth_paddle_movement 

        move_left_paddle_down:
            mov ax, paddle_velocity
            add paddle_left_y, ax 
            jmp check_rigth_paddle_movement 

        check_rigth_paddle_movement:

        ret
    move_paddle endp

    restart_position proc
        ;La pelota al chocar con la pared izquierda o derecha, se reiniciará su posición al centro de la pantalla.
        mov ax, ball_restart_position_x
        mov ball_x, ax
        
        mov ax, ball_restart_position_y
        mov ball_y, ax

    restart_position endp

    move_ball proc
        push ax
        ;Dibujamos la posición de la pelota agregando la velocidad
            ;Movemos la pelota horizontalmente
            mov ax, ball_velocity_x 
            add ball_x, ax
            
            ;Condiciones de colisión pared izquierda y derecha
            ;ball_x < 0   
            mov ax, window_bounce
            cmp ball_x, ax
            jl reset_position_x 
            ;ball_x > 320px
            mov ax, window_width
            sub ax, ball_size
            sub ax, window_bounce
            cmp ball_x, ax
            jg reset_position_x

            ;Movemos la pelota verticalmente
            mov ax, ball_velocity_y 
            add ball_y, ax

            ;Condiciones de colisión pared Superior y inferior
            ;ball_y < 0   
            mov ax, window_bounce
            cmp ball_y, ax
            jl ball_velocity_y_NEG 
            ;ball_x > 200px
            mov ax, window_height
            sub ax, ball_size
            sub ax, window_bounce
            cmp ball_y, ax
            jg ball_velocity_y_NEG
            
            pop ax
            ret
        
        ;Llamo al proc restart_position para reiniciar la posición de la pelota al centro de la pantalla. 
        reset_position_x:
            call restart_position
            pop ax
            ret 

        ;Invierto el valor de la velocidad (valor que se le suma a la posición inicial). 
        ball_velocity_y_NEG:
            neg ball_velocity_y ;ball_velocity_y = - ball_velocity_y
            pop ax
            ret 
    move_ball endp

    clear_screen proc
        push ax
        push bx
        ;Utilizamos interrupción 10h
        ;Ah pasamos el servicio, en este caso 0h -> Modo de video
        ;AL pasamos el parámetro, en este caso 13h -> 320x200 256 color graphics (MCGA,VGA)
        mov ah, 00h
        mov al, 13h
        int 10h

        ;Definimos el color de fondo
        ;ah: servicio 0bh -> Definir paleta de colores
        ;bh: parametro de paleta de color -> 0: fondo y borde; 1: paleta de 4 colores
        ;bl parametro de color -> 00h = negro
        mov ah, 0bh
        mov bh, 00h
        mov bl, 00h 
        int 10h

        pop bx
        pop ax
        ret
    clear_screen endp

    draw_ball proc
        push cx
        push dx
        push ax
        ;Dibujamos un pixel
        ;Ah: servicio 0ch -> Dibujar un pixel gráfico
        ;Al: parámetro de color -> 0fh = blanco
        ;Bh: parámetro Página ->  
        ;Cx: posición en x -> definimos en 0 (columna)
        ;Dx: posición en y -> definimos en 0 (Fila)

        mov cx, ball_x ;Posición inicial x para dibujar la bola
        mov dx, ball_y ;Posición inicial y para dibujar la bola
    
        ;Ciclo que dibujará pixel por pixel. 
    
        draw_ball_horinzontal:
            mov ah, 0ch
            mov al, 0fh
            mov bh, 00h
            int 10h
            inc cx ;cx++
            
            ;cx - ball_x > ball_size
            ;jng = saltar si no es mayor
            ;V: Salta a la siguiente linea
            ;F: Saltamos a la siguiente columna
            mov ax, cx
            sub ax, ball_x
            cmp ax, ball_size
            jng draw_ball_horinzontal   


            mov cx, ball_x ;Inicializamos cx a la posición incial
            inc dx ;Avanzamos una fila

            mov ax, dx
            sub ax, ball_y
            cmp ax, ball_size
            jng draw_ball_horinzontal

        pop ax
        pop dx
        pop cx

            ret
    draw_ball endp

    draw_paddle proc 
        ;posicion inicial paleta izquierda 
        mov cx, paddle_left_x
        mov dx, paddle_left_y

        draw_paddle_left_horinzontal:
            ;Dibujar pixeles
            mov ah, 0ch
            mov al, 0fh
            mov bh, 00h
            int 10h
            ;Dibuja la primera fila (todas las columnas)
            inc cx 
            mov ax, cx 
            sub ax, paddle_left_x
            cmp ax, paddle_width
            jng draw_paddle_left_horinzontal

            ;incrementa a la siguiente fila
            mov cx, paddle_left_x
            inc dx 
            mov ax, dx
            sub ax, paddle_left_y
            cmp ax, paddle_height
            jng draw_paddle_left_horinzontal

        ;posicion inicial paleta derecha 
        mov cx, paddle_right_x
        mov dx, paddle_right_y

        draw_paddle_right_horinzontal:
            ;Dibujar pixeles
            mov ah, 0ch
            mov al, 0fh
            mov bh, 00h
            int 10h
            ;Dibuja la primera fila (todas las columnas)
            inc cx 
            mov ax, cx 
            sub ax, paddle_right_x
            cmp ax, paddle_width
            jng draw_paddle_right_horinzontal

            ;incrementa a la siguiente fila
            mov cx, paddle_right_x
            inc dx 
            mov ax, dx
            sub ax, paddle_right_y
            cmp ax, paddle_height
            jng draw_paddle_right_horinzontal

            ret 
    draw_paddle endp
end

