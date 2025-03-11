.model small
.stack 100h ; Стек 256 байт

.data
    InputBuffer db 81, 0, 81 dup('$')  ; Буфер ввода: [макс. длина][факт. длина][строка]
    NewLine db 13, 10, '$'             ; Перевод строки
    words dw 40 dup(0)                 ; Массив адресов слов
    word_count dw 0                    ; Счётчик слов

.code
start:
    ; Инициализация сегментов
    mov ax, @data ; загрузка адреса сегмента данных в регистр
    mov ds, ax ; перемещаем в ds, чтобы можно было считать все строки посимвольно

    ; Ввод строки
    mov ah, 0Ah
    lea dx, InputBuffer
    int 21h

    ; Заменяем Enter на '$'
    mov bl, InputBuffer+1 ; здесь получаем фактическую длину строки в InputBuffer+1, ложим именно в bl, 
    ; т.к. InputBuffer типа db + экономия ресурсов
    mov byte ptr [InputBuffer+2+bx], '$' ; непосредственная замена Enter на $,
    ; здесь используем именно bx, т.к. индексация памяти всегда требует использование 16-битового регистра

    ; Перевод строки
    mov ah, 09h
    lea dx, NewLine
    int 21h

    ; Разбиение на слова
    lea si, InputBuffer+2 ; копируем адрес начала строки
    lea di, words ; копируем адрес массива строк

parse_loop:
    skip_spaces:
    lodsb ; Читаем по байту, записываем в al
    cmp al, ' ' ; посимвольно проверяем и делаем прыжки к нужным сегментам
    je skip_spaces
    cmp al, '*'               
    je replace_star           
    cmp al, '$'               
    je parsing_done

    dec si ; перед записью в массив вычитаем 1 т.к. lodsb по умолчанию увеличивает si на 1. Нужно для правильной записи адреса                   
    mov [di], si; Сохраняет адрес начала слова в массив words         
    add di, 2 ; увеличиваем на 2 чтобы перейти к след. элементу массива words, т.к. он типа dw, т.е. 2 байта               
    inc word_count ; увеличиваем переменную, отвечающую за количество слов           

    ; если слово не заканчивается на *, как предполагается в условии, всё равно корректно заканчиваем обработку строки
    find_end:
    lodsb                     
    cmp al, ' '
    je word_end               
    cmp al, '*'               
    je replace_star
    cmp al, '$'
    jne find_end              

    dec si                    
    jmp parsing_done

replace_star:
    mov byte ptr [si-1], '$'  
    jmp parsing_done          

word_end:
    mov byte ptr [si-1], '$'
    jmp parse_loop            

parsing_done:

    ; Вывод слов попарно
    mov cx, word_count        
    test cx, cx ; Проверяем, равно ли CX нулю
    jz exit ; Если слов нет, переходим к метке exit

    ; Количество пар
    mov ax, cx ; Копируем количество слов в AX
    shr ax, 1 ; находим количество пар через побитовый сдвиг вправо на 1 бит, т.е. целое число пар слов                
    jz skip_pairs ; если длина слова = 0, переходим к метке exit                  
    mov cx, ax ; Загружаем количество пар в CX               

    lea si, words ; Загружаем адрес массива words в SI            
    add si, 2 ; Увеличиваем SI на 2 (пропускаем первое слово), т.к. задача заключается в замене слов попарно                

    mov bx, cx ; Копируем количество пар в BX               

print_loop:
    ; выводим второе слово
    mov dx, [si]
    mov ah, 09h
    int 21h

    ; Пробел внутри пары
    mov dl, ' '
    mov ah, 02h ; выводим символ
    int 21h

    ; Первое слово
    mov dx, [si-2]
    mov ah, 09h
    int 21h

    dec bx
    jz no_space

    ; Пробел между парами
    mov dl, ' '
    mov ah, 02h
    int 21h

no_space:
    add si, 4 ; переходим к следующей паре слов, 4 т.к. каждое слово по 2 байта                
    loop print_loop ; зацикливаемся, пока CX не 0

skip_pairs:
    ; Проверка на нечетное количество слов
    mov ax, word_count
    test ax, 1
    jz exit

    mov ax, word_count
    dec ax ; AX = индекс последнего слова (начиная с 0)
    shl ax, 1 ; Умножаем на 2 (каждый элемент массива words занимает 2 байта)
    lea si, words
    add si, ax ; SI указывает на последний элемент массива
    
    mov dl, ' '
    mov ah, 02h
    int 21h

    ; Вывод последнего слова
    mov dx, [si]
    mov ah, 09h
    int 21h

exit:
    ; Новая строка
    mov ah, 09h
    lea dx, NewLine
    int 21h
    ; Завершение
    mov ax, 4C00h
    int 21h

end start