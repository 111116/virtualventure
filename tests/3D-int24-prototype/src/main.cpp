#include <iostream>
#include <cstdio>
#include "render.hpp"
#include "view.hpp"
#include "lib/writebmp.hpp"
#include "genmodel.hpp"
#include "lib/stb_image.h"

unsigned char* texturePixels;

Color getTexture(real u, real v)
{
	int i = intfloor(u*64);
	int j = intfloor(v*64);
	if (i<0 || i>=1024 || j<0 || j>=1024) return {255,255,255};
	int pxoff = 3*(j*1024 + i);
	Color t;
	t.r = texturePixels[pxoff+0];
	t.g = texturePixels[pxoff+1];
	t.b = texturePixels[pxoff+2];
	// add coordinate hint (plaided)
	// if (intfloor(49*u)%6==0)
	// {
	// 	t.r *= 0.7;
	// 	t.g *= 0.7;
	// 	t.b *= 0.7;
	// }
	// if (intfloor(49*v)%6==0)
	// {
	// 	t.r *= 0.7;
	// 	t.g *= 0.7;
	// 	t.b *= 0.7;
	// }
	return t;
}


int main()
{
	// generate model
	int n_trig;
	Vertex* v;
	genmodel(n_trig, v);
	// calculate transform matrix
	vec3 pos(0, 5, -6);
	vec3 dir(0,-0.3,0.953939);
	vec3 up(0,0.953939,0.3);
	vec3 right(-1,0,0);
	mat4 view = perspective(0.37,1.33333,0.1,20) * lookAt(pos, dir, up, right);
	console.log(view);
	// load texture
	int texw, texh, texn;
	texturePixels = stbi_load("../texture.png", &texw, &texh, &texn, 3);
	assert(texw==1024);
	assert(texh==1024);
	// render to result
	char result[640*480*3] = {0};
	render(view, n_trig, v, result, getTexture);
	writeBMP("1.bmp", result, 640, 480);
}