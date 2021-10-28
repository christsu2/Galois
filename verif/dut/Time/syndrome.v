/* Bleen Systems, Inc. Confidential Information */
/* Copyright (C) 2003 Baleen Systems, Inc. */

/* $Header: L:\\src/lightning2/rtl/ECC/syndrome.v,v 1.1 2003/05/27 17:34:54 JEROME Exp $ */
/*---------------------------------------------------------------------------*
 * Author            : Chris Tsu
 * Created on        : Tue March 15 13:19:51 PST 2003
 * Last checked in by: $Author: JEROME $
 * Last checked in on: $Date: 2003/05/27 17:34:54 $
 *
 *---------------------------------------------------------------------------*/
/*
 * $Log: syndrome.v,v $
 *
 */

module   syndrome(
                clk,
                reset,
		running,

                encoding,
	        endSegment,

		dataI,
		valid,
		blanking, 
	       	
                s0, 
		s1, 
		s2, 
		s3, 
		synReady,
 
		dataO
                );  
 
    /*-----------------------------------------------------------------------*/
    /*     Parameter Declaration (don't touch this parameter)                */
    /*-----------------------------------------------------------------------*/
    parameter   D = 1;                                              /* fixed */

 
input reset;
input clk;
input		running;
 
input            encoding;
input            endSegment, blanking;

output [7:0]     dataO;
input  [7:0]     dataI;
input		valid;
 
output [7:0]     s0, s1, s2, s3;

output           synReady;                        

reg [7:0] mdx1, mdx2, mdx3, aux;
reg [7:0] mdy1, mdy2, mdy3;

wire[7:0] mq1, mq2, mq3, mq0;
mul u_mul0 ( .a(aux ), .b( s0 ), .m(mq0) ); 
mul u_mul1 ( .a(mdx1), .b(mdy1), .m(mq1) ); 
mul u_mul2 ( .a(mdx2), .b(mdy2), .m(mq2) ); 
mul u_mul3 ( .a(mdx3), .b(mdy3), .m(mq3) ); 
/*
//   Decending alpha value generator follow  
//  "Systolic Architectures for decoding reed solomon codes" 
//       by John Nelson et. al
//       CH2920-7/90/0000/0067 IEEE 
*/ 
reg[7:0] alpha; 
reg      synStartP;

reg [2:0] state, nxtState;
parameter rstState = 7,
          standby  = 7,
	  waitforNxtValid = 5,
	  rstSyndrome     = 6,
	  synCal   = 4,
	  parity0  = 0,
	  parity1  = 1,
	  parity2  = 2,
	  parity3  = 3;


wire advanceA = state == synCal;  

always @(posedge clk or negedge reset) 
begin
	if(~reset) alpha <= #D 0;
	else if(~running | synStartP) alpha <= #D 8'hff;
	else 
	     if(advanceA)
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

wire [7:0] alphaSquare ; //= Square(alpha);
Square u_Square ( .k(alpha),  .q ( alphaSquare ) ); 

wire [7:0] alphaCubic  ; //= mul(alpha, alphaSquare);
mul u_mul5 ( .a(alpha), .b(alphaSquare),  .m(alphaCubic) ); 
	     
reg [7:0] s0, s1, s2, s3;

wire synReadyD = state == rstSyndrome;
reg  synReadyQ;
wire synReady = ~synReadyQ & synReadyD;

always @(posedge clk or negedge reset)
	if(!reset) synReadyQ <= #D 0;
	else       synReadyQ <= #D synReadyD;

wire advanceS = state == synCal && !blanking; 
	
always @(posedge clk or negedge reset)
	if(!reset) {s3,s2,s1,s0} <= #D 0;
	else if(~running) {s3,s2,s1,s0} <= #D 0;
	else if(synStartP) 
	     begin	
			s0 <= #D 0;
			s1 <= #D 0;
			s2 <= #D 0;
			s3 <= #D 0;
	     end
	else if (advanceS)
	     begin	
			s0 <= #D s0^dataI;
			s1 <= #D s1^mq1;
			s2 <= #D s2^mq2;
			s3 <= #D s3^mq3;
	     end

reg [1:0] validQ;
always @(posedge clk or negedge reset)
	if(!reset) validQ[1:0]  <= #D 0;
	else       validQ[1:0] <= #D {validQ[0], valid};    

wire delayValid = validQ[0];
	
parameter 
        p00 = 121, p01 = 228, p02 = 183, p03 =  43,
	p10 = 146, p11 =   4, p12 =  33, p13 = 183,
	p20 =  73, p21 = 169, p22 =   4, p23 = 228,
	p30 = 162, p31 =  73, p32 = 146, p33 = 121;


reg [7:0] dataO;


always @(posedge clk or negedge reset)
	if(!reset) state <= #D standby;
	else if(~running) state <= #D standby;
	else state <= #D nxtState;
 
always @( 
	   mq0
	or mq1
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
	or running
	or valid
	or delayValid
	or encoding
	or endSegment
	)
begin	
     
     dataO   = 8'hxx;
     synStartP   = 1'b0;
     mdx1       = 8'hxx;
     mdx2       = 8'hxx;     
     mdx3       = 8'hxx;     
     mdy1       = dataI;     
     mdy2       = dataI;     
     mdy3       = dataI;
     aux        = 8'hxx;
     
     nxtState= state;
     
     case(state)
     standby,  
     rstSyndrome:
        if(valid)
	begin
           synStartP = 1'b1;		
	   nxtState = synCal;
	end 
     waitforNxtValid:
        if(valid) nxtState = synCal;	     
          
     synCal:
     begin
	   dataO   = dataI;
	   mdx1       = alpha;
           mdx2       = alphaSquare;     
           mdx3       = alphaCubic; 
	   if(endSegment)
	   begin
              if(encoding) nxtState = parity0;
	      else         nxtState = rstSyndrome;
           end
	   else            nxtState =  waitforNxtValid;
     end	     
    parity0, parity1, parity2, parity3:
     begin
          mdx1       = s1;
	  mdx2       = s2;     
	  mdx3       = s3; 
  	  dataO = mq0 ^mq1^mq2^mq3;
          case(state[1:0])
             3:		  
	     begin
		mdy1 = p13;    
		mdy2 = p23;    
		mdy3 = p33;    
		aux = p03;
		if(delayValid) 
		begin	
			synStartP = 0;  
			nxtState =standby;
		end	
	     end	     
	     2:
	     begin
		mdy1 = p12;    
		mdy2 = p22;    
		mdy3 = p32;    
		aux = p02;
		if(delayValid) nxtState = parity3;
		     
             end
	     1:
             begin
		mdy1 = p11;    
		mdy2 = p21;    
		mdy3 = p31;    
		aux = p01;
		if(delayValid) nxtState = parity2;
             end		     
	     0:	
             begin
		mdy1 = p10;    
		mdy2 = p20;    
		mdy3 = p30;    
		aux = p00;
		if(delayValid) nxtState = parity1;
             end		        
		     
          endcase
        end	  
     endcase	     
end
endmodule  
