This project adds functionality to the different buttons on the ATMega 2560 Arduino.

There were four parts to this assignment, each building on the previous one, with part D being the final one. In this part, the following functionalities have been incorporated:
One, the bottom right of the LCD display either shows a "-" or "*" to indicate if a button is currently pressed.
Two, the bottom left of the LCD display will show the last button that was pressed, with "R" for right, "L" for left, "U" for up, and "D" for down.
Three, on the top row of the LCD display, the left or right buttons would move the cursor to different columns. Then, for each column, the up or down would be used to cycle and display different values from the "AVAILABLE_CHERSET" string near the bottom of the file. 
Please note that each column could be at a different place in the string, and when at the column, the up and down buttons would start from that point in the string.

The LCD.asm and LCDdefs.inc files were the helper files provided for this assignment.

For exact details and specifications, please read the PDF.
