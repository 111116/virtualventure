#include <iostream>
#include <fstream>
#include "stb_image.h"


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
	// check dimensions
	if (w!=1024 || h!=1024)
	{
		std::cerr << "Image must be 1024 x 1024.\n";
		return 1;
	}
	// binary output
	std::ofstream fout("texture.bin");
	for (int i=0; i<w*h; ++i) {
		fout << pixels[3*i+0] << pixels[3*i+1] << pixels[3*i+2] << char(0);
	}
}
