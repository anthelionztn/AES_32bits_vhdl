library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
------------------------sub_bytes----------------------
--remplacement des mots par leur équivalent de la s_box
-------------------------------------------------------


entity sub_bytes is
port (
	horl : in std_logic; --horloge de cadencement
	clr : in std_logic; --mise à zéro
	
	data_in : in STATE; --données d'entrée, de demultiplexeur
	data_in_ok : in std_logic; --validité des données d'entrée
	
	data_out : out STATE; --données de sortie, vers shift_rows
	data_out_ok : out std_logic;  --validité des données de sortie
	
	ack_data_in : out std_logic; --acquittement des données d'entrée, vers demultiplexeur
	ack_data_out : in std_logic; --acquittement des données de sortie, de shift_rows
	
	etat : out std_logic_vector (1 downto 0) --état de la machine d'état (debug)
);
end sub_bytes;


architecture archi of sub_bytes is

signal etat_courant : etat_4FSM_type := inactif;

signal data_out_t : STATE := (others => '0');
signal data_out_ok_t : std_logic := '0';
signal ack_data_in_t : std_logic := '0';
signal etat_t : std_logic_vector(1 downto 0) := "10";

begin

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
					etat_courant <= actif;
				end if;
			when attente1 =>
				if (ack_data_out = '1') then
					etat_courant <= attente2;
				end if;
			when attente2 =>
				if (data_in_ok = '0') then
					etat_courant <= inactif;
				end if;
			when actif =>
				etat_courant <= attente1;
		end case;
	end if;
end process process1;

process2 : process(etat_courant, data_in)
variable data_out_temp : STATE := (others => '0'); --mémoire de sortie
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
		when actif =>
			etat_t <= "00";
			
			data_out_temp(7 downto 0) := s_box_fonc(data_in(7 downto 0));
			data_out_temp(15 downto 8) := s_box_fonc(data_in(15 downto 8));
			data_out_temp(23 downto 16) := s_box_fonc(data_in(23 downto 16));
			data_out_temp(31 downto 24) := s_box_fonc(data_in(31 downto 24));
			
			data_out_temp(39 downto 32) := s_box_fonc(data_in(39 downto 32));
			data_out_temp(47 downto 40) := s_box_fonc(data_in(47 downto 40));
			data_out_temp(55 downto 48) := s_box_fonc(data_in(55 downto 48));
			data_out_temp(63 downto 56) := s_box_fonc(data_in(63 downto 56));
			
			data_out_temp(71 downto 64) := s_box_fonc(data_in(71 downto 64));
			data_out_temp(79 downto 72) := s_box_fonc(data_in(79 downto 72));
			data_out_temp(87 downto 80) := s_box_fonc(data_in(87 downto 80));
			data_out_temp(95 downto 88) := s_box_fonc(data_in(95 downto 88));
			
			data_out_temp(103 downto 96) := s_box_fonc(data_in(103 downto 96));
			data_out_temp(111 downto 104) := s_box_fonc(data_in(111 downto 104));
			data_out_temp(119 downto 112) := s_box_fonc(data_in(119 downto 112));
			data_out_temp(127 downto 120) := s_box_fonc(data_in(127 downto 120));

			data_out_t <= data_out_temp;
			data_out_ok_t <= '1';
			ack_data_in_t <= '1';		
	end case;
end process process2;

end archi;