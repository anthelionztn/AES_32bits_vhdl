library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
----------------------multiplexeur---------------------
--redirection de l'entrée A ou B suivant le sélecteur--
-------------------------------------------------------


entity multiplexeur is
port (
	horl : in std_logic; --horloge de cadencement
	clr : in std_logic; --mise à zéro
	
	sel : in std_logic_vector(3 downto 0); --sélecteur, provient de compte_tours
	
	data_in_A : in STATE; --entrée des données, d'un concateneur
	data_in_ok_A : in std_logic; --validité des données de la première entrée
	
	data_in_B : in STATE; --entrée des données, de mix_columns
	data_in_ok_B : in std_logic; --validité des données de la deuxième entrée
	
	data_out : out STATE; --sortie des données, vers add_round_key
	data_out_ok : out std_logic; --validité des données de sortie
	
	ack_data_in_A : out std_logic; --acquittement des données de la première entrée
	ack_data_in_B : out std_logic; --acquittement des données de la deuxième entrée
	
	ack_data_out : in std_logic; --acquittement des données de sortie
	
	etat : out std_logic_vector (1 downto 0) --indicateur de l'état de la machine d'état (pour debug)
);
end multiplexeur;

architecture archi of multiplexeur is

signal etat_courant : state_type := inactif;
signal etat_prochain : state_type := actif;
signal sel_t : integer range 0 to 11 := 0; --sélecteur d'entrée

begin

sel_t <= to_integer(unsigned(sel));

--process combinatoire asynchrone
machine_d_etat : process(etat_prochain, data_in_ok_A, data_in_ok_B, ack_data_out, clr) is
	
	begin
		
		if (clr = '1') then
			etat_courant <= inactif;
			etat <= "10";
		--actif si signal de validation de données d'entrée
		elsif (etat_prochain = actif) then
			if data_in_ok_A = '1' then
				etat_courant <= actif;
				etat <= "00";
			elsif data_in_ok_B = '1' then
				etat_courant <= actif;
				etat <= "11";
			end if;
		--attente si demande d'attente
		elsif (etat_prochain = attente) then 
			etat_courant <= attente;
			etat <= "01";
		--inactivité si signal d'acquittement des données de sortie
		elsif (etat_prochain = inactif) and (ack_data_out = '1') then
			etat_courant <= inactif;
			etat <= "10";
		end if;
		
end process machine_d_etat;

--process synchrone
mux : process(horl, clr)
	
	begin
		
		if (clr = '1') then
			etat_prochain <= actif;
			data_out <= (others => '0');
			data_out_ok <= '0';
			ack_data_in_A <= '0';
			ack_data_in_B <= '0';
			--sel_t <= 0;
	
		elsif rising_edge(horl) then
		
		case etat_courant is
		
			--attente de données valables en entrée
			--mise à zéro de la sortie
			when inactif =>
				data_out_ok <= '0';
				data_out <= (others => '0');
				etat_prochain <= actif;
				
			--attendre la prise en compte du résultats de la part de l'unité suivante
			--mise à zéro des acquittements
			when attente =>
				ack_data_in_A <= '0';
				ack_data_in_B <= '0';
				etat_prochain <= inactif;
			
			--recopie de l'entrée A ou B selon la valeur du sélecteur
			when actif =>
			
				if (sel_t = 0) then --données provenant d'un concateneur au premier tour
				
					data_out <= data_in_A; --recopie de l'entrée A
					ack_data_in_A <= '1';

				else --données provenant de mix_columns

					data_out <= data_in_B; --recopie de l'entrée B
					ack_data_in_B <= '1';
					
				end if;
				
				data_out_ok <= '1'; --validation des données en sortie
				etat_prochain <= attente;
			
		end case;
	
	end if;
	
end process mux;

end archi;