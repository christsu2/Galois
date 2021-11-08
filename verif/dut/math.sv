const logic [7:0] log[256] =
{
//  *LOGROM: Base on Mr. Tomisawa's basic data, i.e. Log(3) = 25 etc.
8'hff,  0,  1, 25,  2, 50, 26,198,  3,223, 51,238, 27,104,199, 75,
   4,100,224, 14, 52,141,239,129, 28,193,105,248,200,  8, 76,113,
   5,138,101, 47,225, 36, 15, 33, 53,147,142,218,240, 18,130, 69,
  29,181,194,125,106, 39,249,185,201,154,  9,120, 77,228,114,166,
   6,191,139, 98,102,221, 48,253,226,152, 37,179, 16,145, 34,136,
  54,208,148,206,143,150,219,189,241,210, 19, 92,131, 56, 70, 64,
  30, 66,182,163,195, 72,126,110,107, 58, 40, 84,250,133,186, 61,
 202, 94,155,159, 10, 21,121, 43, 78,212,229,172,115,243,167, 87,
   7,112,192,247,140,128, 99, 13,103, 74,222,237, 49,197,254, 24,
 227,165,153,119, 38,184,180,124, 17, 68,146,217, 35, 32,137, 46,
  55, 63,209, 91,149,188,207,205,144,135,151,178,220,252,190, 97,
 242, 86,211,171, 20, 42, 93,158,132, 60, 57, 83, 71,109, 65,162,
  31, 45, 67,216,183,123,164,118,196, 23, 73,236,127, 12,111,246,
 108,161, 59, 82, 41,157, 85,170,251, 96,134,177,187,204, 62, 90,
 203, 89, 95,176,156,169,160, 81, 11,245, 22,235,122,117, 44,215,
  79,174,213,233,230,231,173,232,116,214,244,234,168, 80, 88,175
};

const logic [7:0]  exp[256] =
{
// *EXPROM: Base on Mr. Tomisawa's basic data,
//  i.e. P(x) = x^8 + x^4 + x^3 + x^2 + 1,
//  x^8 = x^4 + x^3 + x^2 + 1 = 16 + 8 + 4 + 1 = 29

   1,  2,  4,  8, 16, 32, 64,128, 29, 58,116,232,205,135, 19, 38,
  76,152, 45, 90,180,117,234,201,143,  3,  6, 12, 24, 48, 96,192,
 157, 39, 78,156, 37, 74,148, 53,106,212,181,119,238,193,159, 35,
  70,140,  5, 10, 20, 40, 80,160, 93,186,105,210,185,111,222,161,
  95,190, 97,194,153, 47, 94,188,101,202,137, 15, 30, 60,120,240,
 253,231,211,187,107,214,177,127,254,225,223,163, 91,182,113,226,
 217,175, 67,134, 17, 34, 68,136, 13, 26, 52,104,208,189,103,206,
 129, 31, 62,124,248,237,199,147, 59,118,236,197,151, 51,102,204,
 133, 23, 46, 92,184,109,218,169, 79,158, 33, 66,132, 21, 42, 84,
 168, 77,154, 41, 82,164, 85,170, 73,146, 57,114,228,213,183,115,
 230,209,191, 99,198,145, 63,126,252,229,215,179,123,246,241,255,
 227,219,171, 75,150, 49, 98,196,149, 55,110,220,165, 87,174, 65,
 130, 25, 50,100,200,141,  7, 14, 28, 56,112,224,221,167, 83,166,
  81,162, 89,178,121,242,249,239,195,155, 43, 86,172, 69,138,  9,
  18, 36, 72,144, 61,122,244,245,247,243,251,235,203,139, 11, 22,
  44, 88,176,125,250,233,207,131, 27, 54,108,216,173, 71,142,  1
};

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

function logic [6:0] cub_rt(input logic [7:0] i);
   if(i[0] == 0) return 0; else //You only need odd quadrature root, see paper
   case(i) //cubic root table
        1: cub_rt =   1;
        7: cub_rt =  97;
        8: cub_rt =   2;
       10: cub_rt =  68;
       12: cub_rt =  58;
       15: cub_rt =   3;
       21: cub_rt =  35;
       23: cub_rt = 119;
       26: cub_rt =  59;
       33: cub_rt =  92;
       36: cub_rt =  15;
       37: cub_rt =  98;
       38: cub_rt =  32;
       39: cub_rt =  49;
       41: cub_rt =  86;
       44: cub_rt = 108;
       45: cub_rt =  64;
       47: cub_rt =  25;
       53: cub_rt =  67;
       54: cub_rt =  71;
       56: cub_rt =  73;
       58: cub_rt =   8;
       59: cub_rt =  51;
       61: cub_rt =  30;
       62: cub_rt =  81;
       64: cub_rt =   4;
       68: cub_rt =  78;
       70: cub_rt =  34;
       80: cub_rt =  45;
       85: cub_rt =   5;
       86: cub_rt = 125;
       87: cub_rt =  82;
       89: cub_rt =  44;
       96: cub_rt = 116;
       97: cub_rt = 104;
      100: cub_rt =  85;
      101: cub_rt =  50;
      102: cub_rt = 121;
      107: cub_rt =   7;
      110: cub_rt =  41;
      115: cub_rt =   9;
      117: cub_rt =  91;
      120: cub_rt =   6;
      125: cub_rt =  63;
      127: cub_rt =  14;
      130: cub_rt =  95;
      134: cub_rt =  39;
      138: cub_rt = 115;
      139: cub_rt =  54;
      143: cub_rt =  29;
      145: cub_rt =  36;
      146: cub_rt =  10;
      150: cub_rt =  77;
      161: cub_rt =  52;
      166: cub_rt =  22;
      168: cub_rt =  43;
      169: cub_rt =  46;
      173: cub_rt = 107;
      179: cub_rt =  42;
      181: cub_rt =  19;
      182: cub_rt =  56;
      184: cub_rt =  23;
      185: cub_rt =  26;
      186: cub_rt =  13;
      191: cub_rt =  18;
      193: cub_rt =  17;
      195: cub_rt = 101;
      196: cub_rt = 111;
      197: cub_rt = 102;
      205: cub_rt =  16;
      206: cub_rt =  74;
      207: cub_rt = 126;
      208: cub_rt =  37;
      217: cub_rt = 112;
      219: cub_rt = 122;
      221: cub_rt =  11;
      223: cub_rt =  28;
      228: cub_rt =  20;
      231: cub_rt =  12;
      237: cub_rt =  53;
      241: cub_rt =  61;
      242: cub_rt =  88;
      245: cub_rt =  60;
      251: cub_rt =  27;
      252: cub_rt =  21;
      default: cub_rt = 0;  //cubic root not exist
   endcase
endfunction


function logic [7:0] inv(input logic [7:0] i);
case(i)
//invert table

   0: inv =   1;
   1: inv =   1;
   2: inv = 142;
   3: inv = 244;
   4: inv =  71;
   5: inv = 167;
   6: inv = 122;
   7: inv = 186;
   8: inv = 173;
   9: inv = 157;
  10: inv = 221;
  11: inv = 152;
  12: inv =  61;
  13: inv = 170;
  14: inv =  93;
  15: inv = 150;
  16: inv = 216;
  17: inv = 114;
  18: inv = 192;
  19: inv =  88;
  20: inv = 224;
  21: inv =  62;
  22: inv =  76;
  23: inv = 102;
  24: inv = 144;
  25: inv = 222;
  26: inv =  85;
  27: inv = 128;
  28: inv = 160;
  29: inv = 131;
  30: inv =  75;
  31: inv =  42;
  32: inv = 108;
  33: inv = 237;
  34: inv =  57;
  35: inv =  81;
  36: inv =  96;
  37: inv =  86;
  38: inv =  44;
  39: inv = 138;
  40: inv = 112;
  41: inv = 208;
  42: inv =  31;
  43: inv =  74;
  44: inv =  38;
  45: inv = 139;
  46: inv =  51;
  47: inv = 110;
  48: inv =  72;
  49: inv = 137;
  50: inv = 111;
  51: inv =  46;
  52: inv = 164;
  53: inv = 195;
  54: inv =  64;
  55: inv =  94;
  56: inv =  80;
  57: inv =  34;
  58: inv = 207;
  59: inv = 169;
  60: inv = 171;
  61: inv =  12;
  62: inv =  21;
  63: inv = 225;
  64: inv =  54;
  65: inv =  95;
  66: inv = 248;
  67: inv = 213;
  68: inv = 146;
  69: inv =  78;
  70: inv = 166;
  71: inv =   4;
  72: inv =  48;
  73: inv = 136;
  74: inv =  43;
  75: inv =  30;
  76: inv =  22;
  77: inv = 103;
  78: inv =  69;
  79: inv = 147;
  80: inv =  56;
  81: inv =  35;
  82: inv = 104;
  83: inv = 140;
  84: inv = 129;
  85: inv =  26;
  86: inv =  37;
  87: inv =  97;
  88: inv =  19;
  89: inv = 193;
  90: inv = 203;
  91: inv =  99;
  92: inv = 151;
  93: inv =  14;
  94: inv =  55;
  95: inv =  65;
  96: inv =  36;
  97: inv =  87;
  98: inv = 202;
  99: inv =  91;
 100: inv = 185;
 101: inv = 196;
 102: inv =  23;
 103: inv =  77;
 104: inv =  82;
 105: inv = 141;
 106: inv = 239;
 107: inv = 179;
 108: inv =  32;
 109: inv = 236;
 110: inv =  47;
 111: inv =  50;
 112: inv =  40;
 113: inv = 209;
 114: inv =  17;
 115: inv = 217;
 116: inv = 233;
 117: inv = 251;
 118: inv = 218;
 119: inv = 121;
 120: inv = 219;
 121: inv = 119;
 122: inv =   6;
 123: inv = 187;
 124: inv = 132;
 125: inv = 205;
 126: inv = 254;
 127: inv = 252;
 128: inv =  27;
 129: inv =  84;
 130: inv = 161;
 131: inv =  29;
 132: inv = 124;
 133: inv = 204;
 134: inv = 228;
 135: inv = 176;
 136: inv =  73;
 137: inv =  49;
 138: inv =  39;
 139: inv =  45;
 140: inv =  83;
 141: inv = 105;
 142: inv =   2;
 143: inv = 245;
 144: inv =  24;
 145: inv = 223;
 146: inv =  68;
 147: inv =  79;
 148: inv = 155;
 149: inv = 188;
 150: inv =  15;
 151: inv =  92;
 152: inv =  11;
 153: inv = 220;
 154: inv = 189;
 155: inv = 148;
 156: inv = 172;
 157: inv =   9;
 158: inv = 199;
 159: inv = 162;
 160: inv =  28;
 161: inv = 130;
 162: inv = 159;
 163: inv = 198;
 164: inv =  52;
 165: inv = 194;
 166: inv =  70;
 167: inv =   5;
 168: inv = 206;
 169: inv =  59;
 170: inv =  13;
 171: inv =  60;
 172: inv = 156;
 173: inv =   8;
 174: inv = 190;
 175: inv = 183;
 176: inv = 135;
 177: inv = 229;
 178: inv = 238;
 179: inv = 107;
 180: inv = 235;
 181: inv = 242;
 182: inv = 191;
 183: inv = 175;
 184: inv = 197;
 185: inv = 100;
 186: inv =   7;
 187: inv = 123;
 188: inv = 149;
 189: inv = 154;
 190: inv = 174;
 191: inv = 182;
 192: inv =  18;
 193: inv =  89;
 194: inv = 165;
 195: inv =  53;
 196: inv = 101;
 197: inv = 184;
 198: inv = 163;
 199: inv = 158;
 200: inv = 210;
 201: inv = 247;
 202: inv =  98;
 203: inv =  90;
 204: inv = 133;
 205: inv = 125;
 206: inv = 168;
 207: inv =  58;
 208: inv =  41;
 209: inv = 113;
 210: inv = 200;
 211: inv = 246;
 212: inv = 249;
 213: inv =  67;
 214: inv = 215;
 215: inv = 214;
 216: inv =  16;
 217: inv = 115;
 218: inv = 118;
 219: inv = 120;
 220: inv = 153;
 221: inv =  10;
 222: inv =  25;
 223: inv = 145;
 224: inv =  20;
 225: inv =  63;
 226: inv = 230;
 227: inv = 240;
 228: inv = 134;
 229: inv = 177;
 230: inv = 226;
 231: inv = 241;
 232: inv = 250;
 233: inv = 116;
 234: inv = 243;
 235: inv = 180;
 236: inv = 109;
 237: inv =  33;
 238: inv = 178;
 239: inv = 106;
 240: inv = 227;
 241: inv = 231;
 242: inv = 181;
 243: inv = 234;
 244: inv =   3;
 245: inv = 143;
 246: inv = 211;
 247: inv = 201;
 248: inv =  66;
 249: inv = 212;
 250: inv = 232;
 251: inv = 117;
 252: inv = 127;
 253: inv = 255;
 254: inv = 126;
 255: inv = 253;
endcase

endfunction
