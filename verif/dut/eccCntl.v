module   eccCntl(
                    clk,
                    reset,

                    sramDi,
                    sramDo,
                    sramEnable,
                    sramAdrs,
                    sramWE,

                    flashDataValid,
                    flashDi,
                    flashDo,

                    encoding,
                    start, 
                    status,
                       
                   );  
 
    /*-----------------------------------------------------------------------*/
    /*     Parameter Declaration (don't touch this parameter)                */
    /*-----------------------------------------------------------------------*/
    parameter   D = 1;                                              /* fixed */

 
input reset;
input clk;  
output [7:0]     sramDi;
input  [7:0]     sramDo;
output           sramEnable;
output [8:0]     sramAdrs;
output           sramWE;

output           flashDataValid;
output[7:0]      flashDi;
input [7:0]      flashDo;

input            encoding;
input            start; 
output [7:0]     status;

wire             synDataValid, synDataReq;

wire             sramEnable = 0;
wire             sramWE = encoding ? 1 : synDataValid;

reg [8:0]        sramAdrs;	//count to 512 
reg [9:0]        flashDataCnt;  //count to 528        

//parameter firstFlag = 0,
parameter firstFlag = 512,
          secondFlag = firstFlag + 2;

  
wire       flagArea       =     flashDataCnt == firstFlag
                          |	flashDataCnt == firstFlag + 1
			  |	flashDataCnt == secondFlag
			  |	flashDataCnt == secondFlag + 1;
			  
wire	   parityArea     =	flashDataCnt == 172
			  |	flashDataCnt == 173
			  |	flashDataCnt == 174
			  |	flashDataCnt == 175
			  |	flashDataCnt == 348
			  |	flashDataCnt == 349
			  |	flashDataCnt == 350
			  |	flashDataCnt == 351
			  |	flashDataCnt == 524
			  |	flashDataCnt == 525
			  |	flashDataCnt == 526
			  |	flashDataCnt == 527;

wire	   endSegmentE    =	flashDataCnt == 172
			  |	flashDataCnt == 348
			  |	flashDataCnt == 524;
			  
wire	   endSegmentD     =	flashDataCnt == 175
			  |	flashDataCnt == 351
			  |	flashDataCnt == 527;

wire       endSegment = encoding ? endSegmentE : endSegmentD;
			  
wire	   sramCntInhibit =	flagArea | parityArea;

reg startQ, parityAreaQ, flagAreaQ, endSegmentQ;

always @(posedge clk or negedge reset)
	if(~reset)                         startQ <= #D 0;
	else if(start)                     startQ <= #D 1;
	     else if (flashDataCnt == 527) startQ <= #D 0; 

always @(posedge clk or negedge reset)
	if(~reset) { endSegmentQ, flagAreaQ } <= #D 0;
	else       { endSegmentQ, flagAreaQ } <= #D { endSegment, flagArea};
		
always @(posedge clk or negedge reset)
	if(~reset) flashDataCnt  <= #D 0;
	else if(start)
		   flashDataCnt  <= #D 0;  //alpha start at 175 
	     else if( flashDataCnt != 527) flashDataCnt <= #D flashDataCnt + 1;
	     
always @(posedge clk or negedge reset)
	if(~reset) sramAdrs  <= #D 0;
	else if(start)
		   sramAdrs  <= #D 0;  //alpha start at 175 
	     else if(~sramCntInhibit) sramAdrs <= #D sramAdrs + 1;
	     

			  
wire       synStart = startQ;
wire [7:0] s0, s1, s2, s3;
wire [7:0] synDataO;

wire [7:0] synDataI = encoding ? (flagAreaQ ? 8'hff : sramDo) : flashDo;                        

wire       flashDataValid = synDataValid;
wire [7:0] flashDi    = synDataO;
wire [7:0] sramDi     = synDataO;
wire       synReady;

syndrome syndrome1(
                .clk(clk),
                .reset(reset),

                .encoding(encoding),
                .start(synStart),
	
		.abort(),
		.endSegment(endSegment),

		.dataI(synDataI),
		.dataRequest(synDataReq),

		.s0(s0),
		.s1(s1),
		.s2(s2),
		.s3(s3),
		.synReady(synReady),

		.dataO(synDataO), 
		.dataValid(synDataValid)
                   ); 

wire        RSdone;
wire [33:0] RSresults;
wire [7:0] romAdrs;
wire       log;
wire [7:0] romData;

reedSolomon reedSolomon1(
                .clk(clk),
                .reset(reset),

		.si0(s0),
		.si1(s1),
		.si2(s2),
		.si3(s3),
		.synReady(synReady),

		.logSearch(log),
		.romAdrs(romAdrs),
		.romData(romData),

		.RSresults(RSresults), 
		.RSdone(RSdone)
                   );  
		   
rsROM    rsROM1( 
                 .i({log, romAdrs}),
                 .q(romData),
		 .clk(clk)
               );


  
endmodule 

 
