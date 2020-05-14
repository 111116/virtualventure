-- fill framebuffer given tiles of texture coordinates

library  ieee;
use      ieee.std_logic_1164.all;
use      ieee.numeric_std.all;


entity texture_filler is
	port (
		-- control signals
		clk0 : in std_logic; -- 100MHz clock
		start_addr : in unsigned(19 downto 0); -- must be hold
      start   : in std_logic;   -- start trigger, active high
      busy    : out std_logic;  -- indicates working, active high
		-- ports to tile buffer
      buf_clk  : out std_logic;
		buf_addr : out std_logic_vector(12 downto 0);
		buf_q	 	: in  std_logic_vector(35 downto 0);
      -- internal ports to SRAM controller
      sram_addr1 : out std_logic_vector(19 downto 0); -- read1
      sram_q1    : in  std_logic_vector(31 downto 0); -- read1
      sram_addr2 : out std_logic_vector(19 downto 0); -- read2
      sram_q2    : in  std_logic_vector(31 downto 0); -- read2
      sram_addrw : out std_logic_vector(19 downto 0); -- write
      sram_dataw : out std_logic_vector(31 downto 0); -- write
      sram_wren  : out std_logic
	);
end entity texture_filler;


architecture behav of texture_filler is

	--component dither_buffer is
	--	port (
			
	--	);
	--end component dither_buffer;


   -- 80ns cycled clock
   signal clkslow : std_logic := '0';
   signal clk1_4 : std_logic := '0';
   signal clkcnt : integer range 0 to 3 := 0;

   -- pipeline registers
   signal x, x_reg : integer range 0 to 79 := 0; -- current position in tile
   signal y, y_reg : integer range 0 to 79 := 0; -- current position in tile
   signal texaddr_reg      : std_logic_vector(19 downto 0); -- registered of even-indexed px
   signal writeaddr        : std_logic_vector(19 downto 0);
   signal writeaddr_reg1   : std_logic_vector(19 downto 0);
   signal sram_q1_reg1     : std_logic_vector(31 downto 0);
   signal sram_q2_reg1     : std_logic_vector(31 downto 0);

   signal state_valid      : std_logic := '0';
   signal state_valid_reg  : std_logic := '0';
   signal state_valid_reg2 : std_logic := '0';
   signal state_valid_reg3 : std_logic := '0';

begin

   -- clk divider 1/8
   -- hopefully clk is ahead of SRAM fetch timing
   process (clk0, clkcnt)
   begin
      if rising_edge(clk0) then
         if clkcnt = 0 then
            clkslow <= not clkslow;
         end if;
         if clkcnt = 3 then
            clkcnt <= 0;
         else
            clkcnt <= clkcnt + 1;
         end if;
      end if;
   end process;

   -- clk divider 1/4
   process (clk0, clkcnt)
   begin
      if rising_edge(clk0) then
         if clkcnt = 0 or clkcnt = 2 then
            clk1_4 <= not clk1_4;
         end if;
      end if;
   end process;

   buf_clk <= clk1_4;

   -- stage 0: update state & current position
   process (clkslow, x, y, start, state_valid)
   begin
      if rising_edge(clkslow) then
         if state_valid = '0' and start = '1' then
            -- initialize
            state_valid <= '1';
            x <= 0;
            y <= 0;
         -- otherwise continue update x and y in [0..79]^2
         elsif x = 78 then
				if y = 79 then
               -- finished
					state_valid <= '0';
				else
					y <= y+1;
				end if;
            x <= 0;
			else
				x <= x+2;
         end if;
      end if;
   end process;

   -- stage 1 & 1.5: fetch texture address 1 from buffer
   process (clk0, clkcnt, x, y, buf_q, state_valid)
   begin
      if rising_edge(clk0) and clkcnt=0 then
      	if clkslow = '1' then -- rising edge of slow clock
	      	buf_addr <= std_logic_vector(to_unsigned(x+y*80, buf_addr'length));
	      	x_reg <= x;
	      	y_reg <= y;
	      else -- falling edge of slow clock
	      	texaddr_reg <= buf_q(19 downto 0);
	      	buf_addr <= std_logic_vector(to_unsigned(x_reg+1+y_reg*80, buf_addr'length));
	      end if;
         state_valid_reg <= state_valid;
      end if;
   end process;

   -- stage 2: read texture & calc write addr
   process (clkslow, buf_q, texaddr_reg, x_reg, y_reg, state_valid_reg)
   begin
      if rising_edge(clkslow) then
         -- texture address
         sram_addr1 <= texaddr_reg;
         sram_addr2 <= buf_q(19 downto 0);
         writeaddr  <= std_logic_vector(to_unsigned(x_reg/2 + y_reg*320 + to_integer(start_addr), 20));
         state_valid_reg2 <= state_valid_reg;
      end if;
   end process;

   -- stage 3: fetch texture data
   process (clkslow, sram_q1, sram_q2, writeaddr, state_valid_reg2)
   begin
      if rising_edge(clkslow) then
         sram_q1_reg1 <= sram_q1;
         sram_q2_reg1 <= sram_q2;
         writeaddr_reg1 <= writeaddr;
         state_valid_reg3 <= state_valid_reg2;
      end if;
   end process;

   -- state 4: calculate quantized color
   process (clkslow, sram_q1_reg1, sram_q2_reg1, writeaddr_reg1, state_valid_reg3)
      variable r1,g1,b1,r2,g2,b2: std_logic_vector(2 downto 0); -- to fill
   begin
      if rising_edge(clkslow) then
         -- direct quantize (floor)
         r1 := sram_q1_reg1(7 downto 5);
         g1 := sram_q1_reg1(15 downto 13);
         b1 := sram_q1_reg1(23 downto 21);
         r2 := sram_q2_reg1(7 downto 5);
         g2 := sram_q2_reg1(15 downto 13);
         b2 := sram_q2_reg1(23 downto 21);
         sram_addrw <= writeaddr_reg1;
         sram_dataw <= "00000000000000"&b2&g2&r2&b1&g1&r1;
         sram_wren  <= state_valid_reg3;
      end if;
   end process;

   busy <= state_valid or state_valid_reg3;

end architecture ; -- behav
