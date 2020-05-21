#pragma once

#include <functional>
#include <map>
#include "data_types.hpp"
#include "lib/consolelog.hpp"
#include "fixed_point.hpp"

std::map<std::string, std::pair<real, real>> rec;

#define record(x) {rec[#x].first=min(rec[#x].first,(x));rec[#x].second=max(rec[#x].second,(x));}

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
	out.x = (out.x+1) * 10;
	out.y = (-out.y+1) * 7.5;
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
		// backface culling: none
		// precompute barycentric coefficients
		const real denom = real(1) / ((sv1.x-sv3.x) * (sv2.y-sv1.y) - (sv1.x-sv2.x) * (sv3.y-sv1.y));
		const vec3 bary_x = vec3( denom * (sv2.y - sv3.y), denom * (sv3.y - sv1.y), denom * (sv1.y - sv2.y) );
		const vec3 bary_y = vec3( denom * (sv3.x - sv2.x), denom * (sv1.x - sv3.x), denom * (sv2.x - sv1.x) );
		const vec3 bary_c = vec3(
	        denom * (sv2.x*sv3.y - sv3.x*sv2.y),
	       	denom * (sv3.x*sv1.y - sv1.x*sv3.y),
	        denom * (sv1.x*sv2.y - sv2.x*sv1.y)
	    ); // this must be stored in higher precision
	    short bary_x_x = float2fixed(bary_x.x);
	    short bary_x_y = float2fixed(bary_x.y);
	    short bary_x_z = float2fixed(bary_x.z);
	    short bary_y_x = float2fixed(bary_y.x);
	    short bary_y_y = float2fixed(bary_y.y);
	    short bary_y_z = float2fixed(bary_y.z);
	    int bary_c_x = round(bary_c.x*256);
	    int bary_c_y = round(bary_c.y*256);
	    int bary_c_z = round(bary_c.z*256);
		// calculate bounding box
		int lbound = max(0, min(intfloor(32*sv1.x), min(intfloor(32*sv2.x), intfloor(32*sv3.x))));
		int rbound = min(w, max(intfloor(32*sv1.x), max(intfloor(32*sv2.x), intfloor(32*sv3.x)))+1);
		int ubound = max(0, min(intfloor(32*sv1.y), min(intfloor(32*sv2.y), intfloor(32*sv3.y))));
		int dbound = min(h, max(intfloor(32*sv1.y), max(intfloor(32*sv2.y), intfloor(32*sv3.y)))+1);
		// loop over all pixels in bounding box
		for (int i=lbound; i<rbound; ++i)
		for (int j=ubound; j<dbound; ++j)
		{
			real x = (real)i/32;
			real y = (real)j/32;
			// barycentric coordinate
        	real bary1 = x * bary_x.x + y * bary_y.x + bary_c.x;
        	real bary2 = x * bary_x.y + y * bary_y.y + bary_c.y;
        	real bary3 = x * bary_x.z + y * bary_y.z + bary_c.z;
			// determine if pixel is inside triangle
        	bool inside = bary1>=0 && bary2>=0 && bary3>=0;
			// perspective interpolation
			real z = bary1 * sv1.z + bary2 * sv2.z + bary3 * sv3.z;
			real w = bary1 * sv1.w + bary2 * sv2.w + bary3 * sv3.w;
			// near/far plane clip
			bool insideclip = z>=0 /*&& z<=1*/;
			// convert to perspective correct (clip-space) barycentric
			real inv_w = 1/w;
			// console.log(bary2, inv_w, sv2.w);
			// usable
			short psp1 = float2fixed(errorf(inv_w/4) * errorf(bary1) * errorf(sv1.w*4));
			short psp2 = float2fixed(errorf(inv_w/4) * errorf(bary2) * errorf(sv2.w*4));
			short psp3 = float2fixed(errorf(inv_w/4) * errorf(bary3) * errorf(sv3.w*4));
			short u = fmul(psp1, sv1.u) + fmul(psp2, sv2.u) + fmul(psp3, sv3.u);
			short v = fmul(psp1, sv1.v) + fmul(psp2, sv2.v) + fmul(psp3, sv3.v);
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

	// print stats
	// for (auto p: rec)
	// 	console.log(p.first, ' ', p.second.first, '~', p.second.second);
}
