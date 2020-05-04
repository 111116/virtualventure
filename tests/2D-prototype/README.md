software prototype of 2D graphics.

renders axis-aligned boxes with texture

### Data representation

Geometry buffer

```vhdl
data: std_logic_vector(23 downto 0)
  
addr #0: std_logic_vector(Y) & std_logic_vector(X)
addr #1: std_logic_vector(V) & std_logic_vector(U)
addr #2: std_logic_vector(H) & std_logic_vector(W)
addr #3: "0000000000000000"  & std_logic_vector(D)
```

Color: RGB565 / RGBA5551 ?

