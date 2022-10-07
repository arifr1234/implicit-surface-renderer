struct R_params{
  float time;
};

dual R(dual3 p, R_params params)
{
    dual2 xy = dual2(p[0], p[1]);
    
    float r0 = 3.;
    float r1 = 1.;
    
    return Sq(Sqrt(AbsSq(xy)) - constant(r0)) + Sq(p[2]) - constant(sq(r1));
}