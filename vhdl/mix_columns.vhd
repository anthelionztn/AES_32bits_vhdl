library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
----------------------mix_columns----------------------
--multiplication des données d'entrée par une matrice--
-------------------------------------------------------


entity mix_columns is
port (
	horl : in std_logic; --signal d'horloge
	clr : in std_logic; --mise à zéro
	
	round_in : in std_logic_vector(3 downto 0); --entrée du numéro de tour
	
	data_in : in STATE; --données d'entrée, de shift_rows
	data_in_ok : in std_logic; --indicateur de validité de l'entrée
	
	data_out : out STATE; --données de sortie, vers multiplexeur
	data_out_ok : out std_logic; --indicateur de validité de la sortie
	
	ack_data_in : out std_logic; --vers l'amont : entrée prise en compte
	ack_data_out : in std_logic; --de l'aval : sortie prise en compte
	
	etat : out std_logic_vector (1 downto 0) --indicateur de l'état courant (pour debug)
);
end mix_columns;


architecture archi of mix_columns is

signal etat_courant : etat_5FSM_type := inactif;

signal round_in_t : integer range 0 to 15 := 0; --numéro du tour courant
signal data_out_t : STATE := (others => '0');
signal data_out_ok_t : std_logic := '0';
signal ack_data_in_t : std_logic := '0';
signal etat_t : std_logic_vector(1 downto 0) := "10";

begin

round_in_t <= to_integer(unsigned(round_in));
data_out <= data_out_t;
data_out_ok <= data_out_ok_t;
ack_data_in <= ack_data_in_t;
etat <= etat_t;

process1 : process(horl, clr)
begin
	if(clr = '1') then
		etat_courant <= inactif;
	elsif rising_edge(horl) then
		case etat_courant is
			when inactif =>
				if (data_in_ok = '1') and (ack_data_out = '0') then
					case round_in_t is
						when 10 =>
							etat_courant <= actif_a;
						when others =>
							etat_courant <= actif_b;
					end case;
				end if;
			when attente1 =>
				if (ack_data_out = '1') then
					etat_courant <= attente2;
				end if;
			when attente2 =>
				if (data_in_ok = '0') then
					etat_courant <= inactif;
				end if;
			when actif_a =>
				etat_courant <= attente1;
			when actif_b =>
				etat_courant <= attente1;
		end case;
	end if;
end process process1;


process2 : process(etat_courant, data_in)
variable data_out_temp : STATE := (others => '0');
begin
	case etat_courant is
		when inactif =>
			etat_t <= "10";
			data_out_t <= (others => '0');
			data_out_ok_t <= '0';
			ack_data_in_t <= '0';
		when attente1 =>
			etat_t <= "11";
			data_out_ok_t <= '1';
			ack_data_in_t <= '1';
		when attente2 =>
			etat_t <= "01";
			data_out_t <= (others => '0');
			data_out_ok_t <= '0';
			ack_data_in_t <= '0';
		when actif_a =>
			etat_t <= "00";
			data_out_t <= data_in;
			data_out_ok_t <= '1';
			ack_data_in_t <= '1';
		when actif_b =>
			etat_t <= "00";
			
			--colonne 0
			data_out_temp(7 downto 0) := mult_2_fonc(elt_fonc(data_in, 0))
								xor mult_3_fonc(elt_fonc(data_in, 1)) 
								xor elt_fonc(data_in, 2) 
								xor elt_fonc(data_in, 3);
			data_out_temp(15 downto 8) := elt_fonc(data_in, 0)
								xor mult_2_fonc(elt_fonc(data_in, 1))
								xor mult_3_fonc(elt_fonc(data_in, 2)) 
								xor elt_fonc(data_in, 3);
			data_out_temp(23 downto 16) := elt_fonc(data_in, 0)
								xor elt_fonc(data_in, 1) 
								xor mult_2_fonc(elt_fonc(data_in, 2))
								xor mult_3_fonc(elt_fonc(data_in, 3));
			data_out_temp(31 downto 24) := mult_3_fonc(elt_fonc(data_in, 0))
								xor elt_fonc(data_in, 1) 
								xor elt_fonc(data_in, 2) 
								xor mult_2_fonc(elt_fonc(data_in, 3));
			
			--colonne 1
			data_out_temp(39 downto 32) := mult_2_fonc(elt_fonc(data_in, 4))
								xor mult_3_fonc(elt_fonc(data_in, 5))
								xor elt_fonc(data_in, 6) 
								xor elt_fonc(data_in, 7);
			data_out_temp(47 downto 40) := elt_fonc(data_in, 4)
								xor mult_2_fonc(elt_fonc(data_in, 5))
								xor mult_3_fonc(elt_fonc(data_in, 6)) 
								xor elt_fonc(data_in, 7);
			data_out_temp(55 downto 48) := elt_fonc(data_in, 4)
								xor elt_fonc(data_in, 5) 
								xor mult_2_fonc(elt_fonc(data_in, 6))
								xor mult_3_fonc(elt_fonc(data_in, 7));
			data_out_temp(63 downto 56) := mult_3_fonc(elt_fonc(data_in, 4)) 
								xor elt_fonc(data_in, 5) 
								xor elt_fonc(data_in, 6) 
								xor mult_2_fonc(elt_fonc(data_in, 7));
			
			--colonne 2
			data_out_temp(71 downto 64) := mult_2_fonc(elt_fonc(data_in, 8))
								xor mult_3_fonc(elt_fonc(data_in, 9)) 
								xor elt_fonc(data_in, 10) 
								xor elt_fonc(data_in, 11);
			data_out_temp(79 downto 72) := elt_fonc(data_in, 8)
								xor mult_2_fonc(elt_fonc(data_in, 9))
								xor mult_3_fonc(elt_fonc(data_in, 10))  
								xor elt_fonc(data_in, 11);
			data_out_temp(87 downto 80) := elt_fonc(data_in, 8)
								xor elt_fonc(data_in, 9) 
								xor mult_2_fonc(elt_fonc(data_in, 10))
								xor mult_3_fonc(elt_fonc(data_in, 11));
			data_out_temp(95 downto 88) := mult_3_fonc(elt_fonc(data_in, 8)) 
								xor elt_fonc(data_in, 9) 
								xor elt_fonc(data_in, 10) 
								xor mult_2_fonc(elt_fonc(data_in, 11));
			
			--colonne 3
			data_out_temp(103 downto 96) := mult_2_fonc(elt_fonc(data_in, 12))
								xor mult_3_fonc(elt_fonc(data_in, 13))  
								xor elt_fonc(data_in, 14) 
								xor elt_fonc(data_in, 15);
			data_out_temp(111 downto 104) := elt_fonc(data_in, 12)
								xor mult_2_fonc(elt_fonc(data_in, 13))
								xor mult_3_fonc(elt_fonc(data_in, 14)) 
								xor elt_fonc(data_in, 15);
			data_out_temp(119 downto 112) := elt_fonc(data_in, 12)
								xor elt_fonc(data_in, 13) 
								xor mult_2_fonc(elt_fonc(data_in, 14)) 
								xor mult_3_fonc(elt_fonc(data_in, 15));
			data_out_temp(127 downto 120) := mult_3_fonc(elt_fonc(data_in, 12)) 
								xor elt_fonc(data_in, 13) 
								xor elt_fonc(data_in, 14) 
								xor mult_2_fonc(elt_fonc(data_in, 15));
			
			data_out_t <= data_out_temp;
			data_out_ok_t <= '1';
			ack_data_in_t <= '1';
	end case;
end process process2;

end archi;