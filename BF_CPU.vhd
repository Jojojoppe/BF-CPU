library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.all;

entity BF_CPU is
	port(
		CLK			: in std_logic;
		RST			: in std_logic;

		-- Debug output
		LED			: out std_logic_vector(7 downto 0);
		D_clk		: out std_logic
	);
end entity;

architecture a of BF_CPU is
	signal nRST		: std_logic;
	
	signal A		: std_logic_vector(15 downto 0);

	signal sCLK		: std_logic;

begin

	D_clk <= sCLK;
	nRST <= not(RST);

	e_FDIV : entity FDIV(a) generic map(100000000, 2)
		port map(CLK, sCLK, nRST);

	e_RAM : entity ip_RAM(ip_RAM_a)
		port map(CLK, nRST, sCLK, "0", A, x"00", LED);

	p_cnt : process(nRST, sCLK)
	begin
		if nRST='1' then
			A <= x"0000";
		elsif rising_edge(sCLK) then
			A <= std_logic_vector(unsigned(A)+1);
		end if;
	end process;

end architecture;
