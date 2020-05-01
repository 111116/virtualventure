#pragma once

#include <algorithm>

using std::min;
using std::max;

typedef float real;

int intfloor(real a)
{
	return a<0? int(a-1): int(a);
}

struct vec3
{
	real x,y,z;
};

struct vec4
{
	real x,y,z,w;
};

struct Color
{
	unsigned char r,g,b;
};

struct mat4
{

};

typedef vec3 Vertex;