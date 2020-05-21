#pragma once

#include <functional>
#include "data_types.hpp"
#include "lib/consolelog.hpp"


Vertex perVertex(mat4 in_view, Vertex in)
{
	Vertex out;
	out.x = in_view[0][0] * in.x + in_view[0][1] * in.y + in_view[0][2] * in.z + in_view[0][3];
	out.y = in_view[1][0] * in.x + in_view[1][1] * in.y + in_view[1][2] * in.z + in_view[1][3];
	out.z = in_view[2][0] * in.x + in_view[2][1] * in.y + in_view[2][2] * in.z + in_view[2][3];
	out.w = in_view[3][0] * in.x + in_view[3][1] * in.y + in_view[3][2] * in.z + in_view[3][3];
	// perspective division
	out.w = real(1) / out.w;
	out.x *= out.w;
	out.y *= out.w;
	out.z *= out.w;
	// viewport
	out.x = (out.x+1) * 320;
	out.y = (-out.y+1) * 240;
	out.z = (out.z+1) * 0.5;
	// texture coord
	out.u = in.u;
	out.v = in.v;
	return out;
}

// perspective interpolation https://stackoverflow.com/a/24460895/7884249
void render(const mat4& in_view, int in_ntrig, Vertex* in_trigs, char* out_color, std::function<Color(real,real)> getTexture)
{
	// screen resolution
	const int w = 640;
	const int h = 480;
	real zbuffer[w][h];
	Color colorbuffer[w][h];
	// clear buffers
	for (int i=0; i<w; ++i)
	for (int j=0; j<h; ++j) {
		zbuffer[i][j] = 100; // max value possible
		colorbuffer[i][j].r = 0;
		colorbuffer[i][j].g = 0;
		colorbuffer[i][j].b = 0;
	}
	// loop over all triangles
	for (int i=0; i<in_ntrig; ++i)
	{
		// fetch triangle
		Vertex v1 = in_trigs[3*i+0];
		Vertex v2 = in_trigs[3*i+1];
		Vertex v3 = in_trigs[3*i+2];
		// apply transformation
		Vertex sv1 = perVertex(in_view, v1);
		Vertex sv2 = perVertex(in_view, v2);
		Vertex sv3 = perVertex(in_view, v3);
		// backface culling
		// precompute barycentric coefficients
		const real denom = real(1) / ((sv1.x-sv3.x) * (sv2.y-sv1.y) - (sv1.x-sv2.x) * (sv3.y-sv1.y));
		const vec3 bary_x = vec3( denom * (sv2.y - sv3.y), denom * (sv3.y - sv1.y), denom * (sv1.y - sv2.y) );
		const vec3 bary_y = vec3( denom * (sv3.x - sv2.x), denom * (sv1.x - sv3.x), denom * (sv2.x - sv1.x) );
		const vec3 bary_c = vec3(
	        denom * (sv2.x*sv3.y - sv3.x*sv2.y),
	       	denom * (sv3.x*sv1.y - sv1.x*sv3.y),
	        denom * (sv1.x*sv2.y - sv2.x*sv1.y)
	    );
		// calculate bounding box
		int lbound = max(0, min(intfloor(sv1.x), min(intfloor(sv2.x), intfloor(sv3.x))));
		int rbound = min(w, max(intfloor(sv1.x), max(intfloor(sv2.x), intfloor(sv3.x)))+1);
		int ubound = max(0, min(intfloor(sv1.y), min(intfloor(sv2.y), intfloor(sv3.y))));
		int dbound = min(h, max(intfloor(sv1.y), max(intfloor(sv2.y), intfloor(sv3.y)))+1);
		// loop over all pixels in bounding box
		for (int i=lbound; i<rbound; ++i)
		for (int j=ubound; j<dbound; ++j)
		{
			real x = i;
			real y = j;
			// barycentric coordinate
        	const vec3 bary = vec3(
        		x * bary_x.x + y * bary_y.x + bary_c.x,
        		x * bary_x.y + y * bary_y.y + bary_c.y,
        		x * bary_x.z + y * bary_y.z + bary_c.z
        	);
			// determine if pixel is inside triangle
        	bool inside = bary.x>=0 && bary.y>=0 && bary.z>=0;
			// perspective interpolation
			real z = dot(bary, vec3(sv1.z, sv2.z, sv3.z));
			real w = dot(bary, vec3(sv1.w, sv2.w, sv3.w));
			// near/far plane clip
			bool insideclip = z>=0 /*&& z<=1*/;
			// convert to perspective correct (clip-space) barycentric
			const vec3 perspective = vec3(
				1/w * bary.x * sv1.w,
				1/w * bary.y * sv2.w,
				1/w * bary.z * sv3.w
			);
			real u = dot(perspective, vec3(sv1.u, sv2.u, sv3.u));
			real v = dot(perspective, vec3(sv1.v, sv2.v, sv3.v));
			// check depth buffer
			bool overwrite = zbuffer[i][j] > z;
			// write color
			if (inside && overwrite && insideclip) {
				colorbuffer[i][j] = getTexture(u,v);
				zbuffer[i][j] = z;
			}
		}
	}
	for (int i=0; i<w; ++i)
	for (int j=0; j<h; ++j)
		memcpy(out_color+(i+j*w)*3, colorbuffer[i]+j, 3);
}
