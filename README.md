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
  input_controller  进度：待联合编译
  map_gen           进度：待联合编译
  game_logic        进度：待联合编译
  geometry          进度：
  renderer          进度：2D开发中
  sram_controller   进度：已完成测试
  vga_controller    进度：已完成测试

## 传感器控制器
输入：clk,Rx
输出：
  （跳起/落下/无命令）+（向左/向右/无命令）

```
  UD: 2位无符整型，00表示跳起，11表示向下滑，01、10表示上下无操作
  LR：2位无符整型，00表示向左，11表示向右，01、10表示左右无操作
```
## 地形生成器+游戏主逻辑

port in:clk，UD,LR,rst

port out:type_carriage,pos_carriage,num_carriage,type_barrier,pos_barrier,character_y,character_h
每轨道：

​	列车数量，每列车：种类，起点，车厢数量，有没有斜坡 <=4x(enum+real+short+bool) \~12byte
```
  ​	N：2位无符整型，表示列车数量
    ​	kind[4]：2位无符整型：00表示不存在，01为静止的列车，10为向前匀速运动的列车
    ​	pos_start[4]：12位有符号整数，表示列车起点的坐标，-1024表示不存在
    ​	num_carriage[4]：3位无符整型，车厢的数量（不包含斜坡）
    ​	slope[4]:1位bool，1表示有斜坡
```

​	障碍数量，每个障碍：位置，种类 10 x (real + enum) \~20bytes
```
	num_barrier:4位无符整型：障碍数量（不超过10个）
​	pos_barrier[10]:12位有符号整数，表示障碍起点坐标,-1024表示不存在
​	type_barrier[10]:2位无符整型：00表示上下都可通过类型，01表示只能跳跃通过类型，10表示只能下方滑过类型，11为不可通过
```
​		\*金币数量，每个金币：位置，高度 20 x (real + real) \~60bytes

total 300bytes 2400bits

\*景观

\*隧道

process:
```
每个周期
    对每个轨道：
---maintain
      每节列车：起点--；
      每个障碍：起点--；
      \*金币，景观，隧道
---free
      如果列车起点<（-车厢长度):                            --以主角所在的地方为x轴原点但非屏幕最左端
        如果列车有斜坡:
          列车没有斜坡；
        否则：
          列车车厢数目-1，起点+=车厢长度；
      如果障碍起点<(-障碍长度+人物宽度）：
        该障碍消失；
---new
      #如果最后一节列车最后一节车厢进入画面，则读取随机数表格并随机生成新的列车、障碍
```


---玩家与列车，金币作碰撞检测。碰撞检测：玩家所在轨道离散


signal:
```
（pos_x:int，x坐标，常为0）
pos_y:int，y坐标
pos_y_discrete:std_logic_vector(2)，由y坐标得到角色属于三条铁路中的哪一条
pos_h:int，高度坐标，表示角色高度。用于碰撞检测
pos_h_center:int,重心高度坐标，考虑跳跃/下滑影响后即为高度坐标。用于斜坡对角色的高度影响
time_mov_y:int，左右移动剩余时间。+表示向左移动，-表示向右移动，不可被打断（不为0时不接受LR对其值的更改）
time_mov_h:int，上下移动剩余时间。+表示跳起，-表示下滑，可被打断（UD）
survive:std_logic,角色是否死亡
```
process：
角色接收指令
```
---加速度指令
UD==00：
  time_mov_h=10;起跳
  pos_h=pos_h_center;中断上一次跳跃/下滑的影响
UD==11：
  time_mov_h=-10;下滑
  pos_h=pos_h_center;中断上一次跳跃/下滑的影响
time_mov_y==0:左右运动结束
  LR==00:
    time_mov_y=10;
  LR==11:
    time_mov_y=-10;


---速度指令
pos_h = pos_h_center + function_h( time_mov_h );
pos_y = pos_y + function_y( time_mov_y );
pos_y_discrete = function_yd( pos_y );

```
状态检测&碰撞检测
```
                                                                                                         ---状态检测
如果角色未死亡：
                                                                                                         ---碰撞检测
  根据pos_y_discrete判断角色在哪一条轨道上（在两条轨道中间时只考虑pos_y_discrete确定的轨道的影响）
  列车碰撞检测：
    如果pos_h<=列车高度:                                                                                                 ---处于列车上不必碰撞检测
      如果第一节列车的起点<0且>(-车厢长度）:
        如果有斜坡：
          pos_h_center=（0-列车起点）*列车高度/车厢长度；                                                                        ---假设斜坡为三角形
        没有斜坡：
          角色死亡，survive=0；

  障碍碰撞检测：
    如果障碍起点<0且>(-障碍长度）:
      如果type_barrier为11:
        角色死亡，survive=0；
      如果type_barrier为01:
        如果time_mov_h<5:
          角色死亡，survive=0；
      如果type_barrier为10:
        如果time_mov_h>-5:
          角色死亡，survive=0；
      如果type_barrier为00:
        如果time_mov_h<5且>-5:
          角色死亡，survive=0；
```


####port out:
```
玩家位置 (x:real,h:real)
```

## 几何实例化

接受地形与玩家信息

输出绘制指令

```vhdl
clk: in std_logic;
type_carriage: out std_logic_vector(11 downto 0);
pos_carriage:out std_logic_vector(71 downto 0);
num_carriage:out std_logic_vector(17 downto 0);
pos_barrier:out std_logic_vector(71 downto 0);
type_barrier:out std_logic_vector(11 downto 0);
character_y:out std_logic_vector(11 downto 0);
character_h:out std_logic_vector(11 downto 0);

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

执行2D矩形贴图操作

#### 接口

每次从几何缓冲中接受一系列绘制指令，将渲染得到的所有像素颜色发送给SRAM控制器。

指令在几何缓冲中从地址0开始排列 `XY-UV-WH-D-XY-UV-WH-D-...` ，每条指令即复制贴图上一个矩形到屏幕缓冲上，指令参数含义如下（全部小端序）

```plain
X 12位有符号整数，所绘制矩形在屏幕上的左上角横坐标，屏幕最左列为0
Y 12位有符号整数，所绘制矩形在屏幕上的左上角纵坐标，屏幕最上行为0
-  8位占位符，会被忽略
U 12位无符号整数，所绘制矩形在贴图上的左上角横坐标，贴图最左列为0
V 12位无符号整数，所绘制矩形在贴图上的左上角纵坐标，贴图最上行为0
-  8位占位符，会被忽略
W 12位无符号整数，所绘制矩形的宽度（横向像素数量）
H 12位无符号整数，所绘制矩形的高度（纵向像素数量）
-  8位占位符，会被忽略
D 16位无符号整数，所绘制矩形的深度（深度小的矩形覆盖深度大的矩形）
- 16位占位符，会被忽略
```

每条指令共96位，几何缓冲数据位宽32位，地址位宽为12位（最多1024条指令）。

具体地，当输入 `start` 为高时，将 `busy` 置为高并开始工作，不断从几何缓冲中读取绘图指令进行渲染，直到渲染完成并全部写入SRAM后，将 `busy` 置为低，等待下一次 `start` 信号。

```vhdl
clk0: in std_logic; -- 100MHz master clock input
-- internal ports to geometry buffer (RAM)
n_element   : in unsigned(11 downto 0); -- number of rectangles to draw
geobuf_clk  : out std_logic;
geobuf_addr : out std_logic_vector(11 downto 0);
geobuf_q    : in  std_logic_vector(23 downto 0);
-- controls
start : in std_logic; -- set to HIGH to start
busy : out std_logic;
-- internal ports to SRAM controller
sram_addr1 : out std_logic_vector(19 downto 0);
sram_q1    : in  std_logic_vector(31 downto 0);
sram_addr2 : out std_logic_vector(19 downto 0);
sram_q2    : in  std_logic_vector(31 downto 0);
sram_addrw : out std_logic_vector(19 downto 0);
sram_dataw : out std_logic_vector(31 downto 0);
sram_wren  : out std_logic
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

块缓冲格式：80x80 words ，行优先，数据位宽36位，其中

```plain
19 downto 0 : UV 20位无符号整数，该像素的贴图地址（即SRAM上的地址）
35 downto 20: DEP 16位无符号整数，该像素的当前深度
```

## SRAM控制器

将SRAM共享给VGA控制器（只读）和渲染器（读写）。以80ns周期运行，3读1写，见代码。

## VGA控制器

从SRAM控制器读取像素值并显示。以25MHz运行，提前2拍从SRAM控制器读取像素值

