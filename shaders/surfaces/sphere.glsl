struct R_params{
  float time;
};

dual R(dual3 p, R_params params)
{
    return Sq(p[0]) + Sq(p[1]) + Sq(p[2]) - sq(2.);
}