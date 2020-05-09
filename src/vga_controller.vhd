-- VGA controller
-- display pixels from SRAM controller

-- SRAM pixel format:
-- addr #0 to addr #(640x480), row-major
-- r: 2 downto 0
-- g: 5 downto 3
-- b: 8 downto 6

library  ieee;
use      ieee.std_logic_1164.all;
use      ieee.numeric_std.all;

entity vga_controller is
   port(
      -- internal ports
      clk_0 : in std_logic; -- 100MHz master clock input
      reset : in  std_logic; -- async reset (low valid)
      -- internal ports to SRAM controller
      addr  : out std_logic_vector(19 downto 0);
      q     : in std_logic_vector(31 downto 0);
      -- external ports to VGA DAC
      hs,vs : out std_logic;
      r,g,b : out std_logic_vector(2 downto 0)
   );
end vga_controller;

architecture behavior of vga_controller is

   signal clk      : std_logic := '0';            -- cached 25MHz clock
   signal clk50    : std_logic := '0';            -- cached 50MHz clock
   signal r1,g1,b1 : std_logic_vector(2 downto 0); -- cached color
   signal hs1,vs1  : std_logic;                    -- cached sync
   signal vector_x : unsigned(9 downto 0) := (others=>'0'); -- horizontal position of current scan
   signal vector_y : unsigned(8 downto 0) := (others=>'0'); -- vertical position of current scan

begin

 -----------------------------------------------------------------------
   --clock frequency divider 1/4
   process(clk_0)
   begin
      if rising_edge(clk_0) then
         clk50 <= not clk50;
      end if;
   end process;

   process(clk50)
   begin
      if rising_edge(clk50) then
         clk <= not clk;
      end if;
   end process;

 -----------------------------------------------------------------------
   process(clk,reset)  -- assign to H pos (blank included)
   begin
      if reset='0' then
         vector_x <= (others=>'0');
      elsif rising_edge(clk) then
         if vector_x=799 then
            vector_x <= (others=>'0');
         else
            vector_x <= vector_x + 1;
         end if;
      end if;
   end process;

 -----------------------------------------------------------------------
   process(clk,reset)  -- assign to V pos (blank included)
   begin
      if reset='0' then
         vector_y <= (others=>'0');
      elsif rising_edge(clk) then
         if vector_x=799 then
            if vector_y=524 then
               vector_y <= (others=>'0');
            else
               vector_y <= vector_y + 1;
            end if;
         end if;
      end if;
   end process;
 
-----------------------------------------------------------------------
   process(clk,reset) -- assign to Hsync
   begin
        if reset='0' then
         hs1 <= '1';
        elsif rising_edge(clk) then
            if vector_x>=656 and vector_x<752 then
               hs1 <= '0';
            else
               hs1 <= '1';
            end if;
        end if;
   end process;
 
-----------------------------------------------------------------------
   process(clk,reset) -- assign to Vsync
   begin
      if reset='0' then
            vs1 <= '1';
      elsif rising_edge(clk) then
            if vector_y>=490 and vector_y<492 then
            vs1 <= '0';
            else
            vs1 <= '1';
            end if;
      end if;
   end process;
 -----------------------------------------------------------------------
   process(clk,reset) -- output Hsync
   begin
      if reset='0' then
            hs <= '0';
      elsif rising_edge(clk) then
            hs <=  hs1;
      end if;
   end process;

 -----------------------------------------------------------------------
   process(clk,reset) -- output Vsync
   begin
      if reset='0' then
            vs <= '0';
      elsif rising_edge(clk) then
            vs <=  vs1;
      end if;
   end process;
   
 -----------------------------------------------------------------------   
   process(reset,clk,vector_x,vector_y) -- drawing
      variable x,y: integer range 0 to 1000;
   begin  
      if reset='0' then
         r1  <= "000";
         g1 <= "000";
         b1 <= "000";   
		elsif rising_edge(clk) and vector_x<640 and vector_y<480 then
			r1 <= q(5 downto 3);
         g1 <= "000";
         b1 <= "111";
				--if vector_x=639 and vector_y=479 then
				--	addr <= (others=>'0');
				--else
					addr <= "00"&std_logic_vector(vector_x+vector_y*640);
				--end if;
      end if;      
   end process;  

   -----------------------------------------------------------------------
   process (hs1, vs1, r1, g1, b1, vector_x, vector_y)   -- output to rgb
   begin
      if vector_x<640 and vector_y<480 then
         r  <= r1;
         g  <= g1;
         b  <= b1;
      else
         r  <= (others => '0');
         g  <= (others => '0');
         b  <= (others => '0');
      end if;
   end process;

end behavior;

