-- SRAM controller

-- share SRAM between VGA controller (read only, prioritized) and renderer
-- working at 100MHz

library  ieee;
use      ieee.std_logic_1164.all;

entity sram_controller is
   port(
      clk: in std_logic; -- sram sync clock
      widepulse: in std_logic; -- 8.5ns low, 1.5ns high 
      -- internal ports to VGA
      addr1: in std_logic_vector(19 downto 0);
      q1:   out std_logic_vector(31 downto 0);
      -- internal ports to renderer
      addr2: in std_logic_vector(19 downto 0);
      q2:   out std_logic_vector(31 downto 0);
      data2: in std_logic_vector(31 downto 0);
      wren2: in std_logic;
      acc2: out std_logic;
      -- external ports to SRAM
      addr_e: out std_logic_vector(19 downto 0);
      data_e: inout std_logic_vector(31 downto 0);
      rden_e: out std_logic; -- low valid
      wren_e: out std_logic; -- low valid
      chsl_e: out std_logic  -- low valid
   );
end sram_controller;

architecture behav of sram_controller is

   type state_t is (st1, st2);
   signal state: state_t := st1;
   signal writing: std_logic;
	signal datacache: std_logic_vector(31 downto 0);

begin

   -- WE pulse

   -- SRAM ports
   rden_e <= writing;
   wren_e <= not clk when writing = '1' else '1';
   -- wren_e <= not writing;
   data_e <= datacache when writing = '1' else (others => 'Z');
   chsl_e <= '0';

   -- update state & cache
   process (clk)
   begin
      if rising_edge(clk) then
         -- switch state
         if state = st1 then
            q1 <= data_e; -- cache result for VGA
            state <= st2; -- switch to renderer
            acc2 <= '1';
            addr_e <= addr2;
            writing <= wren2;
				datacache <= data2;
         else
            q2 <= data_e; -- cache result for renderer
            state <= st1; -- switch to VGA
            acc2 <= '0';
            addr_e <= addr1;
            writing <= '0';
         end if;
      end if;
   end process;

end architecture ; -- behav