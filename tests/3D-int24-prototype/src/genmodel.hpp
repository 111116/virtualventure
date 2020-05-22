#pragma once

#include <vector>
#include "data_types.hpp"


std::vector<Vertex> genrail(real ox, real oy, real oz)
{
	// uv: 30,155 - 426,543
	// left front
	Vertex a = {-1 + ox, 0 + oy, 0 + oz, 1,  30, 543};
	// left back
	Vertex b = {-1 + ox, 0 + oy, 8 + oz, 1,  30, 155};
	// right front
	Vertex c = { 1 + ox, 0 + oy, 0 + oz, 1, 426, 543};
	// right back
	Vertex d = { 1 + ox, 0 + oy, 8 + oz, 1, 426, 155};
	a.u /= 64;
	a.v /= 64;
	b.u /= 64;
	b.v /= 64;
	c.u /= 64;
	c.v /= 64;
	d.u /= 64;
	d.v /= 64;
	return {a,b,d,a,d,c};
}

std::vector<Vertex> gencar(real ox, real oy, real oz)
{
	// params
	real topw = 0.55f; // half top width
	real botw = 0.8f; // half bottom width
	real toph = 2.0f; // height of car
	real both = 0.1f; // distance to ground
	real len  = 5.0f; // length of car
	// frontface uv: 50,796  216,796  4,1010  261,1010
	Vertex a = {-botw + ox, both + oy, 0 + oz, 1,  4, 1010}; // left bottom
	Vertex b = {-topw + ox, toph + oy, 0 + oz, 1,  50, 796}; // left top
	Vertex c = { botw + ox, both + oy, 0 + oz, 1, 261, 1010}; // right bottom
	Vertex d = { topw + ox, toph + oy, 0 + oz, 1, 216, 796}; // right top
	a.u /= 64; a.v /= 64;
	b.u /= 64; b.v /= 64;
	c.u /= 64; c.v /= 64;
	d.u /= 64; d.v /= 64;
	// top face uv: 268,759 - 600,814
	Vertex t1 = {-topw + ox, toph + oy,   0 + oz, 1, 268, 759};
	Vertex t2 = {-topw + ox, toph + oy, len + oz, 1, 600, 759};
	Vertex t3 = { topw + ox, toph + oy,   0 + oz, 1, 268, 814};
	Vertex t4 = { topw + ox, toph + oy, len + oz, 1, 600, 814};
	t1.u /= 64, t1.v /= 64;
	t2.u /= 64, t2.v /= 64;
	t3.u /= 64, t3.v /= 64;
	t4.u /= 64, t4.v /= 64;
	// left face uv: 282,821  744,821  268,1009  758,1009
	Vertex l1 = {-botw + ox, both + oy,   0 + oz, 1, 268, 1009}; // front bot
	Vertex l2 = {-topw + ox, toph + oy,   0 + oz, 1, 282, 821};  // front top
	Vertex l3 = {-botw + ox, both + oy, len + oz, 1, 758, 1009}; // far bot
	Vertex l4 = {-topw + ox, toph + oy, len + oz, 1, 744, 821};  // far top
	l1.u /= 64, l1.v /= 64;
	l2.u /= 64, l2.v /= 64;
	l3.u /= 64, l3.v /= 64;
	l4.u /= 64, l4.v /= 64;
	// right face uv: 282,821  744,821  268,1009  758,1009
	Vertex r1 = { botw + ox, both + oy,   0 + oz, 1, 268, 1009}; // front bot
	Vertex r2 = { topw + ox, toph + oy,   0 + oz, 1, 282, 821};  // front top
	Vertex r3 = { botw + ox, both + oy, len + oz, 1, 758, 1009}; // far bot
	Vertex r4 = { topw + ox, toph + oy, len + oz, 1, 744, 821};  // far top
	r1.u /= 64, r1.v /= 64;
	r2.u /= 64, r2.v /= 64;
	r3.u /= 64, r3.v /= 64;
	r4.u /= 64, r4.v /= 64;
	return {a,b,d,a,d,c, t1,t2,t4,t1,t4,t3, l1,l2,l4,l1,l4,l3, r1,r2,r4,r1,r4,r3};
}

void genmodel(int& n_triangle, Vertex*& vertices)
{
	// an example model (cornell box)
	n_triangle = 0;
	std::vector<Vertex> res;
	auto add = [&](std::vector<Vertex> v) {
		if (v.size()%3!=0) throw "invalid model";
		n_triangle += v.size()/3;
		for (auto a: v) res.push_back(a);
	};

	for (int i=0; i<60; i+=8) {
		add(genrail(0,0,i));
		add(genrail(-2,0,i));
		add(genrail(2,0,i));
	}
	add(gencar(-2,0,-5.5));
	add(gencar(-2,0,0));
	add(gencar(-2,0,5.5));
	add(gencar(2,0,11));
	add(gencar(2,0,16.5));
	add(gencar(0,0,20));
	add(gencar(0,0,25.5));

	vertices = new Vertex[n_triangle*3];
	for (int i=0; i<n_triangle*3; ++i)
		vertices[i] = res[i];
}