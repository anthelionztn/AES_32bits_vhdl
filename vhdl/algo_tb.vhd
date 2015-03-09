library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
-----------------------algo_tb-------------------------
---testbench du système complet avec E/S de 32 bits----
-------------------------------------------------------


entity algo_tb is
end entity;


architecture archi of algo_tb is

signal HORL : std_logic := '0';
signal CLR : std_logic := '0';
	
signal KEY_IN_4_4 : COLUMN := (others => '0'); --3C_4F_CF_09
signal KEY_IN_3_4 : COLUMN := (others => '0'); --88_15_F7_AB
signal KEY_IN_2_4 : COLUMN := (others => '0'); --A6_D2_AE_28
signal KEY_IN_1_4 : COLUMN := (others => '0'); --16_15_7E_2B
signal KEY_IN_OK : std_logic := '0';
signal KEY_IN_ACK : std_logic := '0';
	
signal DATA_IN_4_4 : COLUMN := (others => '0'); --34_07_37_E0
signal DATA_IN_3_4 : COLUMN := (others => '0'); --A2_98_31_31
signal DATA_IN_2_4 : COLUMN := (others => '0'); --8D_30_5A_88
signal DATA_IN_1_4 : COLUMN := (others => '0'); --A8_F6_43_32
signal DATA_IN_OK : std_logic := '0';
signal DATA_IN_ACK : std_logic := '0';

signal DATA_OUT_4_4 : COLUMN := (others => '0'); --32_0B_6A_19
signal DATA_OUT_3_4 : COLUMN := (others => '0'); --97_85_11_DC
signal DATA_OUT_2_4 : COLUMN := (others => '0'); --FB_09_DC_02
signal DATA_OUT_1_4 : COLUMN := (others => '0'); --1D_84_25_39
signal DATA_OUT_OK : std_logic := '0';
signal DATA_OUT_ACK : std_logic := '0';


component algo is
port (
	HORL : in std_logic;
	CLR : in std_logic;
	KEY_IN_4_4 : in COLUMN;
	KEY_IN_3_4 : in COLUMN;
	KEY_IN_2_4 : in COLUMN;
	KEY_IN_1_4 : in COLUMN;
	KEY_IN_OK : in std_logic;
	KEY_IN_ACK : out std_logic;
	
	DATA_IN_4_4 : in COLUMN;
	DATA_IN_3_4 : in COLUMN;
	DATA_IN_2_4 : in COLUMN;
	DATA_IN_1_4 : in COLUMN;
	DATA_IN_OK : in std_logic;
	DATA_IN_ACK : out std_logic;
	
	DATA_OUT_4_4 : out COLUMN;
	DATA_OUT_3_4 : out COLUMN;
	DATA_OUT_2_4 : out COLUMN;
	DATA_OUT_1_4 : out COLUMN;
	DATA_OUT_OK : out std_logic;
	DATA_OUT_ACK : in std_logic
);
end component;

begin

U0 : algo port map
(
	HORL => HORL,
	CLR => CLR,
	KEY_IN_4_4 => KEY_IN_4_4,
	KEY_IN_3_4 => KEY_IN_3_4,
	KEY_IN_2_4 => KEY_IN_2_4,
	KEY_IN_1_4 => KEY_IN_1_4,
	KEY_IN_OK => KEY_IN_OK,
	KEY_IN_ACK => KEY_IN_ACK,
	DATA_IN_4_4 => DATA_IN_4_4,
	DATA_IN_3_4 => DATA_IN_3_4,
	DATA_IN_2_4 => DATA_IN_2_4,
	DATA_IN_1_4 => DATA_IN_1_4,
	DATA_IN_OK => DATA_IN_OK,
	DATA_IN_ACK => DATA_IN_ACK,
	DATA_OUT_4_4 => DATA_OUT_4_4,
	DATA_OUT_3_4 => DATA_OUT_3_4,
	DATA_OUT_2_4 => DATA_OUT_2_4,
	DATA_OUT_1_4 => DATA_OUT_1_4,
	DATA_OUT_OK => DATA_OUT_OK,
	DATA_OUT_ACK => DATA_OUT_ACK
);

HORL <= not HORL after 10 ns; --50 MHz

KEY_IN_4_4 <= x"0f0e0d0c" after 25 ns, x"3C_4F_CF_09" after 2812 ns;
KEY_IN_3_4 <= x"0b0a0908" after 25 ns, x"88_15_F7_AB" after 2812 ns;
KEY_IN_2_4 <= x"07060504" after 25 ns, x"A6_D2_AE_28" after 2812 ns;
KEY_IN_1_4 <= x"03020100" after 25 ns, x"16_15_7E_2B" after 2812 ns;

--KEY_IN_OK <= '1' after 25 ns, '0' after 52 ns, '1' after 1600 ns, '0' after 1621 ns;
KEY_IN_OK <= '1' after 75 ns, '0' after 2812 ns, '1' after 3000 ns, '0' after 3500 ns;

DATA_IN_4_4 <= x"ffeeddcc" after 33 ns, x"34_07_37_E0" after 2812 ns;
DATA_IN_3_4 <= x"bbaa9988" after 33 ns, x"A2_98_31_31" after 2812 ns;
DATA_IN_2_4	<= x"77665544" after 33 ns, x"8D_30_5A_88" after 2812 ns;
DATA_IN_1_4 <= x"33221100" after 33 ns, x"A8_F6_43_32" after 2812 ns;

--DATA_IN_OK <= '1' after 33 ns, '0' after 68 ns, '1' after 1600 ns, '0' after 1608 ns;
DATA_IN_OK <= '1' after 100 ns, '0' after 2237 ns, '1' after 3000 ns, '0' after 3500 ns;

DATA_OUT_ACK <= '1' after 2000 ns, '0' after 2550 ns, '1' after 4600 ns;-- '0' after 5500 ns;

--CLR <= '0' after 15 ns, '1' after 1425 ns, '0' after 1468 ns;
--CLR <= '0' after 15 ns;


end archi;