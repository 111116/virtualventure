#include "data_types.hpp"
#include "consolelog.hpp"


Vertex vertexShader(mat4 in_view, Vertex in)
{
	Vertex out;
	out.x = in_view[0][0] * in.x + in_view[0][1] * in.y + in_view[0][2] * in.z + in_view[0][3];
	out.y = in_view[1][0] * in.x + in_view[1][1] * in.y + in_view[1][2] * in.z + in_view[1][3];
	out.z = in_view[2][0] * in.x + in_view[2][1] * in.y + in_view[2][2] * in.z + in_view[2][3];
	out.w = in_view[3][0] * in.x + in_view[3][1] * in.y + in_view[3][2] * in.z + in_view[3][3];
	// perspective
	out.w = real(1) / out.w;
	out.x *= out.w;
	out.y *= out.w;
	out.z *= out.w;
	// viewport
	out.x = (out.x+1) * 320;
	out.y = (-out.y+1) * 240;
	out.z = (out.z+1) * 0.5;
	return out;
}

Color getTexture(int u, int v)
{
	// return ;
}

bool insideTriangle(real x, real y, Vertex v1, Vertex v2, Vertex v3)
{
	// using cross products to determine if (x,y) is inside
	// a triangle of counter-clockwise ordered vertices

	return (v2.x-v1.x)*(y-v1.y) <= (v2.y-v1.y)*(x-v1.x)
		&& (v3.x-v2.x)*(y-v2.y) <= (v3.y-v2.y)*(x-v2.x)
		&& (v1.x-v3.x)*(y-v3.y) <= (v1.y-v3.y)*(x-v3.x) ||
		   (v2.x-v1.x)*(y-v1.y) >= (v2.y-v1.y)*(x-v1.x)
		&& (v3.x-v2.x)*(y-v2.y) >= (v3.y-v2.y)*(x-v2.x)
		&& (v1.x-v3.x)*(y-v3.y) >= (v1.y-v3.y)*(x-v3.x);
}

bool barycentricInterpolation(int x, int y, real& z, int& u, int& v, Vertex v1, Vertex v2, Vertex v3)
{

}

bool perspectiveInterpolation(int x, int y, int& z, int& u, int& v, Vertex v1, Vertex v2, Vertex v3)
{

}

void render(const mat4& in_view, int in_ntrig, Vertex* in_trigs, char* out_color)
{
	// screen resolution
	const int w = 640;
	const int h = 480;
	real zbuffer[w][h];
	Color colorbuffer[w][h];
	// clear buffers
	for (int i=0; i<w; ++i)
	for (int j=0; j<h; ++j) {
		zbuffer[i][j] = 1;
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
		Vertex sv1 = vertexShader(in_view, v1);
		Vertex sv2 = vertexShader(in_view, v2);
		Vertex sv3 = vertexShader(in_view, v3);
		// console.log(sv1, sv2, sv3);
		// backface culling
		// calculate bounding box
		int lbound = max(0, min(intfloor(sv1.x), min(intfloor(sv2.x), intfloor(sv3.x))));
		int rbound = min(w, max(intfloor(sv1.x), max(intfloor(sv2.x), intfloor(sv3.x)))+1);
		int ubound = max(0, min(intfloor(sv1.y), min(intfloor(sv2.y), intfloor(sv3.y))));
		int dbound = min(h, max(intfloor(sv1.y), max(intfloor(sv2.y), intfloor(sv3.y)))+1);
		// loop over all pixels in bounding box
		for (int x=lbound; x<rbound; ++x)
		for (int y=ubound; y<dbound; ++y)
		{
			// determine if pixel is inside triangle
			bool inside = insideTriangle(x,y, sv1,sv2,sv3);
			// attribute perspective interpolation
			int u,v;
			real z;
			// perspectiveInterpolation(x,y,z,u,v, v1,v2,v3);
			// test barycentric interpolation
			barycentricInterpolation(x,y,z,u,v, sv1,sv2,sv3);
			// check depth buffer
			bool overwrite = zbuffer[x][y] > z;
			overwrite = 1;
			// inside = 1;
			// write color
			if (inside && overwrite) {
				colorbuffer[x][y].r = 255;
				colorbuffer[x][y].g = 0;
				colorbuffer[x][y].b = 0;
				zbuffer[x][y] = z;
			}
		}
	}
	for (int i=0; i<w; ++i)
	for (int j=0; j<h; ++j)
		memcpy(out_color+(i+j*w)*3, colorbuffer[i]+j, 3);
}