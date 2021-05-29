primer  START  0

first
	LDA rows		...calculate max screen address
	MUL cols
	ADD screenOrg
	STA screenMax
	LDA =0
	JSUB initializeCoordinateAxes   ...function that draws initial graph
	
startLoop
	LDA =0x24
	WD stdout
	TD stdin
	RD stdin			
	COMP =0x30			...if '0' on input, end program (inf. loop)
	JEQ EOP
	COMP =0x66			...if 'f' on input, draw function
	JEQ fun
	COMP =0x63			...if 'c' on input, clear screen
	JEQ clr
	COMP =0x70
	JEQ point			...if 'p' on input, draw point
	J halt				...if invalid input, end program (inf. loop)
	
clr
	JSUB clearScreen	....function for clearing screen
	J fun1

point
	JSUB drawPointFunction		....function for drawing points
	J fun1

fun
	JSUB function		....function for drawing functions
	

fun1
	RD stdin			...NL
	...RD stdin			...CR

	LDA =0
	STA col				...reset row and column that were used
	STA row
	J startLoop
	
EOP						...end of program, triggered by incorrect input
	RD stdin
halt    J      halt

.................
clearScreen
	STL jumpPoint	...save L register
	LDA =0
	STA row
	STA col
	
	...Nested loop that iterates over the whole screen, setting every address to 0
clearLoop
			JSUB calculateAddr	...Calculates the address
			LDA =0
			STA @address
			LDA col
			ADD =3
			STA col
			COMP cols
		JLT clearLoop
		
		LDA =0	
		STA col
		LDA row
		ADD =1	
		STA row
		COMP rows	
	JLT clearLoop
		
	JSUB initializeCoordinateAxes	...after screen cleared, redraw graph
	LDL jumpPoint	...reload L register
	RSUB
	
.................

...Function for drawing functions(jump here if 'f' on input)
function
	STL jump	...save L register
	
	JSUB getFun		...Read other parameters of input
	LDA functionSpr	...variable that tells us what kind of function we have
	COMP =0			...if functionSpr == 0 then we have a function of type y = 2 (not dependant on x)
	JGT functionDone	...skip if functionSpr > 0, because it was already drawn
	JSUB getColor	
	LDA =0
	
functionLoop		...Draw the function if functionSpr = 0
		STA col
		JSUB calculateAddr
		LDA color
		STCH @address
		LDA col 
		ADD =1
		COMP cols
	JLT functionLoop

functionDone	.... When done reset col and row
	LDA =0
	STA col
	STA row
	LDL jump	...reload L register
	RSUB
.................	
...Function for drawing points
drawPointFunction
	STL jump
	
	JSUB getCol	..gets column where we want to draw
	JSUB getRow	 ..gets row where we want to draw
	JSUB drawPoint ..draws the point
	
	LDL jump
	RSUB
.................
getFun
	STL jumpPoint	...save L register
	
	JSUB getRow     ...get the function that was on input
	LDA functionSpr 
	COMP =0
	JEQ gotFun      ...if function of type y = n (not dependant of x), then draw it in the other subroutine
	JSUB getColor  ...otherwise get color
	COMP =2
	JEQ posFunction	...y = x
	COMP =1
	JEQ negFunction ...y = -x
	

posFunction
		LDA screenMax	...start at first column of last row
		SUB =110
		STA address
		LDA screenOrg
		ADD =109
		STA screenTemp	...end at last column of first row

posFunLoop				...draw function
		LDA color
		STCH @address
		LDA address
		SUB =108		...equivalent to: row - 1, col - 1
		STA address
		COMP screenTemp
	JGT posFunLoop
	J gotFun
	
negFunction
		LDA screenMax	...start at last column of last row
		STA address
		
negFunLoop
		LDA color
		STCH @address
		LDA address
		SUB =110		...equivalent to: row + 1, col + 1
		STA address
		COMP screenOrg	...end at first element of screen
	JGT negFunLoop	
	
gotFun
	LDL jumpPoint	...reload L register
	RSUB
	
.................	
getCol
	LDA =0	
	STA col
	TD stdin
	RD stdin		...get column where to draw from input: [-5,5]
	COMP =0x2D		...if '-' on input
	JEQ colNeg
	
	....positive x coordinate, normalize input according to size of screen
	SUB =48	
	MUL =10	
	ADD =54
	J concCol
	
	....negative x coordinate, normalize input according to size of screen
colNeg
	RD stdin
	SUB =48
	STA tempNeg
	LDA =5
	SUB tempNeg
	MUL =10
	ADD =3
	
concCol
	STA col	...store normalized input to variable
	RSUB
.................

...Same as getCol, except for functions part
getRow 
	LDA =0
	STA row
	TD stdin	... testing device before taking input
	RD stdin
	COMP =0x78
	JEQ functionPos
	COMP =0x2D
	JEQ negRow
	
	....primer positivne koordinate y-os
	SUB =48
	STA tempNeg
	LDA =5
	SUB tempNeg
	STA testiram
	MUL =10
	ADD =3	
	J concRow

negRow	
	....primer negativne koordinate y-os
	RD stdin
	COMP =0x78
	JEQ functionNeg
	SUB =48
	MUL =10
	ADD =54
	J concRow
	
	....if input is a positive function
functionPos
	LDA =2
	STA functionSpr
	J concRow2
	
	....if input is a negative function
functionNeg
	LDA =1
	STA functionSpr
	J concRow2
	
	...when done, store to varibles
concRow
	STA row
	LDA =0
	STA functionSpr ...if input function is not dependant on x
concRow2
	RSUB
.................
drawPoint
	STL jumpPoint 		... save L register
	JSUB getColor  		... get color of the point
	JSUB calculateAddr 	... get address
	LDA color 
	STCH @address    	... draw point
	LDA cross     		... check if 'K' was in input (is set in getColor)
	COMP =1        		... if cross == 0, jump to end of function
	JLT resetCross
	
	LDA address	   ...draw cross	
	ADD =109	   ...row + 1
	STA address
	LDA color
	STCH @address
	LDA address
	SUB =108       ...row - 1, col + 1
	STA address
	LDA color
	STCH @address
	LDA address
	SUB =2         ...col - 2
	STA address
	LDA color
	STCH @address
	LDA address
	SUB =108       ...row - 1, col + 1
	STA address
	LDA color
	STCH @address
	
resetCross
	LDA =0
	STA cross	  ... reset cross variable
	LDL jumpPoint
	RSUB	
.................

...Function that reads the color from input
getColor
	STA temp
	TD stdin 		...... testing device before taking input
	RD stdin
	COMP =0x67
	JLT crossJmp	...if 'K' on input, jump (in reality anything that has ASCII < 0x67 will work)
	COMP =0x77		...'w'-> white
	JEQ whiteColor
	COMP =0x72		...'r'-> red	
	JEQ redColor
	COMP =0x67		...'g'-> green
	JEQ greenColor
	COMP =0x79		...'y'-> yellow
	JEQ yellowColor
	
	J gotColor
	
crossJmp
	LDA =1
	STA cross		...if 'K' on input, read again to get color
	RD stdin
	COMP =0x67
	JLT cross
	COMP =0x77		...'w'-> white
	JEQ whiteColor
	COMP =0x72		...'r'-> red	
	JEQ redColor
	COMP =0x67		...'g'-> green
	JEQ greenColor
	COMP =0x79		...'y'-> yellow
	JEQ yellowColor	
	
...Store colors into color variable
yellowColor
	LDA yellow
	STA color 
	J gotColor
	
greenColor
	LDA green
	STA color
	J gotColor
	
redColor
	LDA red
	STA color
	J gotColor
	
whiteColor
	LDA white
	STA color
	J gotColor
	
gotColor
	LDA temp
	RSUB

..................

..Function for calculation of address: row * COLUMNS + col + screenOrg
calculateAddr
	STA temp
	LDA row
	MUL cols
	ADD col
	ADD screenOrg
	STA address
	LDA temp
	RSUB
	
..................

..Function that draws inital graph (x and y axis)
initializeCoordinateAxes
	STL jump		..save L register
	STA temp
	LDA =0			..Start in center of the first row
	STA row		
	LDA =54			
	STA col
	
	..draw y axis
navpCrta
		JSUB calculateAddr	
		LDA white
		STCH @address
		LDA row 
		ADD =1
		COMP rows
		STA row
	JLT navpCrta
	
	LDA =54
	STA row
	LDA =0
	STA col
	
	..draw x axis
vodCrta
		JSUB calculateAddr
		LDA white
		STCH @address
		LDA col 
		ADD =1
		COMP cols
		STA col
	JLT vodCrta
	
	LDA =3
	STA row
	
	..draw "flare" on y axis (number indicators (i guess?))
	.. this is a bit awkward, because I didn't use the perfect screen size (row, col)
	.. meaning it is not exactly symmetric, hence so many jumps inside the loop.
	.. Essentially it draws 2 points around the axis and skips 10 rows ahead, 
	.. which normalized translates to 1 row -> it jumps to the next number,
	.. if the next number is 0 (if we are in row 43) it jumps 21 rows,
	.. to maintain "symmetry" of the graph
navpFlare
		LDA =53
		STA col
		JSUB calculateAddr
		LDA white
		STCH @address
		LDA =55
		STA col
		JSUB calculateAddr
		LDA white
		STCH @address
		LDA row 
		COMP =43
		JEQ navpDrugAdd
		ADD =10
		J navpAdd10
navpDrugAdd	
		ADD =21		
navpAdd10	
		COMP rows
		STA row
	JLT navpFlare

	LDA =3
	STA col
	
	...Same thing as y axis flare, just for x axis
vodFlare
		LDA =53
		STA row
		JSUB calculateAddr
		LDA white
		STCH @address
		LDA =55
		STA row
		JSUB calculateAddr
		LDA white
		STCH @address
		LDA col 
		COMP =43
		JEQ vodDrugAdd
		ADD =10
		J vodAdd10
vodDrugAdd	
		ADD =21		
vodAdd10	
		COMP cols
		STA col
	JLT vodFlare
	LDA temp
	LDL jump
	RSUB
...........................End of initializeCoordinateAxes	

. data
stdin		BYTE X'00'
stdout		BYTE X'01'
white		WORD 0x0000FF
red			WORD 0x0000F0
green		WORD 0x0000CC
yellow		WORD 0x0000FC
color		WORD 0x79
cols		WORD 109
rows		WORD 109
col			WORD 0
row			WORD 0
temp		WORD 0
screenOrg	WORD 0x0A000
screenMax	WORD 0
screenTemp  WORD 0
address		WORD 0
jump		WORD 0
jumpPoint	WORD 0
cross 		WORD 0
x			WORD 0
tempNeg		WORD 0
testiram 	WORD 0
testiram1 	WORD 0
testiram2 	WORD 0
functionSpr	WORD 0 ..... 0 = ni function odvisna od x, 1 => y = x, 2 => y = -x
			END    first