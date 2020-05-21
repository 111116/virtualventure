#pragma once

// represent: sign, int 7b, frac 8b (-128.000 ~ 127.996)
// i.e. signed short x represents (float)x/128

short fmul(short a, short b)
{
	return short((int(a)*b) >> 7);
}
int fmul_raw(short a, short b)
{
	return (int(a)*b);
}
short int2short(int a)
{
	return short(a>>8);
}

short float2fixed(float x)
{
	return short(round(x*128));
}

float fixed2float(short x)
{
	return float(x)/128;
}

float errorf(float a)
{
	return fixed2float(float2fixed(a));
}

short inv(short x)
{
	if (x == 0) return 0;
	return short(round(16384.0 / x));
}