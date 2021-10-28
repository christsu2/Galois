`timescale 1 ns/100 ps

module top; 
 
    /*-----------------------------------------------------------------------*/
    /*     Parameter Declaration (don't touch this parameter)                */
    /*-----------------------------------------------------------------------*/
    parameter   D = 1;                                              /* fixed */

 
reg xin;  
reg reset;
 
always 	#29.5 xin = ~xin; 
integer count;  
 
reg [7:0] K, tmp, dataIn; 
 
reg[7:0] Test[255:0]; 
integer i,j; 
 
initial
begin
$dumpon;
$dumpfile("x.dmp");
$dumpvars;
end


reg [7:0] dataI;
wire[7:0] dataO;
reg [8:0] adrs;
reg       ce, we;
reg       eccStart;
reg       eccEncoding;
reg [7:0] flashMem[0:527];


wire [7:0] sramDi, sramDo;
wire [8:0] sramAdrs;
wire       sramEnable;
wire       sramWE;
wire [7:0] flashDi;
reg  [7:0] flashDo;
wire       flashDataValid;

initial 
	
	begin 

 
	xin = 0;  
	reset = 0;
	ce = 1;
	we = 1;
	eccEncoding = 1;
	eccStart = 0;

        repeat(3) @(posedge xin) #1;
	
	eccStart = 1;
	reset = 1;
	eccStart = 1;	
	ce = 0;
	we = 1;
		
	@(posedge xin) #1 eccStart = 0;  
	/*	
		for ( i = 0; i < 512; i = i + 1)
		begin

		   @(posedge xin) #1;
		   if(i <= 255) dataI = i;
		   else dataI = ~i;
                end

                @(posedge xin) #1;
        */
		
	j = 0;
	        
	for ( i = 0; i < 512+20; i = i + 1)
	begin
	    @(posedge xin);
	    if(flashDataValid)
            begin
	   	    
	       flashMem[j] = flashDi;
	       j = j + 1;
            end 
        end 

	eccEncoding = 0;
	eccStart = 1;
	for ( i = 0; i < 528; i = i + 1)
	begin
	    @(posedge xin) #2 ;
            begin
	       eccStart = 0;
	       if(i == 171) flashDo = 0;
	 //      else if(i == 171) flashDo = 0;
	      // else if(i == 170) flashDo = 0;
	       else flashDo = flashMem[i];
            end 
        end 

	repeat(3) @(posedge xin) #2 ;

		$finish; 
	end 
	
eccCntl     eccCntl1(
                    .clk(xin),
                    .reset(reset),

                    .sramDi(sramDi),
                    .sramDo(sramDo),
                    .sramEnable(sramEnable),
                    .sramAdrs(sramAdrs),
                    .sramWE(sramWE),

                    .flashDataValid(flashDataValid),
                    .flashDi(flashDi),
                    .flashDo(flashDo),

                    .encoding(eccEncoding),
                    .start(eccStart),
                    .status()
                       
                   ); 
 


sram512x8 sram512x8_0 (
                    .Q(sramDo),
                    .CLK(xin),
                    .CEN(sramEnable),
                    .WEN(sramWE),
                    .A(sramAdrs),
                    .D(sramDi),
                    .OEN(1'b0)
                      );
endmodule
 
