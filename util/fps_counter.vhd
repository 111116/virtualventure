-- counts number of input falling_edge in a second
-- outputs to LCD

library  ieee;
use      ieee.std_logic_1164.all;

entity fps_counter is
	port (
		clk0 : in std_logic; -- 100MHz input
		sgn  : in std_logic; -- counted signal 
		-- output 7-seg digits
		dgt2 : out std_logic_vector(6 downto 0);
		dgt1 : out std_logic_vector(6 downto 0);
		dgt0 : out std_logic_vector(6 downto 0)
	) ;
end entity ; -- fps_counter

architecture arch of fps_counter is

	component bcd_decoder is
		port (
			num: in std_logic_vector(3 downto 0); -- 8421 input
			bcd: out std_logic_vector(6 downto 0) -- digit display output	
		);
	end component;

	signal t0: integer range 0 to 100000000 := 0;
	signal cnt: integer range 0 to 10000 := 0;    -- count in current second
	signal outcnt: integer range 0 to 10000 := 0; -- cached count in last second
	signal n2, n1, n0: integer range 0 to 100; -- digits

begin

	-- assign to digits
	n2 <= outcnt / 100;
	n1 <= (outcnt / 10) mod 10;
	n0 <= outcnt mod 10;

	-- reset counter every second
	process (clk0)
	begin
		if rising_edge(clk0) then
			if t0 = 99999999 then
				t0 <= 0;
				outcnt <= cnt;
				cnt <= 0;
			else
				t0 <= t0 + 1;
			end if;
		end if;
	end process;

	-- count increment
	process (sgn)
	begin
		if falling_edge(sgn) then
			if cnt /= 999 then
				cnt <= cnt + 1;
			end if;
		end if;
	end process;



end architecture ; -- arch