#include <iostream>

int main(){
	for (int i=0; i<640*480; ++i)
	{
		char c[4];
		memcpy(c, (char*)&i, sizeof c);
		for (int j=0; j<4; ++j)
			std::cout << c[j];
	}
}
