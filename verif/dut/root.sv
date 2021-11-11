
/*
//                     4. Solve X^2 + sigma1 X + sigma0 = 0 for X1.
//
//                        A. Calculate C from substitution of x = sigma1 Y.
//
//                           C = sigma0 / sigma1^2
//
//                        B. Get solution for Y1 & Y2 from quad table of Y^2 + Y + C = 0.
//
//                        C. Calculate X1 & X2 from substitution equation.
//
//                              X1 = sigma1 Y1,   X2 = sigma1 Y2
*/ 
function triplet_t Quad_root(triplet_t sigma);

logic [7:0] C, Y;
   C = mul(sigma[0], inv(Square(sigma[1])));
   Y = QuadTable(C);
   Quad_root[0] = mul(sigma[1], Y);
   Quad_root[1] = mul(sigma[1], Y^1);

endfunction 
/*
//                     2. Solve sigma(X) = X^3 + (sigma2)X^2 + (sigma1)X + sigma0 = 0
//
//                        A. Calculate C from substitutions.
//
//                           C  =  (sigma2^2  + sigma1)^3  / [(sigma1)(sigma2) + sigma0]^2
//
//                        B. Get solution for V from quad table of V^2 + V + C = 0.
//                           (Use odd solution for V)
//
//                        C. Get solution for U from substitution equation:
//
//                           U = [(sigma1)(sigma2) + sigma0] V
//
//                        D. Get solution for T1 from sustitution equation:
//
//                           T  = U^(1/3)
//                            1
//
//                        E. Get solutions for T2 & T3 from equation:
//
//                           T  = T1 <>^k
//                            2
//
//                           T  = T2 <>^k    where k = (2^n - 1)/3 = 85
//                            3
//
//                        F. Calculate X1, X2, & X3 from substitution equation.
//
//                           X1 = T1   +   sigma2   +   (sigma2^2 + sigma1)/T1
//
//                           X2 = T2   +   sigma2   +   (sigma2^2 + sigma1)/T2
//
//                           X3 = T3   +   sigma2   +   (sigma2^2 + sigma1)/T3
*/
function triplet_t Cubic_root(triplet_t sigma); 

 logic [7:0] term1, term2, C, V, U ;
 triplet_t   T, X;

 term1 = Square(sigma[2]) ^ sigma[1]; 
 term2 = mul(sigma[1],sigma[2]) ^ sigma[0];

 C     = mul(mul(Square(term1), term1), inv(Square(term2)));
 V     = QuadTable(C);
 U     = mul(term2,V);
 T[0]  = cub_rt(U);
 if(T[0] == 0) $display("Cubic Root does not exist!!!");
 T[1]  = mul(T[0], exp[85]);
 T[2]  = mul(T[1], exp[85]);
 X[0]  = T[0] ^ sigma[2] ^ mul(term1, inv(T[0]));
 X[1]  = T[1] ^ sigma[2] ^ mul(term1, inv(T[1]));
 X[2]  = T[2] ^ sigma[2] ^ mul(term1, inv(T[2]));

return X;   

endfunction

//Check root by plug into Cubic polynominal equation

function logic [7:0] Cubic_poly( triplet_t sigma, logic [7:0] x); 

 logic [7:0] term1;
 
 term1 = mul(Square(x), x) ^ mul(sigma[2], Square(x)) ^ mul(sigma[1], x) ^ sigma[0]; 
 
return term1;   

endfunction

//Check root by plug into Quadratic polynominal equation

function logic [7:0] Quad_poly( triplet_t sigma, logic [7:0] x); 

 logic [7:0] term1;
 
 term1 = Square(x) ^ mul(sigma[1], x) ^ sigma[0]; 
 
return term1;   

endfunction




