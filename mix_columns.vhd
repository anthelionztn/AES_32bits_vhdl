library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
-----------------------mix_columns---------------------
--multiplication des données d'entrée par une matrice--
-------------------------------------------------------


entity mix_columns is
port (
	horl : in std_logic; --signal d'horloge
	clr : in std_logic; --mise à zéro
	
	round_in : in std_logic_vector(3 downto 0); --entrée du numéro de tour
	
	data_in : in STATE; --données d'entrée, de shift_rows
	data_in_ok : in std_logic; --indicateur de validité de l'entrée
	
	data_out : out STATE; --données de sortie, vers multiplexeur
	data_out_ok : out std_logic; --indicateur de validité de la sortie
	
	ack_data_in : out std_logic; --vers l'amont : entrée prise en compte
	ack_data_out : in std_logic; --de l'aval : sortie prise en compte
	
	etat : out std_logic_vector (1 downto 0) --indicateur de l'état courant (pour debug)
);
end mix_columns;

architecture archi of mix_columns is

signal etat_courant : state_type := inactif;
signal etat_prochain : state_type := actif;
signal round_in_t : integer range 0 to 11 := 0; --numéro du tour courant

begin

round_in_t <= to_integer(unsigned(round_in));

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
		--inactif si acquittement des données de sortie
		elsif (etat_prochain = inactif) and (ack_data_out = '1') then
			etat_courant <= inactif;
			etat <= "10";
		end if;
		
end process machine_d_etat;

--process synchrone
multiplication : process(horl, clr) is
	
	variable D_out_t : STATE := (others => '0'); --mémoire de sortie
	
	begin
	
	if (clr = '1') then
		etat_prochain <= actif;
		data_out <= (others => '0');
		data_out_ok <= '0';
		ack_data_in <= '0';
		--round_in_t <= 0;
		
	elsif rising_edge(horl) then
	
		case etat_courant is
			
			--attente de données valables en entrée
			--mise à zéro des sorties
			when inactif =>
				data_out_ok <= '0';
				data_out <= (others => '0');
				etat_prochain <= actif;
			
			--attendre la prise en compte du résultats de la part de l'unité suivante
			--mise à zéro de l'acquittement d'entrée
			when attente =>
				ack_data_in <= '0';
				etat_prochain <= inactif;
			
			--multiplier les données d'entrée par
			--|02|03|01|01|
			--|01|02|03|01|
			--|01|01|02|03|
			--|03|01|01|02|
			
			when actif =>
				
				--recopie de l'entrée pendant le tour 10
				--opération non réalisée pendant le dernier tour
				if (round_in_t = 10) then
					
					data_out <= data_in;
					data_out_ok <= '1';
					ack_data_in <= '1';
					etat_prochain <= attente;
						
				else
			
					--colonne 0
					D_out_t(7 downto 0) := mult_2_fonc(elt_fonc(data_in, 0))
										xor mult_3_fonc(elt_fonc(data_in, 1)) 
										xor elt_fonc(data_in, 2) 
										xor elt_fonc(data_in, 3);
					D_out_t(15 downto 8) := elt_fonc(data_in, 0)
										xor mult_2_fonc(elt_fonc(data_in, 1))
										xor mult_3_fonc(elt_fonc(data_in, 2)) 
										xor elt_fonc(data_in, 3);
					D_out_t(23 downto 16) := elt_fonc(data_in, 0)
										xor elt_fonc(data_in, 1) 
										xor mult_2_fonc(elt_fonc(data_in, 2))
										xor mult_3_fonc(elt_fonc(data_in, 3));
					D_out_t(31 downto 24) := mult_3_fonc(elt_fonc(data_in, 0))
										xor elt_fonc(data_in, 1) 
										xor elt_fonc(data_in, 2) 
										xor mult_2_fonc(elt_fonc(data_in, 3));
					
					--colonne 1
					D_out_t(39 downto 32) := mult_2_fonc(elt_fonc(data_in, 4))
										xor mult_3_fonc(elt_fonc(data_in, 5))
										xor elt_fonc(data_in, 6) 
										xor elt_fonc(data_in, 7);
					D_out_t(47 downto 40) := elt_fonc(data_in, 4)
										xor mult_2_fonc(elt_fonc(data_in, 5))
										xor mult_3_fonc(elt_fonc(data_in, 6)) 
										xor elt_fonc(data_in, 7);
					D_out_t(55 downto 48) := elt_fonc(data_in, 4)
										xor elt_fonc(data_in, 5) 
										xor mult_2_fonc(elt_fonc(data_in, 6))
										xor mult_3_fonc(elt_fonc(data_in, 7));
					D_out_t(63 downto 56) := mult_3_fonc(elt_fonc(data_in, 4)) 
										xor elt_fonc(data_in, 5) 
										xor elt_fonc(data_in, 6) 
										xor mult_2_fonc(elt_fonc(data_in, 7));
					
					--colonne 2
					D_out_t(71 downto 64) := mult_2_fonc(elt_fonc(data_in, 8))
										xor mult_3_fonc(elt_fonc(data_in, 9)) 
										xor elt_fonc(data_in, 10) 
										xor elt_fonc(data_in, 11);
					D_out_t(79 downto 72) := elt_fonc(data_in, 8)
										xor mult_2_fonc(elt_fonc(data_in, 9))
										xor mult_3_fonc(elt_fonc(data_in, 10))  
										xor elt_fonc(data_in, 11);
					D_out_t(87 downto 80) := elt_fonc(data_in, 8)
										xor elt_fonc(data_in, 9) 
										xor mult_2_fonc(elt_fonc(data_in, 10))
										xor mult_3_fonc(elt_fonc(data_in, 11));
					D_out_t(95 downto 88) := mult_3_fonc(elt_fonc(data_in, 8)) 
										xor elt_fonc(data_in, 9) 
										xor elt_fonc(data_in, 10) 
										xor mult_2_fonc(elt_fonc(data_in, 11));
					
					--colonne 3
					D_out_t(103 downto 96) :=mult_2_fonc(elt_fonc(data_in, 12))
										xor mult_3_fonc(elt_fonc(data_in, 13))  
										xor elt_fonc(data_in, 14) 
										xor elt_fonc(data_in, 15);
					D_out_t(111 downto 104) := elt_fonc(data_in, 12)
										xor mult_2_fonc(elt_fonc(data_in, 13))
										xor mult_3_fonc(elt_fonc(data_in, 14)) 
										xor elt_fonc(data_in, 15);
					D_out_t(119 downto 112) := elt_fonc(data_in, 12)
										xor elt_fonc(data_in, 13) 
										xor mult_2_fonc(elt_fonc(data_in, 14)) 
										xor mult_3_fonc(elt_fonc(data_in, 15));
					D_out_t(127 downto 120) := mult_3_fonc(elt_fonc(data_in, 12)) 
										xor elt_fonc(data_in, 13) 
										xor elt_fonc(data_in, 14) 
										xor mult_2_fonc(elt_fonc(data_in, 15));
					
					data_out <= D_out_t; --envoi des données
					data_out_ok <= '1';
					ack_data_in <= '1';
					etat_prochain <= attente;
				
				end if;
				
		end case;
		
	end if;
		
end process multiplication;

end archi;