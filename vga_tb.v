//////////////////////////////////////////////////////////////////////////////////
// Author:		        Jackson Skaaden
// Create Date:         12:22:4 4/15/21 
// File Name:		    vga_tb.v
// Description: 
//
//
// Revision: 		    0.1 Creation
// Additional Comments:   
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module vga_tb_v;

	// Inputs to the core unit
	reg clk;
	reg Reset;
	reg up, down, left, right;
	reg Sw0;
	
	reg[9:0] hcount, vcount;
	reg bright;
	
	
	// Outputs to the core unit
	reg [11:0] rgb;
	reg [11:0] background;
	
	integer clk_cnt, clocks_taken;
	
	//instantiate your core design for testing (UUT)
	
	//Generate clock
	always begin #5; clk = ~clk; end
	//Track the clk count
	always@(posedge clk) clk_cnt = clk_cnt + 1;
	
	initial 
	begin
		//initialize inputs.
		clk_cnt = 0;
		clk = 0;
		Reset = 0;
		up = 0;
		down = 0;
		left = 0;
		right = 0;
		Sw0 = 0;
		
		//reset control
		@(posedge clk)
		@(posedge clk)
		#1;
		Reset = 1;
		@(posedge clk)
		#1;
		Reset = 0;
		
		
		
		
	end 
	
	
	//generate hcount and vcount
	always @(posedge clk, posedge Reset)
	begin 
		if (Reset)
		begin
			hcount <= 0;
			vcount <= 0;
		end 
	end 
	
	
	