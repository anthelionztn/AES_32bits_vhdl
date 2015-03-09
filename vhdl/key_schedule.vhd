library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
---------------------key_schedule----------------------
----expansion de la clé en 10 autres clés partielles---
-------------------------------------------------------


entity key_schedule is
port (
	horl : in std_logic; --signal d'horloge
	clr : in std_logic; --mise à zéro
	
	round_in : in std_logic_vector(3 downto 0); --entrée du numéro de tour
	
	key_in : in STATE; --clé en entrée, d'un concatenateur
	key_in_ok  : in std_logic; --indicateur de validité de la clé

	key_out : out STATE; --données de sortie, vers add_round_key
	key_out_ok : out std_logic; --indicateur de validité de la sortie
	
	ack_key_in : out std_logic; --vers l'amont : entrée prise en compte
	ack_key_out : in std_logic; --de l'aval : sortie prise en compte
	
	etat : out std_logic_vector (1 downto 0) --indicateur de l'état courant (pour debug)
);
end key_schedule;


architecture archi of key_schedule is

signal etat_courant : etat_5FSM_type := inactif;
signal round_in_t : integer range 0 to 15 := 0; --numéro du tours courant
signal key_in_ok_t : std_logic := '0';
signal key_out_t : STATE := (others => '0');
signal key_out_ok_t : std_logic := '0';
signal ack_key_in_t : std_logic := '0';
signal etat_t : std_logic_vector(1 downto 0) := "10";

begin

round_in_t <= to_integer(unsigned(round_in));
key_out <= key_out_t;
key_out_ok <= key_out_ok_t;
ack_key_in <= ack_key_in_t;
etat <= etat_t;

	
process(key_in_ok, clr, round_in_t) is

	begin
		
		if(clr = '1') then
			key_in_ok_t <= '0';		
		elsif (round_in_t = 11) then
			key_in_ok_t <= '0';
		elsif rising_edge(key_in_ok) then
			key_in_ok_t <= '1';	
		end if;
		
end process;	


process1 : process(horl, clr)
begin
	if(clr = '1') then
		etat_courant <= inactif;
	elsif rising_edge(horl) then
		case etat_courant is
			when inactif =>
				if (key_in_ok_t = '1') and (ack_key_out = '0') then
					case round_in_t is
						when 0 =>
							etat_courant <= actif_a;
						when others =>
							etat_courant <= actif_b;
					end case;
				end if;
			when attente1 =>
				if (ack_key_out = '1') then
					etat_courant <= attente2;
				end if;
			when attente2 =>
				etat_courant <= inactif;
			when actif_a =>
				etat_courant <= attente1;
			when actif_b =>
				etat_courant <= attente1;
		end case;
	end if;
end process process1;


process2 : process(etat_courant, key_in, round_in_t)
variable key_out_temp : STATE := (others => '0'); --mémoire de sortie
variable mem_key : STATE := (others => '0'); --mémoire de clé
variable column_t : COLUMN := (others => '0'); --dernière colonne de la clé

begin
	case etat_courant is
		when inactif =>
			etat_t <= "10";
			key_out_t <= (others => '0');
			key_out_ok_t <= '0';
			ack_key_in_t <= '0';
		when attente1 =>
			etat_t <= "11";
			key_out_ok_t <= '1';
			ack_key_in_t <= '1';
		when attente2 =>
			etat_t <= "01";
			key_out_t <= (others => '0');
			key_out_ok_t <= '0';
			ack_key_in_t <= '0';
		when actif_a =>
			etat_t <= "00";
			mem_key := key_in;
			key_out_t <= mem_key;
			key_out_ok_t <= '1';
			ack_key_in_t <= '1';
		when actif_b =>
			etat_t <= "00";
			
			--création de la clé i+1 à partir de la clé i
			--puis mise en mémoire de la clé i+1 pour l'étape suivante
		
			--rot_word sur la dernière colonne de l'état
			column_t := rot_word_fonc(mem_key(127 downto 96));
			
			--ack_key_in_t <= '1'; --acquittement
			
			--sub_bytes sur la dernière colonne de l'état				
			column_t(7 downto 0) := s_box_fonc(column_t(7 downto 0));
			column_t(15 downto 8) := s_box_fonc(column_t(15 downto 8));
			column_t(23 downto 16) := s_box_fonc(column_t(23 downto 16));
			column_t(31 downto 24) := s_box_fonc(column_t(31 downto 24));
			
			--vecteur Rcon(numéro de tour) : x"00_00_00_XX" => on n'utilise que le LSB
			
			--addition des colonnes
			--première colonne de l'état suivant
			key_out_temp(7 downto 0) := mem_key(7 downto 0) xor column_t(7 downto 0) xor Rcon(round_in_t);--rcon_vect(7 downto 0);
			key_out_temp(15 downto 8) := mem_key(15 downto 8) xor column_t(15 downto 8);-- xor rcon_vect(15 downto 8);
			key_out_temp(23 downto 16) := mem_key(23 downto 16) xor column_t(23 downto 16);-- xor rcon_vect(23 downto 16);
			key_out_temp(31 downto 24) := mem_key(31 downto 24) xor column_t(31 downto 24);-- xor rcon_vect(31 downto 24);
			
			--deuxième colonne			
			key_out_temp(39 downto 32) := key_out_temp(7 downto 0) xor mem_key(39 downto 32);
			key_out_temp(47 downto 40) := key_out_temp(15 downto 8) xor mem_key(47 downto 40);
			key_out_temp(55 downto 48) := key_out_temp(23 downto 16) xor mem_key(55 downto 48);
			key_out_temp(63 downto 56) := key_out_temp(31 downto 24) xor mem_key(63 downto 56);
			
			--troisième colonne
			key_out_temp(71 downto 64) := key_out_temp(39 downto 32) xor mem_key(71 downto 64);
			key_out_temp(79 downto 72) := key_out_temp(47 downto 40) xor mem_key(79 downto 72);
			key_out_temp(87 downto 80) := key_out_temp(55 downto 48) xor mem_key(87 downto 80);
			key_out_temp(95 downto 88) := key_out_temp(63 downto 56) xor mem_key(95 downto 88);
			
			--quatrième colonne
			key_out_temp(103 downto 96) := key_out_temp(71 downto 64) xor mem_key(103 downto 96);
			key_out_temp(111 downto 104) := key_out_temp(79 downto 72) xor mem_key(111 downto 104);
			key_out_temp(119 downto 112) := key_out_temp(87 downto 80) xor mem_key(119 downto 112);
			key_out_temp(127 downto 120) := key_out_temp(95 downto 88) xor mem_key(127 downto 120);
			
			key_out_t <= key_out_temp; --mise à jour de la sortie
			mem_key := key_out_temp; --mise en mémoire du résultat
			key_out_ok_t <= '1';
		
	end case;
end process process2;

	
end archi;