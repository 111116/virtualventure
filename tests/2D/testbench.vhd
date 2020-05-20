
library  ieee;
use      ieee.std_logic_1164.all;


entity testbench is
      
end entity testbench;

architecture arch of testbench is

   component main is
      port (
         -- 100MHz master clock input
         clk0 : in std_logic;
         -- external ports to SRAM
         sram_addr: out std_logic_vector(19 downto 0);
         sram_data: inout std_logic_vector(31 downto 0);
         sram_oe: out std_logic; -- low valid
         sram_we: out std_logic; -- low valid
         sram_ce: out std_logic; -- low valid
         -- external ports to VGA
         vga_r, vga_g, vga_b : out std_logic_vector(2 downto 0);
         vga_hs, vga_vs : out std_logic
      );
   end component main; -- main

   signal clk: std_logic := '0';

begin
   
   tested: main port map (
      clk,
      open,
      open,
      open,
      open,
      open,
      open, open, open,
      open, open
   );

   process
   begin
      clk <= not clk;
      wait for 5 ns;
   end process;

end architecture arch;