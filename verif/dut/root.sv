
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
function [7:0] Quad_root;
input [7:0] k;
begin

return 0;

end
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
function triplet_t Cubic_root( triplet_t sigma); 

 logic [7:0] term1, term2, C, V, U ;
 triplet_t   T, X;

 term2 = mul(sigma[1],sigma[2]) ^ sigma[0];
 term1 = Square(sigma[2]) ^ sigma[1]; 
 C     = mul(mul(Square(term1), term1), inv(Square(term2)));
 V     = QuadTable(C) | 1;
 U     = mul(term2,V);
 T[0]  = cub_rt(U);
 T[1]  = mul(T[0], exp[85]);
 T[2]  = mul(T[1], exp[85]);
 X[0]  = T[0] ^ sigma[2] ^ mul(term2, inv(T[0]));
 X[1]  = T[1] ^ sigma[2] ^ mul(term2, inv(T[1]));
 X[2]  = T[2] ^ sigma[2] ^ mul(term2, inv(T[2]));

return X;   

endfunction




