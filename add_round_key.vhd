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

signal etat_courant : state_type := inactif;
signal etat_prochain : state_type := actif;

begin

--process combinatoire asynchrone
machine_d_etat : process(etat_prochain, data_in_ok, key_in_ok, ack_data_out, clr) is
	
	begin
		
		if (clr = '1') then
			etat_courant <= inactif;
			etat <= "10";
		--actif si données d'entrée et clé valides en même temps
		elsif (etat_prochain = actif) and (data_in_ok = '1') and (key_in_ok = '1') then
			etat_courant <= actif;
			etat <= "00";
		--attente si demande d'attente
		elsif (etat_prochain = attente) then
			etat_courant <= attente;
			etat <= "01";
		--inactif si prise en compte de la données de sortie
		elsif (etat_prochain = inactif) and (ack_data_out = '1') then
			etat_courant <= inactif;
			etat <= "10";
		end if;
		
end process machine_d_etat;

--process synchrone
addition : process(horl, clr) is
	
	variable D_out_t : STATE := (others => '0');
	
	begin
	
	if (clr ='1') then
		etat_prochain <= actif;
		data_out <= (others => '0');
		data_out_ok <= '0';
		ack_key_in <= '0';
		ack_data_in <= '0';
		
	elsif rising_edge(horl) then
		
		case etat_courant is
		
			--attente de données valables en entrée
			when inactif =>
				data_out_ok <= '0';
				data_out <= (others => '0');
				etat_prochain <= actif;
			
			--attendre la prise en compte du résultats de la part de l'unité suivante
			when attente =>
				ack_data_in <= '0';
				ack_key_in <= '0';
				etat_prochain <= inactif;
			
			--xor des données d'entrées et de la clé
			when actif =>
			
				D_out_t := add_mat_fonc(data_in, key_in); --appel de la fonction d'addition de matrices
			
				data_out <= D_out_t;
				data_out_ok <= '1';
				ack_data_in <= '1';
				ack_key_in <= '1';
				etat_prochain <= attente;
			
		end case;
		
	end if;
	
end process addition;
	
end archi;