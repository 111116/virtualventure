## 说明

文档暂时就写在这里。

使用的数据类型：范围整数，定点实数，枚举，……

`src` 主项目设计用到的代码（VHDL/Verilog源文件，不要放Quartus生成的文件）

`project` Quartus工作目录（Quartus生成的文件视需要，不一定要加进repo）

`tests` 测试功能/模块等用到的设计

`res` 主项目设计用到的资源文件

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

#### 接口

每次从几何缓冲中接受一系列绘制指令，将渲染得到的所有像素颜色发送给SRAM控制器。

指令在几何缓冲中从地址0开始排列 `XYUVWHD-XYUVWHD-...` ，每条指令即复制贴图上一个矩形到屏幕缓冲上，指令参数含义如下

```plain
X 12位有符号整数，所绘制矩形在屏幕上的左上角横坐标，屏幕最左列为0
Y 12位有符号整数，所绘制矩形在屏幕上的左上角纵坐标，屏幕最上行为0
U 12位无符号整数，所绘制矩形在贴图上的左上角横坐标，贴图最左列为0
V 12位无符号整数，所绘制矩形在贴图上的左上角纵坐标，贴图最上行为0
W 12位无符号整数，所绘制矩形的宽度（横向像素数量）
H 12位无符号整数，所绘制矩形的高度（纵向像素数量）
D  8位无符号整数，所绘制矩形的深度（深度小的矩形覆盖深度大的矩形）
- 16位占位符，会被忽略
```

每条指令共96位，几何缓冲数据位宽24位，地址位宽暂定为9位（最多170条指令）。

具体地，当输入 `data_available` 为高时，将 `busy` 置为高并开始工作，不断从几何缓冲中读取绘图指令进行渲染，直到渲染完成并全部写入SRAM后，将 `busy` 置为低，等待下一次 `data_available` 的信号。

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
-- internal ports to SRAM controller
sram_addr  : out std_logic_vector(31 downto 0);
sram_data  : inout std_logic;
sram_wren  : out std_logic;
sram_valid : in std_logic
```

#### 实现

实现思路：用时钟和状态机控制顺序执行

```plain
遍历所有块：
    遍历当前块内像素：
        重置深度
    遍历所有绘制指令：
        取指令
        遍历绘制区域包围盒与当前块的相交矩形内像素：
            判断深度并写入贴图坐标和深度
    遍历当前块内像素：
        读取贴图值
        抖动量化
        向SRAM写入像素颜色
```

块缓冲格式：`(UVD)×tilesize` ，数据位宽32位，其中

```plain
U 12位无符号整数，该像素在贴图上的横坐标
V 12位无符号整数，该像素在贴图上的纵坐标
D  8位无符号整数，该像素的当前深度
```

## SRAM控制器

将SRAM共享给VGA控制器（只读）和渲染器（读写），其中VGA控制器优先。本模块为同步电路，在每个时钟周期若VGA控制器端产生新的读请求，则执行该请求；否则执行来自渲染器的读写请求。

```vhdl
clk: in std_logic;
-- internal ports to VGA
addr1: in std_logic_vector(19 downto 0);
data1: out std_logic_vector(31 downto 0);
...
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
chsl_e: out std_logic;
```

## VGA控制器

从SRAM控制器读取像素值并显示。

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