library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
------------------------algo---------------------------
------assemblage de l'algo avec E/S de 32 bits---------
-------------------------------------------------------


entity algo is
port (
	HORL : in std_logic; --signal d'horloge
	
	CLR : in std_logic; --mise à zéro du compteur de tours
	
	KEY_IN_4_4 : in COLUMN; --entrée de la clé --MSB
	KEY_IN_3_4 : in COLUMN;
	KEY_IN_2_4 : in COLUMN;
	KEY_IN_1_4 : in COLUMN; --LSB
	KEY_IN_OK : in std_logic; --signaux de contrôle
	KEY_IN_ACK : out std_logic;
	
	DATA_IN_4_4 : in COLUMN; --entrée des données --MSB
	DATA_IN_3_4 : in COLUMN;
	DATA_IN_2_4 : in COLUMN;
	DATA_IN_1_4 : in COLUMN; --LSB
	DATA_IN_OK : in std_logic; --signaux de contrôle
	DATA_IN_ACK : out std_logic;
	
	DATA_OUT_4_4 : out COLUMN; --sortie des données chiffrées --MSB
	DATA_OUT_3_4 : out COLUMN;
	DATA_OUT_2_4 : out COLUMN;
	DATA_OUT_1_4 : out COLUMN; --LSB
	DATA_OUT_OK : out std_logic; --signaux de contrôle
	DATA_OUT_ACK : in std_logic
);
end algo;


architecture archi of algo is

component multiplexeur is
port (
	horl : in std_logic;
	clr : in std_logic;
	
	sel : in std_logic_vector(3 downto 0);
	
	data_in_A : in STATE; 
	data_in_ok_A : in std_logic;
	
	data_in_B : in STATE; 
	data_in_ok_B : in std_logic;
	
	data_out : out STATE;
	data_out_ok : out std_logic;
	
	ack_data_in_A : out std_logic;
	ack_data_in_B : out std_logic;
	
	ack_data_out : in std_logic;
	
	etat : out std_logic_vector (1 downto 0)
);
end component;

component key_schedule is
port (
	horl : in std_logic;
	clr : in std_logic;	
	
	round_in : in std_logic_vector(3 downto 0);
	
	Key_in : in STATE;
	Key_in_ok  : in std_logic;

	Key_out : out STATE;
	Key_out_ok : out std_logic;
	
	ack_Key_in : out std_logic;
	ack_Key_out : in std_logic;
	
	etat : out std_logic_vector (1 downto 0)
);
end component;

component add_round_key is
port (
	horl : in std_logic;
	clr : in std_logic;
	
	Key_in : in STATE;
	Key_in_ok  : in std_logic;
	
	D_in : in STATE;
	D_in_ok : in std_logic;
	
	D_out : out STATE;
	D_out_ok : out std_logic;
	
	ack_D_in : out std_logic;
	ack_Key_in : out std_logic;
	ack_D_out : in std_logic;
	
	etat : out std_logic_vector (1 downto 0)
);
end component;

component demultiplexeur is
port (
	horl : in std_logic;
	clr : in std_logic;
	
	sel : in std_logic_vector(3 downto 0);
	
	data_in : in STATE; 
	data_in_ok : in std_logic;
	
	data_out_A : out STATE;
	data_out_ok_A : out std_logic;
	
	data_out_B : out STATE;
	data_out_ok_B : out std_logic;
	
	ack_data_in : out std_logic;
	
	ack_data_out_A : in std_logic;
	ack_data_out_B : in std_logic;
	
	etat : out std_logic_vector (1 downto 0)
);
end component;

component sub_bytes is
port (
	horl : in std_logic;
	clr : in std_logic;
	
	v_in : in STATE;
	v_in_ok : in std_logic;
	
	v_out : out STATE;
	v_out_ok : out std_logic;
	
	ack_v_in : out std_logic;
	ack_v_out : in std_logic;
	
	etat : out std_logic_vector (1 downto 0)
);
end component;

component shift_rows is
port (
	horl : in std_logic;
	clr : in std_logic;
	
	din : in STATE;
	din_ok : in std_logic;
	
	dout : out STATE;
	dout_ok : out std_logic;
	
	ack_din : out std_logic;
	ack_dout : in std_logic;
	
	etat : out std_logic_vector (1 downto 0)
);
end component;

component mix_columns is
port (
	horl : in std_logic;
	clr : in std_logic;
	
	round_in : in std_logic_vector(3 downto 0);
	
	D_in : in STATE;
	D_in_ok : in std_logic;
	
	D_out : out STATE;
	D_out_ok : out std_logic;
	
	ack_D_in : out std_logic;
	ack_D_out : in std_logic;
	
	etat : out std_logic_vector (1 downto 0)
);
end component;

component compte_tours is
port (
	clr : in std_logic;
	tour_inc_in : in std_logic;
	tour_out : out std_logic_vector (3 downto 0)
);
end component;

component concateneur is
port (
	horl : in std_logic;
	clr : in std_logic;
	data_in_4_4 : in COLUMN;
	data_in_3_4 : in COLUMN;
	data_in_2_4 : in COLUMN;
	data_in_1_4 : in COLUMN;
	data_in_ok : in std_logic;
	ack_data_in : out std_logic;
	data_out : out STATE;
	data_out_ok : out std_logic;
	ack_data_out : in std_logic;
	etat : out std_logic_vector (1 downto 0)
);
end component;

component deconcateneur is
port (
	horl : in std_logic;
	clr : in std_logic;
	data_in : in STATE;
	data_in_ok : in std_logic;
	ack_data_in : out std_logic;
	data_out_4_4 : out COLUMN;
	data_out_3_4 : out COLUMN;
	data_out_2_4 : out COLUMN;
	data_out_1_4 : out COLUMN;
	data_out_ok : out std_logic;
	ack_data_out : in std_logic;
	etat : out std_logic_vector (1 downto 0)
);
end component;


signal nb_tour : std_logic_vector(3 downto 0) := (others => '0');

signal etat_mux : std_logic_vector(1 downto 0) := (others => '0');
signal etat_ksch : std_logic_vector(1 downto 0) := (others => '0');
signal etat_add : std_logic_vector(1 downto 0) := (others => '0');
signal etat_demux : std_logic_vector(1 downto 0) := (others => '0');
signal etat_sub : std_logic_vector(1 downto 0) := (others => '0');
signal etat_sh : std_logic_vector(1 downto 0) := (others => '0');
signal etat_mix : std_logic_vector(1 downto 0) := (others => '0');
signal etat_conc_data : std_logic_vector (1 downto 0) := (others => '0');
signal etat_conc_key : std_logic_vector (1 downto 0) := (others => '0');
signal etat_deconc : std_logic_vector (1 downto 0) := (others => '0');

signal ksch_add_key : STATE := (others => '0');
signal ksch_add_key_ok : std_logic :='0';
signal add_ksch_ack_key : std_logic :='0';

signal mux_add_data : STATE := (others => '0');
signal mux_add_data_ok : std_logic :='0';
signal add_mux_ack_data : std_logic :='0';

signal add_demux_data : STATE := (others => '0');
signal add_demux_data_ok : std_logic :='0';
signal demux_add_ack_data : std_logic :='0';

signal demux_sub_data : STATE := (others => '0');
signal demux_sub_data_ok : std_logic :='0';
signal sub_demux_ack_data : std_logic :='0';

signal sub_sh_data : STATE := (others => '0');
signal sub_sh_data_ok : std_logic :='0';
signal sh_sub_ack_data : std_logic :='0';

signal sh_mix_data : STATE := (others => '0');
signal sh_mix_data_ok : std_logic :='0';
signal mix_sh_ack_data : std_logic :='0';

signal mix_mux_data : STATE := (others => '0');
signal mix_mux_data_ok : std_logic :='0';
signal mux_mix_ack_data : std_logic :='0';

signal conc_ksch_data : STATE := (others => '0');
signal conc_ksch_data_ok : std_logic :='0';
signal ksch_conc_ack_data : std_logic :='0';

signal conc_mux_data : STATE := (others => '0');
signal conc_mux_data_ok : std_logic :='0';
signal mux_conc_ack_data : std_logic :='0';

signal demux_deconc_data : STATE := (others => '0');
signal demux_deconc_data_ok : std_logic :='0';
signal deconc_demux_ack_data : std_logic :='0';

begin

U0 : multiplexeur port map
(
	horl => HORL,
	clr => CLR,
	sel => nb_tour,
	data_in_A => conc_mux_data,
	data_in_ok_A => conc_mux_data_ok,
	data_in_B => mix_mux_data,
	data_in_ok_B => mix_mux_data_ok,
	data_out => mux_add_data,
	data_out_ok => mux_add_data_ok,
	ack_data_in_A => mux_conc_ack_data,
	ack_data_in_B => mux_mix_ack_data,
	ack_data_out => add_mux_ack_data,
	etat => etat_mux
);

U1 : key_schedule port map
(
	horl => HORL,
	clr => CLR,
	round_in => nb_tour,
	Key_in => conc_ksch_data,
	Key_in_ok => conc_ksch_data_ok,
	Key_out => ksch_add_key,
	Key_out_ok => ksch_add_key_ok,
	ack_Key_in => ksch_conc_ack_data,
	ack_Key_out => add_ksch_ack_key,
	etat => etat_ksch
);

U2 : add_round_key port map
(
	horl => HORL,
	clr => CLR,
	Key_in => ksch_add_key,
	Key_in_ok => ksch_add_key_ok,
	D_in => mux_add_data,
	D_in_ok => mux_add_data_ok,
	D_out => add_demux_data,
	D_out_ok => add_demux_data_ok,
	ack_D_in => add_mux_ack_data,
	ack_Key_in => add_ksch_ack_key,
	ack_D_out => demux_add_ack_data,
	etat => etat_add
);

U3 : demultiplexeur port map
(
	horl => HORL,
	clr => CLR,
	sel => nb_tour,
	data_in => add_demux_data,
	data_in_ok => add_demux_data_ok,
	data_out_A => demux_deconc_data,
	data_out_ok_A => demux_deconc_data_ok,
	data_out_B => demux_sub_data,
	data_out_ok_B => demux_sub_data_ok,
	ack_data_in => demux_add_ack_data,
	ack_data_out_A => deconc_demux_ack_data,
	ack_data_out_B => sub_demux_ack_data,
	etat => etat_demux
);

U4 : sub_bytes port map
(
	horl => HORL,
	clr => CLR,
	v_in => demux_sub_data,
	v_in_ok => demux_sub_data_ok,
	v_out => sub_sh_data,
	v_out_ok => sub_sh_data_ok,
	ack_v_in => sub_demux_ack_data,
	ack_v_out => sh_sub_ack_data,
	etat => etat_sub
);

U5 : shift_rows port map
(
	horl => HORL,
	clr => CLR,
	din => sub_sh_data,
	din_ok => sub_sh_data_ok,
	dout => sh_mix_data,
	dout_ok => sh_mix_data_ok,
	ack_din => sh_sub_ack_data,
	ack_dout => mix_sh_ack_data,
	etat => etat_sh
);

U6 : mix_columns port map
(
	horl => HORL,
	clr => CLR,
	round_in => nb_tour,
	D_in => sh_mix_data,
	D_in_ok => sh_mix_data_ok,
	D_out => mix_mux_data,
	D_out_ok => mix_mux_data_ok,
	ack_D_in => mix_sh_ack_data,
	ack_D_out => mux_mix_ack_data,
	etat => etat_mix
);

U7 : compte_tours port map
(

	clr => CLR,
	tour_inc_in => add_demux_data_ok,
	tour_out => nb_tour
);

U8 : concateneur port map
(
	horl => HORL,
	clr => CLR,
	data_in_4_4 => DATA_IN_4_4,
	data_in_3_4 => DATA_IN_3_4,
	data_in_2_4 => DATA_IN_2_4,
	data_in_1_4 => DATA_IN_1_4,
	data_in_ok => DATA_IN_OK,
	ack_data_in => DATA_IN_ACK,
	data_out => conc_mux_data,
	data_out_ok => conc_mux_data_ok,
	ack_data_out => mux_conc_ack_data,
	etat => etat_conc_data
); 

U9 : concateneur port map
(
	horl => HORL,
	clr => CLR,
	data_in_4_4 => KEY_IN_4_4,
	data_in_3_4 => KEY_IN_3_4,
	data_in_2_4 => KEY_IN_2_4,
	data_in_1_4 => KEY_IN_1_4,
	data_in_ok => KEY_IN_OK,
	ack_data_in => KEY_IN_ACK,
	data_out => conc_ksch_data,
	data_out_ok => conc_ksch_data_ok,
	ack_data_out => ksch_conc_ack_data,
	etat => etat_conc_key
); 

U10 : deconcateneur port map
(
	horl => HORL,
	clr => CLR,
	data_in => demux_deconc_data,
	data_in_ok => demux_deconc_data_ok,
	ack_data_in => deconc_demux_ack_data,
	data_out_4_4 => DATA_OUT_4_4,
	data_out_3_4 => DATA_OUT_3_4,
	data_out_2_4 => DATA_OUT_2_4,
	data_out_1_4 => DATA_OUT_1_4,
	data_out_ok => DATA_OUT_OK,
	ack_data_out => DATA_OUT_ACK,
	etat => etat_deconc
);

end archi;