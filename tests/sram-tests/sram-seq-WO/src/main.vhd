
library  ieee;
use      ieee.std_logic_1164.all;
use		ieee.numeric_std.all;

entity main is
   port (
      -- 100MHz master clock input
      clk0 : in std_logic;
      -- external ports to SRAM
      sram_addr: out std_logic_vector(19 downto 0);
      sram_data: inout std_logic_vector(31 downto 0);
      sram_oe: out std_logic; -- low valid
      sram_we: out std_logic; -- low valid
      sram_ce: out std_logic  -- low valid
   );
end entity main; -- main


architecture arch of main is

   component main_pll is 
      port (
         inclk0: in std_logic;
         c0: out std_logic -- 8.5ns low, 1.5ns high 
      );
   end component;

   signal curaddr: integer range 0 to 1000000 := 0;
   signal widepulse: std_logic;

begin

   pll: main_pll port map (
      inclk0   => clk0,
      c0       => widepulse
   );

   sram_addr <= std_logic_vector(to_unsigned(curaddr, 20)) ;
	sram_data <= std_logic_vector(to_unsigned(curaddr, 24)) & "00000000";
	--sram_data <= (others=>'1');
	sram_ce <= '0';
	sram_we <= widepulse;
	sram_oe <= '1';

   process (clk0)
   begin
      if rising_edge(clk0) then
			if curaddr = 80 then
				curaddr <= 0;
			else
				curaddr <= curaddr + 1;
			end if;
      end if;
   end process;

end architecture arch; -- arch
