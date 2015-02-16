library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
--------------------deconcateneur----------------------
-------entrée = 1x128 bits ; sortie = 4x32 bits--------
-------------------------------------------------------


entity deconcateneur is
port (
	horl : in std_logic; --horloge de cadencement
	clr : in std_logic; --mise à zéro
	
	data_in : in STATE; --entrée des données
	data_in_ok : in std_logic; --signal de validité des données d'entrée
	ack_data_in : out std_logic; --acquittement envoyé à l'amont
	
	data_out_4_4 : out COLUMN; --sortie des données --MSB
	data_out_3_4 : out COLUMN;
	data_out_2_4 : out COLUMN;
	data_out_1_4 : out COLUMN; --LSB
	
	data_out_ok : out std_logic;
	ack_data_out : in std_logic;
	
	etat : out std_logic_vector (1 downto 0) --état de la machine d'état (debug)
);
end deconcateneur;

architecture archi of deconcateneur is

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
		--inactif sur demande
		elsif (etat_prochain = inactif) and (ack_data_out = '1') then
			etat_courant <= inactif;
			etat <= "10";
		end if;
		
end process machine_d_etat;

--process synchrone
deconcatenation : process(horl, clr) is
	
	variable data_out_t : STATE := (others => '0'); --mémoire de sortie
	
	begin
	
	if (clr = '1') then
		etat_prochain <= actif;
		data_out_4_4 <= (others => '0');
		data_out_3_4 <= (others => '0');
		data_out_2_4 <= (others => '0');
		data_out_1_4 <= (others => '0');
		data_out_ok <= '0';
		ack_data_in <= '0';
	
	elsif rising_edge(horl) then
		
		case etat_courant is
			
			--ràz du compteur et mise à zéro de la sortie
			when inactif =>
				
				data_out_4_4 <= (others => '0');
				data_out_3_4 <= (others => '0');
				data_out_2_4 <= (others => '0');
				data_out_1_4 <= (others => '0');
				data_out_ok <= '0';
				etat_prochain <= actif;
				
			--état d'attente jamais appelé, boucle infinie si entrée dans cet état
			when attente =>
				
				ack_data_in <= '0';
				etat_prochain <= inactif;
			
			--séparation du mot d'entrée en 4 parties
			when actif =>
				
				--en entrée :
				--|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00|
				
				--en sortie :
				--|15|14|13|12|--|11|10|09|08|--|07|06|05|04|--|03|02|01|00|	
				
				data_out_4_4 <= data_in(127 downto 96);
				data_out_3_4 <= data_in(95 downto 64);
				data_out_2_4 <= data_in(63 downto 32);
				data_out_1_4 <= data_in(31 downto 0);
				
				data_out_ok <= '1';
				ack_data_in <= '1';
				etat_prochain <= attente;
				
		end case;
	
	end if;
	
end process deconcatenation;

end archi;