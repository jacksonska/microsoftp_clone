`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer(s): Jackson Carroll and Jackson Skaaden 
// 
// Create Date:    12:18:00 12/14/2017 
// Design Name: 
// Module Name:    vga_top 
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
// Description: 
//////////////////////////////////////////////////////////////////////////////////
module vga_top(
	input ClkPort,
	input BtnC,
	input BtnU, BtnD, BtnL, BtnR,
	input Sw0, Sw1, Sw2, 
	input Sw15, Sw14, Sw13, Sw12, Sw11, Sw10, Sw9, Sw8, Sw7, Sw6, Sw5, Sw4,	//Switches for color selection
	//VGA signal
	output hSync, vSync,
	output [3:0] vgaR, vgaG, vgaB,
	
	//SSD signal 
	output An0, An1, An2, An3, An4, An5, An6, An7,
	output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,	
	output MemOE, MemWR, RamCS, QuadSpiFlashCS
	);
	
	// Vars to use/generate in Top
	
	// TODO: Use these if you make a new module for generting SSD output
	// wire [6:0] ssdOut;
	// wire [3:0] anode;
	
	reg [3:0]	SSD;
	wire [3:0]	SSD3, SSD2, SSD1, SSD0;
	reg [7:0]  	SSD_CATHODES;
	wire [1:0] 	ssdscan_clk;
	
	wire vga_clk;
	wire Reset;

	//Generated in Display controller module.
	wire bright;
	wire[9:0] hCount, vCount;
	
	//Generated in cursor control module
	wire [11:0] rgb;
	wire [11:0] background;
	// requires the vga_clk var generated in top
	

	// disable mamory ports
	assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;
	
	// Need div_clk for VGA 
	reg [27:0] DIV_CLK;
	always @ (posedge ClkPort, posedge Reset)  
	begin : CLOCK_DIVIDER
      if (Reset)
			DIV_CLK <= 0;
	  else
			DIV_CLK <= DIV_CLK + 1'b1;
	end
	
	assign Reset = BtnC;
		
	// Grab the slower clock for displaying movement on VGA.
	assign vga_clk = DIV_CLK[19]; 
	
	// Instantiate modules for display control and cursor control
	display_controller dc(.clk(ClkPort), .hSync(hSync), .vSync(vSync), 
		.bright(bright), .hCount(hCount), .vCount(vCount));
	
	//TODO: this signature will change when you add new functionalities to the system - color adjustment, etc.
	vga_cursor_control c_cursor(.clk(vga_clk), .reset(Reset), .up(BtnU), 
		.down(BtnD), .right(BtnR), .left(BtnL), .Sw0(Sw0), .Sw1(Sw1), 
		.Sw2(Sw2), .Sw4(Sw4), .Sw5(Sw5), .Sw6(Sw6), .Sw7(Sw7), .Sw8(Sw8), 
		.Sw9(Sw9), .Sw10(Sw10), .Sw11(Sw11), .Sw12(Sw12), .Sw13(Sw13), .Sw14(Sw14), 
		.Sw15(Sw15), .hCount(hCount), .vCount(vCount), .bright(bright), .rgb(rgb), 
		.background(background));
	
	// - module that determines what is getting displayed. vga_bitchange vbc(.clk(ClkPort), .bright(bright), .button(BtnU), .hCount(hc), .vCount(vc), .rgb(rgb), .score(score));
	// - module that determines the SSD stuff. counter cnt(.clk(ClkPort), .displayNumber(score), .anode(anode), .ssdOut(ssdOut));
	
	assign Dp = 1;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg} = 7'b1111111; //ssdOut[6 : 0];
    assign {An7, An6, An5, An4, An3, An2, An1, An0} = {4'b1111, 4'b1111};

	
	assign vgaR = rgb[11 : 8]; 
	assign vgaG = rgb[7  : 4];
	assign vgaB = rgb[3  : 0];
	
	

endmodule
