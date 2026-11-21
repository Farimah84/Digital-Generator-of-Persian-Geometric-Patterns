-- ============================================================
-- workSpace name: twelve_pointed_star
-- design/entity name: starShape
-- architecture name: behavioral
-- testbench name: starShape_TB
-- ============================================================

-- ============================================================
-- Design code
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

-- ------------------------------------------------------------
-- Entity: starShape
-- ------------------------------------------------------------
entity starShape is
port (
    clk : in std_logic;
    reset : in std_logic;
    enable : in std_logic;
    pixel_x : in integer range 0 to 1023;
    pixel_y : in integer range 0 to 1023;
    center_x : in integer range 0 to 1023;
    center_y : in integer range 0 to 1023;
    pattern_on : out std_logic;
    rgb_out : out std_logic_vector(11 downto 0)
);
end starShape;

-- ------------------------------------------------------------
-- Architecture: Behavioral
-- ------------------------------------------------------------
architecture Behavioral of starShape is

constant PI : real := 3.14159265358979323846;
constant OUTER_RADIUS : real := 100.0;
constant INNER_RADIUS : real := 55.0;
constant GOLDEN_COLOR : std_logic_vector(11 downto 0) := "111110100000";
constant BACKGROUND_COLOR : std_logic_vector(11 downto 0) := "000100010011";

begin

process(clk, reset)
variable dx : real;
variable dy : real;
variable radius : real;
variable angle : real;
variable normalized_angle : real;
variable sector_angle : real;
variable boundary_radius : real;
begin
    if reset = '1' then
        pattern_on <= '0';
        rgb_out <= (others => '0');
    elsif rising_edge(clk) then
        if enable = '1' then
            dx := real(pixel_x - center_x);
            dy := real(center_y - pixel_y);
            radius := sqrt(dx * dx + dy * dy);

            if (dx = 0.0) and (dy = 0.0) then
                angle := 0.0;
            else
                angle := arctan(dy, dx);
            end if;

            if angle < 0.0 then
                angle := angle + 2.0 * PI;
            end if;

            sector_angle := PI / 6.0;
            normalized_angle := angle / sector_angle;
            normalized_angle := normalized_angle - floor(normalized_angle);

            if normalized_angle > 0.5 then
                normalized_angle := 1.0 - normalized_angle;
            end if;

            boundary_radius := INNER_RADIUS + (OUTER_RADIUS - INNER_RADIUS) * (1.0 - normalized_angle * 2.0);

            if radius <= boundary_radius then
                pattern_on <= '1';
                rgb_out <= GOLDEN_COLOR;
            else
                pattern_on <= '0';
                rgb_out <= BACKGROUND_COLOR;
            end if;
        else
            pattern_on <= '0';
            rgb_out <= BACKGROUND_COLOR;
        end if;
    end if;
end process;

end Behavioral;

-- ============================================================
-- Testbench code
-- ============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

-- ------------------------------------------------------------
-- Entity: starShape_tb
-- ------------------------------------------------------------
entity starShape_tb is
end starShape_tb;

-- ------------------------------------------------------------
-- Architecture: Testbench
-- ------------------------------------------------------------
architecture Testbench of starShape_tb is

component starShape
port (
    clk : in std_logic;
    reset : in std_logic;
    enable : in std_logic;
    pixel_x : in integer range 0 to 1023;
    pixel_y : in integer range 0 to 1023;
    center_x : in integer range 0 to 1023;
    center_y : in integer range 0 to 1023;
    pattern_on : out std_logic;
    rgb_out : out std_logic_vector(11 downto 0)
);
end component;

signal clk : std_logic := '0';
signal reset : std_logic := '1';
signal enable : std_logic := '0';
signal pixel_x : integer range 0 to 1023 := 0;
signal pixel_y : integer range 0 to 1023 := 0;
signal center_x : integer range 0 to 1023 := 320;
signal center_y : integer range 0 to 1023 := 240;
signal pattern_on : std_logic;
signal rgb_out : std_logic_vector(11 downto 0);

constant CLK_PERIOD : time := 10 ns;

file image_file : text open write_mode is "star12.pgm";

begin

uut: starShape
port map (
    clk => clk,
    reset => reset,
    enable => enable,
    pixel_x => pixel_x,
    pixel_y => pixel_y,
    center_x => center_x,
    center_y => center_y,
    pattern_on => pattern_on,
    rgb_out => rgb_out
);

-- ------------------------------------------------------------
-- Clock generation
-- ------------------------------------------------------------
clk_process : process
begin
    clk <= '0';
    wait for CLK_PERIOD / 2;
    clk <= '1';
    wait for CLK_PERIOD / 2;
end process;

-- ------------------------------------------------------------
-- Stimulus process
-- ------------------------------------------------------------
stim_proc : process
variable row : line;
variable pixel_value : integer;
begin
    reset <= '1';
    enable <= '0';
    wait for 20 ns;

    reset <= '0';
    enable <= '1';
    wait until falling_edge(clk);

    write(row, string'("P2"));
    writeline(image_file, row);

    write(row, string'("201 201"));
    writeline(image_file, row);

    write(row, string'("255"));
    writeline(image_file, row);

    for y in 140 to 340 loop
        for x in 220 to 420 loop
            pixel_x <= x;
            pixel_y <= y;

            wait until rising_edge(clk);
            wait for 1 ns;

            if pattern_on = '1' then
                pixel_value := 255;
            else
                pixel_value := 0;
            end if;

            write(row, pixel_value);
            write(row, string'(" "));
        end loop;
        writeline(image_file, row);
    end loop;

    file_close(image_file);

    assert false
        report "Image generation completed: star12.pgm"
        severity note;

    wait;
end process;

end Testbench;
