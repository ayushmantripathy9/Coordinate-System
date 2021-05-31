primer  START  0

initialize
	LDA rows		
	MUL cols						... for doing rows x cols to get the screen area in the accumulator
	ADD screenOrg
	STA screenMax
	
	LDA =0
	JSUB initializeCoordinateAxes   ... plotting the coordinate axes
	
.........................

programBegin			... this is the initial loop for taking inputs and executing commands 
	JSUB enterInput
	TD stdin
	RD stdin			
	
	COMP =0x30			... if '0' is the input then end the program 
	JEQ EOP
	
	COMP =0x70			... if 'p' is the input then plot the point 
	JEQ point			
	
	COMP =0x66			... if 'f' is the input, then plot the function
	JEQ drawFunctions
	
	COMP =0x63			... 'c' as input clears the screen, preserving only the coordinate axes
	JEQ clr
	
	J endmsg			... displays end message and terminates the program
...........................

...This block contains code for taking input and printing in the command line

enterInput
	LDCH commandInput, X	... print the message requesting for enter input
	WD stdout
	TIX =14
	JLT enterInput
	
	LDX =0
	
	LDA =0x24				... printing the dollar symbol before taking input
	WD stdout
	RSUB

EOP							... end of program, triggered by incorrect input
	RD stdin

endmsg
	LDCH prgmendmsg, X		... print the message that program has ended
	WD stdout
	TIX =22
	JLT endmsg
	LDX =0
	LDA =0x0A
	WD stdout
	J halt

halt    J      halt

.................

...this block contains code for plotting various outputs in the graphical screen

drawFunctions
	JSUB drawLine					... function for drawing the given lines
	J again

point
	JSUB drawPointFunction			... function for drawing points
	J again

...fuctions for clearing the screen
clr
	JSUB clearScreen				... function for clearing screen
	J again


clearScreen
	STL jumpPoint
	LDA =0
	STA row
	STA col
	
	
resetAddresses						... We iterate over the whole screen, and set all the values to 0
	JSUB calcAddr					... Calculates the address
	LDA =0
	STA @address
	
	LDA col
	ADD =3
	STA col
	COMP cols
	JLT resetAddresses
		
	LDA =0	
	STA col
	
	LDA row
	ADD =1	
	STA row
	COMP rows	
	JLT resetAddresses
		
	JSUB initializeCoordinateAxes	... after screen is cleared, redraw axes
	LDL jumpPoint
	RSUB

calcAddr							... calculating the address of a cell--> row * cols + col + screenOrg
	STA temp
	
	LDA row
	MUL cols
	ADD col
	ADD screenOrg
	STA address
	
	LDA temp
	RSUB

again								... here we reset the rows and columns that were used to 0
	RD stdin			
	LDA =0
	STA col				
	STA row
	J programBegin

..........................

...this code block contains code for drawing the three different types of fucntions

drawLine				... drawing functions when 'f' is the input
	STL jump
	JSUB getFun			... Read other parameters of input
	
	LDA isVariable		... it checks whether we have ton draw y = const or y = +-x
	COMP =0				... if isVariable == 0 then we have a function of type y = constant
	JGT functionDone	... we skip if isVariable > 0, because it would already have been executed
	
	JSUB getColor	
	LDA =0
	
drawConstFunction		...Draw the function y = constant when isVariable = 0
	STA col
	JSUB calcAddr
	
	LDA color
	STCH @address
	
	LDA col 
	ADD =1
	
	COMP cols
	JLT drawConstFunction

...once the above loop is complete, the functionDone is executed

functionDone			... Reset col and row after drawing of function is complete
	LDA =0
	STA col
	STA row
	LDL jump
	RSUB

.................	

drawPointFunction		... Function for drawing points
	STL jump
	
	JSUB getCol			... gets column where we want to draw
	JSUB getRow	 		... gets row where we want to draw
	JSUB drawPoint 		... draws the point
	
	LDL jump
	RSUB
.................

getFun
	STL jumpPoint		... save the L register	(if y = const, this would contain the 'n' value)
	JSUB getRow     	... get the function that was on input (either y = const or +-x)
	LDA isVariable 		
	... isVariable stores which type of function (0 => y = const, 1 => y = -x, and 2 => y = x)
	
	COMP =0
	JEQ gotFun      	... if function of type y = n (not dependant of x), then draw it in the other subroutine
	
	JSUB getColor  		... otherwise get color
	
	COMP =2
	JEQ drawPositiveLine		... draws the line y = x on the graphical screen
	
	COMP =1
	JEQ drawNegativeLine 	...	draws the line y = -x on the graphical screen
	
... for plotting the y = x line
drawPositiveLine
		LDA screenMax	... start at first column of last row
		SUB =110
		STA address
		LDA screenOrg
		ADD =109
		STA screenTemp	... end at last column of first row

loopPositiveLine				... draw function
		LDA color 
		STCH @address
		LDA address
		SUB =108		...equivalent to: row - 1, col - 1
		STA address
		COMP screenTemp
	JGT loopPositiveLine
	J gotFun
.......

... for plotting the y = -x line 
drawNegativeLine
		LDA screenMax	... start at last column of last row
		STA address
		
loopNegativeLine
		LDA color
		STCH @address
		LDA address
		SUB =110		... equivalent to: row + 1, col + 1
		STA address
		COMP screenOrg	... end at first element of screen
	JGT loopNegativeLine	
......

gotFun
	LDL jumpPoint		... reload L register
	RSUB
	
.................	

getCol
	LDA =0	
	STA col
	TD stdin
	RD stdin			... get column where to draw from input: [-5,5]
	COMP =0x2D			... if '-' on input
	JEQ colNeg
	
	....positive x coordinate, normalize input according to size of screen
	SUB =48	
	MUL =10	
	ADD =54
	J colPosition
	
	....negative x coordinate, normalize input according to size of screen
colNeg
	RD stdin
	SUB =48
	STA negativeTemp
	LDA =5
	SUB negativeTemp
	MUL =10
	ADD =3
	
colPosition
	STA col	...store normalized input to variable
	RSUB

.................

...Same as getCol
getRow 
	LDA =0
	STA row
	
	TD stdin						... testing device before taking input
	RD stdin						... reads whether x or - or const
	
	COMP =0x78						... comparing with x
	JEQ positiveLine				... draw y = x, if input is x
	
	COMP =0x2D						... checks if '-' is present
	JEQ negativeFunction			... draw y = -x or y = -ve constant, if input is '-'
	
	... find the position of the line above x-axis in the graphical screen
	SUB =48
	MUL =-10
	ADD =53
	J rowPosition

negativeFunction					... checks whether negative constant line or y = -x and draws them

	TD stdin
	RD stdin

	COMP =0x78						... compare with 'x' 
	JEQ negativeLine				... if found 'x', then draw y = -x

	... calculating the position of the negative line on the screen
	SUB =48
	MUL =10
	ADD =54
	J rowPosition
	
	... if input is a positive line (fx{color} i.e y = x)
positiveLine
	LDA =2
	STA isVariable
	J rowPosition2
	
	... if input is a negative line i.e y = -x
negativeLine
	LDA =1
	STA isVariable
	J rowPosition2
	
	... when done, store to variables
rowPosition
	STA row
	LDA =0
	STA isVariable 					... if input function is not dependent on x

rowPosition2		
	RSUB							... returns to getFun function, so that we can draw our graph

.................

drawPoint
	STL jumpPoint 		... save L register
	JSUB getColor  		... get color of the point
	JSUB calcAddr 		... get address
	LDA color 
	STCH @address    	... draw point
	LDA cross     		... check if 'K' was in input (is set in getColor)
	COMP =1        		... if cross == 0, jump to end of function
	JLT resetCross
	...
	LDA address	   		... draw cross	
	SUB =108	   		... row - 1 + col + 1
	STA address
	LDA color
	STCH @address
	LDA address
	SUB =2       		... row - 1, col + 1
	STA address
	LDA color
	STCH @address
	LDA address
	ADD =110
	ADD =108
         ...col - 2
	STA address
	LDA color
	STCH @address
	LDA address
	ADD =2       		... row - 1, col + 1
	STA address	
	LDA color
	STCH @address
	
resetCross
	LDA =0
	STA cross	  		... reset cross variable
	LDL jumpPoint
	RSUB	
	
.................

...Function that reads the color from input
getColor
	STA temp
	
	TD stdin 			... testing device before taking input
	RD stdin
	
	COMP =0x67
	JLT crossJmp		... if 'K' on input (also any variable with ascii less than 'K' would work)
	
	COMP =0x77			... 'w'-> white
	JEQ whiteColor
	
	COMP =0x72			... 'r'-> red	
	JEQ redColor
	
	COMP =0x67			... 'g'-> green
	JEQ greenColor
	
	COMP =0x79			... 'y'-> yellow
	JEQ yellowColor	
	
	J gotColor
	
crossJmp
	LDA =1
	STA cross			... if 'K' on input, read again to get color
	
	TD stdin
	RD stdin
	
	COMP =0x67
	JLT cross
	
	COMP =0x77			... 'w'-> white
	JEQ whiteColor
	
	COMP =0x72			... 'r'-> red	
	JEQ redColor
	
	COMP =0x67			... 'g'-> green
	JEQ greenColor
	
	COMP =0x79			... 'y'-> yellow
	JEQ yellowColor	
	
... Store colors into color variable
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

... Function to draw the coordinate axes
initializeCoordinateAxes
	STL jump			... save L register
	STA temp
	LDA =0				... Start in center of the first row
	STA row		
	LDA =54			
	STA col
	
drawAxisY				... plots the y-axis
		JSUB calcAddr	
		LDA white
		STCH @address
		LDA row 
		ADD =1
		COMP rows
		STA row
	JLT drawAxisY
	
	LDA =54
	STA row
	LDA =0
	STA col
	
drawAxisX				... plots the x-axis
		JSUB calcAddr
		LDA white
		STCH @address
		LDA col 
		ADD =1
		COMP cols
		STA col
	JLT drawAxisX
	
	LDA =3
	STA row
	

drawMarxkersY			... plots the markings on the y-axis
		LDA =53			... plot left of the x-axis
		STA col
		JSUB calcAddr
		LDA white
		STCH @address
		
		LDA =55			... plot right of the x-axis
		STA col
		JSUB calcAddr
		LDA white
		STCH @address
		
		LDA row 
		COMP =43
		JEQ drawOppositeMarkersY
		ADD =10
		
		J drawNextMarkerY
		
drawOppositeMarkersY	
		ADD =21		

drawNextMarkerY	
		COMP rows
		STA row
	JLT drawMarxkersY

	LDA =3
	STA col
	
drawMarxkersX			... plots the markings on the x-axis
		LDA =53			... plot above the x-axis
		STA row
		JSUB calcAddr
		LDA white
		STCH @address
		
		LDA =55			... plot below the x-axis
		STA row
		JSUB calcAddr
		LDA white
		STCH @address
		
		LDA col 
		COMP =43
		JEQ drawOppositeMarkersX
		ADD =10
		
		J drawNextMarkerX

drawOppositeMarkersX	
		ADD =21		

drawNextMarkerX	
		COMP cols
		STA col
	JLT drawMarxkersX
	
	LDA temp
	LDL jump
	
	RSUB

.... End of initializeCoordinateAxes	

. data

... input and output variables
stdin				BYTE X'00'
stdout				BYTE X'01'

cols				WORD 109
rows				WORD 109
col					WORD 0
row					WORD 0

... variables for color and type of printing in graphical screen
color				WORD 0x79
white				WORD 0x0000FF
red					WORD 0x0000F0
green				WORD 0x0000CC
yellow				WORD 0x0000FC
cross 				WORD 0

... screen-values
screenOrg			WORD 0x0A000
screenMax			WORD 0
screenTemp  		WORD 0

address				WORD 0
jump				WORD 0
jumpPoint			WORD 0

... temporary variables 
temp				WORD 0
negativeTemp		WORD 0

... variable to check type of function
isVariable			WORD 0 				... 0 => y = constant , 1 => y = x, 2 => y = -x

... stdout messages
commandInput BYTE C'Enter Command '
prgmendmsg BYTE C'Program has terminated'

			END    initialize