;感谢王爽老师的教程
assume cs: code, ds: data, ss: stack

data segment
BOUNDARY_COLOR		dw		1131h
NEXT_ROW			dw		160


SNAKE_HEAD			dw		0						;
		
SNAKE_STERN			dw		12						;

SNAKE				dw		200 dup (0,0,0)			;(前一刻的位置，此时的位置，下一刻的位置)

SNAKE_COLOR			dw		2241h

SCREEN_COLOR		dw		0700h

DIRECTION			dw		3

DIRECTION_FUN		dw		offset isMoveUp 	- greedy_snake + 7e00h; 0
					dw		offset isMoveDown 	- greedy_snake + 7e00h; 2
					dw		offset isMoveLeft	- greedy_snake + 7e00h; 4
					dw		offset isMoveRight 	- greedy_snake + 7e00h; 6

FOOD_LOCATION		dw		160*3 + 20*2

FOOD_COLOR			dw		4439h

NEW_NODE			dw		18

data ends

stack segment
		db 128 dup(0)
stack ends

code segment
		start:	mov ax,stack
				mov ss,ax
				mov sp,128
				
				
				call cpy_greedy_snake
				call sav_old_int9
				call set_new_int9
				
				mov bx,0
				push bx
				mov bx,7e00h
				push bx	
				retf
				
				
				mov ax,4c00h
				int 21h
				
				
;-----------------------------------------------
greedy_snake:	call init_reg
				call clear_screen
				
				call init_screen
				
				call init_food
				
				call init_snake
				
nextMove:		call delay
				cli
				call isMoveDirection
				sti
				jmp nextMove
				
testA:			mov ax,1000h
				jmp testA

				mov ax,4c00h
;-----------------------------------------------				
init_food:
				mov di,FOOD_LOCATION
				push FOOD_COLOR
				pop es:[di]
				ret
				
;-----------------------------------------------				
isMoveDirection:
				mov bx,DIRECTION
				add bx,bx
				call word ptr ds:DIRECTION_FUN[bx]
				ret
;-----------------------------------------------				int 21h
delay:
				push ax
				push dx
				
				mov dx,2h
				sub ax,ax

				
				
delayIng:		sub ax,1
				sbb dx,0
				cmp dx,0
				jne delayIng
				cmp ax,0
				jne delayIng
				
				
				
				pop dx
				pop ax
				ret
;-----------------------------------------------
;es = 0b80
init_snake:		mov bx,offset SNAKE
				add bx,SNAKE_HEAD
				mov si,160*10 + 40*2
				mov dx,SNAKE_COLOR
				
				mov word ptr ds:[bx+0],0
				mov ds:[bx+2],si
				mov es:[si],dx
				mov word ptr ds:[bx+4],6				
				
				sub si,2
				add bx,6
				
				mov word ptr ds:[bx+0],0
				mov ds:[bx+2],si
				mov es:[si],dx
				mov word ptr ds:[bx+4],12				
				
				sub si,2
				add bx,6
				
				
				mov word ptr ds:[bx+0],6
				mov ds:[bx+2],si
				mov es:[si],dx
				mov word ptr ds:[bx+4],18				
				

				ret
;双向链表
;-----------------------------------------------				
init_screen:	mov dx,BOUNDARY_COLOR
				call show_up_down_line
				call show_left_right_line
				ret
				
;-----------------------------------------------				
show_left_right_line:		
				mov bx,160
				mov cx,23


showLeftRightLine:			    
			    mov es:[bx],dx
			    mov es:[bx+158],dx
			    add bx,NEXT_ROW
			    loop showLeftRightLine
			    
			    ret
;-----------------------------------------------
show_up_down_line:
				mov bx,0
				mov cx,80
				
showUpDownLine:	mov es:[bx],dx
				mov es:[bx+160*23],dx
				add bx,2
				loop showUpDownLine
				ret
;-----------------------------------------------
clear_screen:	
				mov bx,0
				mov dx,SCREEN_COLOR
				mov cx,2000
				
clearScreen:	mov es:[bx],dx
				add bx,2
				loop clearScreen
				ret
;-----------------------------------------------
init_reg:		mov bx,0b800h
				mov es,bx
				
				mov bx,data
				mov ds,bx
				
				ret
;-----------------------------------------------
new_int9:		push ax

				call clear_buff

				in al,60h			;输入
				pushf
				call dword ptr cs:[200h]
				
				cmp al,48h;UP
				je	isUp
				
				cmp al,50h;DOWN
				je	isDown
				
				cmp al,4bh;LEFT
				je	isLeft
				
				cmp al,4dh;RIGHT
				je	isRight

				
				
				cmp al,3bh			;F1
				jne int9Ret
				call change_screen_color
				
int9Ret:		pop ax
				iret
;-----------------------------------------------				
isUp:			mov di,160*24 + 40*2
				mov byte ptr es:[di],'U'
				cmp DIRECTION,1
				je int9Ret
				call isMoveUp
				jmp int9Ret
				
isDown:			mov di,160*24 + 40*2
				mov byte ptr es:[di],'D'
				cmp DIRECTION,0
				je int9Ret
				call isMoveDown
				jmp int9Ret
				
isLeft:			mov di,160*24 + 40*2
				mov byte ptr es:[di],'L'
				cmp DIRECTION,3
				je int9Ret
				call isMoveLeft
				jmp int9Ret
				
isRight:		mov di,160*24 + 40*2
				mov byte ptr es:[di],'R'
				cmp DIRECTION,2
				je int9Ret
				call isMoveRight
				jmp int9Ret
				
;-----------------------------------------------		
isMoveUp:		mov bx,offset SNAKE
				add bx,SNAKE_HEAD
				mov si,ds:[bx+2]
				sub si,NEXT_ROW		;向上减少一行
				
				cmp byte ptr es:[si],0
				jne noMoveUp
				call draw_new_snake 
				mov DIRECTION,0
				jmp upContinue
				
noMoveUp:		call isFood

upContinue:		ret
;-----------------------------------------------
isMoveDown:
				mov bx,offset SNAKE
				add bx,SNAKE_HEAD
				mov si,ds:[bx+2]
				add si,NEXT_ROW
				
				cmp byte ptr es:[si],0			;判断是否有障碍物，无障碍物的时候ASCII为0
				jne noMoveDown
				call draw_new_snake
				mov DIRECTION,1
				jmp downContinue
				
noMoveDown:		call isFood

downContinue:	ret
;-----------------------------------------------
isMoveLeft:
				mov bx,offset SNAKE
				add bx,SNAKE_HEAD
				mov si,ds:[bx+2]
				sub si,2
				
				cmp byte ptr es:[si],0
				jne noMoveLeft
				call draw_new_snake
				mov DIRECTION,2
				jmp leftContinue
				
noMoveLeft:		call isFood

leftContinue:	ret
;-----------------------------------------------
isMoveRight:
				mov bx,offset SNAKE
				add bx,SNAKE_HEAD
				mov si,ds:[bx+2]
				add si,2
				
				cmp byte ptr es:[si],0
				jne noMoveRight
				call draw_new_snake
				mov DIRECTION,3
				jmp rightContinue
				
noMoveRight:	call isFood

rightContinue:	ret
;-----------------------------------------------				
isFood:			cmp byte ptr es:[si],'9'		;food为9 判断是否是食物
				
				jne draw_game_over
				
				
				push NEW_NODE
				pop ds:[bx+0]
				
				mov bx,offset SNAKE
				add bx,NEW_NODE
				
				mov word ptr ds:[bx+0],0
				mov ds:[bx+2],si
				push SNAKE_COLOR
				pop es:[si]
				
				push SNAKE_HEAD
				pop ds:[bx+4]
				
				push NEW_NODE
				pop SNAKE_HEAD
				
				add NEW_NODE,6
				call set_new_food
				
noFood:
				ret
;-----------------------------------------------
draw_game_over:
				mov di,160*24 + 40*2 - 8
				mov byte ptr es:[di],'G'
				
				mov di,160*24 + 40*2 - 6
				mov byte ptr es:[di],'A'
				
				mov di,160*24 + 40*2 - 4
				mov byte ptr es:[di],'M'
				
				mov di,160*24 + 40*2 - 2
				mov byte ptr es:[di],'E'
				
				mov di,160*24 + 40*2
				mov byte ptr es:[di],' '
				
				mov di,160*24 + 40*2 + 2
				mov byte ptr es:[di],'O'
				
				mov di,160*24 + 40*2 + 4
				mov byte ptr es:[di],'V'
				
				mov di,160*24 + 40*2 + 6
				mov byte ptr es:[di],'E'
				
				mov di,160*24 + 40*2 + 8
				mov byte ptr es:[di],'R'
				
				mov di,160*24 + 40*2 + 10
				mov byte ptr es:[di],'!'
				
				

				
				call clear_buff
				call game_end
				ret

;-----------------------------------------------
set_new_food:	mov al,0
				out 70h,al
				in al,71h
				
				mov dl,al
				and dl,00001111b
				shr al,1
				shr al,1
				shr al,1
				shr al,1
				
				mov bl,10
				mul bl
				add al,dl				;秒数
				
				mul al					;防止奇数
				shr al,1
				shl al,1
				
				mov bx,ax
				cmp byte ptr es:[bx],0
				jne set_new_food
				
				push FOOD_COLOR
				pop es:[bx]
				
				ret
;-----------------------------------------------				
draw_new_snake:
				push SNAKE_STERN		;把尾部压入栈
				pop ds:[bx+0]			;当前的身体变为尾部
				
				mov bx,offset SNAKE		;
				add bx,SNAKE_STERN
				
				push ds:[bx+0]
				mov word ptr ds:[bx+0],0
				mov di,ds:[bx+2]
				push SCREEN_COLOR
				pop es:[di]
				
				mov ds:[bx+2],si
				push SNAKE_COLOR
				pop es:[si]
				
				push SNAKE_HEAD
				pop ds:[bx+4]
				
				push SNAKE_STERN
				pop SNAKE_HEAD
				
				pop SNAKE_STERN
				
				
				ret				
;-----------------------------------------------				
clear_buff:		mov ah,1
				int	16h
				jz clearBuffRet
				mov ah,0
				int 16h
				jmp	clear_buff
				
				
clearBuffRet: 	ret
;-----------------------------------------------
change_screen_color:
				push bx
				push cx
				push es

				mov bx,0b800h
				mov es,bx
				mov bx,1
				
				mov cx,2000
		
				
changeScreen:	inc byte ptr es:[bx]
				add bx,2
				loop changeScreen
				
				
				
				pop es
				pop cx
				pop bx
				ret

greedy_snake_end:		nop





;-----------------------------------------------
set_new_int9:
				mov bx,0
				mov es,bx
				
				cli
				mov word ptr es:[9*4],offset new_int9 - offset greedy_snake + 7e00h
				mov word ptr es:[9*4+2],0
				sti
				
				ret
;-----------------------------------------------
sav_old_int9:
;保护原来的int9中断 放到0000:0200后
				mov bx,0
				mov es,bx
				
				cli					;防止外中断
				push es:[9*4]
				pop es:[200h]
				push es:[9*4 + 2]
				pop es:[202h]
				ret
;-----------------------------------------------
cpy_greedy_snake:
				mov bx,cs
				mov ds,bx
				mov si,offset greedy_snake
				
				mov bx,0
				mov es,bx
				mov di,7E00h
				
				mov cx,offset greedy_snake_end - offset greedy_snake
				cld
				rep movsb
				
				
				ret			
				
game_end:		MOV  AH,4CH
     			INT  21H
code ends

end start




