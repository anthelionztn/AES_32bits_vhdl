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
		--inactif sur acquittement des données de sortie
		elsif (etat_prochain = inactif) and (ack_data_out = '1') then
			etat_courant <= inactif;
			etat <= "10";
		end if;
		
end process machine_d_etat;

--process synchrone
substitute : process(horl, clr) is

	variable v_out_t : STATE := (others => '0'); --mémoire de sortie
	variable compteur : integer range 0 to 15 := 0; --compteur interne

	begin
	
	if (clr ='1') then
		etat_prochain <= actif;
		data_out <= (others => '0');
		data_out_ok <= '0';
		ack_data_in <= '0';
		
	elsif rising_edge(horl) then
		
		case etat_courant is
			
			--mise à zéro de la sortie et attente de données valides en entrée
			when inactif =>
				data_out_ok <= '0';
				data_out <= (others => '0');
				etat_prochain <= actif;
			
			--mise à zéro du signal d'acquittement
			when attente =>
				ack_data_in <= '0';
				etat_prochain <= inactif;
			
			--remplace chaque élément de l'état par son
			--équivalent de la table de substitution
			when actif =>
				
				boucle : for compteur in 0 to 15 loop
					
					v_out_t (compteur*8+7 downto compteur*8) := s_box_fonc(data_in (compteur*8+7 downto compteur*8));
					
				end loop boucle;
				
				--envoi des données
				data_out <= v_out_t;
				data_out_ok <= '1';
				ack_data_in <= '1';
				etat_prochain <= attente;
				
		end case;			
		
	end if;
	
end process substitute;
	
end archi;