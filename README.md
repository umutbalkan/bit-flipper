# bit-flipper
## Bilkent University Engineering Department: CS 223 - Digital Design
Digital Logic Design: Term Project
   
   




There are basically tree main blocks: Keyboard Analyzer, VGA Display, text operator.
Keyboard Analyzer takes the input from keyboard, receives a 11-bit data which contains start and stop bits, rest 8-bit is the scan code of the pressed key at the keyboard. Analyzer tries to extract that scan code from 11-bit data which can be quite hard sometimes. because scan codes are somewhat are in reverse order, meaning LSB-MSB. Displays the binary version of scan codes on LEDs on BASYS3 board and also displays the hexadecimal version of scan codes at BASYS3 7-segment display. Since BASYS3
doesn’t have a PS/2 input and creating a USB HID controller is impossible for me , there is built in micro controller on BASYS3 just below the USB port which mimics PS/2 input when there is USB.
VGA Display, takes the inputs from top module and tries to draw characters on the screen based on a algorithm, outputs are R,G,B and horizontal synch, vertical synch. It also has a submodule which synchronizes the BASYS 3 CLK with monitor.
Text operator, takes the input from Keyboard Analyzer and creates a string do all the shifting for cryptography. SystemVerilog do support string data-type but unfortunately Vivado software couldn’t implemented it yet. So I’ve used registers for creating strings. That’s why my strings have upper bound. I’ve defined an array of bytes, then assigned ASCII to each element then I’had a constant with ASCII values in it that I can index into.
4 - References:
These sources are provided me the knowledge of PS/2 Keyboard http://www.instructables.com/id/PS2-Keyboard-for-FPGA/ http://www.computer-engineering.org/ps2protocol/ http://www.eetimes.com/document.asp?doc_id=1279155
