#include "data_types.hpp"
#include "consolelog.hpp"


Vertex vertexShader(const mat4& in_view, Vertex in)
{
	return in;
}

Color getTexture(int u, int v)
{
	// return ;
}

bool insideTriangle(real x, real y, Vertex v1, Vertex v2, Vertex v3)
{
	return true;
}

void render(const mat4& in_view, int in_ntrig, Vertex* in_trigs, char* out_color)
{
	// screen resolution
	const int w = 640;
	const int h = 480;
	real zbuffer[w][h];
	Color colorbuffer[w][h] = {0};
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
		// calculate bounding box
		int lbound = max(0, min(intfloor(sv1.x), min(intfloor(sv2.x), intfloor(sv3.x))));
		int rbound = min(w, max(intfloor(sv1.x), max(intfloor(sv2.x), intfloor(sv3.x)))+1);
		int ubound = max(0, min(intfloor(sv1.y), min(intfloor(sv2.y), intfloor(sv3.y))));
		int dbound = min(h, max(intfloor(sv1.y), max(intfloor(sv2.y), intfloor(sv3.y)))+1);
		console.log(lbound, rbound, ubound, dbound);
		// loop over all pixels in bounding box
		for (int x=lbound; x<rbound; ++x)
		for (int y=ubound; y<dbound; ++y)
		{
			// determine if pixel is inside triangle
			bool inside = insideTriangle(x,y, v1,v2,v3);
			// attribute perspective interpolation

			// check depth buffer

			// write color
			colorbuffer[x][y].r = 255;
			colorbuffer[x][y].g = 0;
			colorbuffer[x][y].b = 0;
		}
	}
	for (int i=0; i<w; ++i)
	for (int j=0; j<h; ++j)
		memcpy(out_color+(i+j*w)*3, colorbuffer[i]+j, 3);
}