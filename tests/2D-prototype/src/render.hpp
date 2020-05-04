#pragma once

#include <functional>
#include "data_types.hpp"
#include "lib/consolelog.hpp"


void render(int in_nbox, AAB* in_boxes, char* out_color, std::function<Color(int)> getTexture)
{
	// screen resolution
	const int w = 640;
	const int h = 480;
	unsigned char zbuffer[w][h];
	int uvbuffer[w][h];
	// clear buffers
	for (int i=0; i<w; ++i)
	for (int j=0; j<h; ++j) {
		zbuffer[i][j] = 255;
		uvbuffer[i][j] = 0;
	}
	// loop over all aabbs
	for (int i=0; i<in_nbox; ++i)
	{
		// fetch attributes
		int x = in_boxes[i].x;
		int y = in_boxes[i].y;
		int au = in_boxes[i].u;
		int av = in_boxes[i].v;
		int aw = in_boxes[i].w;
		int ah = in_boxes[i].h;
		unsigned char d = in_boxes[i].d;
		// calculate intersected bounding box
		int lbound = max(0, x);
		int rbound = min(w, x+aw);
		int ubound = max(0, y);
		int dbound = min(h, y+ah);
		// loop over all pixels in bounding box
		for (int i=lbound; i<rbound; ++i)
		for (int j=ubound; j<dbound; ++j)
		{
			// depth test
			if (d < zbuffer[i][j])
			{
				int u = au + i - x;
				int v = av + j - y;
				uvbuffer[i][j] = u+1024*v;
			}
		}
	}
	for (int i=0; i<w; ++i)
	for (int j=0; j<h; ++j)
	{
		Color tmp = getTexture(uvbuffer[i][j]);
		memcpy(out_color+(i+j*w)*3, &tmp, 3);
	}
}
