library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
---------------------demultiplexeur--------------------
-----redirection de l'entrée vers la sortie A ou B-----
-------------------------------------------------------


entity demultiplexeur is
port (
	horl : in std_logic; --horloge de cadencement
	clr : in std_logic; --mise à zéro
	
	sel : in std_logic_vector(3 downto 0); --sélecteur, connecté à compte_tours
	
	data_in : in STATE; --données d'entrée, de add_round_key
	data_in_ok : in std_logic; --validité des données d'entrée
	
	data_out_A : out STATE; --première sortie de données, vers sub_bytes
	data_out_ok_A : out std_logic; --validité des données de la première sortie
	
	data_out_B : out STATE; --deuxième sortie de données, vers deconcateneur
	data_out_ok_B : out std_logic; --validité des données de la deuxième sortie
	
	ack_data_in : out std_logic; --acquittement des données d'entrée, va vers l'amont
	
	ack_data_out_A : in std_logic; --acquittement des données de la première sortie, vient de sub_bytes
	ack_data_out_B : in std_logic; --acquittement des données de la deuxième sortie, vient du deconcateneur
	
	etat : out std_logic_vector (1 downto 0) --état de la machine d'état (debug)
);
end demultiplexeur;

architecture archi of demultiplexeur is

signal etat_courant : state_type := inactif;
signal etat_prochain : state_type := actif;
signal sel_t : integer range 0 to 11 := 0; --sélecteur de redirection de l'entrée

begin

sel_t <= to_integer(unsigned(sel));

--process combinatoire asynchrone
machine_d_etat : process(etat_prochain, data_in_ok, ack_data_out_A, ack_data_out_B, clr) is
	
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
		--inactif si acquittement de l'unité en aval
		elsif (etat_prochain = inactif) and
				((ack_data_out_A = '1') or (ack_data_out_B = '1')) then
			etat_courant <= inactif;
			etat <= "10";
		end if;
		
end process machine_d_etat;

--process synchrone
demux : process(horl, clr)

	begin
	
	if (clr = '1') then
	
		etat_prochain <= actif;
		data_out_A <= (others => '0');
		data_out_B <= (others => '0');
		data_out_ok_A <= '0';
		data_out_ok_B <= '0';
		ack_data_in <= '0';
		--sel_t <= 0;
	
	elsif rising_edge(horl) then
		
		case etat_courant is
		
			--attente de données valables en entrée
			--mise à zéro des sorties
			when inactif =>
				data_out_ok_A <= '0';
				data_out_A <= (others => '0');
				data_out_ok_B <= '0';
				data_out_B <= (others => '0');
				etat_prochain <= actif;
			
			--attendre la prise en compte du résultats de la part de l'unité suivante
			--mise à zéro de l'acquittement
			when attente =>
				ack_data_in <= '0';
				etat_prochain <= inactif;
			
			--redirection de l'entrée vers le deconcateneur ou sub_bytes
			when actif =>
				
				--redirection de l'entrée vers la sortie lors du dernier tour
				if (sel_t = 11) then --vers le deconcateneur
				
					data_out_A <= data_in;
					data_out_ok_A <= '1';			
				
				--sinon redirection vers sub_bytes
				else --vers sub_bytes

					data_out_B <= data_in;
					data_out_ok_B <= '1';
					
				end if;
				
				ack_data_in <= '1';
				etat_prochain <= attente;
				
		end case;
	
	end if;
	
end process demux;

end archi;