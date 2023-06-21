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
ball_restart_position_x dw 6Eh ;110 px
ball_restart_position_Y dw 64h ;100 px

;Velocidad pelota
ball_velocity_x dw 05h ;Velocidad de pelota en x
ball_velocity_y dw 02h ;Velocidad de pelota en y

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

            jmp check_time 

        mov ax, 4c00h
        int 21h
    main endp

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
end

