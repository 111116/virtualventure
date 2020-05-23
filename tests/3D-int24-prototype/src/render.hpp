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
	// out.w = 8.0 / out.w;
	out.w = errinv(out.w / 8.0);
	out.x *= out.w / 8.0;
	out.y *= out.w / 8.0;
	out.z *= out.w / 8.0;
	// viewport
	out.x = errorf((out.x+1) * 5);
	out.y = errorf((-out.y+1) * 3.75);
	out.z = errorf((out.z+1) * 0.5);
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
		const real denom = errinv((sv1.x-sv3.x) * (sv2.y-sv1.y)/1.0 - (sv1.x-sv2.x) * (sv3.y-sv1.y)/1.0);
		const vec3 bary_x = vec3( denom * (sv2.y - sv3.y)/1.0, denom * (sv3.y - sv1.y)/1.0, denom * (sv1.y - sv2.y)/1.0 );
		const vec3 bary_y = vec3( denom * (sv3.x - sv2.x)/1.0, denom * (sv1.x - sv3.x)/1.0, denom * (sv2.x - sv1.x)/1.0 );
		const vec3 bary_c = vec3(
	        denom * (sv2.x*sv3.y - sv3.x*sv2.y)/1.0,
	       	denom * (sv3.x*sv1.y - sv1.x*sv3.y)/1.0,
	        denom * (sv1.x*sv2.y - sv2.x*sv1.y)/1.0
	    ); // this must be stored in higher precision
		// calculate bounding box
		int lbound = max(0, min(intfloor(64*sv1.x), min(intfloor(64*sv2.x), intfloor(64*sv3.x))));
		int rbound = min(w, max(intfloor(64*sv1.x), max(intfloor(64*sv2.x), intfloor(64*sv3.x)))+1);
		int ubound = max(0, min(intfloor(64*sv1.y), min(intfloor(64*sv2.y), intfloor(64*sv3.y))));
		int dbound = min(h, max(intfloor(64*sv1.y), max(intfloor(64*sv2.y), intfloor(64*sv3.y)))+1);
		// loop over all pixels in bounding box
		for (int i=lbound; i<rbound; ++i)
		for (int j=ubound; j<dbound; ++j)
		{
			real x = (real)i/64;
			real y = (real)j/64;
			// barycentric coordinate
        	real bary1 = x * errorf(bary_x.x) + y * errorf(bary_y.x) + errorf(bary_c.x) + 0.0004;
        	real bary2 = x * errorf(bary_x.y) + y * errorf(bary_y.y) + errorf(bary_c.y) + 0.0004;
        	real bary3 = x * errorf(bary_x.z) + y * errorf(bary_y.z) + errorf(bary_c.z) + 0.0004;
			// determine if pixel is inside triangle
        	bool inside = bary1>=0 && bary2>=0 && bary3>=0;
			// perspective interpolation
			real z = bary1 * sv1.z + bary2 * sv2.z + bary3 * sv3.z;
			real w = bary1 * sv1.w + bary2 * sv2.w + bary3 * sv3.w;
			// near/far plane clip
			bool insideclip = z>=0 /*&& z<=1*/;
			// convert to perspective correct (clip-space) barycentric
			real inv_w = errinv(w);
			// real inv_w = 1/w;
			real psp1 = errorf(inv_w * bary1 * sv1.w);
			real psp2 = errorf(inv_w * bary2 * sv2.w);
			real psp3 = errorf(inv_w * bary3 * sv3.w);
			real u = psp1 * errorf(sv1.u) + psp2 * errorf(sv2.u) + psp3 * errorf(sv3.u);
			real v = psp1 * errorf(sv1.v) + psp2 * errorf(sv2.v) + psp3 * errorf(sv3.v);
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
