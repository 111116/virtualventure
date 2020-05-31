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

   type state_t is (st_idle, st_fetch, st_work);
   signal state : state_t := st_idle;
   signal element_id : integer range 0 to 1023; -- outer loop variable: which element is being drawed

   signal param_x, param_y : integer range -2048 to 2047 := 0;
   signal param_u, param_v : integer range 0 to 4095 := 0;
   signal param_w, param_h : integer range 0 to 4095 := 0;
   signal param_d : unsigned (15 downto 0);

   signal blockx : integer range 0 to 19 := 0; -- current position in tile
   signal y : integer range 0 to 79 := 0; -- current position in tile
   signal cur_valid : std_logic;

   signal rel_x, rel_y : integer range -2048 to 2047; -- position of drawed rectangle relative to current block
   signal rel_u, rel_v : integer range -2048 to 2047; -- texture coordinate of topleft corner of current block as if it's drawed
   signal rel_xend, rel_yend : integer range -2048 to 2047; -- end position of drawed rectangle relative to current block
   signal loop_xbegin, loop_ybegin, loop_xend, loop_yend : integer range -2048 to 2047; -- range of pixel loop
   signal loop_blockxbegin, loop_blockxend : integer range -2048 to 2047; -- range of block (actual) loop
   signal loop_empty : std_logic;

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

   process (clk0, blockx, y, start, state, loop_empty)
   begin
      if rising_edge(clk0) and clkcnt8=0 then
         case state is
            when st_idle =>
               if start = '1' then
                  -- initialize
                  state <= st_fetch;
                  element_id <= 0;
                  cur_valid <= '0';
               end if;
            when st_fetch =>
               if element_id = n_element then -- outer loop is over
                  state <= st_idle;
                  element_id <= 0;
                  cur_valid <= '0';
               elsif loop_empty = '1' then
                  state <= st_fetch;
                  element_id <= element_id + 1;
                  cur_valid <= '0';
               else
                  -- start x-y loop
                  state <= st_work;
                  blockx <= loop_blockxbegin;
                  y <= loop_ybegin;
                  cur_valid <= '1';
               end if;
            when st_work =>
               -- loop control
               if blockx+1=loop_blockxend then
                  blockx <= loop_blockxbegin;
                  if y+1=loop_yend then -- inner loop is over
                     state <= st_fetch;
                     element_id <= element_id + 1;
                     cur_valid <= '0';
                  else
                     y <= y+1;
                  end if;
               else
                  blockx <= blockx+1;
               end if;
         end case;
      end if;
   end process;

   -- fetch parameters of primitive
   process (clk0, state, element_id, geobuf_q)
   begin
      if rising_edge(clk0) and state = st_fetch then
         case clkcnt8 is
            when 1 =>
               -- fetch param X,Y
               geobuf_addr <= std_logic_vector(to_unsigned(element_id*4+0, geobuf_addr'length));
            when 2 =>
               -- fetch param U,V
               geobuf_addr <= std_logic_vector(to_unsigned(element_id*4+1, geobuf_addr'length));
            when 3 =>
               -- fetch param W,H
               geobuf_addr <= std_logic_vector(to_unsigned(element_id*4+2, geobuf_addr'length));
               param_x <= to_integer(signed(geobuf_q(11 downto 0)));
               param_y <= to_integer(signed(geobuf_q(23 downto 12)));
            when 4 =>
               -- fetch param D
               geobuf_addr <= std_logic_vector(to_unsigned(element_id*4+3, geobuf_addr'length));
               param_u <= to_integer(unsigned(geobuf_q(11 downto 0)));
               param_v <= to_integer(unsigned(geobuf_q(23 downto 12)));
            when 5 =>
               param_w <= to_integer(unsigned(geobuf_q(11 downto 0)));
               param_h <= to_integer(unsigned(geobuf_q(23 downto 12)));
            when 6 =>
               param_d <= unsigned(geobuf_q(15 downto 0));
            when others =>
               null;
         end case;
      end if;
   end process;

   -- comb: calculate overlapping bounding box
   process (param_x, param_y, param_w, param_h, param_u, param_v, startx, starty, rel_x, rel_y, rel_xend, rel_yend, loop_xbegin, loop_xend, loop_ybegin, loop_yend)
   begin
      rel_x <= param_x - to_integer(startx);
      rel_y <= param_y - to_integer(starty);
      rel_xend <= rel_x + param_w;
      rel_yend <= rel_y + param_h;
      rel_u <= param_u - rel_x;
      rel_v <= param_v - rel_y;
      -- loop_xbegin = max(rel_x, 0)
      if rel_x>=0 then
         loop_xbegin <= rel_x;
      else
         loop_xbegin <= 0;
      end if;
      -- loop_ybegin = max(rel_y, 0)
      if rel_y>=0 then
         loop_ybegin <= rel_y;
      else
         loop_ybegin <= 0;
      end if;
      -- loop_xend = min(rel_xend, 80)
      if rel_xend>=80 then
         loop_xend <= 80;
      else
         loop_xend <= rel_xend;
      end if;
      -- loop_yend = min(rel_yend, 80)
      if rel_yend>=80 then
         loop_yend <= 80;
      else
         loop_yend <= rel_yend;
      end if;
      -- check if loop is empty
      if loop_xbegin >= loop_xend or loop_ybegin >= loop_yend then
         loop_empty <= '1';
      else
         loop_empty <= '0';
      end if;
      -- compute bound of x-block
      loop_blockxbegin <= loop_xbegin / 4;
      loop_blockxend <= (loop_xend + 3) / 4;
   end process;
	
   busy <= '1' when state /= st_idle else '0';
   tilebuf_clk <= clk0;
   geobuf_clk <= clk0;

   -- stage 1: request data
   process (clk0, clkcnt8, blockx, y)
      variable u1,u2,v: integer range 0 to 1023;
   begin
      if rising_edge(clk0) and clkcnt8=0 then
         u1 := blockx*4 + to_integer(startx);
         u2 := blockx*4 + to_integer(startx) + 2;
         v := y + to_integer(starty) + 300;
         sram_addr1 <= std_logic_vector(to_unsigned(u1/2 + v*512, 20));
         sram_addr2 <= std_logic_vector(to_unsigned(u2/2 + v*512, 20));
         sram1l_id <= std_logic_vector(to_unsigned(y * 80 + 4*blockx + 0, 13));
         sram1h_id <= std_logic_vector(to_unsigned(y * 80 + 4*blockx + 1, 13));
         sram2l_id <= std_logic_vector(to_unsigned(y * 80 + 4*blockx + 2, 13));
         sram2h_id <= std_logic_vector(to_unsigned(y * 80 + 4*blockx + 3, 13));
         if cur_valid = '1' and 4*blockx + 0 >= loop_xbegin and 4*blockx + 0 < loop_xend then sram1h_valid <= '1'; else sram1h_valid <= '0'; end if;
         if cur_valid = '1' and 4*blockx + 1 >= loop_xbegin and 4*blockx + 1 < loop_xend then sram1l_valid <= '1'; else sram1l_valid <= '0'; end if;
         if cur_valid = '1' and 4*blockx + 2 >= loop_xbegin and 4*blockx + 2 < loop_xend then sram2h_valid <= '1'; else sram2h_valid <= '0'; end if;
         if cur_valid = '1' and 4*blockx + 3 >= loop_xbegin and 4*blockx + 3 < loop_xend then sram2l_valid <= '1'; else sram2l_valid <= '0'; end if;
      end if;
   end process;

   -- stage 2: receive data
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

   -- write pixels
   process (clk0, clkcnt8, sram1l_cache, sram1h_cache, sram2l_cache, sram2h_cache, sram1h_id_reg, sram1l_id_reg, sram2h_id_reg, sram2l_id_reg, sram1h_valid_reg, sram1l_valid_reg, sram2h_valid_reg, sram2l_valid_reg)
      variable cache : std_logic_vector(15 downto 0);
      variable r,g,b : integer range 0 to 255;
      variable a,valid : std_logic; -- opaque
   begin
      if rising_edge(clk0) then
         case clkcnt8 is
            when 1 =>
               cache := sram1l_cache;
               tilebuf_addr <= sram1l_id_reg;
               valid := sram1l_valid_reg;
            when 2 =>
               cache := sram1h_cache;
               tilebuf_addr <= sram1h_id_reg;
               valid := sram1h_valid_reg;
            when 3 =>
               cache := sram2l_cache;
               tilebuf_addr <= sram2l_id_reg;
               valid := sram2l_valid_reg;
            when 4 =>
               cache := sram2h_cache;
               tilebuf_addr <= sram2h_id_reg;
               valid := sram2h_valid_reg;
            when others =>
               cache := (others => '0');
               tilebuf_addr <= (others => '0');
               valid := '0';
         end case;
         r := 8*to_integer(unsigned(cache(4 downto 0)));
         g := 8*to_integer(unsigned(cache(9 downto 5)));
         b := 8*to_integer(unsigned(cache(14 downto 10)));
         a := cache(15);
         tilebuf_wren <= a and valid;
         tilebuf_data <= "000000000000"
            & std_logic_vector(to_unsigned(b,8))
            & std_logic_vector(to_unsigned(g,8))
            & std_logic_vector(to_unsigned(r,8));
      end if;
   end process;
   
end architecture behav;
