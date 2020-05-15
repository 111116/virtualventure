-- SRAM controller

-- share SRAM between VGA controller (read only, prioritized) and renderer
-- working at 100MHz, cycle 80ns
--  0-10ns: READ addr = addr1
-- 10-20ns: READ addr = addr2
-- 20-30ns: READ addr = addr3
--    37ns: fetch read1
--    47ns: fetch read2
--    57ns: fetch read3
-- 60-70ns: WRITE

library  ieee;
use      ieee.std_logic_1164.all;

entity sram_controller is
   port(
      clk: in std_logic; -- sram sync clock
      clk_sramsample: in std_logic; -- shifted, on rising edge samples sram data
      -- read port 1
      addr1: in std_logic_vector(19 downto 0);
      q1:   out std_logic_vector(31 downto 0);
      -- read port 2
      addr2: in std_logic_vector(19 downto 0);
      q2:   out std_logic_vector(31 downto 0);
      -- read port 3
      addr3: in std_logic_vector(19 downto 0);
      q3:   out std_logic_vector(31 downto 0);
      -- write port
      addrw: in std_logic_vector(19 downto 0);
      dataw: in std_logic_vector(31 downto 0);
      wren : in std_logic;
      -- external ports to SRAM
      addr_e: out std_logic_vector(19 downto 0);
      data_e: inout std_logic_vector(31 downto 0);
      rden_e: out std_logic := '1'; -- low valid
      wren_e: out std_logic := '1'; -- low valid
      chsl_e: out std_logic  -- low valid
   );
end entity sram_controller;

architecture behav of sram_controller is

   signal state: integer range 0 to 7;
	signal shiftcache: std_logic_vector(31 downto 0);

begin

   -- chip always enabled
   chsl_e <= '0';

   -- update state & feed external ports
   process (clk, state)
   begin
      if rising_edge(clk) then
         case state is
            when 0 => -- read1
               addr_e <= addr1;
               data_e <= (others => 'Z');
               rden_e <= '0';
               wren_e <= '1';
            when 1 => -- read2
               addr_e <= addr2;
               data_e <= (others => 'Z');
               rden_e <= '0';
               wren_e <= '1';
            when 2 => -- read3
               addr_e <= addr3;
               data_e <= (others => 'Z');
               rden_e <= '0';
               wren_e <= '1';
            when 3 => -- read3 continue
               addr_e <= addr3;
               data_e <= (others => 'Z');
               rden_e <= '0';
               wren_e <= '1';
            when 6 => -- write
               addr_e <= addrw;
               data_e <= dataw;
               rden_e <= '1';
               wren_e <= not wren;
            when others => -- idle
               addr_e <= x"CCCCC";
               data_e <= (others => 'Z');
               rden_e <= '1';
               wren_e <= '1';
         end case;
         if state = 7 then
            state <= 0;
         else
            state <= state + 1;
         end if;
      end if;
   end process;

   -- fetch data
   process (clk_sramsample, data_e)
   begin
      if rising_edge(clk_sramsample) then
         shiftcache <= data_e;
      end if;
   end process;

   -- output to register
   process (clk, shiftcache)
   begin
      if rising_edge(clk) then
         case state is
            when 4 =>
               q1 <= shiftcache;
            when 5 =>
               q2 <= shiftcache;
            when 6 =>
               q3 <= shiftcache;
            when others =>
               null;
         end case;
      end if;
   end process;

end architecture behav;
