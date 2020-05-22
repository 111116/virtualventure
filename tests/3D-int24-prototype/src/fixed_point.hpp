#pragma once


// 24bit fixed point
typedef int fixed;

// fixed fmul(fixed a, fixed b)
// {
// 	return int(((long long)a*b) >> 24)<<8;
// }

const int trail = 15;
const int ratio = 1<<trail;

fixed float2fixed(float x)
{
	return int(round(x*ratio))<<8;
}

float errorf(float x)
{
	return float(float2fixed(x)>>8)/ratio;
}

short inv12(short x)
{
	x = (x<<4)>>4;
	if (x == 0) return 0;
	return 4096/x;
}

fixed inv(fixed x)
{
	int a = x>>8;
	if (a==0) return -2147483648;
	int xref = (1<<(2*trail))/a;
	// return ((1<<(2*trail))/(x>>8))<<8;
	int a1 = ((std::abs(a)<32768?a>>4:a>>13)<<13)+(1<<12);
	int x1 = (1<<(2*trail))/a1;
	if (std::abs(a)<32768) x1<<=9;
	int x2 = 2*x1 - (((long long)a*x1*x1)>>(2*trail));
	int x3 = 2*x2 - (((long long)a*x2*x2)>>(2*trail));
	int x4 = 2*x3 - (((long long)a*x3*x3)>>(2*trail));
	// console.log(1<<(2*trail),a1,x1,x2);
	// int b2 = (1<<(2*trail))/a2;
	// int b = b1 + (a-a1)*(b2-b1)/(a2-a1);
	if (std::abs(x2-xref) > 1000) {
		console.log(1<<(2*trail),a,x1,x2, xref);
		console.log(x1-xref, x2-xref, "!", a);
	}
	return xref<<8;
}

float errinv(float x)
{
	int a = float2fixed(x);
	a = inv(a);
	return float(a>>8)/ratio;
}
// short inv(short x)
// {
// 	if (x == 0) return 0;
// 	if (x == 1 || x == 2) return 32767;
// 	if (x == -1 || x == -2) return -32768;
// 	return short(round(65536.0 / x));
// }