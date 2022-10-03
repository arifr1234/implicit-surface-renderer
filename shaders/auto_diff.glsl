#define dual vec2
#define dual2 mat2x2
#define dual4 mat4x2

#define complex vec2
#define dual_complex mat2x2

#define sq(x) dot(x, x)

dual Mul(dual a, dual b) { return dual(a.x * b.x, a.y * b.x + b.y * a.x); }
dual2 Mul(dual a, dual2 b) { return dual2(Mul(a, b[0]), Mul(a, b[1])); }
dual Sq(dual a) { return dual(sq(a.x), 2. * a.x * a.y); }
dual Sqrt(dual a) { return dual(sqrt(a.x), 0.5 * a.y * inversesqrt(a.x)); }
dual Div(dual a, dual b) { return dual(a.x / b.x, (a.y * b.x - b.y * a.x) / sq(b.x)); }
dual2 Div(dual2 a, dual b) { return dual2(Div(a[0], b), Div(a[1], b)); }
dual4 Div(dual4 a, dual b) { return dual4(Div(a[0], b), Div(a[1], b), Div(a[2], b), Div(a[3], b)); }
dual Exp(dual a) { return exp(a.x) * dual(1., a.y); }
dual Log(dual a) { return dual(log(a.x), a.y / a.x); }


// Complex:
complex mul(complex a, complex b) { return complex(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x); }
dual_complex Mul(dual_complex a, dual_complex b)
{
    return dual_complex(
        Mul(a[0], b[0]) - Mul(a[1], b[1]), 
        Mul(a[0], b[1]) + Mul(a[1], b[0])
    );
}
dual_complex Sq(dual_complex z) { return dual_complex(Sq(z[0]) - Sq(z[1]), 2. * Mul(z[0], z[1])); }
dual AbsSq(dual2 z) { return Sq(z[0]) + Sq(z[1]); }
dual_complex Conj(dual_complex z) { return matrixCompMult(z, mat2x2(vec2(1.), vec2(-1.))); }
dual_complex Inverse(dual_complex z) { return Div(Conj(z), AbsSq(z)); }
dual_complex Div(dual_complex a, dual_complex b) { return Mul(a, Inverse(b)); }
dual Abs(dual2 z) { return Sqrt(AbsSq(z)); }
dual2 Normalize(dual2 z) { return Div(z, Abs(z)); }
dual_complex Cis(dual a)
{
    return dual_complex(
        cos(a.x), -sin(a.x) * a.y,
        sin(a.x), cos(a.x) * a.y
    );
}
dual Atan(dual2 z)
{
    // (-y*x' + x*y') / (x**2 + y**2)
    return vec2(
        atan(z[1].x, z[0].x), 
        dot(
            vec2(-z[1].x, z[0].x), 
            vec2(z[0].y, z[1].y)
        ) / (sq(z[0].x) + sq(z[1].x))
    );
}
dual_complex Exp(dual_complex z) { return Mul(Exp(z[0]), Cis(z[1])); }
dual_complex Log(dual_complex z) {
    return dual_complex(
        0.5 * Log(AbsSq(z)), 
        Atan(z)
    ); 
}
dual_complex Pow(dual_complex z, float n)        { return Exp(    n * Log(z)); }
dual_complex Pow(dual_complex z, dual n)         { return Exp(Mul(n, Log(z))); }
dual_complex Pow(dual_complex z, dual_complex n) { return Exp(Mul(n, Log(z))); }