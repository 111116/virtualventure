#pragma once

#include <algorithm>
#include <iostream>

using std::min;
using std::max;

struct Color
{
	unsigned char r,g,b;
};

struct AAB
{
	int x,y,u,v,w,h;
	unsigned char d;
};