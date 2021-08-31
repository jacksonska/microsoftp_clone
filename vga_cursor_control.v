`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jackson Skaaden
// 
// Create Date:    10:22:00 04/13/2021 
// Design Name: 
// Module Name:    vga_cursor_control 
// Project Name: 	
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
// Date: 04/04/2020
// Author: Jackson Skaaden 
// Description: Module for controlling cursor
//////////////////////////////////////////////////////////////////////////////////

module vga_cursor_control( 
	input clk,
	input reset,
	//TODO: input add up, down, left, right, 	//(Buttons - clear is BtnC) TODO: Implement moving the cursor
	input up, down, right, left, 			// Represent the respective button presses.
	input Sw0, Sw1, Sw2, 
	input Sw15, Sw14, Sw13, Sw12, Sw11, Sw10, Sw9, Sw8, Sw7, Sw6, Sw5, Sw4,	//Switches for color selection
	//TODO: implement switches for size selection
	//TODO: implement the switches for color choices? input all the switches?					
	input [9:0] hCount, vCount, 			//10-bit number used to determine the position of the pixel scan. 
											//Note: Because of porch and backporch, the initial position is  (hcount,vcount)~(144,35)
											// bottom left corner is ~(783,515).
	
	input bright, 							// bright is basically a flag that determines if a particular pixel is within the screen's display
	
	output reg [11:0] rgb,
	output reg[11:0] background
	);
	
	// initial = cursor state so no drawing, paint (do I want to do separate?), erase 
	localparam
	   QINITIAL = 2'b00, 
	   QPAINT 	= 2'b01,
	   QUNK 	= 2'b10, // Unkown state will take you to the initial state
	   QERASE 	= 2'b11;
	
	reg [1:0] state;
	reg [1:0] state_sel;
	//TODO: Add large registers to store the previous values - should be 20 bits
	
	// Loop variable for for loops in SM
	integer i;
	integer j;
	
	//Color hardcodes
	parameter BLACK = 12'b0000_0000_0000;
	parameter WHITE = 12'b1111_1111_1111;
	parameter RED   = 12'b1111_0000_0000;
	parameter GREEN = 12'b0000_1111_0000;
	
	// Addition numbers for cursor size
	parameter FIVE  = 10'b00_0000_0101;
	parameter TEN 	= 10'b00_0000_1010;
	
	// Variables local to module 
	wire block_colored; 			// will evaluate logic to determine if the block should be filled
	reg [9:0] x, y; 				//x and y position of the block. 450, 250 is center of screen 
	
	reg [11:0] color_sel; 			// Var to store the selected color
	reg trails[640:0][480:0];		// 600x480x1 
	
	
	
	
	wire cursor_size_sel;			// 1 == larger cursor desired; 0 == smaller cursor desired;
	reg [9:0] cursor_size;		

	 // initialize the background color we want. TODO: figure out if this should change colors ever?

		
	//Cursor is determined by switch 0.
	assign cursor_size_sel = Sw0;
	
	// Always block for determining the size of the cursor block --- Default value should be set to small --> FIVE
	// @NOTE: small = 10 x 10 pixels and large = 20 x 20 pixels.
	always @(*)
	begin
		if (cursor_size_sel)
		begin
			//The large cursor size was chosen so we want to add +5 or -5 to the x when determining when to fill pixel
			cursor_size = TEN;
		end
		else 
		begin 
			cursor_size = FIVE;
		end 
	end 
	
	
	//Block should be filled if within cursor range or there's a trail.
	assign block_colored = vCount >= (y - cursor_size) && vCount <= (y + cursor_size) 
						&& hCount >= ( x - cursor_size) && hCount <= (x + cursor_size) ||
						(trails[hCount][vCount] == 1);
	
	// Always block to determine what rgb color to be using for current pixel

	always @(*)
	begin : RGB_CONTROL
		if (~bright)
			rgb = BLACK; 		// force the pixel to black if outside screen
		else if (block_colored)
			if (state != QERASE)
				rgb = {Sw15, Sw14, Sw13, Sw12, Sw11, Sw10, Sw9, Sw8, Sw7, Sw6, Sw5, Sw4};
			else
				rgb = WHITE;  //Force the color to white if erasing.
		//if (trails[hCount][vCount] == 1) // If there's a trail for this position, then set display it. USING CURRENTLY SELECTED COLOR - ELSE IF?
			//rgb = {Sw15, Sw14, Sw13, Sw12, Sw11, Sw10, Sw9, Sw8, Sw7, Sw6, Sw5, Sw4};
		else
			rgb = background; 	//background is set in the initial block
	end
	
	// TODO: Add always block for switch control to change the color of the cursor.
	
	// General state machine for the cursor control
	always @(posedge clk, posedge reset)
	begin : STATE_MACHINE
		if (reset)
		begin
			state <= QINITIAL;
			
			// Place the block at the center
			x <= 450;
			y <= 250;
			background <= WHITE;
			//cursor_size_sel <= 1'b0;
		end
		else
		begin
			
			// State transitions determined by switches
			
			case(state)
				QINITIAL:
				begin
					//Initial State represents the Cursor mode
					//NSL
					if ( {Sw2, Sw1} != 2'b00)
						state <= {Sw2, Sw1};
					// Cursor color is the set color
					// Not saving values in the big array because cursor mode.
					//trails[x][y] = WHITE;
				end
				
				QPAINT:
				begin
					//NSL
					if ( {Sw2, Sw1} != 2'b01)
						state <= {Sw2, Sw1};
					
					//Painting so save the trail. - Should be size of the cursor in trails
					
					for (i =0 ; i < cursor_size; i = i + 1)
					begin	
						for (j = 0; j < cursor_size; j = j + 1)
						begin
							trails[x + i][y + i] <= 1'b1;
						end
					end
					
					//trails[x + cursor_size][y + cursor_size] <= rgb;
				end
				
				QERASE:
				begin
				
					if ( {Sw2, Sw1} != 2'b10)
						state <= {Sw2, Sw1};
						
					
					// Update the saved trail's pixels
					for (i =0 ; i < cursor_size; i = i + 1)
					begin	
						for (j = 0; j < cursor_size; j = j + 1)
						begin
							trails[x + i][y + i] <= 1'b0;
						end
					end
					
				end
				QUNK:
					state <= QINITIAL;
			endcase
			
			
		
			// change the value you +/- by to change the speed
			// Watch out for the border.
			if (up)
			begin
				y <= y - 4;
				if (y == 34)
					y <= 514;
			end
			
			if (down) 
			begin
				y <= y + 4;
				if (y == 514)
					y <= 34;
			end
			
			if (left)
			begin
				x <= x - 4;
				if (x == 150)
					x <= 800;
			end
			
			if (right)
			begin
				x <= x + 4;
				if (x == 800)
					x <= 150;
			end
			
			
			background <= WHITE;
			
			
		end
			
	end  

	
	
	//TODO: Add color selection for the cursor
endmodule
	
	
	
	
	
	
	
	
	