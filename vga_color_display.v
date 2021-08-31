module vga_color_display(
	//input rgb,
	input Sw15, Sw14, Sw13, Sw12, Sw11, Sw10, Sw9, Sw8, Sw7, Sw6, Sw5, Sw4,
	input ClkPort,
	//SSD signal
	output An0, An1, An2, An3, An4, An5, An6, An7,
	output Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp
	);
	
	reg [4:0]	SSD;
	wire [4:0]	SSD7, SSD6, SSD4, SSD3, SSD1, SSD0;
	reg [7:0]  	SSD_CATHODES;
	wire [2:0] 	ssdscan_clk;
	wire Reset;
	
	wire [11:0] rgb;
	reg [11:0] RGB_IN;
	assign rgb = RGB_IN;
	
	always@ (*) begin	
		RGB_IN = {Sw15, Sw14, Sw13, Sw12, Sw11, Sw10, Sw9, Sw8, Sw7, Sw6, Sw5, Sw4};
	end
	
	reg [27:0]	DIV_CLK;
	always @ (posedge ClkPort, posedge Reset)  
	begin : CLOCK_DIVIDER
      if (Reset)
			DIV_CLK <= 0;
	  else
			DIV_CLK <= DIV_CLK + 1'b1;
	end
	
	// need a scan clk for the seven segment display 
	
	// 100 MHz / 2^18 = 381.5 cycles/sec ==> frequency of DIV_CLK[17]
	// 100 MHz / 2^19 = 190.7 cycles/sec ==> frequency of DIV_CLK[18]
	// 100 MHz / 2^20 =  95.4 cycles/sec ==> frequency of DIV_CLK[19]
	
	// 381.5 cycles/sec (2.62 ms per digit) [which means all 4 digits are lit once every 10.5 ms (reciprocal of 95.4 cycles/sec)] works well.
	
	//                  --|  |--|  |--|  |--|  |--|  |--|  |--|  |--|  |   
    //                    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 
	//  DIV_CLK[17]       |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
	//
	//               -----|     |-----|     |-----|     |-----|     |
    //                    |  0  |  1  |  0  |  1  |     |     |     |     
	//  DIV_CLK[18]       |_____|     |_____|     |_____|     |_____|
	//
	//         -----------|           |-----------|           |
    //                    |  0     0  |  1     1  |           |           
	//  DIV_CLK[19]       |___________|           |___________|
	//

	assign ssdscan_clk = DIV_CLK[19:17];
	assign An0	=  !(~(ssdscan_clk[2]) && ~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 000
	assign An1	=  !(~(ssdscan_clk[2]) && ~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 001
	assign An3	=  !(~(ssdscan_clk[2]) &&  (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 011
	assign An4	=  !( (ssdscan_clk[2]) && ~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 100
	assign An6	=  !( (ssdscan_clk[2]) &&  (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 110
	assign An7	=  !( (ssdscan_clk[2]) &&  (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 111
	// Turn off other 2 anodes
	assign {An2,An5} = 2'b11;
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD3, SSD4, SSD6, SSD7)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
				  3'b000: SSD = SSD0;
				  3'b001: SSD = SSD1;
				  3'b011: SSD = SSD3;
				  3'b100: SSD = SSD4;
				  3'b110: SSD = SSD6;
				  3'b111: SSD = SSD7;
		endcase 
	end
	
	//SSDs display 
	//to show how we can interface our "game" module with the SSD's, we output the 12-bit rgb background value to the SSD's
	assign SSD7 = 5'b11111; //encoding for r
	assign SSD6 = rgb[11:8];
	assign SSD4 = 5'b10000; //encoding for G
	assign SSD3 = rgb[7:4];
	assign SSD1 = 5'b01011; //encoding for B
	assign SSD0 = rgb[3:0];
	
	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD) // in this solution file the dot points are turned off by making Dp = 1
		    //                                                                abcdefg,Dp
			5'b00000: SSD_CATHODES = 8'b00000011; // 0
			5'b00001: SSD_CATHODES = 8'b10011111; // 1
			5'b00010: SSD_CATHODES = 8'b00100101; // 2
			5'b00011: SSD_CATHODES = 8'b00001101; // 3
			5'b00100: SSD_CATHODES = 8'b10011001; // 4
			5'b00101: SSD_CATHODES = 8'b01001001; // 5
			5'b00110: SSD_CATHODES = 8'b01000001; // 6
			5'b00111: SSD_CATHODES = 8'b00011111; // 7
			5'b01000: SSD_CATHODES = 8'b00000001; // 8
			5'b01001: SSD_CATHODES = 8'b00001001; // 9
			5'b01010: SSD_CATHODES = 8'b00010001; // A
			5'b01011: SSD_CATHODES = 8'b11000001; // B
			5'b01100: SSD_CATHODES = 8'b01100011; // C
			5'b01101: SSD_CATHODES = 8'b10000101; // D
			5'b01110: SSD_CATHODES = 8'b01100001; // E
			5'b01111: SSD_CATHODES = 8'b01110001; // F
			5'b11111: SSD_CATHODES = 8'b11110101; // r
			5'b10000: SSD_CATHODES = 8'b01000011; // G
			default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
		endcase
	end	
	
	// reg [7:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};
	
endmodule