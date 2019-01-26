library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.all;

entity CPU is
	port(
		CLK			: in std_logic;
		RST			: in std_logic;

		Din			: in std_logic_vector(7 downto 0);
		Dout		: out std_logic_vector(7 downto 0);
		A			: out std_logic_vector(31 downto 0);

		wr			: out std_logic;
		rd			: out std_logic;
		iwr			: out std_logic;
		ird			: out std_logic;

		HLT			: out std_logic
	);
end entity;

architecture a of CPU is
	-- Internal main signals
	signal nRST			: std_logic;		-- Inverted of RST (active high)
	signal sRST			: std_logic;		-- Software reset

	-- CPU lines
	signal CPU_D		: std_logic_vector(7 downto 0);
	signal CPU_A		: std_logic_vector(31 downto 0);

	-- RAM control lines
	signal RAM_rd		: std_logic;
	signal RAM_wr		: std_logic;

	-- IO control lines
	signal IO_rd		: std_logic;
	signal IO_wr		: std_logic;

	-- Control lines registers
	signal AC_wr		: std_logic;	-- Accumulator
	signal AC_rd		: std_logic;
	signal AC_clr		: std_logic;
	signal IR_wr		: std_logic;	-- Instruction register
	signal IR_rd		: std_logic;
	signal IOR_wr		: std_logic;
	signal IOR_rd		: std_logic;

	-- Control lines pointer registers
	signal IP_wr		: std_logic;	-- Instruction pointer
	signal IP_rd		: std_logic;
	signal DP_wr		: std_logic;	-- Data pointer
	signal DP_rd		: std_logic;
	signal SP_wr		: std_logic;	-- Stack pointer
	signal SP_rd		: std_logic;
	signal BU_wr		: std_logic_vector(3 downto 0);	-- Buffer
	signal BU_rd		: std_logic;

	-- Direct data lines
	signal AC_d			: std_logic_vector(7 downto 0);
	signal IR_d			: std_logic_vector(7 downto 0);
	signal IP_d			: std_logic_vector(31 downto 0);
	signal DP_d			: std_logic_vector(31 downto 0);
	signal SP_d			: std_logic_vector(31 downto 0);
	signal BU_d			: std_logic_vector(31 downto 0);
	signal IOR_d			: std_logic_vector(7 downto 0);

	-- Arithmetic control lines
	signal DAR_inc		: std_logic;
	signal DAR_dec		: std_logic;
	signal AAR_inc		: std_logic;
	signal AAR_dec		: std_logic;
	signal AAR_adr		: std_logic_vector(31 downto 0);
	signal AAR_sel		: std_logic_vector(3 downto 0); -- Address arithmetic selector [IP, DP, SP, BU]

	-- Data->Address bridge
	signal DAB_sel		: std_logic_vector(3 downto 0);
	signal DAB_en		: std_logic;
	signal DAB_d0		: std_logic_vector(7 downto 0);
	signal DAB_d1		: std_logic_vector(7 downto 0);
	signal DAB_d2		: std_logic_vector(7 downto 0);
	signal DAB_d3		: std_logic_vector(7 downto 0);
	signal BU_Din		: std_logic_vector(31 downto 0);

	-- Address->Data bridge
	signal ADB_sel		: std_logic_vector(3 downto 0);
	signal ADB_d0		: std_logic_vector(7 downto 0);
	signal ADB_d1		: std_logic_vector(7 downto 0);
	signal ADB_d2		: std_logic_vector(7 downto 0);
	signal ADB_d3		: std_logic_vector(7 downto 0);

	signal reg8_wr		: std_logic_vector(1 downto 0);
	signal reg8_rd		: std_logic_vector(1 downto 0);
	signal reg32_wr		: std_logic_vector(2 downto 0);
	signal reg32_rd		: std_logic_vector(2 downto 0);

	type state_t is (reset, fetch, decode, dNOP, dDPp, dDPm, dp, dm, dWo, dWc, dI, dD, dS, dL, dC, dO, dH, dpt, dcm);
	type operation_t is (R8isRAM_R32, RAM_R32isR8, R8inc, R8dec, R32inc, R32dec, R32isRAM_R32plus, R32isRAM_R32min, RAM_R32isR32plus, RAM_R32isR32min);
	type R32isRAM_R32plus_state_t is (fetch, increment, store);
	type R32isRAM_R32min_state_t is (fetch, decrement, store);
	type RAM_R32isR32plus_state_t is (toac, store, increment);
	type RAM_R32isR32min_state_t is (toac, store, decrement);
	signal state		: state_t;
	signal operation	: operation_t;
	signal R32isRAM_R32plus_state	: R32isRAM_R32plus_state_t;
	signal R32isRAM_R32min_state	: R32isRAM_R32min_state_t;
	signal RAM_R32isR32plus_state	: RAM_R32isR32plus_state_t;
	signal RAM_R32isR32min_state	: RAM_R32isR32min_state_t;

begin

-- DEMULTIPLEX SIGNALS
-- -------------------
	-- REG8 wr
	AC_wr		<= reg8_wr(0);
	IR_wr		<= reg8_rd(1);

	-- REG8 rd
	AC_rd		<= reg8_rd(0);
	IR_rd		<= reg8_rd(1);

	-- REG32 wr
	IP_wr		<= reg32_wr(0);
	DP_wr		<= reg32_wr(1);
	SP_wr		<= reg32_wr(2);

	-- REG32 rd
	IP_rd		<= reg32_rd(0);
	DP_rd		<= reg32_rd(1);
	SP_rd		<= reg32_rd(2);

	-- Internal main signals
	nRST <= RST or sRST;

	-- Connections with outher world
	A <= CPU_A;
	Dout <= CPU_D when ((RAM_wr = '1') or (IO_wr = '1')) else "ZZZZZZZZ";
	CPU_D <= Din when ((RAM_rd = '1') or (IO_rd = '1')) else "ZZZZZZZZ";
	wr <= RAM_wr;
	rd <= RAM_rd;
	iwr <= IO_wr;
	ird <= IO_rd;

	-- Registers
	e_AC : entity REG8(a)			-- Accumulator
		port map(CLK, nRST or AC_clr, AC_rd, AC_wr, CPU_D, CPU_D, AC_d);
	e_IR : entity REG8(a)			-- Instruction register
		port map(CLK, nRST, IR_rd, IR_wr, CPU_D, CPU_D, IR_d);

	e_IOR : entity REG8(a)
		port map(CLK, nRST, IOR_rd, IOR_wr, CPU_D, CPU_D, IOR_d);
	CPU_A <= x"000000" & IOR_d WHEN ((IO_wr = '1') or (IO_rd = '1')) else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

	-- Data arithmetic (add/sub))
	e_DAR : entity INC8(a)
		port map(CLK, nRST, DAR_inc, DAR_dec, AC_d, CPU_d);

	-- Address arithmetic (add/sub)
	e_AARMux : entity MUX32_4(a)
		port map(CLK, nRST, AAR_sel, IP_d, DP_d, SP_d, BU_d, AAR_adr);
	e_AAR : entity INC32(a)
		port map(CLK, nRST, AAR_inc, AAR_dec, AAR_adr, CPU_A);

	-- Pointer registers
	e_IP : entity REG32(a)			-- Instruction pointer
		port map(CLK, nRST, IP_rd, IP_wr, CPU_A, CPU_A, IP_d);
	e_DP : entity REG32(a)			-- Data pointer
		port map(CLK, nRST, DP_rd, DP_wr, CPU_A, CPU_A, DP_d);
	e_SP : entity REG32(a)			-- Data pointer
		port map(CLK, nRST, SP_rd, SP_wr, CPU_A, CPU_A, SP_d);
	e_BU : entity REG8_32(a)
		port map(CLK, nRST, BU_rd, BU_wr, BU_Din, CPU_A, BU_d);

	-- Data->Address bridge
	e_DAB : entity DEMUX8_4(a)
		port map(CLK, nRST, DAB_sel, CPU_D, DAB_d0, DAB_d1, DAB_d2, DAB_d3);
	BU_Din <= DAB_d3 & DAB_d2 & DAB_d1 & DAB_d0 when (DAB_en = '1') else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

	-- Address->Data bridge
	e_ADB : entity MUX8_4(a)
		port map(CLK, nRST, ADB_sel, ADB_d0, ADB_d1, ADB_d2, ADB_d3, CPU_D);
	ADB_d0 <= CPU_A(7 downto 0);
	ADB_d1 <= CPU_A(15 downto 8);
	ADB_d2 <= CPU_A(23 downto 16);
	ADB_d3 <= CPU_A(31 downto 24);

	-- CONROL
	-- ------
	p_CONTROL : process(CLK, nRST)
		if nRST = '1' then
			state <= reset;
		elsif falling_edge(CLK) then

			-- CPU state machine
			case state is
				-- Reset the CPU
				when reset =>
					state <= fetch;
					operation <= EX;

					R32isRAM_R32plus_state <= fetch;
					R32isRAM_R32plus_BUFcnt <= 1;
					R32isRAM_R32min_state <= fetch;
					R32isRAM_R32min_BUFcnt <= 8;
					RAM_R32isR32plus_state <= toac;
					RAM_R32isR32plus_BUFcnt <= 8;
					RAM_R32isR32min_state <= toac;
					RAM_R32isR32min_BUFcnt <= 1;

					A <= x"00";
					B <= x"00";

				-- Fetch opcode
				when fetch =>
					operation <= R8isRAM_R32;
					A <= x"02"; -- IR
					B <= x"01"; -- IP
					state <= decode;

				-- Increase IP and decode opcode
				when decode =>
					operation <= R32inc;
					A <= "01"; -- IP;

					case IP_d(3 downto 0) is
						when x"0" => state <= dNOP;	-- " " NOP
						when x"1" => state <= dDPp; -- ">" DP++
						when x"2" => state <= dDPm; -- "<" DP--
						when x"3" => state <= dp; -- "+" *DP++
						when x"4" => state <= dm; -- "-" *DP--
						when x"5" => state <= dWo; -- "[" while(*dp){
						when x"6" => state <= dWc; -- "]" }
						when x"7" => state <= dI; -- "I" IP = *IP
						when x"8" => state <= dD; -- "D" DP = *IP
						when x"9" => state <= dS; -- "S" SP = *IP
						when x"a" => state <= dC; -- "C" *DP = 0
						when x"b" => state <= dL; -- "L" *DP = *IP
						when x"c" => state <= dO; -- "O" IOR = *IP
						when x"d" => state <= dpt; -- "." output = *DP
						when x"e" => state <= dcm; -- "," *DP = input
						when x"f" => state <= dH; -- "H" while(1);
						when others => state <= reset;
					end case;

				-- NOP
				when dNOP =>
					state <= fetch;

				-- HALT
				when dH =>
					HLT <= '1';

				-- DP++
				when dDPp =>
					operation <= R8inc;
					A <= x"01"; -- AC
					state <= fetch;

				-- DP--
				when dDPm =>
					operation <= R8dec;
					A <= x"01"; --AC
					state <= fetch;

				-- *DP++
				when dp =>
					operation <= R8isRAM_R32;
					A <= x"01"; -- AC
					B <= x"02"; -- DP;
					state <= dp1;
				when dp1 =>
					operation <= R8inc;
					A <= x"01"; -- AC;
					state <= dp2;
				when dp2 =>
					operation <= RAM_R32isR8;
					A <= x"02"; -- DP
					B <= x"01"; -- AC
					state <= fetch;
				
				-- *DP--
				when dm =>
					operation <= R8isRAM_R32;
					A <= x"01"; -- AC
					B <= x"02"; -- DP;
					state <= dm1;
				when dm1 =>
					operation <= R8dec;
					A <= x"01"; -- AC;
					state <= dm2;
				when dm2 =>
					operation <= RAM_R32isR8;
					A <= x"02"; -- DP
					B <= x"01"; -- AC
					state <= fetch;

				-- IP = *IP
				when dI =>
					operation <= R32isRAM_R32plus;
					A <= x"01"; -- IP
					B <= x"01"; -- IP
					state <= fetch;

				-- DP = *IP
				when dD =>
					operation <= R32isRAM_R32plus;
					A <= x"02"; -- DD
					B <= x"01"; -- IP
					state <= fetch;

				-- SP = *IP
				when dS =>
					operation <= R32isRAM_R32plus;
					A <= x"04"; -- SP
					B <= x"01"; -- IP
					state <= fetch;

				-- *DP = 0
				when dC =>
					state <= fetch;
					-- TODO not implemented yet

				-- *DP = L
				when dL =>
					operation <= R8isRAM_R32;
					A <= x"01"; -- AC
					B <= x"01"; -- IP
					state <= dL1;
				when dL1 <=
					operation <= R32inc;
					A <= x"01";
					state <= dL2;
				when dL2 =>
					operation <= RAM_R32isR8;
					A <= x"02"; -- DP
					B <= x"01"; -- AC
					state <= fetch;
					
				-- IOR = L
				when dO =>
					state <= fetch;
					-- TODO not implemented yet

				-- Output
				when dpt <=
					state <= fetch;
					-- TODO not implemented yet

				-- Input
				when dcm <=
					state <= fetch;
					-- TODO not implemented yet

				when others =>
					sRST <= '1'; -- Execute reset
					state <= reset;
			end case;

			-- Execute operation
			-- -----------------
			case operation is

				when EX =>
					-- All signals which need to be reset here

				-- REG8(A 2b) = RAM[REG32(B 3b)]
				when R8isRAM_R32 =>
					RAM_rd <= '1';
					reg8_wr <= A(1 downto 0);
					reg32_rd <= B(2 downto 0);
					operation <= EX;

				-- RAM[REG32(A 3b)] = REG8(B 2b)
				when RAM_R32isR8 =>
					RAM_wr <= '1';
					reg8_rd <= B(1 downto 0);
					reg32_rd <= A(2 downto 0);
					operation <= EX;

				-- REG32(A 3b)++
				when R32inc =>
					AAR_sel <= A(2 downto 0);
					AAR_inc <= '1';
					reg32_wr <= A(2 downto 0);
					operation <= EX;

				-- REG32(A 3b)--
				when R32dec =>
					AAR_sel <= A(2 downto 0);
					AAR_dec <= '1';
					reg32_wr <= A(2 downto 0);
					operation <= EX;

				-- REG8++ (only AC)
				when R8inc =>
					reg8_wr <= "01";
					DAR_inc <= '1';
					operation EX;

				-- REG8-- (only AC)
				when R8dec =>
					reg8_wr <= "01";
					DAR_dec <= '1';
					operation EX;

				-- REG32(A 3b) = RAM[REG32(B 3b)] pointer increasing
				when R32isRAM_R32plus =>
					case R32isRAM_R32plus_state is
						when fetch =>
							reg32_rd <= B(2 downto 0);
							RAM_rd <= '1';
							DAB_en <= '1';
							DAB_sel <= std_logic_vector(to_unsigned(R32isRAM_R32plus_BUFcnt, 4));
							BU_wr <= std_logic_vector(to_unsigned(R32isRAM_R32plus_BUFcnt, 4));
							R32isRAM_R32plus_state <= increment;

						when increment =>
							reg32_wr <= B(2 downto 0);
							AAR_sel <= B(2 downto 0);
							AAR_inc <= '1';

							if R32isRAM_R32plus_BUFcnt=8 then
								R32isRAM_R32plus_state <= store;
							else
								R32isRAM_R32plus_BUFcnt <= R32isRAM_R32plus_BUFcnt * 2;
								R32isRAM_R32plus_state <= fetch;
							end if;

						when store =>
							reg32_wr <= A(2 downto 0);
							BU_rd <= '1';
							R32isRAM_R32plus_state <= fetch;
							R32isRAM_R32plus_BUFcnt <= 1;
							operation <= EX;

						when others =>
							operation <= EX;
					end case;

				-- REG32(A 3b) = RAM[REG32(B 3b)] pointer decreasing
				when R32isRAM_R32min =>
					case R32isRAM_R32min_state is
						when fetch =>
							reg32_rd <= B(2 downto 0);
							RAM_rd <= '1';
							DAB_en <= '1';
							DAB_sel <= std_logic_vector(to_unsigned(R32isRAM_R32min_BUFcnt, 4));
							BU_wr <= std_logic_vector(to_unsigned(R32isRAM_R32min_BUFcnt, 4));
							R32isRAM_R32min_state <= decrement;

						when decrement =>
							reg32_wr <= B(2 downto 0);
							AAR_sel <= B(2 downto 0);
							AAR_dec <= '1';

							if R32isRAM_R32min_BUFcnt=1 then
								R32isRAM_R32min_state <= store;
							else
								R32isRAM_R32min_BUFcnt <= R32isRAM_R32min_BUFcnt / 2;
								R32isRAM_R32min_state <= fetch;
							end if;

						when store =>
							reg32_wr <= A(2 downto 0);
							BU_rd <= '1';
							R32isRAM_R32min_state <= fetch;
							R32isRAM_R32min_BUFcnt <= 8;
							operation <= EX;

						when others =>
							operation <= EX;
					end case;


				-- RAM[REG32(A 3b)] = REG32(B 3b) pointer decreasing
				when RAM_R32isR32min =>
					case RAM_R32isR32min_state is
						when toac =>
							reg8_wr <= "01"; --AC
							reg32_rd <= B(2 downto 0);
							ADB_sel <= std_logic_vector(to_unsigned(RAM_R32isR32min_BUFcnt, 4));
							RAM_R32isR32min_state <= decrement;

						when store =>
							RAM_wd <= '1';
							reg8_rr <= "01"; --AC
							reg32_rd <= A(2 downto 0);

							if RAM_R32isR32min_BUFcnt = 1 then
								RAM_R32isR32min_state <= toac;
								RAM_R32isR32min_BUFcnt <= 8;
							else
								RAM_R32isR32min_BUFcnt <= RAM_R32isR32min_BUFcnt / 2;
							end if;

						when decrement =>
							reg32_wr <= A(2 downto 0);
							AAR_sel <= A(2 downto 0);
							AAR_dec <= '1';
							RAM_R32isR32min_state <= store;

						when others =>
							operation <= EX;
					end case;

				-- RAM[REG32(A 3b)] = REG32(B 3b) pointer increasing
				when RAM_R32isR32plus =>
					case RAM_R32isR32plus_state is
						when toac =>
							reg8_wr <= "01"; --AC
							reg32_rd <= B(2 downto 0);
							ADB_sel <= std_logic_vector(to_unsigned(RAM_R32isR32plus_BUFcnt, 4));
							RAM_R32isR32plus_state <=increment;

						when store =>
							RAM_wd <= '1';
							reg8_rr <= "01"; --AC
							reg32_rd <= A(2 downto 0);

							if RAM_R32isR32plus_BUFcnt = 1 then
								RAM_R32isR32plus_state <= toac;
								RAM_R32isR32plus_BUFcnt <= 1;
							else
								RAM_R32isR32plus_BUFcnt <= RAM_R32isR32plus_BUFcnt * 2;
							end if;

						when increment =>
							reg32_wr <= A(2 downto 0);
							AAR_sel <= A(2 downto 0);
							AAR_inc <= '1';
							RAM_R32isR32plus_state <= store;

						when others =>
							operation <= EX;
					end case;

				when others =>
					operation <= EX;
			end case;

		end if;

end architecture;
