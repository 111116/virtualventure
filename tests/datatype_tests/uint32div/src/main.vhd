library ieee;
use ieee.std_logic_1164.all;

entity main is
	port (
		a,b: in integer;
		c: out integer
	);
end entity main;

architecture behav of main is

begin
	c <= a / b;
end architecture behav;