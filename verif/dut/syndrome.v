module   syndrome(
                clk,
                reset,
 
                encoding,
                start,
		abort,
	        endSegment,

		dataI, 
		dataRequest, 
 
                s0, 
		s1, 
		s2, 
		s3, 
		synReady,
 
		dataO,  
		dataValid,
                );  
 
    /*-----------------------------------------------------------------------*/
    /*     Parameter Declaration (don't touch this parameter)                */
    /*-----------------------------------------------------------------------*/
    parameter   D = 1;                                              /* fixed */

 
input reset;
input clk;   
 
input            encoding;
input            start, abort, endSegment;

output [7:0]     dataO;
input  [7:0]     dataI; 
 
output [7:0]     s0, s1, s2, s3;

output           dataRequest;
output           dataValid;
output           synReady;                        

reg [7:0] byteCnt;     //byte count from 0 to 175

reg [7:0] mdx1, mdx2, mdx3;
reg [7:0] mdy1, mdy2, mdy3;

wire[7:0] mq1 = mul( mdx1, mdy1);
wire[7:0] mq2 = mul( mdx2, mdy2);
wire[7:0] mq3 = mul( mdx3, mdy3);

/*
//   Decending alpha value generator follow  
//  "Systolic Architectures for decoding reed solomon codes" 
//       by John Nelson et. al
//       CH2920-7/90/0000/0067 IEEE 
*/ 
reg[7:0] alpha; 
reg       synInit, synInitP, synReady, synStartP;
 
always @(posedge clk or negedge reset)
    begin	
	if(~reset) alpha <= #D 0;
	else if(synStartP | synInitP)
		alpha <= #D 8'hff;  //alpha start at 175 
	     else 
	     begin 
		alpha[7] <= #D alpha[0]; 
		alpha[6] <= #D alpha[7]; 
		alpha[5] <= #D alpha[6]; 
		alpha[4] <= #D alpha[5]; 
		alpha[3] <= #D alpha[4]^alpha[0]; 
		alpha[2] <= #D alpha[3]^alpha[0]; 
		alpha[1] <= #D alpha[2]^alpha[0]; 
		alpha[0] <= #D alpha[1]; 
	     end 
     end
wire [7:0] alphaSquare = Square(alpha);
wire [7:0] alphaCubic  = mul(alpha, alphaSquare);

	     
reg [7:0] s0, s1, s2, s3;
reg       synActive;
 
always @(posedge clk or negedge reset)
	if(!reset) synInit <= #D 0;
        else       synInit <= #D synInitP | synStartP;

always @(posedge clk or negedge reset)
	if(!reset) synReady <= #D 0;
	else       synReady <= #D synInitP & ~encoding;	

always @(posedge clk or negedge reset)
	if(!reset) {s3,s2,s1,s0} <= #D 0;
	else if (synActive) 
        begin
		   s0 <= #D synInit ? dataI : s0^dataI;
		   s1 <= #D synInit ? mq1   : s1^mq1;
		   s2 <= #D synInit ? mq2   : s2^mq2;
		   s3 <= #D synInit ? mq3   : s3^mq3;
        end		   

parameter 
        p00 = 121, p01 = 228, p02 = 183, p03 =  43,
	p10 = 146, p11 =   4, p12 =  33, p13 = 183,
	p20 =  73, p21 = 169, p22 =   4, p23 = 228,
	p30 = 162, p31 =  73, p32 = 146, p33 = 121;

reg [2:0] state, nxtState;
reg       dataValid;
reg [7:0] dataO;
reg       dataRequest;	     

parameter rstState = 7,
          standby  = 7,
	  synCal   = 4,
	  parity0  = 0,
	  parity1  = 1,
	  parity2  = 2,
	  parity3  = 3;

always @(posedge clk or negedge reset)
	if(!reset) state <= #D standby;
	else state <= #D nxtState;
 
always @(  
	   mq1
        or mq2
	or mq3
	or s0
	or s1
	or s2
	or s3
	or alpha
	or alphaSquare
	or alphaCubic
	or dataI
	or state
	or start
	or encoding
	or endSegment
	)
begin	

     
     dataO   = 8'hxx;
     dataValid  = 1'b0; 
     dataRequest = 0;
     synActive  = 1'b0;
     synInitP    = 1'b0;
     synStartP   = 1'b0;
     mdx1       = 8'hxx;
     mdx2       = 8'hxx;     
     mdx3       = 8'hxx;     
     mdy1       = dataI;     
     mdy2       = dataI;     
     mdy3       = dataI;

     
     nxtState= state;
     
     case(state)
     standby:
     begin
        if(start)
	begin
           synStartP = 1'b1;		
	   nxtState = synCal;
	end    
     end	     
     synCal:
     begin
	   synActive  = 1; 
	   dataRequest = 1;
	   dataValid  = 1;
	   dataO   = dataI;
	   mdx1       = alpha;
           mdx2       = alphaSquare;     
           mdx3       = alphaCubic; 
	   if(endSegment)
	   begin
                if(encoding) nxtState = parity0;
		else if(~start) nxtState = standby;
		     else 
			synInitP = 1;     
           end
             
     end	     
    parity0, parity1, parity2, parity3:
     begin
	  dataRequest = 1;
	  dataValid = 1;
          mdx1       = s1;
	  mdx2       = s2;     
	  mdx3       = s3; 
          case(state[1:0])
             3:		  
	     begin
		mdy1 = p13;    
		mdy2 = p23;    
		mdy3 = p33;    
		dataO = mul(p03,s0)^mq1^mq2^mq3;    
		if(~start) nxtState = standby;
		else 
		begin	
			synInitP = 1;  
			nxtState =synCal;
		end	
	     end	     
	     2:
	     begin
		mdy1 = p12;    
		mdy2 = p22;    
		mdy3 = p32;    
		dataO = mul(p02,s0)^mq1^mq2^mq3;    
		nxtState = parity3;
		     
             end
	     1:
             begin
		mdy1 = p11;    
		mdy2 = p21;    
		mdy3 = p31;    
		dataO = mul(p01,s0)^mq1^mq2^mq3;    
		nxtState = parity2;
             end		     
	     0:	
             begin
		mdy1 = p10;    
		mdy2 = p20;    
		mdy3 = p30;    
		dataO = mul(p00,s0)^mq1^mq2^mq3;   
		nxtState = parity1;
             end		        
		     
          endcase
        end	  
     endcase	     
end
   
  
endmodule  
 
