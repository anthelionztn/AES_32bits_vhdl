library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
------------------------algo---------------------------
------assemblage de l'algo avec E/S de 32 bits---------
-------------------------------------------------------


-------------------------------------------------------
--------entrées : 8 registres (4 data + 4 key)---------
---------------- + 1 registre 4 signaux contrôle-------
---------------- + signal d'horloge + signal de raz----
-------------------------------------------------------
---------------sorties : 4 registres data--------------
---------------------- + 1 registre 2 signaux contrôle-
-------------------------------------------------------

-------------------------------------------------------
--------opération complétée en 1262 ns à 50 MHz--------
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
	
	key_in : in STATE;
	key_in_ok  : in std_logic;

	key_out : out STATE;
	key_out_ok : out std_logic;
	
	ack_key_in : out std_logic;
	ack_key_out : in std_logic;
	
	etat : out std_logic_vector (1 downto 0)
);
end component;

component add_round_key is
port (
	horl : in std_logic;
	clr : in std_logic;
	
	key_in : in STATE;
	key_in_ok  : in std_logic;
	
	data_in : in STATE;
	data_in_ok : in std_logic;
	
	data_out : out STATE;
	data_out_ok : out std_logic;
	
	ack_data_in : out std_logic;
	ack_key_in : out std_logic;
	ack_data_out : in std_logic;
	
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
	
	data_in : in STATE;
	data_in_ok : in std_logic;
	
	data_out : out STATE;
	data_out_ok : out std_logic;
	
	ack_data_in : out std_logic;
	ack_data_out : in std_logic;
	
	etat : out std_logic_vector (1 downto 0)
);
end component;

component shift_rows is
port (
	horl : in std_logic;
	clr : in std_logic;
	
	data_in : in STATE;
	data_in_ok : in std_logic;
	
	data_out : out STATE;
	data_out_ok : out std_logic;
	
	ack_data_in : out std_logic;
	ack_data_out : in std_logic;
	
	etat : out std_logic_vector (1 downto 0)
);
end component;

component mix_columns is
port (
	horl : in std_logic;
	clr : in std_logic;
	
	round_in : in std_logic_vector(3 downto 0);
	
	data_in : in STATE;
	data_in_ok : in std_logic;
	
	data_out : out STATE;
	data_out_ok : out std_logic;
	
	ack_data_in : out std_logic;
	ack_data_out : in std_logic;
	
	etat : out std_logic_vector (1 downto 0)
);
end component;

component compte_tours is
port (
	clr : in std_logic;
	raz : in std_logic;
	tour_inc_in : in std_logic;
	tour_out : out std_logic_vector (3 downto 0)
);
end component;

component ordonnanceur is
port (
	
	------------------------------------------------------------------------------
	--de l'exterieur
	horl : in std_logic;
	clr : in std_logic; --signal de mise à zéro
	
	key_in_4_4_a : in COLUMN; --données d'entrée --MSB
	key_in_3_4_a : in COLUMN;
	key_in_2_4_a : in COLUMN;
	key_in_1_4_a : in COLUMN; --LSB
	key_in_ok_a : in std_logic;
	
	data_in_4_4_a : in COLUMN; --données d'entrée --MSB
	data_in_3_4_a : in COLUMN;
	data_in_2_4_a : in COLUMN;
	data_in_1_4_a : in COLUMN; --LSB	
	data_in_ok_a : in std_logic;
	
	ack_data_out_a : in std_logic;
	------------------------------------------------------------------------------
	
	------------------------------------------------------------------------------
	--vers l'exterieur
	ack_key_in_a : out std_logic;
	ack_data_in_a : out std_logic;
	
	data_out_4_4_a : out COLUMN; --sortie des données --MSB
	data_out_3_4_a : out COLUMN;
	data_out_2_4_a : out COLUMN;
	data_out_1_4_a : out COLUMN; --LSB
	data_out_ok_a : out std_logic;
	------------------------------------------------------------------------------
	
	------------------------------------------------------------------------------
	--de l'interieur
	ack_data_out_b : in std_logic; --acquittement des données de sortie, du mux
	
	ack_key_out_b : in std_logic; --acquittement de la clé de sortie, de keyschedule
	
	data_in_b : in STATE; --entrée des données, du demux
	data_in_ok_b : in std_logic; --signal de validité des données d'entrée, du demux
	------------------------------------------------------------------------------
	
	------------------------------------------------------------------------------
	--vers l'interieur
	key_out_b : out STATE; --clé de sortie, vers keyschedule
	key_out_ok_b : out std_logic; --signal de validité de la clé de sortie, vers keyschedule
	
	data_out_b : out STATE; --données de sortie, vers le mux
	data_out_ok_b : out std_logic; --signal de validité des données de sortie, vers le mux
	
	ack_data_in_b : out std_logic; --acquittement envoyé au demux
	------------------------------------------------------------------------------
	
	etat_in : out std_logic_vector (1 downto 0); --état de la machine d'état (debug)
	etat_out : out std_logic_vector (1 downto 0) --état de la machine d'état (debug)
	
);
end component;


signal HORL_T : std_logic := '0';
signal CLR_T : std_logic := '0';
signal KEY_IN_4_4_T : COLUMN := (others => '0');
signal KEY_IN_3_4_T : COLUMN := (others => '0');
signal KEY_IN_2_4_T : COLUMN := (others => '0');
signal KEY_IN_1_4_T : COLUMN := (others => '0');
signal KEY_IN_OK_T : std_logic := '0';
signal KEY_IN_ACK_T : std_logic := '0';
signal DATA_IN_4_4_T : COLUMN := (others => '0');
signal DATA_IN_3_4_T : COLUMN := (others => '0');
signal DATA_IN_2_4_T : COLUMN := (others => '0');
signal DATA_IN_1_4_T : COLUMN := (others => '0');
signal DATA_IN_OK_T : std_logic := '0';
signal DATA_IN_ACK_T : std_logic := '0';
signal DATA_OUT_4_4_T : COLUMN := (others => '0');
signal DATA_OUT_3_4_T : COLUMN := (others => '0');
signal DATA_OUT_2_4_T : COLUMN := (others => '0');
signal DATA_OUT_1_4_T : COLUMN := (others => '0');
signal DATA_OUT_OK_T : std_logic := '0';
signal DATA_OUT_ACK_T : std_logic := '0';
	
	
signal nb_tour : std_logic_vector(3 downto 0) := (others => '0');

signal etat_mux : std_logic_vector(1 downto 0) := (others => '0');
signal etat_ksch : std_logic_vector(1 downto 0) := (others => '0');
signal etat_add : std_logic_vector(1 downto 0) := (others => '0');
signal etat_demux : std_logic_vector(1 downto 0) := (others => '0');
signal etat_sub : std_logic_vector(1 downto 0) := (others => '0');
signal etat_sh : std_logic_vector(1 downto 0) := (others => '0');
signal etat_mix : std_logic_vector(1 downto 0) := (others => '0');
signal etat_ordo_a : std_logic_vector (1 downto 0) := (others => '0');
signal etat_ordo_b : std_logic_vector (1 downto 0) := (others => '0');


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

signal ordo_mux_data : STATE := (others => '0');
signal ordo_mux_data_ok : std_logic :='0';
signal mux_ordo_ack_data : std_logic :='0';

signal ordo_ksch_data : STATE := (others => '0');
signal ordo_ksch_data_ok : std_logic :='0';
signal ksch_ordo_ack_data : std_logic :='0';

signal demux_ordo_data : STATE := (others => '0');
signal demux_ordo_data_ok : std_logic :='0';
signal ordo_demux_ack_data : std_logic :='0';


begin

HORL_T <= HORL;--I
CLR_T <= CLR;--I
KEY_IN_4_4_T <= KEY_IN_4_4;--I
KEY_IN_3_4_T <= KEY_IN_3_4;--I
KEY_IN_2_4_T <= KEY_IN_2_4;--I
KEY_IN_1_4_T <= KEY_IN_1_4;--I
KEY_IN_OK_T <= KEY_IN_OK;--I
KEY_IN_ACK <= KEY_IN_ACK_T;--O
DATA_IN_4_4_T <= DATA_IN_4_4;--I
DATA_IN_3_4_T <= DATA_IN_3_4;--I
DATA_IN_2_4_T <= DATA_IN_2_4;--I
DATA_IN_1_4_T <= DATA_IN_1_4;--I
DATA_IN_OK_T <= DATA_IN_OK;--I
DATA_IN_ACK <= DATA_IN_ACK_T;--O
DATA_OUT_4_4 <= DATA_OUT_4_4_T;--O
DATA_OUT_3_4 <= DATA_OUT_3_4_T;--O
DATA_OUT_2_4 <= DATA_OUT_2_4_T;--O
DATA_OUT_1_4 <= DATA_OUT_1_4_T;--O
DATA_OUT_OK <= DATA_OUT_OK_T;--O
DATA_OUT_ACK_T <= DATA_OUT_ACK;--I

U0 : multiplexeur port map
(
	horl => HORL_T,
	clr => CLR_T,
	sel => nb_tour,
	data_in_A => ordo_mux_data,
	data_in_ok_A => ordo_mux_data_ok,
	data_in_B => mix_mux_data,
	data_in_ok_B => mix_mux_data_ok,
	data_out => mux_add_data,
	data_out_ok => mux_add_data_ok,
	ack_data_in_A => mux_ordo_ack_data,
	ack_data_in_B => mux_mix_ack_data,
	ack_data_out => add_mux_ack_data,
	etat => etat_mux
);

U1 : key_schedule port map
(
	horl => HORL_T,
	clr => CLR_T,
	round_in => nb_tour,
	key_in => ordo_ksch_data,
	key_in_ok => ordo_ksch_data_ok,
	key_out => ksch_add_key,
	key_out_ok => ksch_add_key_ok,
	ack_key_in => ksch_ordo_ack_data,
	ack_key_out => add_ksch_ack_key,
	etat => etat_ksch
);

U2 : add_round_key port map
(
	horl => HORL_T,
	clr => CLR_T,
	key_in => ksch_add_key,
	key_in_ok => ksch_add_key_ok,
	data_in => mux_add_data,
	data_in_ok => mux_add_data_ok,
	data_out => add_demux_data,
	data_out_ok => add_demux_data_ok,
	ack_data_in => add_mux_ack_data,
	ack_key_in => add_ksch_ack_key,
	ack_data_out => demux_add_ack_data,
	etat => etat_add
);

U3 : demultiplexeur port map
(
	horl => HORL_T,
	clr => CLR_T,
	sel => nb_tour,
	data_in => add_demux_data,
	data_in_ok => add_demux_data_ok,
	data_out_A => demux_ordo_data,
	data_out_ok_A => demux_ordo_data_ok,
	data_out_B => demux_sub_data,
	data_out_ok_B => demux_sub_data_ok,
	ack_data_in => demux_add_ack_data,
	ack_data_out_A => ordo_demux_ack_data,
	ack_data_out_B => sub_demux_ack_data,
	etat => etat_demux
);

U4 : sub_bytes port map
(
	horl => HORL_T,
	clr => CLR_T,
	data_in => demux_sub_data,
	data_in_ok => demux_sub_data_ok,
	data_out => sub_sh_data,
	data_out_ok => sub_sh_data_ok,
	ack_data_in => sub_demux_ack_data,
	ack_data_out => sh_sub_ack_data,
	etat => etat_sub
);

U5 : shift_rows port map
(
	horl => HORL_T,
	clr => CLR_T,
	data_in => sub_sh_data,
	data_in_ok => sub_sh_data_ok,
	data_out => sh_mix_data,
	data_out_ok => sh_mix_data_ok,
	ack_data_in => sh_sub_ack_data,
	ack_data_out => mix_sh_ack_data,
	etat => etat_sh
);

U6 : mix_columns port map
(
	horl => HORL_T,
	clr => CLR_T,
	round_in => nb_tour,
	data_in => sh_mix_data,
	data_in_ok => sh_mix_data_ok,
	data_out => mix_mux_data,
	data_out_ok => mix_mux_data_ok,
	ack_data_in => mix_sh_ack_data,
	ack_data_out => mux_mix_ack_data,
	etat => etat_mix
);

U7 : compte_tours port map
(
	clr => CLR_T,
	raz => DATA_OUT_OK_T,
	tour_inc_in => add_demux_data_ok,
	tour_out => nb_tour
);

U8 : ordonnanceur port map
(
	------------------------------------------------------------------------------
	--de l'exterieur
	horl => HORL_T,
	clr => CLR_T,
	key_in_4_4_a => KEY_IN_4_4_T,
	key_in_3_4_a => KEY_IN_3_4_T,
	key_in_2_4_a => KEY_IN_2_4_T,
	key_in_1_4_a => KEY_IN_1_4_T,
	key_in_ok_a => KEY_IN_OK_T,
	
	data_in_4_4_a => DATA_IN_4_4_T,
	data_in_3_4_a => DATA_IN_3_4_T,
	data_in_2_4_a => DATA_IN_2_4_T,
	data_in_1_4_a => DATA_IN_1_4_T,
	data_in_ok_a => DATA_IN_OK_T,
	
	ack_data_out_a => DATA_OUT_ACK_T,
	------------------------------------------------------------------------------
	------------------------------------------------------------------------------
	--vers l'exterieur
	ack_key_in_a => KEY_IN_ACK_T,
	ack_data_in_a => DATA_IN_ACK_T,
	
	data_out_4_4_a => DATA_OUT_4_4_T,
	data_out_3_4_a => DATA_OUT_3_4_T,
	data_out_2_4_a => DATA_OUT_2_4_T,
	data_out_1_4_a => DATA_OUT_1_4_T,
	data_out_ok_a => DATA_OUT_OK_T,
	------------------------------------------------------------------------------
	------------------------------------------------------------------------------
	--de l'interieur
	ack_data_out_b => mux_ordo_ack_data,
	
	ack_key_out_b => ksch_ordo_ack_data,
	
	data_in_b => demux_ordo_data,
	data_in_ok_b => demux_ordo_data_ok,
	------------------------------------------------------------------------------
	------------------------------------------------------------------------------
	--vers l'interieur
	key_out_b => ordo_ksch_data,
	key_out_ok_b => ordo_ksch_data_ok,
	
	data_out_b => ordo_mux_data,
	data_out_ok_b => ordo_mux_data_ok,
	
	ack_data_in_b => ordo_demux_ack_data,
	------------------------------------------------------------------------------
	etat_in => etat_ordo_a,
	etat_out => etat_ordo_b
);

end archi;