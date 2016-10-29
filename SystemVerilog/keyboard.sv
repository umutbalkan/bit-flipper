`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/03/2016 02:08:22 AM
// Design Name: 
// Module Name: keyboard
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Montvydas Klumbys	
// 
// Create Date:    
// Design Name: 
// Module Name:    Keyboard 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//	A module which is used to receive the DATA from PS2 type keyboard and translate that data into sensible codeword.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module keyboard(
    input logic clr,
	input logic CLK,	//board clock
    input logic PS2_CLK,	//keyboard clock and data signals
    input logic PS2_DATA,
//	output reg scan_err,			//These can be used if the Keyboard module is used within a another module
//	output reg [10:0] scan_code,
//	output reg [3:0]COUNT,
//	output reg TRIG_ARR,
//	output reg [7:0]CODEWORD,
    output logic [3:0] an,
    output logic [6:0] seg,
    output logic dp,
    output reg [7:0] led,
    output logic [3:0] red,
    output logic [3:0] green,
    output logic [3:0] blue,
    output logic hsync,
    output logic vsync
   );
   
   NERP_demo_top( CLK, clr, red, green, blue, hsync, vsync);
   

    // our text and final text(Data).
    reg [8*20:1] text, data;

    // 7-SEGMENT stuff.
    reg [3:0] digit1;
    reg [3:0] digit0;
    
    // Keys & their scan-codes.(8-bit, hex)
    wire [7:0] KEY_ENTER = 8'h5A;
	wire [7:0] KEY_A = 8'h1C;
	wire [7:0] KEY_B = 8'h32;
	wire [7:0] KEY_C = 8'h21;
	wire [7:0] KEY_D = 8'h23;
	wire [7:0] KEY_E = 8'h24;
	wire [7:0] KEY_F = 8'h2B;
	wire [7:0] KEY_G = 8'h34;
	wire [7:0] KEY_H = 8'h33;
	wire [7:0] KEY_I = 8'h43;
	wire [7:0] KEY_J = 8'h3B;
	wire [7:0] KEY_K = 8'h42;
	wire [7:0] KEY_L = 8'h4B;
	wire [7:0] KEY_M = 8'h3A;
	wire [7:0] KEY_N = 8'h31;
	wire [7:0] KEY_O = 8'h44;
	wire [7:0] KEY_P = 8'h4D;
	wire [7:0] KEY_Q = 8'h15;
	wire [7:0] KEY_R = 8'h2D;
	wire [7:0] KEY_S = 8'h1B;
	wire [7:0] KEY_T = 8'h2C;
	wire [7:0] KEY_U = 8'h3C;
	wire [7:0] KEY_V = 8'h2A;
	wire [7:0] KEY_W = 8'h1D;
	wire [7:0] KEY_X = 8'h22;
	wire [7:0] KEY_Y = 8'h35;
	wire [7:0] KEY_Z = 8'h1A;
	
	//wire [7:0] ARROW_LEFT = 8'h6B;
	//wire [7:0] ARROW_RIGHT = 8'h74;
	//wire [7:0] EXTENDED = 8'hE0;	//codes 
	//wire [7:0] RELEASED = 8'hF0;
    
	reg read;				//this is 1 if still waits to receive more bits 
	reg [11:0] count_reading;		//this is used to detect how much time passed since it received the previous codeword
	reg PREVIOUS_STATE;			//used to check the previous state of the keyboard clock signal to know if it changed
	reg scan_err;				//this becomes one if an error was received somewhere in the packet
	reg [10:0] scan_code;			//this stores 11 received bits
	reg [7:0] CODEWORD;			//this stores only the DATA codeword
	reg TRIG_ARR;				//this is triggered when full 11 bits are received
	reg [3:0]COUNT;				//tells how many bits were received until now (from 0 to 11)
	reg TRIGGER = 0;			//This acts as a 250 times slower than the board clock. 
	reg [7:0]DOWNCOUNTER = 0;		//This is used together with TRIGGER - look the code
	
	
	// Since string data-type is not supported in Vivado's SystemVerilog. I'm using reg byte vectors.
	// Verilog does not store a string termination character.
	reg[25*8:0] text; // Declare a register variable that is 25 bytes
	reg[25*8:0] mytext; 

	//Set initial start values
	initial begin
        led = 0;
		PREVIOUS_STATE = 1;		
		scan_err = 0;		
		scan_code = 0;
		COUNT = 0;			
		CODEWORD = 0;
		read = 0;
		count_reading = 0;
	end

	always_ff@(posedge CLK) begin				//This reduces the frequency 250 times
		if (DOWNCOUNTER < 249) begin			//and uses variable TRIGGER as the new board clock 
			DOWNCOUNTER <= DOWNCOUNTER + 1;
			TRIGGER <= 0;
		end
		else begin
			DOWNCOUNTER <= 0;
			TRIGGER <= 1;
		end
	end
	
	always_ff@(posedge CLK) begin	
		if (TRIGGER) begin
			if (read)				//if it still waits to read full packet of 11 bits, then (read == 1)
				count_reading <= count_reading + 1;	//and it counts up this variable            
			else 						//and later if check to see how big this value is.
				count_reading <= 0;			//if it is too big, then it resets the received data
		end
	end


	always_ff@(posedge CLK) begin		
	if (TRIGGER) begin						//If the down counter (CLK/250) is ready
		if (PS2_CLK != PREVIOUS_STATE) begin			//if the state of Clock pin changed from previous state
			if (!PS2_CLK) begin				//and if the keyboard clock is at falling edge
				read <= 1;				//mark down that it is still reading for the next bit
				scan_err <= 0;				//no errors
				scan_code[10:0] <= {PS2_DATA, scan_code[10:1]};	//add up the data received by shifting bits and adding one new bit
				COUNT <= COUNT + 1;			//
			end
		end
		else if (COUNT == 11) begin				//if it already received 11 bits
			COUNT <= 0;
			read <= 0;					//mark down that reading stopped
			TRIG_ARR <= 1;					//trigger out that the full pack of 11bits was received
			//calculate scan_err using parity bit
			if (!scan_code[10] || scan_code[0] || !(scan_code[1]^scan_code[2]^scan_code[3]^scan_code[4]
				^scan_code[5]^scan_code[6]^scan_code[7]^scan_code[8]
				^scan_code[9]))
				scan_err <= 1;
			else 
				scan_err <= 0;
		end	
		else  begin						//if it yet not received full pack of 11 bits
			TRIG_ARR <= 0;					//tell that the packet of 11bits was not received yet
			if (COUNT < 11 && count_reading >= 4000) begin	//and if after a certain time no more bits were received, then
				COUNT <= 0;				//reset the number of bits received
				read <= 0;				//and wait for the next packet
			end
		end
	PREVIOUS_STATE <= PS2_CLK;					//mark down the previous state of the keyboard clock
	end
	end


	always_ff@(posedge CLK) begin
		if (TRIGGER) begin					//if the 250 times slower than board clock triggers
			if (TRIG_ARR) begin				//and if a full packet of 11 bits was received
				if (scan_err) begin			//BUT if the packet was NOT OK
					CODEWORD <= 8'd0;		//then reset the codeword register
				end
				else begin
					CODEWORD <= scan_code[8:1];	//else drop down the unnecessary  bits and transport the 7 DATA bits to CODEWORD reg
				end				//notice, that the codeword is also reversed! This is because the first bit to received
			end					//is supposed to be the last bit in the codeword¦
			else CODEWORD <= 8'd0;				//not a full packet received, thus reset codeword
		end
		else CODEWORD <= 8'd0;					//no clock trigger, no data¦
	end
	
	
	// NOW, We've received/extracted -hopefully- correct CODEWORD from keyboard. This block matches CODEWORD to corresponding alphabetical character
	always_ff@(posedge CLK)
	begin
	  	if (TRIGGER) begin
            if (TRIG_ARR) begin
            led<=scan_code[8:1];
            digit1<=led[7:4];
            digit0<=led[3:0];            
            end
        end
        
        // matches CODEWORD with corresponding literals with respesct to their scancodes.
        // and adds it to our text
        case(CODEWORD)
            KEY_ENTER   :   data = text;
            KEY_A       :   text = {text,"A"};
            KEY_B       :   text = {text,"B"};
            KEY_C       :   text = {text,"C"};
            KEY_D       :   text = {text,"D"};
            KEY_E       :   text = {text,"E"};
            KEY_F       :   text = {text,"F"};
            KEY_G       :   text = {text,"G"};
            KEY_H       :   text = {text,"H"};
            KEY_I       :   text = {text,"I"};
            KEY_J       :   text = {text,"J"};
            KEY_K       :   text = {text,"K"};
            KEY_L       :   text = {text,"L"};
            KEY_M       :   text = {text,"M"};
            KEY_N       :   text = {text,"N"};
            KEY_O       :   text = {text,"O"};
            KEY_P       :   text = {text,"P"};
            KEY_Q       :   text = {text,"Q"};
            KEY_R       :   text = {text,"R"};
            KEY_S       :   text = {text,"S"};
            KEY_T       :   text = {text,"T"};
            KEY_U       :   text = {text,"U"};
            KEY_V       :   text = {text,"V"};
            KEY_W       :   text = {text,"W"};
            KEY_X       :   text = {text,"X"};
            KEY_Y       :   text = {text,"Y"};
            KEY_Z       :   text = {text,"Z"};
            default     :   text = text;
        endcase
	end


    display_controller segment(CLK,digit1, digit0,an,seg,dp);
endmodule

