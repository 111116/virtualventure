#include <iostream>
#include <cstdio>
#include "lib/writebmp.hpp"
#include "lib/stb_image.h"
#include "genmodel.hpp"
#include "render.hpp"

unsigned char* texturePixels;

Color getTexture(int addr)
{
	int pxoff = 3*addr;
	Color t;
	t.r = texturePixels[pxoff+0];
	t.g = texturePixels[pxoff+1];
	t.b = texturePixels[pxoff+2];
	return t;
}


int main()
{
	// generate model
	int n_box;
	AAB* v;
	genmodel(n_box, v);
	// load texture
	int texw, texh, texn;
	texturePixels = stbi_load("../texture.png", &texw, &texh, &texn, 3);
	assert(texw==1024);
	assert(texh==1024);
	// render to result
	char result[640*480*3] = {0};
	render(n_box, v, result, getTexture);
	writeBMP("1.bmp", result, 640, 480);
}