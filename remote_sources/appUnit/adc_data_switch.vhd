----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:43:02 10/14/2011 
-- Design Name: 
-- Module Name:    adc_data_switch - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity adc_data_switch is
    Port ( 
           rstn : in  STD_LOGIC;
			  -- Frontend
			  clk : in  STD_LOGIC;
			  eclk : in  STD_LOGIC;
           trgin : in  STD_LOGIC;
           enable : in  STD_LOGIC;
           bigendian : in  STD_LOGIC;
           data_in : in  STD_LOGIC_VECTOR (191 downto 0);
			  -- backend
           rReady_to_evbld : out  STD_LOGIC_VECTOR (15 downto 0);
           data_out : out  STD_LOGIC_VECTOR (7 downto 0);
			  rAddr : in  STD_LOGIC_VECTOR (12 downto 0);
           read_from_evbld : in  STD_LOGIC;
           rDone_from_evbld : in  STD_LOGIC;
			  timestamp: out std_logic_vector(23 downto 0);
			  datalength_to_evbld : out  STD_LOGIC_VECTOR (15 downto 0);
			  -- config
			  chSelect : in STD_LOGIC_VECTOR (3 downto 0);
           datalength : in  STD_LOGIC_VECTOR (15 downto 0);
           eventInfoType : in  STD_LOGIC_VECTOR (7 downto 0);
           chmask_out : out  STD_LOGIC_VECTOR (15 downto 0)
	 );
end adc_data_switch;

architecture Behavioral of adc_data_switch is
	COMPONENT dataCaptureCtrl
	PORT(
		clk : IN std_logic;
		rstn : IN std_logic;
		trgin : IN std_logic;
		enable : IN std_logic;
		datalength : IN std_logic_vector(11 downto 0);
           totEvents : in  STD_LOGIC_VECTOR (15 downto 0);
			  resume: in std_logic;
      datalength_out : out  STD_LOGIC_VECTOR (11 downto 0);
		rDone : IN std_logic;          
		wen : OUT std_logic;
		wAddr : OUT std_logic_vector(11 downto 0);
		timestamp : OUT std_logic_vector(23 downto 0);
		rReady : OUT std_logic
		);
	END COMPONENT;
component dMem
	port (
	clka: IN std_logic;
	wea: IN std_logic_VECTOR(0 downto 0);
--	wea: IN std_logic;
	addra: IN std_logic_VECTOR(11 downto 0);
	dina: IN std_logic_VECTOR(15 downto 0);
	clkb: IN std_logic;
	enb: IN std_logic;
	addrb: IN std_logic_VECTOR(12 downto 0);
	doutb: OUT std_logic_VECTOR(7 downto 0));
end component;
signal datalength_e : std_logic_vector(15 downto 0);
signal datalength_out : std_logic_vector(11 downto 0);
signal wAddr: std_logic_vector(11 downto 0);
signal wen, rReady, rDone: std_logic;
signal wea: std_logic_vector(0 downto 0);

signal din_mem : std_logic_vector(15 downto 0);
type sig16array is array(0 to 15) of std_logic_vector(11 downto 0);
signal datain_a : sig16array;

begin

	Inst_dataCaptureCtrl: dataCaptureCtrl PORT MAP(
		clk => clk,
		rstn => rstn,
		trgin => trgin,
		enable => enable,
		datalength => datalength(11 downto 0),
		datalength_out => datalength_out,
--		totEvents => totEvents,
--		resume => resume,
		totEvents => x"0000",
		resume => '1',
		wen => wen,
		wAddr => wAddr,
		timestamp => timestamp,
		rReady => rReady,
		rDone => rDone
	);
	
	datalength_to_evbld(15 downto 13)	<= "000";
	datalength_to_evbld(12 downto 1) <= datalength_out;
	datalength_to_evbld(0) <= '0';

	rDone <= rDone_from_evbld;

	wea(0) <= wen;
	gen: for i in 0 to 15 generate
		rReady_to_evbld(i) <= rReady;
		datain_a(i) <= data_in(12*i+11 downto 12*i);
	end generate;
	
	process(clk, rstn)
	begin
		if rstn = '0' then
			din_mem <= (others => '0');
		elsif clk'event and clk = '1' then
			if bigendian = '1' then
				din_mem <= datain_a(conv_integer(chSelect))(7 downto 0) & "0000" & datain_a(conv_integer(chSelect))(11 downto 8);
			else
				din_mem <= "0000" & datain_a(conv_integer(chSelect));
			end if;
		end if;
	end process;

	dataMem : dMem port map (
		clka => clk, wea => wea, addra => wAddr, clkb => eclk, addrb => rAddr,
		dina => din_mem , enb => read_from_evbld, doutb => data_out);
	
	process(chSelect)
	begin
		case chSelect is
			when "0000" => chmask_out <= "0000000000000001";
			when "0001" => chmask_out <= "0000000000000010";
			when "0010" => chmask_out <= "0000000000000100";
			when "0011" => chmask_out <= "0000000000001000";
			when "0100" => chmask_out <= "0000000000010000";
			when "0101" => chmask_out <= "0000000000100000";
			when "0110" => chmask_out <= "0000000001000000";
			when "0111" => chmask_out <= "0000000010000000";
			when "1000" => chmask_out <= "0000000100000000";
			when "1001" => chmask_out <= "0000001000000000";
			when "1010" => chmask_out <= "0000010000000000";
			when "1011" => chmask_out <= "0000100000000000";
			when "1100" => chmask_out <= "0001000000000000";
			when "1101" => chmask_out <= "0010000000000000";
			when "1110" => chmask_out <= "0100000000000000";
			when "1111" => chmask_out <= "1000000000000000";
			when others => chmask_out <= "0000000000000001";
		end case;
	end process;


end Behavioral;

