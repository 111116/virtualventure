#pragma once

#include <algorithm>
#include <iostream>

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
	vec3() = default;
	vec3(real x, real y, real z): x(x), y(y), z(z) {}
};

real dot(vec3 a, vec3 b)
{
	return a.x*b.x + a.y*b.y + a.z*b.z;
}

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
	real a[4][4] = {{0}};
	real* operator[] (int i) { return a[i]; }
};
mat4 operator* (mat4 a, mat4 b)
{
	mat4 c;
	for (int i=0; i<4; ++i)
		for (int j=0; j<4; ++j)
			for (int k=0; k<4; ++k)
				c[i][j] += a[i][k] * b[k][j];
	return c;
}


typedef vec4 Vertex;


///////// debug use

std::ostream& operator<< (std::ostream& out, const Vertex& a)
{
	// return out << '(' << int(a.x) << "," << int(a.y) << ")";
	return out << '(' << a.x << "," << a.y << "," << a.z << "," << a.w << ")";
}
std::ostream& operator<< (std::ostream& out, mat4 a)
{
	out << "[";
	for (int i=0; i<4; ++i)
	{
		out << "[";
		for (int j=0; j<4; ++j)
		{
			out << a[i][j];
			if (j < 3) out << ',';
		}
		out << "]";
		if (i < 3) out << ',';
	}
	return out << "]";
}
