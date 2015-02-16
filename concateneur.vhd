library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
---------------------concateneur-----------------------
-------entrée = 4x32 bits ; sortie = 1x128 bits--------
-------------------------------------------------------


entity concateneur is
port (
	horl : in std_logic; --horloge de cadencement
	clr : in std_logic; --mise à zéro
	
	data_in_4_4 : in COLUMN; --données d'entrée --MSB
	data_in_3_4 : in COLUMN;
	data_in_2_4 : in COLUMN;
	data_in_1_4 : in COLUMN; --LSB
	
	data_in_ok : in std_logic;
	ack_data_in : out std_logic;
	
	data_out : out STATE; --données de sortie
	data_out_ok : out std_logic; --signal de validité des données de sortie
	ack_data_out : in std_logic; --acquittement des données de sortie (vient de l'aval)
	
	etat : out std_logic_vector (1 downto 0) --état de la machine d'état (debug)
);
end concateneur;


architecture archi of concateneur is

signal etat_courant : state_type := inactif;
signal etat_prochain : state_type := actif;

begin

--process combinatoire asynchrone
machine_d_etat : process(etat_prochain, data_in_ok, ack_data_out, clr) is
	
	begin
		
		if (clr = '1') then
			etat_courant <= inactif;
			etat <= "10";
		--actif si données d'entrée valides
		elsif (etat_prochain = actif) and (data_in_ok = '1') then
			etat_courant <= actif;
			etat <= "00";
		--attente sur demande
		elsif (etat_prochain = attente) then
			etat_courant <= attente;
			etat <= "01";
		--inactif si acquittement des données envoyées
		elsif (etat_prochain = inactif) and (ack_data_out = '1') then
			etat_courant <= inactif;
			etat <= "10";
		end if;
		
end process machine_d_etat;

--process synchrone
concatenation : process(horl, clr) is
	
	variable data_out_t : STATE := (others => '0'); --mémoire sortie
	
	begin
	
	if (clr ='1') then
		etat_prochain <= actif;
		data_out <= (others => '0');
		data_out_ok <= '0';
		ack_data_in <= '0';
		
	elsif rising_edge(horl) then
		
		case etat_courant is
			
			--mise à zéro des données de sortie
			when inactif =>
				data_out <= (others => '0');
				data_out_ok <= '0';
				etat_prochain <= actif;
				
			--attente d'acquittement de la part de l'aval
			when attente =>
				ack_data_in <= '0';
				etat_prochain <= inactif;
				
			--concaténation des entrées en un seul mot de sortie
			when actif =>
				
				--en entrée :
				--|15|14|13|12|--|11|10|09|08|--|07|06|05|04|--|03|02|01|00|	
				
				--en sortie :
				--|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00|
				
				data_out_t(127 downto 96) := data_in_4_4;
				data_out_t(95 downto 64) := data_in_3_4;
				data_out_t(63 downto 32) := data_in_2_4;
				data_out_t(31 downto 0) := data_in_1_4;
				
				data_out <= data_out_t;
				ack_data_in <= '1';
				data_out_ok <= '1';
				etat_prochain <= attente;
				
		end case;
		
	end if;
	
end process concatenation;

end archi;