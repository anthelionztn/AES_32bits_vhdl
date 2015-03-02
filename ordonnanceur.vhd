library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
--------------------ordonnanceur-----------------------
--interface l'extérieur (CPU) avec l'intérieur (algo)--
-------------------------------------------------------
--interface avec l'extérieur : _a--------------------
--interface avec l'intérieur : _b--------------------
-------------------------------------------------------
--machine_d_etat_a : fsm pour l'envoi des données et--
-----clé d'entrée vers le multiplexeur et key_schedule-
--machine_d_etat_b : fsm pour l'envoi des données du-
------------------------démultiplexeur vers la sortie--
-------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------
-- rajouter un 4 ports de 32 bits appelé Initialization Vector, il prend sa valeur de l'interface AXI (prendre 4 ports en plus)
-- ajouter un signal IV_t qui est la copie de l'entrée IV
-- (copie active si key_in_ok_a_t = '1' <=> si on rentre une nouvelle clé <=> on commence un nouveau cycle de chiffrement)
-- iv_t prend la valeur de la sortie data_in_b.
-- à chaque entrée de données d'entrée, réaliser un xor des données d'entrée avec iv_t avant de l'envoyer vers le multiplexeur
---------------------------------------------------------------------------------------------------------------------------------


entity ordonnanceur is
port (
	
	------------------------------------------------------------------------------
	--de l'extérieur
	horl : in std_logic;
	clr : in std_logic; --signal de mise à zéro
	
	key_in_4_4_a : in COLUMN; --données d'entrée --MSB
	key_in_3_4_a : in COLUMN;
	key_in_2_4_a : in COLUMN;
	key_in_1_4_a : in COLUMN; --LSB
	key_in_ok_a : in std_logic;
	
	data_in_4_4_a : in COLUMN; --données d'entrée --MSB
	data_in_3_4_a : in COLUMN;
	data_in_2_4_a : in COLUMN;
	data_in_1_4_a : in COLUMN; --LSB	
	data_in_ok_a : in std_logic;
	
	ack_data_out_a : in std_logic;
	------------------------------------------------------------------------------
	
	------------------------------------------------------------------------------
	--vers l'extérieur
	ack_key_in_a : out std_logic;
	ack_data_in_a : out std_logic;
	
	data_out_4_4_a : out COLUMN; --sortie des données --MSB
	data_out_3_4_a : out COLUMN;
	data_out_2_4_a : out COLUMN;
	data_out_1_4_a : out COLUMN; --LSB
	data_out_ok_a : out std_logic;
	------------------------------------------------------------------------------
	
	------------------------------------------------------------------------------
	--de l'intérieur
	ack_data_out_b : in std_logic; --acquittement des données de sortie, du mux
	
	ack_key_out_b : in std_logic; --acquittement de la clé de sortie, de key_schedule
	
	data_in_b : in STATE; --entrée des données, du demux
	data_in_ok_b : in std_logic; --signal de validité des données d'entrée, du demux
	------------------------------------------------------------------------------
	
	------------------------------------------------------------------------------
	--vers l'intérieur
	key_out_b : out STATE; --clé de sortie, vers key_schedule
	key_out_ok_b : out std_logic; --signal de validité de la clé de sortie, vers key_schedule
	
	data_out_b : out STATE; --données de sortie, vers le mux
	data_out_ok_b : out std_logic; --signal de validité des données de sortie, vers le mux
	
	ack_data_in_b : out std_logic; --acquittement envoyé au demux
	------------------------------------------------------------------------------
	
	etat_in : out std_logic_vector (1 downto 0); --état de la machine d'état (debug)
	etat_out : out std_logic_vector (1 downto 0) --état de la machine d'état (debug)
	
);
end ordonnanceur;


architecture archi of ordonnanceur is

--mémoires des entrées : 
--permet de considérer signaux ok uniquement sur front montant
--(besoin de remettre à zéro les signaux d'abord)
signal data_in_ok_a_t : std_logic := '0';
signal key_in_ok_a_t : std_logic := '0';
signal ack_data_out_a_t : std_logic := '0';

--état des machines d'états
signal etat_courant_a : state_type := inactif;
signal etat_prochain_a : state_type := actif;
signal etat_courant_b : state_type := inactif;
signal etat_prochain_b : state_type := actif;

--code de l'opération à effectuer : 
-- 0 : rien à faire
-- 1 : prise en compte des données d'entrée, la clé utilisée provient de la mémoire
-- 2 : prise en compte des données d'entrée et de la clé d'entrée
signal operation : integer range 0 to 2 := 0; -- 1 : data_in ; 2 : data_in + key_in
signal operation_data : integer range 0 to 1 := 0; 
signal operation_key : integer range 0 to 1 := 0;

signal mem_key : STATE := (others => '0'); --mémoire sortie vers key_schedule


begin

	--màj code opération
	operation <= operation_data + operation_key;
	
	
--màj code opération avec data_in_ok
process (data_in_ok_a, clr, etat_courant_a) is
	
	begin
		if (clr = '1') then --ràz asynchrone
			operation_data <= 0;
		elsif (etat_courant_a = attente) then --ràz dans l'état d'attente
			operation_data <= 0;
		elsif rising_edge(data_in_ok_a) then --prise en compte sur front montant
			if (operation_data /= 1) then
				operation_data <= operation_data + 1;
			end if;
		end if;
		
end process;

--màj code opération avec key_ok
process (key_in_ok_a, clr, etat_courant_a) is
	
	begin
		if (clr = '1') then --ràz asynchrone
			operation_key <= 0;
		elsif (etat_courant_a = attente) then --ràz dans l'état d'attente
			operation_key <= 0;
		elsif rising_edge(key_in_ok_a) then --prise en compte sur front montant
			if (operation_key /= 1) then
				operation_key <= operation_key + 1;
			end if;	
		end if;
		
end process;


--màj de data_in_ok
process(data_in_ok_a, clr, etat_courant_a) is

	begin
		
		if(clr = '1') then --ràz asynchrone
			data_in_ok_a_t <= '0';
		elsif (etat_courant_a = attente) then --ràz dans l'état d'attente
			data_in_ok_a_t <= '0';
		elsif rising_edge(data_in_ok_a) then --prise en compte sur front montant
			data_in_ok_a_t <= '1';
		end if;
		
end process;

--màj de key_in_ok
process(key_in_ok_a, clr, etat_courant_a) is

	begin
		
		if(clr = '1') then --ràz asynchrone
			key_in_ok_a_t <= '0';			
		elsif (etat_courant_a = attente) then --ràz dans l'état d'attente
			key_in_ok_a_t <= '0';
		elsif rising_edge(key_in_ok_a) then --prise en compte sur front montant
			key_in_ok_a_t <= '1';
		end if;
		
end process;


--màj de ack_data_out
process(ack_data_out_a, clr, etat_courant_b) is

	begin
		
		if(clr = '1') then --ràz asynchrone
			ack_data_out_a_t <= '0';			
		elsif (etat_courant_b = inactif) then --ràz dans l'état d'attente
			ack_data_out_a_t <= '0';
		elsif rising_edge(ack_data_out_a) then --prise en compte sur front montant
			ack_data_out_a_t <= '1';
		end if;
		
end process;


process(operation, etat_courant_a, etat_courant_b, clr) is

	begin
		
		if(clr = '1') then --ràz asynchrone
			mem_key <= (others => '0');
		elsif (operation = 2) and (etat_courant_a = actif) then --si clé valide en entrée, mise en mémoire
			mem_key <= key_in_4_4_a & key_in_3_4_a & key_in_2_4_a & key_in_1_4_a;		
		elsif (etat_courant_b = actif) then
			mem_key <= data_in_b;
		end if;

end process;

------------------------------------------------------------------------
--sorties vers l'intérieur : multiplexeur et key_schedule
--concaténation des entrées extérieures
------------------------------------------------------------------------

--process combinatoire asynchrone
--machine_d_etat_a : process(etat_prochain_a, operation, data_in_ok_a_t, key_in_ok_a_t, ack_data_out_b, ack_key_out_b, clr) is
machine_d_etat_a : process(etat_prochain_a, data_in_ok_a_t, ack_data_out_b, ack_key_out_b, clr) is
	
	begin
		
		if (clr = '1') then
			etat_courant_a <= inactif;
			etat_in <= "10";
		--actif si données d'entrée valides
		--pour prendre en compte la clé d'entrée, positionner key_in_ok_a à '1' avant de positionner data_in_ok_a à '1'
		elsif (etat_prochain_a = actif) then
			--if ((operation = 2) and (data_in_ok_a_t = '1') and (key_in_ok_a_t = '1')) or ((operation = 1) and (data_in_ok_a_t = '1')) then
			if (data_in_ok_a_t = '1') then
				etat_courant_a <= actif;
				etat_in <= "00";
			end if;
		--attente sur demande
		elsif (etat_prochain_a = attente) then
			etat_courant_a <= attente;
			etat_in <= "01";
		--inactif si acquittement des données envoyées
		elsif ((etat_prochain_a = inactif) and (ack_data_out_b = '1') and (ack_key_out_b = '1')) then
			etat_courant_a <= inactif;
			etat_in <= "10";
		end if;
		
end process machine_d_etat_a;


--process synchrone
concatenation : process(horl, clr) is
	
	variable temp : STATE := (others => '0'); --mémoire sortie vers multiplexeur
--	variable mem_key : STATE := (others => '0'); --mémoire sortie vers key_schedule
	
	begin
	
	if (clr ='1') then --ràz asynchrone
		etat_prochain_a <= actif;
		data_out_b <= (others => '0');
		key_out_b <= (others => '0');
		data_out_ok_b <= '0';
		key_out_ok_b <= '0';
		ack_data_in_a <= '0';
		ack_key_in_a <= '0';
		temp := (others => '0');
		
	elsif rising_edge(horl) then
		
		case etat_courant_a is
			
			--mise à zéro des données de sortie
			when inactif =>
				data_out_b <= (others => '0');
				key_out_b <= (others => '0');
				data_out_ok_b <= '0';
				key_out_ok_b <= '0';
				etat_prochain_a <= actif;
				
			--attente d'acquittement de la part de l'aval
			when attente =>
				ack_data_in_a <= '0';
				ack_key_in_a <= '0';
				etat_prochain_a <= inactif;
				
			--concaténation des entrées en un seul mot de sortie
			when actif =>
				
				--en entrée :
				--|15|14|13|12|--|11|10|09|08|--|07|06|05|04|--|03|02|01|00|	
				
				--en sortie :
				--|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00|
				
				temp(127 downto 96) := data_in_4_4_a;
				temp(95 downto 64) := data_in_3_4_a;
				temp(63 downto 32) := data_in_2_4_a;
				temp(31 downto 0) := data_in_1_4_a;				
				
				--envoi du contenu des mémoires
				data_out_b <= temp;
				if (operation = 2) then
					key_out_b <= key_in_4_4_a & key_in_3_4_a & key_in_2_4_a & key_in_1_4_a;
				else
					key_out_b <= mem_key;
				end if;
				
				ack_data_in_a <= '1'; --acquittement données
				if (operation = 2) then --si clé valide en entrée, acquittement vers l'amont
					ack_key_in_a <= '1';
				end if;
				
				--positionnement des signaux de validités des sorties
				data_out_ok_b <= '1';
				key_out_ok_b <= '1';
				
				etat_prochain_a <= attente; --demande d'attente
				
		end case;
		
	end if;
	
end process concatenation;



------------------------------------------------------------------------
--sorties vers l'extérieur
--déconcaténation de l'entrée intérieure
------------------------------------------------------------------------

--process combinatoire asynchrone
machine_d_etat_b : process(etat_prochain_b, data_in_ok_b, ack_data_out_a_t, clr) is
	
	begin
		
		if (clr = '1') then
			etat_courant_b <= inactif;
			etat_out <= "10";
		--actif si données d'entrée valides
		elsif (etat_prochain_b = actif) and (data_in_ok_b = '1') then
			etat_courant_b <= actif;
			etat_out <= "00";
		--attente sur demande
		elsif (etat_prochain_b = attente) then
			etat_courant_b <= attente;
			etat_out <= "01";
		--inactif si acquittement des données envoyées
		elsif ((etat_prochain_b = inactif) and (ack_data_out_a_t = '1')) then
			etat_courant_b <= inactif;
			etat_out <= "10";
		end if;
		
end process machine_d_etat_b;


--process synchrone
deconcatenation : process(horl, clr) is
	
	
	begin
	
	if (clr = '1') then --ràz asynchrone
		etat_prochain_b <= actif;
		data_out_4_4_a <= (others => '0');
		data_out_3_4_a <= (others => '0');
		data_out_2_4_a <= (others => '0');
		data_out_1_4_a <= (others => '0');
		data_out_ok_a <= '0';
		ack_data_in_b <= '0';
	
	elsif rising_edge(horl) then
		
		case etat_courant_b is
			
			--ràz du compteur et mise à zéro de la sortie
			when inactif =>
				
				data_out_4_4_a <= (others => '0');
				data_out_3_4_a <= (others => '0');
				data_out_2_4_a <= (others => '0');
				data_out_1_4_a <= (others => '0');
				data_out_ok_a <= '0';
				etat_prochain_b <= actif;
			
			--attente d'acquittement
			when attente =>
				
				ack_data_in_b <= '0';
				etat_prochain_b <= inactif;
			
			--séparation du mot d'entrée en 4 parties
			when actif =>
				
				--en entrée :
				--|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00|
				
				--en sortie :
				--|15|14|13|12|--|11|10|09|08|--|07|06|05|04|--|03|02|01|00|	
				
				--recopie des données du démultiplexeur vers la sortie
				data_out_4_4_a <= data_in_b(127 downto 96);
				data_out_3_4_a <= data_in_b(95 downto 64);
				data_out_2_4_a <= data_in_b(63 downto 32);
				data_out_1_4_a <= data_in_b(31 downto 0);
				
				--positionnement des signaux de validité
				data_out_ok_a <= '1';
				ack_data_in_b <= '1';
				
				etat_prochain_b <= attente; --demande d'attente
				
		end case;
	
	end if;
	
end process deconcatenation;


end archi;