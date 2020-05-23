template <typename T> 
tmat4x4<T> perspective
(
	T const & fovy, 
	T const & aspect, 
	T const & zNear, 
	T const & zFar
)
{
	T range = tan(radians(fovy / T(2))) * zNear;	
	T left = -range * aspect;
	T right = range * aspect;
	T bottom = -range;
	T top = range;

	tmat4x4<T> Result(T(0));
	Result[0][0] = (T(2) * zNear) / (right - left);
	Result[1][1] = (T(2) * zNear) / (top - bottom);
	Result[2][2] = - (zFar + zNear) / (zFar - zNear);
	Result[2][3] = - T(1);
	Result[3][2] = - (T(2) * zFar * zNear) / (zFar - zNear);
	return Result;
}

template <typename T> 
tmat4x4<T> lookAt
(
	tvec3<T> const & eye,
	tvec3<T> const & center,
	tvec3<T> const & up
)
{
	tvec3<T> f = normalize(center - eye); // direction
	tvec3<T> u = normalize(up); // up
	tvec3<T> s = normalize(cross(f, u)); // right
	u = cross(s, f); // perpendicular up

	tmat4x4<T> Result(1);
	// first row
	Result[0][0] = s.x;
	Result[1][0] = s.y;
	Result[2][0] = s.z;
	// second row
	Result[0][1] = u.x;
	Result[1][1] = u.y;
	Result[2][1] = u.z;
	// third row
	Result[0][2] =-f.x;
	Result[1][2] =-f.y;
	Result[2][2] =-f.z;
	// last column
	Result[3][0] =-dot(s, eye);
	Result[3][1] =-dot(u, eye);
	Result[3][2] = dot(f, eye);
	return Result;
}