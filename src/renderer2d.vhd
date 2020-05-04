-- 2D renderer

library  ieee;
use      ieee.std_logic_1164.all;
use      ieee.std_logic_unsigned.all;

entity renderer2d is
   port(
      clk: in std_logic; -- 100MHz master clock input
      -- internal ports to geometry buffer (RAM)
      ram_clk: out std_logic;
      ram_addr: out std_logic_vector();
      ram_q: in std_logic_vector();
      -- internal ports to geometry generator
      data_available : in std_logic;
      busy : out std_logic;
      -- internal ports to SRAM controller
      sram_addr  : out std_logic_vector(31 downto 0);
      sram_data  : inout std_logic;
      sram_wren  : out std_logic;
      sram_valid : in std_logic
   );
end renderer2d;

architecture behav of renderer2d is

   signal 

begin

end architecture ; -- behav