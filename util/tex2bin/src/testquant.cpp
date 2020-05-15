#include <iostream>
#include <fstream>
#include "stb_image.h"
#include "writebmp.h"


int main(int argc, char* argv[])
{
	// check cmdargs
	if (argc != 2)
	{
		std::cerr << "Usage: " << argv[0] << " <image file>\n";
		return 1;
	}
	// read image
	int w,h,n;
	unsigned char* pixels = stbi_load(argv[1], &w, &h, &n, 3);
	// binary output
	for (int i=0; i<w*h; ++i) {
		pixels[3*i+0] &= 224;
		pixels[3*i+1] &= 224;
		pixels[3*i+2] &= 224;
	}
	writeBMP("preview.bmp", (char*)pixels, w, h);
}
