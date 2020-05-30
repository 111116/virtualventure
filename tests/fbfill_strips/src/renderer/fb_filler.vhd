-- fill framebuffer given tiled buffer of color

library  ieee;
use      ieee.std_logic_1164.all;
use      ieee.numeric_std.all;


entity fb_filler is
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
      sram_addrw : out std_logic_vector(19 downto 0); -- write
      sram_dataw : out std_logic_vector(31 downto 0); -- write
      sram_wren  : out std_logic
	);
end entity fb_filler;


architecture behav of fb_filler is

	--component dither_buffer is
	--	port (
			
	--	);
	--end component dither_buffer;


   signal clk1_2 : std_logic := '0';
   signal clk1_4 : std_logic := '0';
   signal clkst  : std_logic := '0';

   -- pipeline registers
   signal x, x_reg : integer range 0 to 79 := 0; -- current position in tile
   signal y, y_reg : integer range 0 to 79 := 0; -- current position in tile
   signal clr_reg          : std_logic_vector(23 downto 0); -- registered of even-indexed px
   signal writeaddr        : std_logic_vector(19 downto 0);

   signal state_valid      : std_logic := '0';
   signal state_valid_reg  : std_logic := '0';

   signal dr,dg,db : integer range -32 to 31 := 0;

begin

   -- clk divider 1/2
   -- hopefully clk1_4 is ahead of SRAM fetch timing
   process (clk0)
   begin
      if rising_edge(clk0) then
         clk1_2 <= not clk1_2;
      end if;
   end process;

   -- clk divider 1/4
   process (clk1_2)
   begin
      if rising_edge(clk1_2) then
         clk1_4 <= not clk1_4;
      end if;
   end process;

   -- clk divider 1/8  (clkst='0': main op)
   process (clk1_4)
   begin
      if rising_edge(clk1_4) then
         clkst <= not clkst;
      end if;
   end process;

   buf_clk <= clk1_4; -- t = 0.25, 0.75, ...

   -- stage 0: update state & current position
   process (clk1_4, clkst, x, y, start, state_valid)
   begin
      if rising_edge(clk1_4) and clkst='0' then -- t=0
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

   -- stage 1 & 1.5: read addr 1, read addr 2, fetch addr 1
   process (clk1_4, clkst, x, y, buf_q, state_valid)
   begin
      if rising_edge(clk1_4) then
         if clkst='1' then -- t=0.5, 1.5
	      	buf_addr <= std_logic_vector(to_unsigned(x+y*80, buf_addr'length));
            clr_reg <= buf_q(23 downto 0);
	      else -- t=1
            x_reg <= x;
            y_reg <= y;
            state_valid_reg <= state_valid;
	      	buf_addr <= std_logic_vector(to_unsigned(x+1+y*80, buf_addr'length));
	      end if;
      end if;
   end process;

   writeaddr  <= std_logic_vector(to_unsigned(x_reg/2 + y_reg*320 + to_integer(start_addr), 20));

   -- state 4: calculate quantized color
   process (clk1_4, clkst, clr_reg, buf_q, writeaddr, state_valid_reg, x_reg)
      variable or1,og1,ob1,or2,og2,ob2: integer; -- original color
      variable mr1,mg1,mb1,mr2,mg2,mb2: integer; -- mixed: color plus delta
      variable qr1,qg1,qb1,qr2,qg2,qb2: integer; -- quantized to 3bit
      variable resr1,resg1,resb1,resr2,resg2,resb2: integer; -- quantized scaled
      variable r1,g1,b1,r2,g2,b2: std_logic_vector(2 downto 0); -- to fill
   begin
      if rising_edge(clk1_4) and clkst='0' then
         -- get original color of two pixels
         or1 := to_integer(unsigned(clr_reg(7 downto 0)));
         og1 := to_integer(unsigned(clr_reg(15 downto 8)));
         ob1 := to_integer(unsigned(clr_reg(23 downto 16)));
         or2 := to_integer(unsigned(buf_q(7 downto 0)));
         og2 := to_integer(unsigned(buf_q(15 downto 8)));
         ob2 := to_integer(unsigned(buf_q(23 downto 16)));
         -- calculate first pixel
         mr1 := or1 + dr;
         mg1 := og1 + dg;
         mb1 := ob1 + db;
         qr1 := (mr1 + 15) / 32;
         qg1 := (mg1 + 15) / 32;
         qb1 := (mb1 + 15) / 32;
         r1 := std_logic_vector(to_unsigned(qr1,3));
         g1 := std_logic_vector(to_unsigned(qg1,3));
         b1 := std_logic_vector(to_unsigned(qb1,3));
         resr1 := qr1 * 32;
         resg1 := qg1 * 32;
         resb1 := qb1 * 32;
         -- calculate second pixel
         mr2 := or2 + (mr1 - resr1);
         mg2 := og2 + (mg1 - resg1);
         mb2 := ob2 + (mb1 - resb1);
         qr2 := (mr2 + 15) / 32;
         qg2 := (mg2 + 15) / 32;
         qb2 := (mb2 + 15) / 32;
         r2 := std_logic_vector(to_unsigned(qr2,3));
         g2 := std_logic_vector(to_unsigned(qg2,3));
         b2 := std_logic_vector(to_unsigned(qb2,3));
         resr2 := qr2 * 32;
         resg2 := qg2 * 32;
         resb2 := qb2 * 32;
         -- store horizontal delta
         if x_reg = 78 then
            dr <= 0;
            dg <= 0;
            db <= 0;
         else
            dr <= mr2 - resr2;
            dg <= mg2 - resg2;
            db <= mb2 - resb2;
         end if;
         -- write color to framebuffer
         sram_addrw <= writeaddr;
         sram_dataw <= "00000000000000"&b2&g2&r2&b1&g1&r1;
         sram_wren  <= state_valid_reg;
      end if;
   end process;

   busy <= state_valid or state_valid_reg;

end architecture ; -- behav
