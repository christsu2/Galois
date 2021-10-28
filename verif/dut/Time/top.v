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
 
 
reg[7:0] Test[511:0]; 
integer i,j; 
 
initial
begin
$dumpon;
$dumpfile("x.dmp");
$dumpvars;
end


reg [7:0] data;
reg       running;
reg       encoding, valid, endSegment, skip;
reg [7:0] flashMem[0:527];
reg [7:0] Flag[3:0];
reg [9:0] endSegmentD[2:0];
reg [9:0] endSegmentE[2:0];

wire [7:0] dataO;
wire       twoCycle = 1;
reg  [1:0] cycleDelay;

initial 
	
begin 

        endSegmentE[0] = 171; 
        endSegmentE[1] = 171 + 176; 
        endSegmentE[2] = 171 + 176*2;
       	
	endSegmentD[0] = 175; 
        endSegmentD[1] = 175 + 176; 
        endSegmentD[2] = 175 + 176*2;

	cycleDelay = twoCycle ? 1 :2;
	
        Flag[0] = 1; Flag[1] = 2; Flag[2] = 3; Flag[3] = 4;
	
	xin = 0;  
	reset = 0;
	encoding = 1;
	running = 0;
	valid = 0;
	skip = 0;
        endSegment = 0;
	
	for ( i = 0; i <= 511; i = i + 1)
	   Test[i] = ~i;

        repeat(3) @(posedge xin) #1;
	reset = 1;
        repeat(3) @(posedge xin) #1;		
	running = 1;  

        repeat(3) @(posedge xin) #1;		
        endSegment = 0;
	j = 0;

	for ( i = 0; i <= endSegmentE[0]; i = i + 1)
	begin
	   repeat (cycleDelay)@(posedge xin) #1;
	   valid = 1;
	   data = Test[j];
	   if(i == endSegmentE[0]) endSegment = 1; 
	   @(posedge xin) #1;
           flashMem[i] = data;
	   valid = 0;
	   j = j + 1;
        end
	
	for ( i = i; i <= endSegmentD[0]; i = i + 1)
	begin
	   repeat (cycleDelay)@(posedge xin) #1;
	   valid = 1;
	   endSegment = 0; 
	   @(posedge xin) #1;
           flashMem[i] = dataO;
	   valid = 0;
        end
	
/*
*
*
*
*/
       
	
        repeat(3) @(posedge xin) #1;	

	for ( i = i; i <= endSegmentE[1]; i = i + 1)
	begin
	   repeat (cycleDelay)@(posedge xin) #1;
	   valid = 1;

	   data = Test[j];
	   
	   if(i == endSegmentE[1]) endSegment = 1; 
	   @(posedge xin) #1;
           flashMem[i] = data;
	   valid = 0;
	   j = j + 1;
        end
	
	for ( i = i; i <= endSegmentD[1]; i = i + 1)
	begin
	   repeat (cycleDelay)@(posedge xin) #1;
	   valid = 1;
	   endSegment = 0; 
	   @(posedge xin) #1;
           flashMem[i] = dataO;
	   valid = 0;
        end
	
/*
*
*
*
*/
       
	
        repeat(3) @(posedge xin) #1;	

	for ( i = i; i <= endSegmentE[2]; i = i + 1)
	begin
	   repeat (cycleDelay)@(posedge xin) #1;
	   valid = 1;

	   if(j > 511) 
	   begin	   
	      skip = 1;
	      data = Flag[j-512];
           end
	   else data = Test[j];
	   
	   if(i == endSegmentE[2]) endSegment = 1; 
	   @(posedge xin) #1;
           flashMem[i] = data;
	   valid = 0;
	   j = j + 1;
        end
	
	for ( i = i; i <= endSegmentD[2]; i = i + 1)
	begin
	   repeat (cycleDelay)@(posedge xin) #1;
	   skip = 0;
	   valid = 1;
	   endSegment = 0; 
	   @(posedge xin) #1;
           flashMem[i] = dataO;
	   valid = 0;
        end
/*
*
*
*
*/	
        repeat(3) @(posedge xin) #1;
	running = 0;

	repeat(3) @(posedge xin) #1;
	running = 1;
	encoding = 0;

	repeat(3) @(posedge xin) #1;
	j = 0;
	i = 0;
	while(j < 3)
	begin	
	      repeat (cycleDelay)@(posedge xin) #1;
	      valid = 1;
	      data = flashMem[i];
	      if(i == 500) data = data^8'h08;
	      if(i == 510) data = data^8'h88;

	      if(i >= 520 && i <=523) skip = 1;
	      else                    skip = 0;
	      
	      if(i == endSegmentD[j])
	      begin	      
	              j = j + 1;
		      endSegment = 1;
	      end	      
	      else    endSegment = 0; 
	      @(posedge xin) #1;
             flashMem[i] = data;
	     valid = 0;
	     i = i + 1;
        end
        	
	repeat(100) @(posedge xin) #1;

	$finish; 
end 

wire [7:0] s0, s1, s2, s3;
wire       synReady;

wire	[7:0]	romAdrs;
wire		log;
wire	[7:0]	romData;

wire	[33:0]	RSresults;

	
syndrome   u_syndrome(
                .clk(xin),
                .reset(reset),
		.running(running),

                .encoding(encoding),
		.endSegment(endSegment),

		.dataI(data),
		.valid(valid),
		.blanking(skip),
 
                .s0(s0), 
		.s1(s1), 
		.s2(s2), 
		.s3(s3), 
		.synReady(synReady),
 
		.dataO(dataO)
                );


reedSolomon u_reedSolomon (
		.clk		( xin ),
		.reset		( reset ),
		.si0		( s0 ),
		.si1		( s1 ),
		.si2		( s2 ),
		.si3		( s3 ),
		.synReady	( synReady ),
		.logSearch	( log ),
		.romAdrs	( romAdrs ),
		.romData	( romData ),
		.RSresults	( RSresults ),
		.RSdone		( RSdone ));  

rsROM u_rsROM (		.i		( {log, romAdrs} ),
			.q		( romData ));	
endmodule
 
