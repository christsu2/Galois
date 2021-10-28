/* Bleen Systems, Inc. Confidential Information */
/* Copyright (C) 2003 Baleen Systems, Inc. */

/* $Header: L:\\src/lightning2/rtl/ECC/reedSolomon.v,v 1.1 2003/05/27 17:34:54 JEROME Exp $ */
/*---------------------------------------------------------------------------*
 * Author            : Chris Tsu
 * Created on        : Tue March 15 13:19:51 PST 2003
 * Last checked in by: $Author: JEROME $
 * Last checked in on: $Date: 2003/05/27 17:34:54 $
 *
 *---------------------------------------------------------------------------*/
/*
 * $Log: reedSolomon.v,v $
 * Revision 1.1  2003/05/27 17:34:54  JEROME
 * *** empty log message ***
 *
 * Revision 1.4  2003/04/29 00:50:05  mingl
 * new code with results in "absolute byte location"
 *
 * Revision 1.3  2003/04/28 21:32:09  mingl
 * change back to 4 syndrome ECC
 *
 * Revision 1.2  2003/03/19 18:41:03  mingl
 * add CVS header, change initial value of state machine (from 8'hxx to 8'h00)
 *
 *
 */

module reedSolomon(
                clk,
                reset,

		si0,
		si1,
		si2,
		si3,
		synReady,

		logSearch,
		romAdrs,
		romData,

		RSresults,
		RSdone
                );  
		  
parameter D= 1;		

input        clk, reset;
input [7:0]  si0, si1, si2, si3;
input        synReady;
output[33:0] RSresults;
output       RSdone;

output       logSearch;
output[7:0]  romAdrs;
input [7:0]  romData;


//Define all general registers here

reg [7:0]    s0, s1, rd, ra, rb, rc;
reg [7:0]    rdd, rad, rbd, rcd;
reg [1:0]    PSW, PSWd;
reg          ldPSW, ldrd, ldra, ldrb, ldrc;
wire[7:0]    Square_si1 , Square_rd;
reg   [7:0]  QuadTable; 

wire [33:0] RSresults = {PSW[1:0],rd, ra, rb, rc}; 

always @(posedge clk or negedge reset)
	if(!reset) s0 <= #D 0;
	else if (synReady) s0 <= #D si0;
 	
always @(posedge clk or negedge reset)
	if(!reset) s1 <= #D 0;
	else if (synReady) s1 <= #D si1;


	
always @(posedge clk or negedge reset)
	if(!reset) PSW <= #D 0;
	else if (ldPSW) PSW <= #D PSWd;

always @(posedge clk or negedge reset)
	if(!reset) ra <= #D 0;
	else if (ldra) ra <= #D rad;
	
always @(posedge clk or negedge reset)
	if(!reset) rb <= #D 0;
	else if (ldrb) rb <= #D rbd;
 		
always @(posedge clk or negedge reset)
	if(!reset) rc <= #D 0;
	else if (ldrc) rc <= #D rcd;

always @(posedge clk or negedge reset)
	if(!reset) rd <= #D 0;
	else if (ldrd) rd <= #D rdd;

reg   [7:0]  mdx, mdy;
wire  [7:0]  mq; // = mul(mdx,mdy);
mul   u_mul10 ( .a( mdx), .b( mdy), .m( mq) ); 
	
//Reed Solomon resolver state mechine

parameter standby = 31,
	  oneError = standby - 3, 
          checkSyndrome = 0;

  reg [4:0] state, nxtState;
wire RSdone = state ==standby;

always @(posedge clk or negedge reset)
	if(!reset) state <= #D standby;
	else state <= #D nxtState;

reg [7:0] romAdrs;
reg       logSearch;

always @(  si0
	or si1
	or si2
	or si3
	or synReady
	or s0
	or s1
	or mq
	or ra
	or rb
	or rc
	or rd
        or romData	
	or Square_rd or Square_si1
        or  QuadTable  
	or state
	)
begin	
     mdx       = 8'hxx;
     mdy       = 8'hxx;     

     rad       = 8'hxx;     
     rbd       = 8'hxx;     
     rcd       = 8'hxx;
     rdd       = 8'hxx;     
     PSWd      = 2'bxx;

     romAdrs   = 8'hxx;
     logSearch = 0;

     ldrd      = 0;
     ldra      = 0;
     ldrb      = 0;
     ldrc      = 0;
     ldPSW     = 0;
     
     nxtState= state;
     
     case(state)
     standby:
     begin
        if(synReady)
	  if(si0 == 0 && si1 == 0 && si2 == 0 && si3 == 0)
	  begin	  
	   ldPSW = 1; PSWd = 0;
          end
	  else
	  begin
	     mdx  = si0; mdy = si2;
             ldrd = 1; rdd = si2;		
             ldrb = 1; rbd = si3;
             ldra = 1; rad = mq^Square_si1; // A = s1^2+s0*s2
	     nxtState = checkSyndrome;
	  end    
     end	     
     checkSyndrome:// C = s2^2+s1*s3
     begin
        mdx = rb; mdy = s1;
        ldrc = 1; rcd = mq^Square_rd; 
	nxtState = state + 1;     
     end
     
     checkSyndrome+1: // B = s3*s0
     begin
        mdx = rb; mdy = s0;
        ldrb = 1; rbd = mq; 
	nxtState = state + 1;   
     end
     
     checkSyndrome+2: // B = s3*s0 + s1*s2
     begin
	mdx = rd; mdy = s1;
        ldrb = 1; rbd = rb^mq; 
	nxtState = state + 1;   
     end
     checkSyndrome+3:               // if(A=B=C=0) It is one error
     begin
        if( ra == 0 && rb == 0 && rc == 0)
	begin	
           romAdrs = s0;	
           ldra = 1; rad = romData; // A = inv(s0)
	   nxtState = oneError;
        end   
        else nxtState = state + 1;
     end
     checkSyndrome+4:               //Check for more then two error
     begin     
        romAdrs = ra;	
        ldra = 1; rad = romData;    // A = inv(A)
        nxtState = state + 1;
     end
     checkSyndrome+5:               // rd contains Sigma1 = B/A
     begin     
     	mdx = ra; mdy = rb;
        ldrd = 1; rdd = mq; 
        nxtState = state + 1;
     end     
     checkSyndrome+6:               //  rb contain Sigma2 = C/A 
     begin     
        mdx = ra; mdy = rc;
        ldrb = 1; rbd = mq; 
        nxtState = state + 1;
     end
     checkSyndrome+7:   
     begin     
        romAdrs = Square_rd;	
        ldra = 1; rad = romData;    // A = inv(Sigma1^2)
        nxtState = state + 1;
     end
     checkSyndrome+8:   
     begin     
        mdx = rb; mdy = ra;         // rb is the K value
        ldrb = 1; rbd = mq; 
        nxtState = state + 1;
     end
     checkSyndrome+9:               //Check for Quad Table
     begin     
     	if(rb[5] == 1'b1)
	begin
	   ldPSW = 1; PSWd = 3;     //if K value = 0, there is no root
	   nxtState = standby;
	end
	else
	begin
           ldrc = 1; rcd = QuadTable; // rc contain Alpha 
           nxtState = state + 1;
        end
     end
     checkSyndrome+10:   
     begin     
        mdx = rd; mdy = rc;         // rb is Real Label X = Sigma1*Alpha
        ldrb = 1; rbd = mq; 
	nxtState = state + 1;
     end	
     checkSyndrome+11:   
     begin     
	romAdrs=rb; logSearch = 1;  //rb = location of k
        ldrb = 1; rbd = romData;
	nxtState = state + 1; 
     end	
     checkSyndrome+12:
     begin	     
        mdx = rd; mdy = rc^1;       // rc is the Y = Sigma1*Alpha^1
        ldrc = 1; rcd = mq; 
        nxtState = state + 1;
     end	
     checkSyndrome+13:   
     begin     
        romAdrs = rd;	
        ldra = 1; rad = romData;    // A = inv(Sigma1)
        nxtState = state + 1;
     end
     checkSyndrome+14:   
     begin     
	romAdrs=rc; logSearch = 1;  //rd = location of l
        ldrd = 1; rdd = romData;
	nxtState = state + 1; 
     end
     checkSyndrome+15:
     begin	     
        mdx = rc; mdy = s0;         // rc = Alpha^L*s0+s1
        ldrc = 1; rcd = mq^s1; 
        nxtState = state + 1;
     end	
     checkSyndrome+16:   
     begin     
        mdx = ra; mdy = rc;         // rc is Error value of k, Ek
        ldrc = 1; rcd = mq; 
	nxtState = state + 1;
     end
     checkSyndrome+17:   
     begin     
        ldra = 1; rad = rc^s0;      // ra is Error value of l, El 
	ldPSW = 1; PSWd = 2;
	nxtState = standby;
     end
/*
//   One error solution
*/
	     
     oneError:
     begin
	mdx = ra; mdy = s1;
        ldrb = 1; rbd = mq; 
	nxtState = state + 1;   
     end
     oneError+1 :
     begin
	romAdrs=rb; logSearch = 1;   // rd is error location k
        ldrd = 1; rdd = romData;
	nxtState = state + 1;   
     end
     oneError+2 :  //s0 is the error value, ra is the error location
     begin
	ldra = 1; rad = s0;         // ra is Ek
	ldPSW = 1; PSWd = 1;
	nxtState = standby;   
     end
     endcase	     
end

Square  u_Square_rd ( .k( rd), .q(Square_rd) ); 
Square  u_Square_si1( .k(si1), .q(Square_si1)); 

//function
wire  [7:0] i = rb;
always@( i )
//Find root of Alpha^2 + Alpha + K = 0
//if Alpha1 is a root, then Alpha2 = Alpha1 +1 is also a root
//Table only need 7 bits, not 8 bits
//The table only need 128 entry, is i[5] == 1, there is no solution

//See Chris Tsu's derivation on the note

begin 

         QuadTable[0] = ~i[5];
         QuadTable[1] = i[4]^i[2]^i[0];
         QuadTable[2] = i[6]^i[4]^i[3]^i[0];
         QuadTable[3] = i[4]^i[3]^i[2]^i[1];
         QuadTable[4] = i[7]^i[0];
         QuadTable[5] = i[6]^i[4]^i[3]^i[2]^i[1];
         QuadTable[6] = i[7]^i[4]^i[2]^i[1]^i[0];
         QuadTable[7] = i[4]^i[2]^i[1]^i[0];
  
end  

endmodule  
