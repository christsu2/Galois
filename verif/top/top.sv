`timescale 1 ns/100 ps

typedef logic [7:0] triplet_t[3]; 

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

typedef struct packed {
logic unsigned [7:0] data;
logic unsigned [7:0] min;
logic [7:0] occur;
} cubic_root_t;



initial begin
cubic_root_t [256] cub_root = 0;
logic [7:0]        value;
for(int i = 0; i < 256; i++)begin
	value = mul(Square(i), i);
	cub_root[value].data = i[7:0];
	if(cub_root[value].occur == 0) cub_root[value].min = 255;
	cub_root[value].occur += 1;
	if(cub_root[value].min >= cub_root[value].data) cub_root[value].min = cub_root[value].data;
end	

for(int i = 0; i < 256;i++) 
    $display("[%03d] ->  %1d;  %3d;  %3d", i, cub_root[i].occur, cub_root[i].min, cub_root[i].data);

$display("function logic [6:0] cub_rt(input logic [7:0] i);"); 
$display("   case(i) //cubic root table");
for(int i = 0; i < 256;i++) 
   if(cub_root[i].occur == 3) $display("      %3d: cub_rt = %3d;", i, cub_root[i].min);
$display("      default: cub_rt = 0;  //cubic root not exist");       	
$display("   endcase");
$display("endfunction");
end	

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
	       if(i == 12) flashDo = 0;
	       else if(i == 171) flashDo = 0;
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
 
