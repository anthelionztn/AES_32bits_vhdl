library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
-----------------------shift_rows----------------------
-------décalage des rangées de 0, 1, 2 ou 3 mots-------
-------------------------------------------------------


entity shift_rows is
port (
	horl : in std_logic; --signal d'horloge
	clr : in std_logic; --mise à zéro
	
	din : in STATE;	--données d'entrée, de sub_bytes
	din_ok : in std_logic; --indicateur de validité de l'entrée
	
	dout : out STATE; --données de sortie, vers mix_columns
	dout_ok : out std_logic; --indicateur de validité de la sortie
	
	ack_din : out std_logic; --vers sub_bytes : entrée prise en compte
	ack_dout : in std_logic; --de mix_columns : sortie prise en compte
	
	etat : out std_logic_vector (1 downto 0) --indicateur de l'état courant (pour debug)
);
end shift_rows;


architecture archi of shift_rows is

signal etat_courant : state_type := inactif;
signal etat_prochain : state_type := actif;

begin

--process combinatoire asynchrone
machine_d_etat : process(etat_prochain, din_ok, ack_dout, clr) is
	
	begin
		
		if (clr = '1') then
			etat_courant <= inactif;
			etat <= "10";
		--actif si données d'entrée valides
		elsif (etat_prochain = actif) and (din_ok = '1') then
			etat_courant <= actif;
			etat <= "00";
		--attente sur demande
		elsif (etat_prochain = attente) then
			etat_courant <= attente;
			etat <= "01";
		--inactif si acquittement des données de sortie
		elsif (etat_prochain = inactif) and (ack_dout = '1') then
			etat_courant <= inactif;
			etat <= "10";
		end if;
		
end process machine_d_etat;

--process synchrone
decalage : process(horl, clr) is
	
	variable dout_t : STATE := (others => '0'); --mémoire de sortie
	
	begin
	
	if (clr = '1') then	
		etat_prochain <= actif;
		dout <= (others => '0');
		dout_ok <= '0';
		ack_din <= '0';
		
	elsif rising_edge(horl) then
	
		case etat_courant is
			
			--attente de données valables en entrée
			--mise à zéro de la sortie
			when inactif =>
				dout_ok <= '0';
				dout <= (others => '0');
				etat_prochain <= actif;
			
			--attendre la prise en compte du résultats de la part de l'unité suivante
			--mise à zéro de l'acquittement
			when attente =>
				ack_din <= '0';
				etat_prochain <= inactif;
			
			--décaler les rangées puis envoyer le résultats sur dout
			--et indiquer que les données sont bonnes avec dout_ok
			when actif =>
				
				--en entrée :		en sortie :
				--|00|04|08|12|		|00|04|08|12|
				--|01|05|09|13|		|05|09|13|01|
				--|02|06|10|14|		|10|14|02|06|
				--|03|07|11|15|		|15|03|07|11|
				
				--rangée 0
				--|00|04|08|12| => |00|04|08|12|
				dout_t(7 downto 0) := din(7 downto 0);
				dout_t(39 downto 32) := din(39 downto 32);
				dout_t(71 downto 64) := din(71 downto 64);
				dout_t(103 downto 96) := din(103 downto 96);
				
				--rangée 1
				--|01|05|09|13| => |05|09|13|01|
				dout_t(15 downto 8) := din(47 downto 40);
				dout_t(47 downto 40) := din(79 downto 72);
				dout_t(79 downto 72) := din(111 downto 104);
				dout_t(111 downto 104) := din(15 downto 8);
				
				--rangée 2
				--|02|06|10|14| => |10|14|02|06|
				dout_t(23 downto 16) := din(87 downto 80);
				dout_t(55 downto 48) := din(119 downto 112);
				dout_t(87 downto 80) := din(23 downto 16);
				dout_t(119 downto 112) := din(55 downto 48);
				
				--rangée 3
				--|03|07|11|15| => |15|03|07|11|
				dout_t(31 downto 24) := din(127 downto 120);
				dout_t(63 downto 56) := din(31 downto 24);
				dout_t(95 downto 88) := din(63 downto 56);
				dout_t(127 downto 120) := din(95 downto 88);
				
				--envoi des données
				dout <= dout_t;
				dout_ok <= '1';
				ack_din <= '1';
				etat_prochain <= attente;
				
		end case;
		
	end if;
	
end process decalage;

end archi;