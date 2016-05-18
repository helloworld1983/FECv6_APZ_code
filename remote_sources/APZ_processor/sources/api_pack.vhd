----------------------------------------------------------------------------------
-- Company: Universita' di Napoli 'Federico II' and INFN Sez. Napoli
-- Engineer: Raffaele Giordano
-- email: rgiordano@na.infn.it


library IEEE;
use IEEE.STD_LOGIC_1164.all;

package api_pack is
   
	constant NUM_OF_CHANNELS : integer := 128;
   constant APV_WORD_SIZE : integer := 12;
   constant APV_LOG2_CHANNELS : integer := 7;
   -- maximum number of samples, with single buffering
	constant LOG2_MAX_SAMPLES : integer := 5;
	--constant DOUBLE_BUF : integer := 0;

	type array16x12 is array (15 downto 0) of  std_logic_vector(11 downto 0);
	type array16x13 is array (15 downto 0) of  std_logic_vector(12 downto 0);
	type array16x16 is array (15 downto 0) of  std_logic_vector(15 downto 0);
	type array16x7 is array (15 downto 0) of  std_logic_vector(6 downto 0);
	type array16x5 is array (15 downto 0) of  std_logic_vector(4 downto 0);
	type array16x4 is array (15 downto 0) of  std_logic_vector(3 downto 0);

	COMPONENT file_register is
	 generic(M: natural; N: natural);
    Port ( we 		: in std_logic;							  -- write enable
           datain	: in std_logic_vector(N-1 downto 0);    -- data input
           wclk 	: in std_logic;							  -- writing clock
           addrA  : in std_logic_vector(M-1 downto 0);  -- address B
           addrB  : in std_logic_vector(M-1 downto 0);  -- address A
           dataA  : out std_logic_vector(N-1 downto 0);  -- data out A
           dataB  : out std_logic_vector(N-1 downto 0)); -- data out B
	end COMPONENT;
	
	signal dbg_sigma : array16x12;
	signal dbg_pedestal : array16x12;
--	signal dbg_sample : array16x4;
	signal dbg_sample : array16x5;
	signal dbg_chan : array16x7;

	
end api_pack;

package body api_pack is


	
	
---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
end api_pack;
