-- SRAM controller

-- 将SRAM共享给VGA控制器（只读）和渲染器（读写），其中VGA控制器优先。
-- 本模块为同步电路，在每个时钟周期若VGA控制器端产生新的读请求，则执行该请求；
-- 否则执行来自渲染器的读写请求。

library  ieee;
use      ieee.std_logic_1164.all;

entity sram_controller is
   port(
      clk: in std_logic; -- 100MHz master clock input
      -- internal ports to VGA
      addr1: in std_logic_vector(19 downto 0);
      data1: out std_logic_vector(31 downto 0);
      -- internal ports to renderer
      addr2: in std_logic_vector(19 downto 0);
      data2: inout std_logic_vector(31 downto 0);
      wren2: in std_logic;
      valid2: out std_logic;
      ...
      -- external ports to SRAM
      addr_e: in std_logic_vector(19 downto 0);
      data_e: inout std_logic_vector(31 downto 0);
      rden_e: out std_logic;
      wren_e: out std_logic;
      chsl_e: out std_logic
   );
end sram_controller;

architecture behav of sram_controller is

   signal 

begin

end architecture ; -- behav