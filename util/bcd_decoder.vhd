library ieee;
use ieee.std_logic_1164.all;

entity bcd_decoder is
	port (
		num: in std_logic_vector(3 downto 0); -- 8421 input
		bcd: out std_logic_vector(6 downto 0) -- digit display output	
	);
end entity ; -- bcd_decoder

architecture behav of bcd_decoder is
begin
	process (num) begin
		case num is
			when "0000"=> bcd <= "1111110";
			when "0001"=> bcd <= "0110000";
			when "0010"=> bcd <= "1101101";
			when "0011"=> bcd <= "1111001";
			when "0100"=> bcd <= "0110011";
			when "0101"=> bcd <= "1011011";
			when "0110"=> bcd <= "1011111";
			when "0111"=> bcd <= "1110000";
			when "1000"=> bcd <= "1111111";
			when "1001"=> bcd <= "1111011";
			when "1010"=> bcd <= "1110111";
			when "1011"=> bcd <= "0011111";
			when "1100"=> bcd <= "1001110";
			when "1101"=> bcd <= "0111101";
			when "1110"=> bcd <= "1001111";
			when "1111"=> bcd <= "1000111";
			when others=> bcd <= "0000000";
		end case;
	end process;
end architecture;