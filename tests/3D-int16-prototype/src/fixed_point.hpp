#pragma once

// represent: sign, int 7b, frac 8b (-128.000 ~ 127.996)
// i.e. signed short x represents (float)x/256

short fmul(short a, short b)
{
	return short((int(a)*b) >> 8);
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
	return short(round(x*256));
}

float fixed2float(short x)
{
	return float(x)/256;
}

float errorf(float a)
{
	return fixed2float(float2fixed(a));
}

float error32(float a)
{
	return float(int(round(a*256)))/256;
}

float error24(float a)
{
	return float((int(round(a*32768))<<8)>>8)/32768;
}

short inv(short x)
{
	if (x == 0) return 0;
	if (x == 1 || x == 2) return 32767;
	if (x == -1 || x == -2) return -32768;
	return short(round(65536.0 / x));
}