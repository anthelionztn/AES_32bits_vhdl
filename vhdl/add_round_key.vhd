library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
---------------------add_round_key---------------------
-----addition de la clé de chiffrement aux données-----
-------------------------------------------------------


entity add_round_key is
port (
	horl : in std_logic; --signal d'horloge
	clr : in std_logic; --mise à zéro
	
	key_in : in STATE; --clé en entrée, de key_schedule
	key_in_ok  : in std_logic; --indicateur de validité de la clé
	
	data_in : in STATE; --données d'entrée, de multiplexeur
	data_in_ok : in std_logic; --indicateur de validité de l'entrée
	
	data_out : out STATE; --données de sortie, vers demultiplexeur
	data_out_ok : out std_logic; --indicateur de validité de la sortie
	
	ack_data_in : out std_logic; --vers multiplexeur : entrée prise en compte
	ack_key_in : out std_logic; --vers key_schedule : clé prise en compte
	ack_data_out : in std_logic; --de demultiplexeur : sortie prise en compte
	
	etat : out std_logic_vector (1 downto 0) --indicateur de l'état courant (pour debug)
);
end add_round_key;


architecture archi of add_round_key is

signal etat_courant : etat_4FSM_type := inactif;

signal data_out_t : STATE := (others => '0');
signal data_out_ok_t : std_logic := '0';
signal ack_data_in_t : std_logic := '0';
signal ack_key_in_t : std_logic := '0';
signal etat_t : std_logic_vector(1 downto 0) := "10";

begin

data_out <= data_out_t;
data_out_ok <= data_out_ok_t;
ack_data_in <= ack_data_in_t;
ack_key_in <= ack_key_in_t;
etat <= etat_t;

process1 : process(horl, clr)
begin
	if(clr = '1') then
		etat_courant <= inactif;
	elsif rising_edge(horl) then
		case etat_courant is
			when inactif =>
				if (data_in_ok = '1') and (key_in_ok = '1') and (ack_data_out = '0') then
					etat_courant <= actif;
				end if;
			when attente1 =>
				if (ack_data_out = '1') then
					etat_courant <= attente2;
				end if;
			when attente2 =>
				if (data_in_ok = '0') and (key_in_ok = '0') then
					etat_courant <= inactif;
				end if;
			when actif =>
				etat_courant <= attente1;
		end case;
	end if;
end process process1;


process2 : process(etat_courant, data_in, key_in)
variable data_out_temp : STATE := (others => '0');
begin
	case etat_courant is
		when inactif =>
			etat_t <= "10";
			data_out_t <= (others => '0');
			data_out_ok_t <= '0';
			ack_key_in_t <= '0';
			ack_data_in_t <= '0';
		when attente1 =>
			etat_t <= "11";
			data_out_ok_t <= '1';
			ack_data_in_t <= '1';
			ack_key_in_t <= '1';
		when attente2 =>
			etat_t <= "01";
			data_out_t <= (others => '0');
			data_out_ok_t <= '0';
			ack_data_in_t <= '0';
			ack_key_in_t <= '0';
		when actif =>
			etat_t <= "00";
			data_out_temp := data_in xor key_in; --addition des deux matrices
			data_out_t <= data_out_temp;
			data_out_ok_t <= '1';
			ack_data_in_t <= '1';
			ack_key_in_t <= '1';			
	end case;
end process;

	
end archi;