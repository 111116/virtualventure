-- Tile Renderer
-- Renders to a tile buffer of texture address.
-- synchronously triggered by `start` (active high)
-- sets busy='0' when done.

-- procedure: foreach element, fetch params -> calculate overlapped bound -> loop over pixels

library  ieee;
use      ieee.std_logic_1164.all;
use      ieee.numeric_std.all;


entity tile_renderer is
   port (
      -- control signals
      clk0   : in std_logic;              -- must not exceed max freq of RAM
      startx : in unsigned(9 downto 0);   -- leftmost position of tile rendered
      starty : in unsigned(9 downto 0);   -- uppermost position of tile rendered
      start   : in std_logic;             -- start trigger, active high
      busy    : out std_logic;            -- indicates working, active high
      -- internal ports to geometry input buffer (RAM)
      n_element   : in unsigned(11 downto 0);
      geobuf_clk  : out std_logic;
      geobuf_addr : out std_logic_vector(11 downto 0);
      geobuf_q    : in  std_logic_vector(31 downto 0);
      -- internal ports to tile output buffer (RAM)
      tilebuf_clk  : out std_logic;
      tilebuf_wren : out std_logic;
      tilebuf_addr : out std_logic_vector(12 downto 0);
      tilebuf_data : out std_logic_vector(35 downto 0);
      -- internal ports to SRAM controller
      sram_addr1 : out std_logic_vector(19 downto 0); -- read1
      sram_q1    : in  std_logic_vector(31 downto 0); -- read1
      sram_addr2 : out std_logic_vector(19 downto 0); -- read2
      sram_q2    : in  std_logic_vector(31 downto 0)  -- read2
   );
end entity tile_renderer;


architecture behav of tile_renderer is

   signal x, x_reg : integer range 0 to 79 := 0; -- current position in tile
   signal y, y_reg : integer range 0 to 79 := 0; -- current position in tile
   signal state_busy : std_logic := '0';

begin

   sram_addr1 <= x"CCCCC";
   sram_addr2 <= x"CCCCC";
   
   -- stage 0: update state & current position
   process (clk0, x, y, start, state_busy)
   begin
      if rising_edge(clk0) then
         if state_busy = '0' and start = '1' then
            -- initialize
            state_busy <= '1';
            x <= 0;
            y <= 0;
         -- otherwise continue update x and y in [0..79]^2
         elsif x = 79 then
            if y = 79 then
               -- finished
               state_busy <= '0';
            else
               y <= y+1;
            end if;
            x <= 0;
         else
            x <= x+1;
         end if;
      end if;
   end process;

   tilebuf_clk <= clk0;

   -- stage 1: fill tile buffer
   process (clk0, x, y, startx, starty, state_busy)
      variable r,g,b: integer range 0 to 255;
   begin
      tilebuf_wren <= state_busy;
      busy <= state_busy;
      tilebuf_addr <= std_logic_vector(to_unsigned(x + y * 80, tilebuf_addr'length));
      -- texture address
      r := 0;
      g := 0;
      b := 0;
      case x mod 3 is
         when 0 =>
            r := 224;
         when 1 =>
            g := 224;
         when 2 =>
            b := 224;
         when others =>
            null;
      end case;
      tilebuf_data <= "00000000"
         & std_logic_vector(to_unsigned(b,8))
         & std_logic_vector(to_unsigned(g,8))
         & std_logic_vector(to_unsigned(r,8));
   end process;
   
end architecture behav;
