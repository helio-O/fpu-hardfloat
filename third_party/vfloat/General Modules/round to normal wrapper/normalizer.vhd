
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.float_pkg.all;
-- float
library fp_lib;


----------------------------------------------------------
--                    Normalizer                        --
----------------------------------------------------------
entity normalizer is
	generic
	(
		exp_bits			:	integer	:=	8;
		man_bits			:	integer	:=	29
	);
	port
	(
		--inputs
		CLK				:	in		std_logic;
		RESET				:	in		std_logic;
		STALL				:	in		std_logic;
		SIGN_IN			:	in		std_logic;
		EXP_IN			:	in		std_logic_vector(exp_bits-1 downto 0);
		MAN_IN			:	in		std_logic_vector(man_bits-1 downto 0);
		READY				:	in		std_logic;
		EXCEPTION_IN	:	in		std_logic;
		--outputs
		SIGN_OUT			:	out	std_logic;
		EXP_OUT			:	out	std_logic_vector(exp_bits-1 downto 0);
		MAN_OUT			:	out	std_logic_vector(man_bits-1 downto 0);
		EXCEPTION_OUT	:	out	std_logic	:=	'0';
		DONE				:	out	std_logic	:=	'0'
	);
end normalizer;

----------------------------------------------------------
--                    Normalizer                        --
----------------------------------------------------------
architecture normalizer_arch of normalizer is
	--CONSTANTS
	constant	shift_bits	:	integer	:=	ceil_log2(man_bits);
	--SIGNALS
	signal	exc_ppe					:	std_logic	:=	'0';
	signal	exc_pc					:	std_logic	:=	'0';
	signal	exc_int					:	std_logic	:=	'0';
	signal	a_eq_b					:	std_logic	:=	'0';
	signal	a_lt_b					:	std_logic	:=	'0';
	signal	man_int					:	std_logic_vector(man_bits-1 downto 0)		:=	(others=>'0');
	signal	exp_int					:	std_logic_vector(exp_bits-1 downto 0)		:=	(others=>'0');
	signal	shift						:	std_logic_vector(shift_bits-1 downto 0)	:=	(others=>'0');
	signal	exp_wide					:	std_logic_vector(shift_bits-1 downto 0)	:=	(others=>'0');
	signal	shift_wide				:	std_logic_vector(exp_bits-1 downto 0)		:=	(others=>'0');
	signal	exp_int_shift_wide	:	std_logic_vector(shift_bits-1 downto 0)	:=	(others=>'0');
begin
	--ASYNCHRONOUS
	--Instantiate the components
	ppe	: parameterized_priority_encoder
		generic map
		(
			man_bits			=>	man_bits,
			shift_bits		=>	shift_bits
		)
		port map
		(
			MAN_IN			=>	MAN_IN,
			SHIFT				=>	shift,
			EXCEPTION_OUT	=>	exc_ppe
		);
	pvs	: parameterized_variable_shifter
		generic map
		(
			bits				=>	man_bits,
			select_bits		=>	shift_bits,
			direction		=>	'1'
		)
		port map
		(
			I					=>	MAN_IN,
			S					=>	shift,
			CLEAR				=>	'0', --never want to clear
			O					=>	man_int
		);
	--CONDITIONAL PART
	--if exponent wider than shift, most of the time
	exponent_wider	:	if(exp_bits>shift_bits) generate
		shift_wide(shift_bits-1 downto 0)			<=	shift;
		shift_wide(exp_bits-1 downto shift_bits)	<=	(others=>'0');
		pc	: parameterized_comparator
			generic map
			(
				bits			=>	exp_bits
			)
			port map
			(
				A				=>	shift_wide,
				B				=>	EXP_IN,
				A_GT_B		=>	exc_pc,
				A_EQ_B		=>	a_eq_b,
				A_LT_B		=>	a_lt_b
			);
		ps	: parameterized_subtractor
			generic map
			(
				bits			=>	exp_bits
			)
			port map
			(
				A				=>	EXP_IN,
				B				=>	shift_wide,
				O				=>	exp_int
			);
	end generate;--exponent wider
	--if shift wider than exponent, rare
	shift_wider	:	if (exp_bits<shift_bits) generate
	
		exp_wide(exp_bits-1 downto 0)	<=	EXP_IN;
		exp_wide(shift_bits-1 downto exp_bits)	<=	(others=>'0');
		exp_int	<=	exp_int_shift_wide(exp_bits-1 downto 0);
		
		pc	: parameterized_comparator
			generic map
			(
				bits			=>	shift_bits
			)
			port map
			(
				A					=>	shift,
				B					=>	exp_wide,
				A_GT_B			=>	exc_pc,
				A_EQ_B			=>	a_eq_b,
				A_LT_B			=>	a_lt_b
			);
			
		ps	: parameterized_subtractor
			generic map
			(
				bits				=>	shift_bits
			)
			port map
			(
				A					=>	exp_wide,
				B					=>	shift,
				O					=>	exp_int_shift_wide
			);
	end generate;--shift wider
	
	--if exponent and shift equally wide, rare
	equal_width	:	if(exp_bits=shift_bits) generate
		pc	: parameterized_comparator
			generic map
			(
				bits				=>	exp_bits
			)
			port map
			(
				A					=>	shift,
				B					=>	EXP_IN,
				A_GT_B			=>	exc_pc,
				A_EQ_B			=>	a_eq_b,
				A_LT_B			=>	a_lt_b
			);
		ps	: parameterized_subtractor
			generic map
			(
				bits				=>	exp_bits
			)
			port map
			(
				A					=>	EXP_IN,
				B					=>	shift,
				O					=>	exp_int
			);
	end generate;--same width
	
	--exception
	exc_int	<=	exc_pc OR EXCEPTION_IN;
	--SYNCHRONOUS
	assign_outputs: process (CLK,RESET,STALL) is
	begin
		if(RESET = '1') then
			SIGN_OUT			<= '0';
			EXP_OUT			<=	(others=>'0');
			MAN_OUT			<=	(others=>'0');
			EXCEPTION_OUT	<=	'0';
			DONE				<=	'0';			
		elsif(rising_edge(CLK) and STALL = '0') then
			SIGN_OUT			<= SIGN_IN;
			EXP_OUT			<=	exp_int;
			MAN_OUT			<=	man_int;
			EXCEPTION_OUT	<=	exc_int;
			DONE				<=	READY;
		end if;--CLK
	end process;--assign_outputs
end normalizer_arch; -- end of architecture
