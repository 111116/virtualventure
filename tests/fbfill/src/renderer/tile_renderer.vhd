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

   signal clkcnt8 : integer range 0 to 7 := 0;

   signal x, x_reg : integer range 0 to 79 := 0; -- current position in tile
   signal y, y_reg : integer range 0 to 79 := 0; -- current position in tile
   signal state_busy : std_logic := '0';

   -- cached sram data, 12.5MHz
   signal sram1h_cache : std_logic_vector(15 downto 0);
   signal sram1l_cache : std_logic_vector(15 downto 0);
   signal sram2h_cache : std_logic_vector(15 downto 0);
   signal sram2l_cache : std_logic_vector(15 downto 0);
   -- task (addr to save data, wren), 12.5MHz
   signal sram1h_id : std_logic_vector(12 downto 0);
   signal sram1l_id : std_logic_vector(12 downto 0);
   signal sram2h_id : std_logic_vector(12 downto 0);
   signal sram2l_id : std_logic_vector(12 downto 0);
   signal sram1h_valid : std_logic := '0';
   signal sram1l_valid : std_logic := '0';
   signal sram2h_valid : std_logic := '0';
   signal sram2l_valid : std_logic := '0';
   -- task pipelined register, 12.5MHz
   signal sram1h_id_reg : std_logic_vector(12 downto 0);
   signal sram1l_id_reg : std_logic_vector(12 downto 0);
   signal sram2h_id_reg : std_logic_vector(12 downto 0);
   signal sram2l_id_reg : std_logic_vector(12 downto 0);
   signal sram1h_valid_reg : std_logic := '0';
   signal sram1l_valid_reg : std_logic := '0';
   signal sram2h_valid_reg : std_logic := '0';
   signal sram2l_valid_reg : std_logic := '0';

begin

   -- 12.5MHz counter
   process (clk0, clkcnt8)
   begin
      if rising_edge(clk0) then
         if clkcnt8 = 7 then
            clkcnt8 <= 0;
         else
            clkcnt8 <= clkcnt8 + 1;
         end if;
      end if;
   end process;
   
   -- stage 0: update state & current position
   process (clk0, x, y, start, state_busy)
   begin
      if rising_edge(clk0) and clkcnt8=0 then
         if state_busy = '0' and start = '1' then
            -- initialize
            state_busy <= '1';
            x <= 0;
            y <= 0;
         -- otherwise continue update x and y in [0..79]^2
         elsif x = 76 then
            if y = 79 then
               -- finished
               state_busy <= '0';
            else
               y <= y+1;
            end if;
            x <= 0;
         else
            x <= x+4;
         end if;
      end if;
   end process;

   tilebuf_clk <= clk0;

   -- stage 1: request data
   process (clk0, clkcnt8, x, y)
      variable u,v: integer range 0 to 1023;
   begin
      if rising_edge(clk0) and clkcnt8=0 then
         u := x + to_integer(startx);
         v := y + to_integer(starty);
         sram_addr1 <= std_logic_vector(to_unsigned(u/2 + v*40 + 0, 20));
         sram_addr2 <= std_logic_vector(to_unsigned(u/2 + v*40 + 1, 20));
         sram1l_id <= std_logic_vector(to_unsigned(y * 80 + x + 0, 13));
         sram1h_id <= std_logic_vector(to_unsigned(y * 80 + x + 1, 13));
         sram2l_id <= std_logic_vector(to_unsigned(y * 80 + x + 2, 13));
         sram2h_id <= std_logic_vector(to_unsigned(y * 80 + x + 3, 13));
         sram1h_valid <= '1';
         sram1l_valid <= '1';
         sram2h_valid <= '1';
         sram2l_valid <= '1';
      end if;
   end process;

   -- stage 2: receive data
   process (clk0, clkcnt8, sram_q1, sram_q2)
   begin
      if rising_edge(clk0) and clkcnt8=0 then
         sram1l_cache <= sram_q1(15 downto 0);
         sram1h_cache <= sram_q1(31 downto 16);
         sram2l_cache <= sram_q2(15 downto 0);
         sram2h_cache <= sram_q2(31 downto 16);
      end if;
   end process;

   -- stage 3: write content
   process (clk0, clkcnt8, sram_q1, sram_q2, sram1h_id, sram1l_id, sram2h_id, sram2l_id, sram1h_valid, sram1l_valid, sram2h_valid, sram2l_valid)
   begin
      if rising_edge(clk0) and clkcnt8=0 then
         sram1l_cache <= sram_q1(15 downto 0);
         sram1h_cache <= sram_q1(31 downto 16);
         sram2l_cache <= sram_q2(15 downto 0);
         sram2h_cache <= sram_q2(31 downto 16);
         sram1l_id_reg <= sram1l_id;
         sram1h_id_reg <= sram1h_id;
         sram2l_id_reg <= sram2l_id;
         sram2h_id_reg <= sram2h_id;
         sram1h_valid_reg <= sram1h_valid;
         sram1l_valid_reg <= sram1l_valid;
         sram2h_valid_reg <= sram2h_valid;
         sram2l_valid_reg <= sram2l_valid;
      end if;
   end process;

   -- write pixel 1h
   process (clk0, clkcnt8, sram1l_cache, sram1h_cache, sram2l_cache, sram2h_cache, sram1h_id_reg, sram1l_id_reg, sram2h_id_reg, sram2l_id_reg, sram1h_valid_reg, sram1l_valid_reg, sram2h_valid_reg, sram2l_valid_reg)
      variable cache : std_logic_vector(15 downto 0);
      variable r,g,b : integer range 0 to 255;
      variable a : std_logic; -- opaque
   begin
      if rising_edge(clk0) then
         case clkcnt8 is
            when 1 =>
               cache := sram1l_cache;
               tilebuf_addr <= sram1l_id_reg;
               tilebuf_wren <= sram1l_valid_reg;
            when 2 =>
               cache := sram1h_cache;
               tilebuf_addr <= sram1h_id_reg;
               tilebuf_wren <= sram1h_valid_reg;
            when 3 =>
               cache := sram2l_cache;
               tilebuf_addr <= sram2l_id_reg;
               tilebuf_wren <= sram2l_valid_reg;
            when 4 =>
               cache := sram2h_cache;
               tilebuf_addr <= sram2h_id_reg;
               tilebuf_wren <= sram2h_valid_reg;
            when others =>
               cache := (others => '0');
               tilebuf_addr <= (others => '0');
               tilebuf_wren <= '0';
         end case;
         r := 4*to_integer(unsigned(sram1l_cache(4 downto 0)));
         g := 4*to_integer(unsigned(sram1l_cache(9 downto 5)));
         b := 4*to_integer(unsigned(sram1l_cache(14 downto 10)));
         tilebuf_data <= "000000000000"
            & std_logic_vector(to_unsigned(b,8))
            & std_logic_vector(to_unsigned(g,8))
            & std_logic_vector(to_unsigned(r,8));
      end if;
   end process;
   
end architecture behav;
