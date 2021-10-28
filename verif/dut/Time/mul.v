
`define DELAY_TIME  1

module mul ( a, b, m) ;
input [ 7:0] a, b; 
output[ 7:0] m; 
reg   [ 7:0] mx; 
reg[14:0]    p;

always@( a or b ) 
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
end
always@( p ) 
begin 
   mx[7] = p[13]^p[12]^p[11]^p[7];
   mx[6] = p[12]^p[11]^p[10]^p[6];
   mx[5] = p[11]^p[10]^p[ 9]^p[5];
   mx[4] = p[14]^p[10]^p[ 9]^p[8]^p[4];
   mx[3] = p[12]^p[11]^p[ 9]^p[8]^p[3];
   mx[2] = p[13]^p[12]^p[10]^p[8]^p[2];
   mx[1] = p[14]^p[13]^p[ 9]^p[1];
   mx[0] = p[14]^p[13]^p[12]^p[8]^p[0];
end			   
assign #`DELAY_TIME m = mx; 

endmodule 
