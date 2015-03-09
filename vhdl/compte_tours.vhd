library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aaes_pack.all;


-------------------------------------------------------
--------------------compte_tours-----------------------
-------------------------------------------------------


entity compte_tours is
port (
	clr : in std_logic; --signal de mise à zéro
	raz : in std_logic; --raz venant de l'ordonnanceur
	tour_inc_in : in std_logic; --signal d'incrémentation de tour, connectée à data_out_ok de add_round_key
	tour_out : out std_logic_vector (3 downto 0) --numéro du tour courant
);
end compte_tours;


architecture archi of compte_tours is

signal tour_out_t : integer range 0 to 15 := 0;

begin

tour_out <= std_logic_vector(to_unsigned(tour_out_t, 4));

comportement : process (clr, tour_inc_in) is

	begin
	
	if (clr = '1') then --RAZ asynchrone
		tour_out_t <= 0;
	elsif (raz = '1') then --raz ordonnanceur
		tour_out_t <= 0;
	elsif (rising_edge(tour_inc_in)) then --incrémentation sur front montant de données de fin de tour valides
		if tour_out_t = 11 then
			tour_out_t <= 0;
		else
			tour_out_t <= (tour_out_t + 1);
		end if;
	end if;
	
end process comportement;


end archi;