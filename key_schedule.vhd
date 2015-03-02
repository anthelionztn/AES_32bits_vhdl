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

signal etat_courant : state_type := inactif;
signal etat_prochain : state_type := actif;
signal round_in_t : integer range 0 to 12 := 0; --numéro du tours courant
signal key_in_ok_t : std_logic := '0';

begin

	round_in_t <= to_integer(unsigned(round_in));

	
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
	
--process combinatoire asynchrone
machine_d_etat : process(etat_prochain, key_in_ok_t, ack_key_out, clr) is
	
	begin
		
		if (clr = '1') then
			etat_courant <= inactif;
			etat <= "10";
		--actif si validité de la clé en entrée ou si le tour courant n'est pas le premier
		--permet de ne pas avoir besoin de clé valide tout le temps de l'opération, seulement au début
		--elsif (etat_prochain = actif) and ((key_in_ok = '1') or (round_in_t /= 0)) then
		elsif (etat_prochain = actif) and (key_in_ok_t = '1') then
			etat_courant <= actif;
			etat <= "00";
		--attente sur demande
		elsif (etat_prochain = attente) then
			etat_courant <= attente;
			etat <= "01";
		--inactif sur acquittement des données de sortie
		elsif (etat_prochain = inactif) and (ack_key_out = '1') then
			etat_courant <= inactif;
			etat <= "10";
		end if;
		
end process machine_d_etat;

--process synchrone
key_expansion : process(horl, clr) is
	
	variable Key_out_t : STATE := (others => '0'); --mémoire de sortie
	variable Key_in_t : STATE := (others => '0'); --mémoire de clé
	variable column_t : COLUMN := (others => '0'); --dernière colonne de la clé
	variable rcon_vect : COLUMN := (others => '0'); --Rcon, utilisé pour créer la première colonne de la prochaine clé
	variable compteur : integer range 0 to 15 := 0; --compteur interne
	
	begin
	
	if (clr ='1') then
		etat_prochain <= actif;
		key_out <= (others => '0');
		key_out_ok <= '0';
		ack_key_in <= '0';
		
	elsif rising_edge(horl) then
		
		case etat_courant is
			
			--attente de données valables en entrée
			--mise à zéro des sorties
			when inactif =>
				key_out_ok <= '0';
				key_out <= (others => '0');
				etat_prochain <= actif;
			
			--attendre la prise en compte du résultats de la part de l'unité suivante
			--mise à zéro du signal d'acquittement
			when attente =>
				ack_key_in <= '0';
				etat_prochain <= inactif;
			
			--étape d'expansion de clé
			when actif =>
			
			--première clé = clé en entrée
			if (round_in_t = 0) then
				Key_in_t := key_in;
				key_out <= Key_in_t;
				key_out_ok <= '1';
				ack_key_in <= '1';
				etat_prochain <= attente;
			
			--création de la clé i+1 à partir de la clé i
			--puis mise en mémoire de la clé i+1 pour l'étape suivante
			else
			
				--rot_word sur la dernière colonne de l'état
				column_t := Key_in_t(127 downto 96);
				column_t := rot_word_fonc(column_t);
				
				--ack_key_in <= '1'; --acquittement
				
				--sub_bytes sur la dernière colonne de l'état
				substitute : for compteur in 0 to 3 loop
					
					column_t(compteur*8+7 downto compteur*8) := 
						s_box_fonc(column_t(compteur*8+7 downto compteur*8));
					
				end loop substitute;
				
				--vecteur Rcon(numéro de tour)
				rcon_vect := rcon_vect_fonc(round_in_t);
				
				--addition des colonnes
				--première colonne de l'état suivant
				colonne_0 : for compteur in 0 to 3 loop
				
					Key_out_t(compteur*8+7 downto compteur*8) :=
							Key_in_t(compteur*8+7 downto compteur*8)
						xor column_t(compteur*8+7 downto compteur*8)
						xor rcon_vect(compteur*8+7 downto compteur*8);
					
				end loop colonne_0;
				
				--deuxième colonne
				colonne_1 : for compteur in 0 to 3 loop
				
					Key_out_t(compteur*8+7+32 downto compteur*8+32) :=
							Key_out_t(compteur*8+7 downto compteur*8)
						xor Key_in_t(compteur*8+7+32 downto compteur*8+32);
					
				end loop colonne_1;
				
				--troisième colonne
				colonne_2 : for compteur in 0 to 3 loop
				
					Key_out_t(compteur*8+7+64 downto compteur*8+64) :=
							Key_out_t(compteur*8+7+32 downto compteur*8+32)
						xor Key_in_t(compteur*8+7+64 downto compteur*8+64);
					
				end loop colonne_2;
				
				--quatrième colonne
				colonne_3 : for compteur in 0 to 3 loop
				
					Key_out_t(compteur*8+7+96 downto compteur*8+96) :=
							Key_out_t(compteur*8+7+64 downto compteur*8+64)
						xor Key_in_t(compteur*8+7+96 downto compteur*8+96);
					
				end loop colonne_3;
				
				key_out <= Key_out_t; --mise à jour de la sortie
				Key_in_t := Key_out_t; --mise en mémoire du résultat
				key_out_ok <= '1';
				etat_prochain <= attente;
			
			end if;
			
		end case;
		
	end if;	
	
end process key_expansion;

end archi;