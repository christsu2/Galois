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
reg [7:0]    romDataQ;

wire [33:0] RSresults = {PSW[1:0],rd, ra, rb, rc}; 

always @(posedge clk or negedge reset)
	if(!reset)  romDataQ <= #D 0;
	else        romDataQ <= #D  romData;
 	
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
wire  [7:0]  mq = mul(mdx,mdy);
	
//Reed Solomon resolver state mechine

parameter standby = 31,
	  oneError = standby - 6, 
          checkSyndrome = 0;

  reg [4:0] state, nxtState;
wire RSdone = state ==standby;

always @(posedge clk or negedge reset)
	if(!reset) state <= #D standby;
	else state <= #D nxtState;

reg [7:0] romAdrs;
reg       logSearch;

always @(  
	   si2
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
        or romDataQ
	
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
             ldra = 1; rad = mq^Square(si1); // A = s1^2+s0*s2
	     nxtState = checkSyndrome;
	  end    
     end	     
     checkSyndrome:// C = s2^2+s1*s3
     begin
        mdx = rb; mdy = s1;
        ldrc = 1; rcd = mq^Square(rd); 
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
	   nxtState = oneError;
        end   
        else nxtState = state + 1;
     end

     checkSyndrome+4:               //Check for more then two error
     begin     
        romAdrs = ra;	
        nxtState = state + 1;
     end

     checkSyndrome+5:               //Check for more then two error
     begin     
        ldra = 1; rad = romDataQ;    // A = inv(A)
        nxtState = state + 1;
     end
     
     checkSyndrome+6:               // rd contains Sigma1 = B/A
     begin     
     	mdx = ra; mdy = rb;
        ldrd = 1; rdd = mq; 
        nxtState = state + 1;
     end     
     checkSyndrome+7:               //  rb contain Sigma2 = C/A 
     begin     
        mdx = ra; mdy = rc;
        ldrb = 1; rbd = mq; 
        nxtState = state + 1;
     end
     checkSyndrome+8:   
     begin     
        romAdrs = Square(rd);	
        nxtState = state + 1;
     end

     checkSyndrome+9:   
     begin     
        ldra = 1; rad = romDataQ;    // A = inv(Sigma1^2)
        nxtState = state + 1;
     end
     
     checkSyndrome+10:   
     begin     
        mdx = rb; mdy = ra;         // rb is the K value
        ldrb = 1; rbd = mq; 
        nxtState = state + 1;
     end
     checkSyndrome+11:               //Check for Quad Table
     begin     
     	if(rb[5] == 1'b1)
	begin
	   ldPSW = 1; PSWd = 3;     //if K value = 0, there is no root
	   nxtState = standby;
	end
	else
	begin
           ldrc = 1; rcd = QuadTable(rb); // rc contain Alpha 
           nxtState = state + 1;
        end
     end
     checkSyndrome+12:   
     begin     
        mdx = rd; mdy = rc;         // rb is Real Label X = Sigma1*Alpha
        ldrb = 1; rbd = mq; 
	nxtState = state + 1;
     end	
     checkSyndrome+13:   
     begin     
	romAdrs=rb; logSearch = 1;  //rb = location of k
	nxtState = state + 1; 
     end
     
     checkSyndrome+14:   
     begin     
        ldrb = 1; rbd = romDataQ;
	nxtState = state + 1; 
     end	
     
     checkSyndrome+15:
     begin	     
        mdx = rd; mdy = rc^1;       // rc is the Y = Sigma1*Alpha^1
        ldrc = 1; rcd = mq; 
        nxtState = state + 1;
     end	
     checkSyndrome+16:   
     begin     
        romAdrs = rd;	
        nxtState = state + 1;
     end

     checkSyndrome+17:   
     begin     
        ldra = 1; rad = romDataQ;    // A = inv(Sigma1)
        nxtState = state + 1;
     end
     
     checkSyndrome+18:   
     begin     
	romAdrs=rc; logSearch = 1;  //rd = location of l
	nxtState = state + 1; 
     end

     checkSyndrome+19:   
     begin     
        ldrd = 1; rdd = romDataQ;
	nxtState = state + 1; 
     end
     
     checkSyndrome+20:
     begin	     
        mdx = rc; mdy = s0;         // rc = Alpha^L*s0+s1
        ldrc = 1; rcd = mq^s1; 
        nxtState = state + 1;
     end	
     checkSyndrome+21:   
     begin     
        mdx = ra; mdy = rc;         // rc is Error value of k, Ek
        ldrc = 1; rcd = mq; 
	nxtState = state + 1;
     end
     checkSyndrome+22:   
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
        ldra = 1; rad = romDataQ; // A = inv(s0)
	nxtState = state + 1;   
     end

     oneError+1:
     begin
	mdx = ra; mdy = s1;
        ldrb = 1; rbd = mq; 
	nxtState = state + 1;   
     end
     
     oneError+2 :
     begin
	romAdrs=rb; logSearch = 1;   // rd is error location k
	nxtState = state + 1;   
     end

     oneError+3 :
     begin
        ldrd = 1; rdd = romDataQ;
	nxtState = state + 1;   
     end
     
     oneError+4 :  //s0 is the error value, ra is the error location
     begin
	ldra = 1; rad = s0;         // ra is Ek
	ldPSW = 1; PSWd = 1;
	nxtState = standby;   
     end
     endcase	     
end
/*
//	   Square and SquareRoot value of any Alpha  
//          by Chris Tsu's own derivation 
//
*/ 
function [7:0] Square;
input [7:0] k;
begin

	Square[7] = k[6];
	Square[6] = k[6]^k[5]^k[3];
	Square[5] = k[5];
	Square[4] = k[7]^k[5]^k[4]^k[2];
	Square[3] = k[6]^k[4];
	Square[2] = k[6]^k[5]^k[4]^k[1];
	Square[1] = k[7];
	Square[0] = k[7]^k[6]^k[4]^k[0];
end
endfunction 
 
function [7:0] QuadTable; 
input [7:0] i; 

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
endfunction



function [7:0] mul;
input [7:0] a,b;
reg [14:0] p;
begin
	
   p[14] = a[7]&b[7];
   p[13] = a[6]&b[7]^a[7]&b[6];
   p[12] = a[5]&b[7]^a[6]&b[6]^a[7]&b[5];
   p[11] = a[4]&b[7]^a[5]&b[6]^a[6]&b[5]^a[7]&b[4];
   p[10] = a[3]&b[7]^a[4]&b[6]^a[5]&b[5]^a[6]&b[4]^a[7]&b[3];
   p[9 ] = a[2]&b[7]^a[3]&b[6]^a[4]&b[5]^a[5]&b[4]^a[6]&b[3]^a[7]&b[2];
   p[8 ] = a[1]&b[7]^a[2]&b[6]^a[3]&b[5]^a[4]&b[4]^a[5]&b[3]^a[6]&b[2]^a[7]&b[1];
   p[7 ] = a[0]&b[7]^a[1]&b[6]^a[2]&b[5]^a[3]&b[4]^a[4]&b[3]^a[5]&b[2]^a[6]&b[1]^a[7]&b[0];
   p[6 ] = a[0]&b[6]^a[1]&b[5]^a[2]&b[4]^a[3]&b[3]^a[4]&b[2]^a[5]&b[1]^a[6]&b[0];
   p[5 ] = a[0]&b[5]^a[1]&b[4]^a[2]&b[3]^a[3]&b[2]^a[4]&b[1]^a[5]&b[0];	    
   p[4 ] = a[0]&b[4]^a[1]&b[3]^a[2]&b[2]^a[3]&b[1]^a[4]&b[0];	 		   
   p[3 ] = a[0]&b[3]^a[1]&b[2]^a[2]&b[1]^a[3]&b[0];						  
   p[2 ] = a[0]&b[2]^a[1]&b[1]^a[2]&b[0];	 
   p[1 ] = a[0]&b[1]^a[1]&b[0];	   		 
   p[0 ] = a[0]&b[0];	 
   
   mul[7] = p[13]^p[12]^p[11]^p[7];
   mul[6] = p[12]^p[11]^p[10]^p[6];
   mul[5] = p[11]^p[10]^p[ 9]^p[5];
   mul[4] = p[14]^p[10]^p[ 9]^p[8]^p[4];
   mul[3] = p[12]^p[11]^p[ 9]^p[8]^p[3];
   mul[2] = p[13]^p[12]^p[10]^p[8]^p[2];
   mul[1] = p[14]^p[13]^p[ 9]^p[1];
   mul[0] = p[14]^p[13]^p[12]^p[8]^p[0];
   		   		 
end			   
endfunction      
endmodule  


