.8086
.model small
.stack 100h

.data
;Juego
game_active db 01h ; 1=juego activo, 0=gameover 
winner_index db 0 ;Esto lo usaremos para cambiar el cartel del ganador(1 o 2)

;Tiempo
time_aux db 0

;Puntos
paddle_left_points db 0 ;puntos jugador 1
paddle_right_points db 0 ;puntos jugador 2
limit_points_to_win db 01h ;limite de puntos para ganar

;Textos 
text_paddle_left_points db '0', '$' ;Texto puntos jugador 1
text_paddle_right_points db '0', '$' ;Texto puntos jugador 2
text_game_over_title db 'GAME OVER','$' ;Texto pantalla game over
text_game_over_play_again db 'Press R to play again','$' ;Texto para reiniciar el texto
text_game_winner db "PLAYER 0 WINS",'$' ;Texto ganador de la partida

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
paddle_velocity dw 07h

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
            cmp game_active, 00h
            je show_game_over_screen
            
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
            call draw_points 
            jmp check_time 
        show_game_over_screen:
            call draw_game_over_screen
            jmp check_time
        

    main endp

    move_paddle proc
        ;VERIFICAMOS MOVIMIENTO DE LA PALETA IZQUIERDA.

        ;Interrupción 16h y servicio 1 -> Va a obtener el estado del teclado. 
		;ZF = 0 si se presiono una tecla. 
        mov ah, 01h
        int 16h 
        jz check_right_paddle_movement

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

        jmp check_right_paddle_movement 

        ;Agregamos movimineto ascendente
        move_left_paddle_up:
            mov ax, paddle_velocity
            sub paddle_left_y, ax 

            ;Verificamos que la paleta no supere el limite de la pared superior
			;(techo) -> Comparamos la posición de la paleta en y con 
			;window_bounde = 6px.  
            mov ax, window_bounce 
            cmp paddle_left_y, ax  
            jl stop_top_movement_left_paddle
            jmp check_right_paddle_movement 

            stop_top_movement_left_paddle: 
                mov paddle_left_y, ax ;asignamos el valor de 6px a la posición en y de la paleta izquierda. 
                jmp check_right_paddle_movement 

        ;Agregamos movimineto descendente
        move_left_paddle_down:
            mov ax, paddle_velocity
            add paddle_left_y, ax 
            
          ;Verificamos que la paleta no supere el limite inferior (piso)-> Tomamos el alto de la ventana y le restamos el alto de la paleta y del rebote de la pelota y comparamos con la posición de la paleta en y. 
            mov ax, window_height
            sub ax, paddle_height
            sub ax, window_bounce
            cmp paddle_left_y, ax 
            jg stop_bottom_movement_left_paddle
            jmp check_right_paddle_movement
            
            stop_bottom_movement_left_paddle:
                mov paddle_left_y, ax 
                jmp check_right_paddle_movement
         
        ;VERIFICAMOS MOVIMIENTO DE LA PALETA DERECHA.
        check_right_paddle_movement:
            ;Verificamos si se presiono la tecla o -> arriba 
            cmp al, 'o' 
            je move_right_paddle_up
            cmp al, 'O' 
            je move_right_paddle_up
            
            ;Verificamos si se presiono la tecla k -> abajo 
            cmp al, 'k' 
            je move_right_paddle_down
            cmp al, 'K' 
            je move_right_paddle_down
            jmp end_check_movement 

            move_right_paddle_up:
                mov ax, paddle_velocity
                sub paddle_right_y, ax 

                ;Limite con techo
                mov ax, window_bounce 
                cmp paddle_right_y, ax  
                jl stop_top_movement_right_paddle
                jmp end_check_movement  

                stop_top_movement_right_paddle:
                    mov paddle_right_y, ax 
                    jmp end_check_movement  

            move_right_paddle_down:
                mov ax, paddle_velocity
                add paddle_right_y, ax     
                ;Limite con piso
                mov ax, window_height
                sub ax, paddle_height
                sub ax, window_bounce
                cmp paddle_right_y, ax 
                jg stop_bottom_movement_right_paddle
                jmp end_check_movement 
                
                stop_bottom_movement_right_paddle:
                    mov paddle_right_y, ax 
                    jmp end_check_movement 

            end_check_movement:
            ret
    move_paddle endp

    restart_position proc
        push ax 
        ;La pelota al chocar con la pared izquierda o derecha, se reiniciará su posición al centro de la pantalla.
        mov ax, ball_restart_position_x
        mov ball_x, ax
        
        mov ax, ball_restart_position_y
        mov ball_y, ax

        pop ax 
        ret 
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
            jl point_paddle_right_and_reset_position
            ;ball_x > 320px
            mov ax, window_width
            sub ax, ball_size
            sub ax, window_bounce
            cmp ball_x, ax
            jg point_paddle_left_and_reset_position

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
            
            call colision_ball_paddle

            pop ax
            ret
        
        ;Incrementamos un punto al jugador y llamamos al proc restart_position para reiniciar la posición de la pelota al centro de la pantalla. 
        point_paddle_right_and_reset_position:
            inc paddle_right_points
            call restart_position
            ;Actualizamos los puntos de la text_point. 
            call update_points_right_paddle
            mov al, limit_points_to_win ;Comparamos si el jugador llego a los 5 puntos
            cmp paddle_right_points, al
            jge game_over

            pop ax
            ret 
        
        point_paddle_left_and_reset_position:
            inc paddle_left_points
            call restart_position
            call update_points_left_paddle
            mov al, limit_points_to_win
            cmp paddle_left_points, al
            jge game_over

            pop ax
            ret 

        game_over: 
            ;Verificamos quien es el ganador
            mov ah, limit_points_to_win
            cmp paddle_left_points, ah 
            je player_one_wins
            jmp player_two_wins

            ;actualizamos winner index 
            player_one_wins: 
                mov winner_index, 01H 
                jmp continue_game_over_process            
            player_two_wins:
                mov winner_index, 02H
                jmp continue_game_over_process

        continue_game_over_process:
            ;Termina el juego e inicializa los puntos a 0. 
            mov paddle_left_points, 00h
            mov paddle_right_points, 00h 
            call update_points_left_paddle 
            call update_points_right_paddle
            mov game_active, 0 ;cambiamos valor de 0 para terminar. 
            pop ax
            ret 
        ;Invierto el valor de la velocidad (valor que se le suma a la posición inicial). 
        ball_velocity_y_NEG:
            neg ball_velocity_y ;ball_velocity_y = - ball_velocity_y
            pop ax
            ret 
    move_ball endp

    colision_ball_paddle proc
        push ax 
         ;Checkeamos si la pelota colisiona con la paleta derecha    
            ;(maxx1 > minx2) && 
            ;(minx1 < maxx2) && 
            ;(maxy1 > miny2) && 
            ;(miny1 < maxy2)

            ;Equivalente a:  

            ;((ball_x + ball_size) > paddle_right_x ) && 
            ;(ball_x < (paddle_right_x + paddle_width)) && 
            ;((ball_y + ball_size)> paddle_right_y) && 
            ;(ball_y < (paddle_right_y + paddle_height))

            mov ax, ball_x
            add ax, ball_size
            cmp ax, paddle_right_x 
            jng check_colision_left_paddle ;Si no hay colisión, chequear paleta izquierda

            mov ax, paddle_right_x
            add ax, paddle_width
            cmp ax, ball_x
            jng check_colision_left_paddle

            mov ax, ball_y
            add ax, ball_size
            cmp ax, paddle_right_y 
            jng check_colision_left_paddle

            mov ax, paddle_right_y
            add ax, paddle_height
            cmp ax, ball_y 
            jng check_colision_left_paddle
            
            ;Si llegamos a este punto, la pelota colisionó con la paleta derecha => Revertimos la velocidad de la pelota. 
            neg ball_velocity_x 
            pop ax 
            ret ;No puede colisionar con la otra paleta. 

        check_colision_left_paddle:
            ;Checkeamos si la pelota colisiona con la paleta izquierda
            ;((ball_x + ball_size) > paddle_left_x ) && 
            ;(ball_x < (paddle_left_x + paddle_width)) && 
            ;((ball_y + ball_size)> paddle_left_y) && 
            ;(ball_y < (paddle_left_y + paddle_height))
            mov ax, ball_x
            add ax, ball_size
            cmp ax, paddle_left_x 
            jng end_check_colision ;Si no hay colisión, chequear paleta izquierda

            mov ax, paddle_left_x
            add ax, paddle_width
            cmp ax, ball_x
            jng end_check_colision

            mov ax, ball_y
            add ax, ball_size
            cmp ax, paddle_left_y 
            jng end_check_colision

            mov ax, paddle_left_y
            add ax, paddle_height
            cmp ax, ball_y 
            jng end_check_colision
            
            ;Si llegamos a este punto, la pelota colisionó con la paleta derecha => Revertimos la velocidad de la pelota. 
            neg ball_velocity_x 

        end_check_colision:
            pop ax
            ret
    colision_ball_paddle endp

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

    draw_points proc
        ;Mostraremos los puntos en pantalla utilizando la interrupción 21h servicio 09h
        ;También utilizaremos la interrupción 10h y el servicio 02h para setear la posición del cursor. 
        
        ;Puntos del jugador 1(paddle left)
            ;Establecemos la posición del cursor
            mov ah, 02h     
            mov bh, 00h     ;Seteamos el número de pagina
            mov dh, 04h     ;Seteamos la fila
            mov dl, 07h     ;Seteamos la columna
            int 10h 

            ;Escribimos los puntos
            mov ah, 09h 
            lea dx, text_paddle_left_points ;= mov dx, offset text_paddle_left_points 
            int 21h 

        ;Puntos del jugador 2(paddle right)
           
            mov ah, 02h     
            mov bh, 00h     
            mov dh, 04h     
            mov dl, 1fh      
            int 10h 

            ;Escribimos los puntos
            mov ah, 09h 
            lea dx, text_paddle_right_points 
            int 21h 
          
        ret 
    draw_points endp

    draw_game_over_screen proc
        push ax 
        
        call clear_screen ;limpiamos pantalla. 

        ;****HACER FUNCIÓN DE POSICIÓN DE PANTALLA CON PARAMETROS POR STACK***
        ;Posición del cursor 
        mov ah, 02h     
        mov bh, 00h     ;Seteamos el número de pagina
        mov dh, 04h     ;Seteamos la fila
        mov dl, 0fh     ;Seteamos la columna
        int 10h 

        ;mostrar titulo
        mov ah, 09h 
        lea dx, text_game_over_title 
        int 21h 

        call update_winner_index_text ;Actualizamos si gano el jugador 1 o 2. 

        mov ah, 02h     
        mov bh, 00h     ;Seteamos el número de pagina
        mov dh, 0ah     ;Seteamos la fila
        mov dl, 0dh     ;Seteamos la columna
        int 10h 
        ;mostrar ganador
        mov ah, 09h 
        lea dx, text_game_winner
        int 21h 


        mov ah, 02h     
        mov bh, 00h     ;Seteamos el número de pagina
        mov dh, 11h     ;Seteamos la fila
        mov dl, 0ah     ;Seteamos la columna
        int 10h 

        ;mostrar ganador
        mov ah, 09h 
        lea dx, text_game_over_play_again
        int 21h 

        ;Opciones para reiniciar el juego
        mov ah, 00h ;Esperamos que el usuario ingrese una tecla.
        int 16h 

        cmp al, 'R'
        cmp al, 'r'
        je restart_game

        restart_game: 
        mov game_active, 01h 

        pop ax 
        ret 
    draw_game_over_screen endp 

    update_winner_index_text proc 
        push ax 
        ;Actualizamos la variable text_game_winner con el valor de winner_index
        
        mov al, winner_index ;Pasamos el valor 1 o 2 a AL. 
        add al, 30h ;lo convertimos a ascii. 
        mov [text_game_winner + 7], al ;reemplazamos el 0 o valor anterior.  
        
        pop ax 
        ret 
    update_winner_index_text endp  

    update_points_left_paddle proc
        push ax 
        ;vamos a actualizar los puntos de la variable text_point. Para ello hay que convertir el valor de los puntos(reg) a texto (ascii). Una manera sencilla de hacer esto es sumar 30h al valor de la variable "paddle_left_points". 
        ;Como nuestro juego no va a superar los 9 puntos va a servir. 

        xor ax, ax ;Limpia registro ax, lo inicializa en 0. 
        mov al, paddle_left_points
        add al, 30h 
        mov text_paddle_left_points, al 

        pop ax
        ret
    update_points_left_paddle endp
    
    update_points_right_paddle proc
        push ax 
        xor ax, ax ;Limpia registro ax, lo inicializa en 0. 
        mov al, paddle_right_points
        add al, 30h 
        mov text_paddle_right_points, al 

        pop ax
        ret
    update_points_right_paddle endp
end