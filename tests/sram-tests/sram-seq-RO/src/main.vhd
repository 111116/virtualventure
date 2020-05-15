
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
      sram_ce: out std_logic; -- low valid
		test:    out std_logic_vector(31 downto 0)
   );
end entity main; -- main


architecture arch of main is

	component mainpll is
		port (inclk0: in std_logic; c0: out std_logic);
	end component;

   signal curaddr: integer range 0 to 1000000 := 0;
	signal cnt : integer range 0 to 3;
	signal samplesgn: std_logic;
	signal data_cache: std_logic_vector(31 downto 0);
	signal data_cache_shift: std_logic_vector(31 downto 0);

begin

   sram_data <= (others => 'Z');
	sram_addr <= std_logic_vector(to_unsigned(curaddr, 20));
	sram_ce <= '0';
	sram_we <= '1';
	sram_oe <= '0';
	
	samplesignal: mainpll port map (clk0, samplesgn);
	
	-- cache SRAM data (first)
	process (samplesgn, sram_data)
	begin
		if rising_edge(samplesgn) then
			data_cache_shift <= sram_data;
		end if;
	end process;
	
	-- cache SRAM data
	process (clk0, data_cache_shift, data_cache)
	begin
		if rising_edge(clk0) then
			test <= data_cache;
			data_cache <= data_cache_shift;
		end if;
	end process;
	

	-- addr update
   process (clk0, curaddr)
   begin
      if rising_edge(clk0) then
			if curaddr = 1000 then
				curaddr <= 0;
			else
				curaddr <= curaddr + 1;
			end if;
      end if;
   end process;
	
	
	-- cnt update
	process (clk0, cnt)
   begin
      if rising_edge(clk0) then
			if cnt = 3 then
				cnt <= 0;
			else 
				cnt <= cnt + 1;
			end if;
		end if;
	end process;

end architecture arch; -- arch
