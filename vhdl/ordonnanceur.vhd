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


entity ordonnanceur is
port (
	horl : in std_logic;
	clr : in std_logic; --signal de mise à zéro
	
	--première machine d'état
	--envoi des données de l'extérieur vers l'intérieur
	data_in_4_4_a : in COLUMN; --données d'entrée --MSB
	data_in_3_4_a : in COLUMN;
	data_in_2_4_a : in COLUMN;
	data_in_1_4_a : in COLUMN; --LSB
	data_in_ok_a : in std_logic;
	
	key_in_4_4_a : in COLUMN; --clé d'entrée --MSB
	key_in_3_4_a : in COLUMN;
	key_in_2_4_a : in COLUMN;
	key_in_1_4_a : in COLUMN; --LSB
	key_in_ok_a : in std_logic;
	
	data_out_b : out STATE; --données de sortie, vers le mux
	data_out_ok_b : out std_logic; --signal de validité des données de sortie, vers le mux
	
	key_out_b : out STATE; --clé de sortie, vers key_schedule
	key_out_ok_b : out std_logic; --signal de validité de la clé de sortie, vers key_schedule
	
	ack_data_in_a : out std_logic;
	ack_key_in_a : out std_logic;
	
	ack_data_out_b : in std_logic; --acquittement des données de sortie, du mux
	ack_key_out_b : in std_logic; --acquittement de la clé de sortie, de key_schedule
	
	etat_in : out std_logic_vector (1 downto 0); --état de la machine d'état a (debug)
	
	
	--deuxième machine d'état
	--envoi de données de l'intérieur vers l'extérieur
	data_in_b : in STATE; --entrée des données, du demux
	data_in_ok_b : in std_logic; --signal de validité des données d'entrée, du demux
	
	data_out_4_4_a : out COLUMN; --sortie des données --MSB
	data_out_3_4_a : out COLUMN;
	data_out_2_4_a : out COLUMN;
	data_out_1_4_a : out COLUMN; --LSB
	data_out_ok_a : out std_logic;
	
	ack_data_in_b : out std_logic; --acquittement envoyé au demux
	
	ack_data_out_a : in std_logic;
	
	etat_out : out std_logic_vector (1 downto 0) --état de la machine d'état b (debug)
);
end ordonnanceur;


architecture archi of ordonnanceur is

--état des machines d'états
signal etat_courant_a : etat_6FSM_type := inactif;
signal etat_courant_b : etat_4FSM_type := inactif;

--code de l'opération à effectuer : 
-- 0 : rien à faire
-- 1 : prise en compte des données d'entrée, la clé utilisée provient de la mémoire
-- 2 : prise en compte des données d'entrée et de la clé d'entrée
signal operation : integer range 0 to 2 := 0; -- 1 : data_in ; 2 : data_in + key_in
signal operation_data : integer range 0 to 1 := 0; 
signal operation_key : integer range 0 to 1 := 0;

--mémoire sortie vers key_schedule
signal mem_key : STATE := (others => '0');

signal data_out_b_t : STATE := (others => '0');
signal data_out_ok_b_t : std_logic := '0';
signal key_out_b_t : STATE := (others => '0');
signal key_out_ok_b_t : std_logic := '0';
signal ack_data_in_a_t : std_logic := '0';
signal ack_key_in_a_t : std_logic := '0';
signal etat_in_t : std_logic_vector(1 downto 0) := "10";
signal data_out_4_4_a_t : COLUMN := (others => '0');
signal data_out_3_4_a_t : COLUMN := (others => '0');
signal data_out_2_4_a_t : COLUMN := (others => '0');
signal data_out_1_4_a_t : COLUMN := (others => '0');
signal data_out_ok_a_t : std_logic := '0';
signal ack_data_in_b_t : std_logic := '0';
signal etat_out_t : std_logic_vector(1 downto 0) := "10";

begin

data_out_b <= data_out_b_t;
data_out_ok_b <= data_out_ok_b_t;
key_out_b <= key_out_b_t;
key_out_ok_b <= key_out_ok_b_t;
ack_data_in_a <= ack_data_in_a_t;
ack_key_in_a <= ack_key_in_a_t;
etat_in <= etat_in_t;
data_out_4_4_a <= data_out_4_4_a_t;
data_out_3_4_a <= data_out_3_4_a_t;
data_out_2_4_a <= data_out_2_4_a_t;
data_out_1_4_a <= data_out_1_4_a_t;
data_out_ok_a <= data_out_ok_a_t;
ack_data_in_b <= ack_data_in_b_t;
etat_out <= etat_out_t;

--màj code opération
operation <= operation_data + operation_key;
	
--màj code opération avec data_in_ok
op_data : process (data_in_ok_a, etat_courant_a, clr, operation_data) is
	
	begin
		if (clr = '1') then --ràz asynchrone
			operation_data <= 0;
		elsif (etat_courant_a = attente2) then --ràz dans l'état d'attente de la machine d'états a
			operation_data <= 0;
		elsif (data_in_ok_a = '1') then --prise en compte sur front montant
			if (operation_data /= 1) then
				operation_data <= operation_data + 1;
			end if;
		end if;
		
end process op_data;

--màj code opération avec key_ok
op_key : process (key_in_ok_a, etat_courant_a, clr, operation_key) is
	
	begin
		if (clr = '1') then --ràz asynchrone
			operation_key <= 0;
		elsif (etat_courant_a = attente2) then --ràz dans l'état d'attente de la machine d'états a
			operation_key <= 0;
		elsif (key_in_ok_a = '1') then --prise en compte sur front montant
			if (operation_key /= 1) then
				operation_key <= operation_key + 1;
			end if;	
		end if;
		
end process op_key;


--mise en mémoire de la clé d'entrée
key_in_save : process(operation, etat_courant_a, clr,
		key_in_4_4_a, key_in_3_4_a, key_in_2_4_a, key_in_1_4_a)

	begin
		
		if(clr = '1') then --ràz asynchrone
			mem_key <= (others => '0');
		elsif (operation = 2) and ((etat_courant_a = actif_a) or (etat_courant_a = actif_b)) then --si clé valide en entrée, mise en mémoire
			mem_key <= key_in_4_4_a & key_in_3_4_a & key_in_2_4_a & key_in_1_4_a;		
		end if;

end process key_in_save;


------------------------------------------------------------------------
--sorties vers l'intérieur : multiplexeur et key_schedule
--concaténation des entrées extérieures
------------------------------------------------------------------------

process1 : process(horl, clr)
begin
	if(clr = '1') then
		etat_courant_a <= inactif;
	elsif rising_edge(horl) then
		case etat_courant_a is
			when inactif =>
				if (data_in_ok_a = '1') and (ack_data_out_b = '0') and (ack_key_out_b = '0') then
					if (operation = 2) then
						etat_courant_a <= actif_a;
					else
						etat_courant_a <= actif_b;
					end if;
				end if;
			when attente1_a =>
				if (ack_data_out_b = '1') and (ack_key_out_b = '1') then
					etat_courant_a <= attente2;
				end if;
			when attente1_b =>
				if (ack_data_out_b = '1') and (ack_key_out_b = '1') then
					etat_courant_a <= attente2;
				end if;
			when attente2 =>
				if (data_in_ok_a = '0') and (key_in_ok_a = '0') then
					etat_courant_a <= inactif;
				end if;
			when actif_a =>
				etat_courant_a <= attente1_a;
			when actif_b =>
				etat_courant_a <= attente1_b;
		end case;
	end if;
end process process1;

	
process2 : process(etat_courant_a, operation, mem_key, 
		data_in_4_4_a, data_in_3_4_a, data_in_2_4_a, data_in_1_4_a, 
		key_in_4_4_a, key_in_3_4_a, key_in_2_4_a, key_in_1_4_a)
begin
	case etat_courant_a is 
		when inactif =>
			etat_in_t <= "10";
			data_out_b_t <= (others => '0');
			key_out_b_t <= (others => '0');
			data_out_ok_b_t <= '0';
			key_out_ok_b_t <= '0';
			ack_data_in_a_t <= '0';
			ack_key_in_a_t <= '0';
		when attente1_a =>
			etat_in_t <= "11";
			data_out_ok_b_t <= '1';
			key_out_ok_b_t <= '1';
			ack_data_in_a_t <= '1';
			ack_key_in_a_t <= '1';
		when attente1_b =>
			etat_in_t <= "11";
			data_out_ok_b_t <= '1';
			key_out_ok_b_t <= '1';
			ack_data_in_a_t <= '1';
			ack_key_in_a_t <= '0';
		when attente2 =>
			etat_in_t <= "01";
			data_out_b_t <= (others => '0');
			key_out_b_t <= (others => '0');
			data_out_ok_b_t <= '0';
			key_out_ok_b_t <= '0';
			ack_data_in_a_t <= '0';
			ack_key_in_a_t <= '0';
		when actif_a =>
			etat_in_t <= "00";
			data_out_b_t <= data_in_4_4_a & data_in_3_4_a & data_in_2_4_a & data_in_1_4_a;
			key_out_b_t <= key_in_4_4_a & key_in_3_4_a & key_in_2_4_a & key_in_1_4_a;
			data_out_ok_b_t <= '1';
			key_out_ok_b_t <= '1';
			ack_data_in_a_t <= '1';
			ack_key_in_a_t <= '1';
		when actif_b =>
			etat_in_t <= "00";
			data_out_b_t <= data_in_4_4_a & data_in_3_4_a & data_in_2_4_a & data_in_1_4_a;
			key_out_b_t <= mem_key;
			data_out_ok_b_t <= '1';
			key_out_ok_b_t <= '1';
			ack_data_in_a_t <= '1';
			ack_key_in_a_t <= '0';
			--en entrée :
			--|15|14|13|12|--|11|10|09|08|--|07|06|05|04|--|03|02|01|00|	
			
			--en sortie :
			--|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00|
	end case;
end process process2;

------------------------------------------------------------------------
--sorties vers l'extérieur
--déconcaténation de l'entrée intérieure
------------------------------------------------------------------------

process3 : process(horl, clr)
begin
	if(clr = '1') then
		etat_courant_b <= inactif;
	elsif rising_edge(horl) then
		case etat_courant_b is
			when inactif =>
				if (data_in_ok_b = '1') and (ack_data_out_a = '0') then
					etat_courant_b <= actif;
				end if;
			when attente1 =>
				if (ack_data_out_a = '1') then
					etat_courant_b <= attente2;
				end if;
			when attente2 =>
				if (data_in_ok_b = '0') then
					etat_courant_b <= inactif;
				end if;
			when actif =>
				etat_courant_b <= attente1;
		end case;
	end if;
end process process3;


process4 : process(etat_courant_b, data_in_b)
begin
	case etat_courant_b is
		when inactif =>
			etat_out_t <= "10";
			data_out_4_4_a_t <= (others => '0');
			data_out_3_4_a_t <= (others => '0');
			data_out_2_4_a_t <= (others => '0');
			data_out_1_4_a_t <= (others => '0');
			data_out_ok_a_t <= '0';
			ack_data_in_b_t <= '0';
		when attente1 =>
			etat_out_t <= "11";
			data_out_ok_a_t <= '1';
			ack_data_in_b_t <= '1';
		when attente2 =>
			etat_out_t <= "01";
			ack_data_in_b_t <= '0';
			data_out_ok_a_t <= '0';
			ack_data_in_b_t <= '0';
		when actif =>
			etat_out_t <= "00";
			--en entrée :
			--|15|14|13|12|11|10|09|08|07|06|05|04|03|02|01|00|
			
			--en sortie :
			--|15|14|13|12|--|11|10|09|08|--|07|06|05|04|--|03|02|01|00|	
			
			--recopie des données du démultiplexeur vers la sortie
			data_out_4_4_a_t <= data_in_b(127 downto 96);
			data_out_3_4_a_t <= data_in_b(95 downto 64);
			data_out_2_4_a_t <= data_in_b(63 downto 32);
			data_out_1_4_a_t <= data_in_b(31 downto 0);
			
			--positionnement des signaux de validité
			data_out_ok_a_t <= '1';
			ack_data_in_b_t <= '1';
	end case;
end process process4;

end archi;