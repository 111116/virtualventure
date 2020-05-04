-- VGA controller
-- display pixels from SRAM controller

library  ieee;
use      ieee.std_logic_1164.all;
use      ieee.std_logic_unsigned.all;
use      ieee.std_logic_arith.all;

entity vga_controller is
   port(
      -- internal ports
      clk_0 : in std_logic; -- 100MHz master clock input
      reset : in  std_logic; -- async reset (low valid)
      -- internal ports to SRAM controller
      addr  : out std_logic_vector(31 downto 0);
      q     : in std_logic;
      -- external ports to VGA DAC
      clk25 : out std_logic;
      hs,vs : out std_logic;
      r,g,b : out std_logic_vector(2 downto 0)
   );
end vga_controller;

architecture behavior of vga_controller is
   
   signal clk      : std_logic;                    -- cached 25MHz clock output
   signal r1,g1,b1 : std_logic_vector(2 downto 0); -- cached color output           
   signal hs1,vs1  : std_logic;                    -- cached sync output
   signal vector_x : std_logic_vector(9 downto 0); -- horizontal position of current scan
   signal vector_y : std_logic_vector(8 downto 0); -- vertical position of current scan

begin

   clk25 <= clk;
 -----------------------------------------------------------------------
   process(clk_0)  --clock frequency divider
   begin
      if(clk_0'event and clk_0='1') then 
         clk <= not clk;
      end if;
   end process;

 -----------------------------------------------------------------------
   process(clk,reset)  --行区间像素数（含消隐区）
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
   process(clk,reset)  --场区间行数（含消隐区）
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
   process(clk,reset) --行同步信号产生（同步宽度96，前沿16）
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
   process(clk,reset) --场同步信号产生（同步宽度2，前沿10）
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
   process(clk,reset) --行同步信号输出
   begin
      if reset='0' then
            hs <= '0';
      elsif rising_edge(clk) then
            hs <=  hs1;
      end if;
   end process;

 -----------------------------------------------------------------------
   process(clk,reset) --场同步信号输出
   begin
      if reset='0' then
            vs <= '0';
      elsif rising_edge(clk) then
            vs <=  vs1;
      end if;
   end process;
   
 -----------------------------------------------------------------------   
   process(reset,clk,vector_x,vector_y) -- XY坐标定位控制
   begin  
      if reset='0' then
         r1  <= "000";
         g1 <= "000";
         b1 <= "000";   
      elsif rising_edge(clk) then
         -- TODO: assign to r1,g1,b1 with pixel values
      end if;      
   end process;  

   -----------------------------------------------------------------------
   process (hs1, vs1, r1, g1, b1)   --色彩输出
   begin
      if hs1 = '1' and vs1 = '1' then
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

