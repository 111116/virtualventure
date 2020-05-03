#pragma once

#include "data_types.hpp"


// glm 

mat4 perspective
(
	real const & tanHalfFOVy,
	real const & aspect, // x:y
	real const & zNear, 
	real const & zFar
)
{
	real range = tanHalfFOVy * zNear;
	real left = -range * aspect;
	real right = range * aspect;
	real bottom = -range;
	real top = range;

	mat4 Result;
	Result[0][0] = (real(2) * zNear) / (right - left);
	Result[1][1] = (real(2) * zNear) / (top - bottom);
	Result[2][2] = - (zFar + zNear) / (zFar - zNear);
	Result[3][2] = - real(1);
	Result[2][3] = - (real(2) * zFar * zNear) / (zFar - zNear);
	return Result;
}

mat4 lookAt
(
	vec3 const & eye, // camera origin
	vec3 const & dir, // normalized direction
	vec3 const & up, // normalized up vec, must be perpendicular
	vec3 const & right // normalized right vec, must be perpendicular
)
{
	mat4 Result;
	// first row
	Result[0][0] = right.x;
	Result[0][1] = right.y;
	Result[0][2] = right.z;
	// second row
	Result[1][0] = up.x;
	Result[1][1] = up.y;
	Result[1][2] = up.z;
	// third row
	Result[2][0] = -dir.x;
	Result[2][1] = -dir.y;
	Result[2][2] = -dir.z;
	// last column
	Result[0][3] =-dot(right, eye);
	Result[1][3] =-dot(up,    eye);
	Result[2][3] = dot(dir,   eye);
	// last row
	Result[3][0] = real(0);
	Result[3][1] = real(0);
	Result[3][2] = real(0);
	Result[3][3] = real(1);
	return Result;
}

mat4 viewport(int w, int h, int d)
{
	mat4 Result;
	// first row
	Result[0][0] = real(0.5*w);
	Result[0][1] = real(0);
	Result[0][2] = real(0);
	Result[0][3] = real(0.5*w);

	Result[1][0] = real(0);
	Result[1][1] = real(0.5*h);
	Result[1][2] = real(0);
	Result[1][3] = real(0.5*h);

	Result[2][0] = real(0);
	Result[2][1] = real(0);
	Result[2][2] = real(0.5*d);
	Result[2][3] = real(0.5*d);

	Result[3][0] = real(0);
	Result[3][1] = real(0);
	Result[3][2] = real(0);
	Result[3][3] = real(1);

	return Result;
}