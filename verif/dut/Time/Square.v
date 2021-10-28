/* Bleen Systems, Inc. Confidential Information */
/* Copyright (C) 2003 Baleen Systems, Inc. */

/* $Header: L:\\src/lightning2/rtl/ECC/Square.v,v 1.1 2003/05/27 17:41:45 JEROME Exp $ */
/*---------------------------------------------------------------------------*
 * Author            : Chris Tsu
 * Created on        : Tue March 15 13:19:51 PST 2003
 * Last checked in by: $Author: JEROME $
 * Last checked in on: $Date: 2003/05/27 17:41:45 $
 *
 *---------------------------------------------------------------------------*/
/*
 * $Log: Square.v,v $
 * Revision 1.1  2003/05/27 17:41:45  JEROME
 * *** empty log message ***
 *
 * Revision 1.2  2003/03/19 18:41:03  mingl
 * add CVS header, change initial value of state machine (from 8'hxx to 8'h00)
 *
 *
 */

module Square ( k, q) ;
input [ 7:0] k; 
output[ 7:0] q; 
reg   [ 7:0] Square; 

assign #1 q = Square; 

always@( k ) 
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

endmodule 
