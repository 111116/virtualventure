#pragma once

#include "data_types.hpp"

void genmodel(int& nbox, AAB*& box)
{
	// an example model (cornell box)
	nbox = 1;
	AAB v[] = {
		{200, 200, 400, 400, 200, 200, 1}
	};

	assert(sizeof(AAB)*nbox == sizeof(v));
	box = new AAB[nbox*3];
	memcpy(box, v, sizeof v);
}