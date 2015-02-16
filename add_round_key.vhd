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
	
	Key_in : in STATE; --clé en entrée, de key_schedule
	Key_in_ok  : in std_logic; --indicateur de validité de la clé
	
	D_in : in STATE; --données d'entrée, de multiplexeur
	D_in_ok : in std_logic; --indicateur de validité de l'entrée
	
	D_out : out STATE; --données de sortie, vers demultiplexeur
	D_out_ok : out std_logic; --indicateur de validité de la sortie
	
	ack_D_in : out std_logic; --vers multiplexeur : entrée prise en compte
	ack_Key_in : out std_logic; --vers key_schedule : clé prise en compte
	ack_D_out : in std_logic; --de demultiplexeur : sortie prise en compte
	
	etat : out std_logic_vector (1 downto 0) --indicateur de l'état courant (pour debug)
);
end add_round_key;


architecture archi of add_round_key is

signal etat_courant : state_type := inactif;
signal etat_prochain : state_type := actif;

begin

--process combinatoire asynchrone
machine_d_etat : process(etat_prochain, D_in_ok, Key_in_ok, ack_D_out, clr) is
	
	begin
		
		if (clr = '1') then
			etat_courant <= inactif;
			etat <= "10";
		--actif si données d'entrée et clé valides en même temps
		elsif (etat_prochain = actif) and (D_in_ok = '1') and (Key_in_ok = '1') then
			etat_courant <= actif;
			etat <= "00";
		--attente si demande d'attente
		elsif (etat_prochain = attente) then
			etat_courant <= attente;
			etat <= "01";
		--inactif si prise en compte de la données de sortie
		elsif (etat_prochain = inactif) and (ack_D_out = '1') then
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
		D_out <= (others => '0');
		D_out_ok <= '0';
		ack_Key_in <= '0';
		ack_D_in <= '0';
		
	elsif rising_edge(horl) then
		
		case etat_courant is
		
			--attente de données valables en entrée
			when inactif =>
				D_out_ok <= '0';
				D_out <= (others => '0');
				etat_prochain <= actif;
			
			--attendre la prise en compte du résultats de la part de l'unité suivante
			when attente =>
				ack_D_in <= '0';
				ack_Key_in <= '0';
				etat_prochain <= inactif;
			
			--xor des données d'entrées et de la clé
			when actif =>
			
				D_out_t := add_mat_fonc(D_in, Key_in); --appel de la fonction d'addition de matrices
			
				D_out <= D_out_t;
				D_out_ok <= '1';
				ack_D_in <= '1';
				ack_Key_in <= '1';
				etat_prochain <= attente;
			
		end case;
		
	end if;
	
end process addition;
	
end archi;