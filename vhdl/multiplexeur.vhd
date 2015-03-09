library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
----------------------multiplexeur---------------------
--redirection de l'entrée A ou B suivant le sélecteur--
-------------------------------------------------------


entity multiplexeur is
port (
	horl : in std_logic; --horloge de cadencement
	clr : in std_logic; --mise à zéro
	
	sel : in std_logic_vector(3 downto 0); --sélecteur, provient de compte_tours
	
	data_in_A : in STATE; --entrée des données, d'un concateneur
	data_in_ok_A : in std_logic; --validité des données de la première entrée
	
	data_in_B : in STATE; --entrée des données, de mix_columns
	data_in_ok_B : in std_logic; --validité des données de la deuxième entrée
	
	data_out : out STATE; --sortie des données, vers add_round_key
	data_out_ok : out std_logic; --validité des données de sortie
	
	ack_data_in_A : out std_logic; --acquittement des données de la première entrée
	ack_data_in_B : out std_logic; --acquittement des données de la deuxième entrée
	
	ack_data_out : in std_logic; --acquittement des données de sortie
	
	etat : out std_logic_vector (1 downto 0) --indicateur de l'état de la machine d'état (pour debug)
);
end multiplexeur;

architecture archi of multiplexeur is

signal etat_courant : etat_6FSM_type := inactif;

signal sel_t : integer range 0 to 15 := 0; --sélecteur d'entrée
signal data_out_t : STATE := (others => '0');
signal data_out_ok_t : std_logic := '0';
signal ack_data_in_A_t : std_logic := '0';
signal ack_data_in_B_t : std_logic := '0';
signal etat_t : std_logic_vector(1 downto 0) := "10";

begin

sel_t <= to_integer(unsigned(sel));
data_out <= data_out_t;
data_out_ok <= data_out_ok_t;
ack_data_in_A <= ack_data_in_A_t;
ack_data_in_B <= ack_data_in_B_t;
etat <= etat_t;


process1 : process(horl, clr)
begin
	if(clr = '1') then
		etat_courant <= inactif;
	elsif rising_edge(horl) then
		case etat_courant is
			when inactif =>
				case sel_t is
					when 0 =>
						if (data_in_ok_A = '1') then
							etat_courant <= actif_a;
						end if;
					when others =>
						if (data_in_ok_B = '1') then
							etat_courant <= actif_b;
						end if;
				end case;
			when attente1_a =>
				if (ack_data_out = '1') then
					etat_courant <= attente2;
				end if;
			when attente1_b =>
				if (ack_data_out = '1') then
					etat_courant <= attente2;
				end if;
			when attente2 =>
				if (data_in_ok_A = '0') and (data_in_ok_B = '0') then
					etat_courant <= inactif;
				end if;
			when actif_a =>
				etat_courant <= attente1_a;
			when actif_b =>
				etat_courant <= attente1_b;
		end case;
	end if;
end process process1;

process2 : process(etat_courant, data_in_A, data_in_B)
begin
	case etat_courant is
		when inactif =>
			etat_t <= "10";
			data_out_t <= (others => '0');
			data_out_ok_t <= '0';
			ack_data_in_A_t <= '0';
			ack_data_in_B_t <= '0';
		when attente1_a =>
			etat_t <= "11";
			data_out_ok_t <= '1';
			ack_data_in_A_t <= '1';
			ack_data_in_B_t <= '0';
		when attente1_b =>
			etat_t <= "11";
			data_out_ok_t <= '1';
			ack_data_in_A_t <= '0';
			ack_data_in_B_t <= '1';
		when attente2 =>
			etat_t <= "01";
			data_out_t <= (others => '0');
			ack_data_in_A_t <= '0';
			ack_data_in_B_t <= '0';
		when actif_a =>
			etat_t <= "00";
			data_out_t <= data_in_A; --recopie de l'entrée A
			data_out_ok_t <= '1'; --validation des données en sortie
			ack_data_in_A_t <= '1';
		when actif_b =>
			etat_t <= "00";	
			data_out_t <= data_in_B; --recopie de l'entrée B
			data_out_ok_t <= '1'; --validation des données en sortie
			ack_data_in_B_t <= '1';
	end case;
end process process2;

end archi;