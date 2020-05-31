// rgba5551 spritesheet to binary
#include <iostream>
#include <iomanip>
#include <fstream>
#include "lib/stb_image.h"


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
	unsigned char* pixels = stbi_load(argv[1], &w, &h, &n, 4);
	// check dimensions
	if (w!=1024 || h!=2048)
	{
		std::cerr << "Image must be 1024 x 2048 (portrait).\n";
		return 1;
	}
	// binary output
	std::ofstream fout("texture.bin");
	int opaque_cnt = 0;
	for (int i=0; i<w*h; ++i)
	{
		// fetch color
		int r = pixels[4*i+0];
		int g = pixels[4*i+1];
		int b = pixels[4*i+2];
		int a = pixels[4*i+3];
		// add noise
		r = std::max(0, std::min(255, r + rand()%7 - 3));
		g = std::max(0, std::min(255, g + rand()%7 - 3));
		b = std::max(0, std::min(255, b + rand()%7 - 3));
		// map [0,255] to [0,28]
		r = r * 28 / 247;
		g = g * 28 / 247;
		b = b * 28 / 247;
		a = a > 0;
		opaque_cnt += a;
		fout << char(r | ((g & 7) << 5)) << char((g>>3) | (b<<2) | (a<<7));
	}
	std::cout << std::fixed << std::setprecision(1) << (double) opaque_cnt / 2048 / 1024 * 100 << "% opqaue\n";
}
