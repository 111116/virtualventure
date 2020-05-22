#pragma once


// 24bit fixed point
typedef int fixed;

// fixed fmul(fixed a, fixed b)
// {
// 	return int(((long long)a*b) >> 24)<<8;
// }

const int ratio = 16384;

fixed float2fixed(float x)
{
	return int(round(x*ratio))<<8;
}

float errorf(float x)
{
	return float(float2fixed(x)>>8)/ratio;
}

// short inv(short x)
// {
// 	if (x == 0) return 0;
// 	if (x == 1 || x == 2) return 32767;
// 	if (x == -1 || x == -2) return -32768;
// 	return short(round(65536.0 / x));
// }