library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
---------------------demultiplexeur--------------------
-----redirection de l'entrée vers la sortie A ou B-----
-------------------------------------------------------


entity demultiplexeur is
port (
	horl : in std_logic; --horloge de cadencement
	clr : in std_logic; --mise à zéro
	
	sel : in std_logic_vector(3 downto 0); --sélecteur, connecté à compte_tours
	
	data_in : in STATE; --données d'entrée, de add_round_key
	data_in_ok : in std_logic; --validité des données d'entrée
	
	data_out_A : out STATE; --première sortie de données, vers sub_bytes
	data_out_ok_A : out std_logic; --validité des données de la première sortie
	
	data_out_B : out STATE; --deuxième sortie de données, vers deconcateneur
	data_out_ok_B : out std_logic; --validité des données de la deuxième sortie
	
	ack_data_in : out std_logic; --acquittement des données d'entrée, va vers l'amont
	
	ack_data_out_A : in std_logic; --acquittement des données de la première sortie, vient de sub_bytes
	ack_data_out_B : in std_logic; --acquittement des données de la deuxième sortie, vient du deconcateneur
	
	etat : out std_logic_vector (1 downto 0) --état de la machine d'état (debug)
);
end demultiplexeur;


architecture archi of demultiplexeur is

signal etat_courant : etat_6FSM_type := inactif;

signal sel_t : integer range 0 to 15 := 0; --sélecteur de redirection de l'entrée
signal data_out_A_t : STATE := (others => '0');
signal data_out_ok_A_t : std_logic := '0';
signal data_out_B_t : STATE := (others => '0');
signal data_out_ok_B_t : std_logic := '0';
signal ack_data_in_t : std_logic := '0';
signal etat_t : std_logic_vector(1 downto 0) := "10";

begin

sel_t <= to_integer(unsigned(sel));
data_out_A <= data_out_A_t;
data_out_ok_A <= data_out_ok_A_t;
data_out_B <= data_out_B_t;
data_out_ok_B <= data_out_ok_B_t;
ack_data_in <= ack_data_in_t;
etat <= etat_t;

process1 : process(horl, clr)
begin
	if(clr = '1') then
		etat_courant <= inactif;
	elsif rising_edge(horl) then
		case etat_courant is
			when inactif =>
				if (data_in_ok = '1') then
					case sel_t is
						when 11 =>
							etat_courant <= actif_a;
						when others =>
							etat_courant <= actif_b;
					end case;
				end if;
			when attente1_a =>
				if (ack_data_out_A = '1') then
					etat_courant <= attente2;
				end if;
			when attente1_b => 
				if (ack_data_out_B = '1') then
					etat_courant <= attente2;
				end if;
			when attente2 =>
				if (data_in_ok = '0') then
					etat_courant <= inactif;
				end if;
			when actif_a =>
				etat_courant <= attente1_a;
			when actif_b =>
				etat_courant <= attente1_b;
		end case;
	end if;
end process process1;


process2 : process(etat_courant, data_in)
begin
	case etat_courant is
		when inactif =>
			etat_t <= "10";
			data_out_A_t <= (others => '0');
			data_out_B_t <= (others => '0');
			data_out_ok_A_t <= '0';
			data_out_ok_B_t <= '0';
			ack_data_in_t <= '0';
		when attente1_a =>
			etat_t <= "11";
			data_out_ok_A_t <= '1';
			data_out_ok_B_t <= '0';
			ack_data_in_t <= '1';
		when attente1_b =>
			etat_t <= "11";
			data_out_ok_A_t <= '0';
			data_out_ok_B_t <= '1';
			ack_data_in_t <= '1';
		when attente2 =>
			etat_t <= "01";
			data_out_A_t <= (others => '0');
			data_out_B_t <= (others => '0');
			data_out_ok_A_t <= '0';
			data_out_ok_B_t <= '0';
			ack_data_in_t <= '0';
		when actif_a =>
			etat_t <= "00";
			data_out_A_t <= data_in;
			data_out_B_t <= (others => '0');
			data_out_ok_A_t <= '1';
			data_out_ok_B_t <= '0';
			ack_data_in_t <= '1';
		when actif_b =>
			etat_t <= "00";
			data_out_A_t <= (others => '0');
			data_out_B_t <= data_in;
			data_out_ok_A_t <= '0';
			data_out_ok_B_t <= '1';
			ack_data_in_t <= '1';
	end case;
end process process2;


end archi;