library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package uint32la is
	type ivec4 is array (0 to 3) of integer;
	type imat4 is array (0 to 15) of integer; -- row major
end package uint32la;

package body uint32la is

end package body uint32la;


use work.uint32la.all;

entity igemv44 is
	port (
		a: in imat4;
		x: in ivec4;
		y: out ivec4
	);
end entity igemv44;


architecture mul of igemv44 is

begin

	y(0) <= a(0)*x(0) + a(1)*x(1) + a(2)*x(2) + a(3)*x(3);
	y(1) <= a(4)*x(0) + a(5)*x(1) + a(6)*x(2) + a(7)*x(3);
	y(2) <= a(8)*x(0) + a(9)*x(1) + a(10)*x(2) + a(11)*x(3);
	y(3) <= a(12)*x(0) + a(13)*x(1) + a(14)*x(2) + a(15)*x(3);

end architecture mul;