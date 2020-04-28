## 说明

文档暂时就写在这里。

使用的数据类型：范围整数，定点实数，枚举，……

## 概览

```vhdl
main
  input_controller
  map_gen
  game_logic
  geometry
  renderer
  sram_controller
  vga_controller
```

## 传感器控制器



## 地形生成器

每轨道：

​		列车数量，每列车：种类，起点，车厢数量，有没有斜坡 <=4x(enum+real+short+bool) \~12byte

​		障碍数量，每个障碍：位置，种类 10 x (real + enum) \~20bytes

​		\*金币数量，每个金币：位置，高度 20 x (real + real) \~60bytes

total 300bytes 2400bits

\*景观

\*隧道

## 游戏主逻辑

玩家与列车，金币作碰撞检测。碰撞检测：玩家所在轨道离散

输出：玩家位置 (x:real,h:real)

## 几何实例化

接受地形与玩家信息

输出绘制指令

```vhdl
clk: in std_logic;
-- internal ports to main game logic
...
-- internal ports to geometry buffer (RAM)
ram_clk: out std_logic;
ram_addr: out std_logic_vector();
ram_data: out std_logic_vector();
...
-- internal ports to renderer
data_available: out std_logic;
```

## 渲染器

```vhdl
clk: in std_logic;
-- internal ports to geometry buffer (RAM)
ram_clk: out std_logic;
ram_addr: out std_logic_vector();
ram_q: in std_logic_vector();
...
-- internal ports to geometry generator
data_available: in std_logic;
busy: out std_logic;
```

## SRAM控制器

```vhdl
clk: in std_logic;
-- internal ports to VGA
addr1: in std_logic_vector(19 downto 0);
data1: out std_logic_vector(31 downto 0);
...
-- internal ports to renderer
addr2: in std_logic_vector(19 downto 0);
data2: inout std_logic_vector(31 downto 0);
...
-- external ports to SRAM
addr_e: in std_logic_vector(19 downto 0);
data_e: inout std_logic_vector(31 downto 0);
rden_e: out std_logic;
wren_e: out std_logic;
chsl_e: out std_logic;
```


## VGA控制器

```vhdl
clk: in std_logic;
-- internal ports to SRAM controller
addr: out std_logic_vector(19 downto 0);
data: in std_logic_vector(31 downto 0);
...
-- external ports to VGA
r,g,b: out std_logic_vector(2 downto 0);
hs,vs: out std_logic;
```