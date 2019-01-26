library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.all;

entity BF_CPU is
	port(
		CLK			: in std_logic;
		RST			: in std_logic;

		TX			: out std_logic;
		RX			: in std_logic;

		-- Debug output
		LED			: out std_logic_vector(7 downto 0);
		D_IOrd		: out std_logic;
		D_IOwr		: out std_logic
	);
end entity;

architecture a of BF_CPU is
	signal nRST		: std_logic;

	signal A		: std_logic_vector(31 downto 0);
	signal D		: std_logic_vector(7 downto 0);

	signal RAM_Dout	: std_logic_vector(7 downto 0);

	signal RAM_wr	: std_logic;
	signal RAM_rd	: std_logic;
	signal IO_wr	: std_logic;
	signal IO_rd	: std_logic;

	signal UART_ack	: std_logic;
	signal UART_bus	: std_logic;
	signal UART_rx	: std_logic;
	signal UART_d	: std_logic_vector(7 downto 0);
	signal IOrx_d	: std_logic_vector(7 downto 0);

	signal IOrx_rdy	: std_logic;

	signal sCLK		: std_logic;
	signal HLT		: std_logic;

begin

	D_IOrd <= IO_rd;
	D_IOwr <= IO_wr;
	nRST <= not(RST);

	e_FDIV : entity FDIV(a) generic map(100000000, 100000)
		port map(CLK, sCLK, nRST);

	e_RAM : entity ip_RAM(ip_RAM_a)
		port map(CLK, nRST, RAM_rd or RAM_wr, "" & RAM_wr, A(15 downto 0), D, RAM_Dout);

	e_CPU : entity CPU(a)
		port map(sCLK, nRST, D, D, A, RAM_wr, RAM_rd, IO_wr, IO_rd, IOrx_rdy, UART_bus, HLT);

	D <= RAM_Dout when (RAM_rd = '1') else "ZZZZZZZZ";

	e_IOrx : entity REG8(a)
		port map(CLK, nRST, IO_rd, UART_rx, UART_d, D, IOrx_d);

	e_UART : entity UART(rtl) generic map(9600, 100000000)
		port map(CLK, nRST, D, IO_wr, UART_ack, UART_bus, UART_d, UART_rx, TX, RX);

	LED <= IOrx_d;

	p_RX : process(CLK, nRST)
	begin
		if nRST = '1' then
			IOrx_rdy <= '0';
		elsif rising_edge(CLK) then 
			if UART_rx = '1' then
				IOrx_rdy <= '1';
			end if;
			if IO_rd = '1' then
				IOrx_rdy <= '0';
			end if;
		end if;
	end process;

end architecture;
