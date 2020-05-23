#pragma once

// represent: sign, int 7b, frac 8b (-128.000 ~ 127.996)
// i.e. signed short x represents (float)x/128

short fmul(short a, short b)
{
	return short((int(a)*b) >> 7);
}
int fmul_raw(short a, short b)
{
	return int(((long long)a*b) >> 24)<<8;
}

fixed float2fixed(float x)
{
	return int(round(x*32768))<<8;
}

float error24(float a)
{
	return float((int(round(a*32768))<<8)>>8)/32768;
}

// short inv(short x)
// {
// 	if (x == 0) return 0;
// 	if (x == 1 || x == 2) return 32767;
// 	if (x == -1 || x == -2) return -32768;
// 	return short(round(65536.0 / x));
// }
