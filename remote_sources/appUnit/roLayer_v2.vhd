----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:07:55 09/16/2010 
-- Design Name: 
-- Module Name:    roLayer - Behavioral 
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
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity roLayer_v2 is
    Port ( 
           rstn : in  STD_LOGIC;
			  -- Frontend
			  clk : in  STD_LOGIC;
           trgin : in  STD_LOGIC;
           enable : in  STD_LOGIC;
           data0 : in  STD_LOGIC_VECTOR (15 downto 0);
           data1 : in  STD_LOGIC_VECTOR (15 downto 0);
           data2 : in  STD_LOGIC_VECTOR (15 downto 0);
           data3 : in  STD_LOGIC_VECTOR (15 downto 0);
           data4 : in  STD_LOGIC_VECTOR (15 downto 0);
           data5 : in  STD_LOGIC_VECTOR (15 downto 0);
           data6 : in  STD_LOGIC_VECTOR (15 downto 0);
           data7 : in  STD_LOGIC_VECTOR (15 downto 0);
           data8 : in  STD_LOGIC_VECTOR (15 downto 0);
           data9 : in  STD_LOGIC_VECTOR (15 downto 0);
           data10: in  STD_LOGIC_VECTOR (15 downto 0);
           data11: in  STD_LOGIC_VECTOR (15 downto 0);
           data12: in  STD_LOGIC_VECTOR (15 downto 0);
           data13: in  STD_LOGIC_VECTOR (15 downto 0);
           data14: in  STD_LOGIC_VECTOR (15 downto 0);
           data15: in  STD_LOGIC_VECTOR (15 downto 0);
--           datain1 : in  STD_LOGIC_VECTOR (15 downto 0);
			  frameCounterOut: out STD_LOGIC_VECTOR (31 downto 0);
			  -- Backend
			  eclk : in  STD_LOGIC;
           dataout : out  STD_LOGIC_VECTOR (7 downto 0);
           udpLength : out  STD_LOGIC_VECTOR (15 downto 0);
           udpPauseData, frameEndEvent : in  STD_LOGIC;
           udpStartTx : out  STD_LOGIC;
           udpStopTx : out  STD_LOGIC;
			  txreq, txdone : out std_logic;
			  txack : in std_logic;
--			  resume: in std_logic;
			  -- Config
--           totEvents : in  STD_LOGIC_VECTOR (15 downto 0);
			  udpBuildMode: in std_logic_vector(7 downto 0);
           datalength : in  STD_LOGIC_VECTOR (15 downto 0);
           eventInfoType : in  STD_LOGIC_VECTOR (7 downto 0);
           eventInfoData : in  STD_LOGIC_VECTOR (31 downto 0);
           chmask : in  STD_LOGIC_VECTOR (15 downto 0)
			  );
end roLayer_v2;

architecture Behavioral of roLayer_v2 is
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
		rBusy : OUT std_logic;
		rReady : OUT std_logic
		);
	END COMPONENT;
	COMPONENT udpEventBuild2
	PORT(
		clk : IN std_logic;
		rstn : IN std_logic;
		mode: in std_logic_vector(7 downto 0);
		rReady : IN std_logic_vector(15 downto 0);
		timestamp : IN std_logic_vector(23 downto 0);
           data0 : in  STD_LOGIC_VECTOR (7 downto 0);
           data1 : in  STD_LOGIC_VECTOR (7 downto 0);
           data2 : in  STD_LOGIC_VECTOR (7 downto 0);
           data3 : in  STD_LOGIC_VECTOR (7 downto 0);
           data4 : in  STD_LOGIC_VECTOR (7 downto 0);
           data5 : in  STD_LOGIC_VECTOR (7 downto 0);
           data6 : in  STD_LOGIC_VECTOR (7 downto 0);
           data7 : in  STD_LOGIC_VECTOR (7 downto 0);
           data8 : in  STD_LOGIC_VECTOR (7 downto 0);
           data9 : in  STD_LOGIC_VECTOR (7 downto 0);
           data10: in  STD_LOGIC_VECTOR (7 downto 0);
           data11: in  STD_LOGIC_VECTOR (7 downto 0);
           data12: in  STD_LOGIC_VECTOR (7 downto 0);
           data13: in  STD_LOGIC_VECTOR (7 downto 0);
           data14: in  STD_LOGIC_VECTOR (7 downto 0);
           data15: in  STD_LOGIC_VECTOR (7 downto 0);
			  frameCounterOut: out STD_LOGIC_VECTOR (31 downto 0);
		rAddr : out std_logic_vector(12 downto 0);
		datalength : IN std_logic_vector(15 downto 0);
		eventInfoType : IN std_logic_vector(7 downto 0);
		eventInfoData : IN std_logic_vector(31 downto 0);
		udpPauseData, frameEndEvent : IN std_logic;
		chmask : IN std_logic_vector(15 downto 0);          
		ren : OUT std_logic_vector(15 downto 0);
			  txreq, txdone : out std_logic;
			  txack : in std_logic;
		dataout : OUT std_logic_vector(7 downto 0);
		udpLength : OUT std_logic_vector(15 downto 0);
		udpStartTx : OUT std_logic;
		udpStopTx : OUT std_logic
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
signal ren, udprReady : std_logic_vector(15 downto 0);
signal datalength_e : std_logic_vector(15 downto 0);
signal datalength_out : std_logic_vector(11 downto 0);
signal wen, rReady, rBusy, rDone, rReady_e, udpStopTx_i: std_logic;
signal wAddr: std_logic_vector(11 downto 0);
signal rAddr: std_logic_vector(12 downto 0);
signal wea: std_logic_vector(0 downto 0);

type sig8array is array(0 to 15) of std_logic_vector(7 downto 0);
type sig16array is array(0 to 15) of std_logic_vector(15 downto 0);
signal din_mem : sig16array;
signal dout_mem : sig8array;

signal timestamp: std_logic_vector(23 downto 0);
signal eventInfoData_i : std_logic_vector(31 downto 0);

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
		rBusy => rBusy,
		rDone => rDone
	);
	
	process(clk, rstn)
	begin
		if rstn = '0' then
			eventInfoData_i <= (others => '0');
		elsif clk'event and clk = '1' then
			-- registers the info on trigger only when the Capture SM is idle
			if ((trgin and enable) = '1') and (rBusy = '0') then
				eventInfoData_i <= eventInfoData;
			end if;
		end if;
	end process;
			
--	Inst_TaskAck_CrossDomain: TaskAck_CrossDomain PORT MAP(
--		rstn => rstn,
--		clkA => clk,
--		TaskStart_clkA => rReady,
--		TaskBusy_clkA => open,
--		TaskDone_clkA => rDone,
--		clkB => eclk,
--		TaskStart_clkB => rReady_e,
--		TaskBusy_clkB => open,
--		TaskDone_clkB => udpStopTx_i
--	);
	 din_mem(0) <= data0;
	 din_mem(1) <= data1;
	 din_mem(2) <= data2;
	 din_mem(3) <= data3;
	 din_mem(4) <= data4;
	 din_mem(5) <= data5;
	 din_mem(6) <= data6;
	 din_mem(7) <= data7;
	 din_mem(8) <= data8;
	 din_mem(9) <= data9;
	 din_mem(10) <= data10;
	 din_mem(11) <= data11;
	 din_mem(12) <= data12;
	 din_mem(13) <= data13;
	 din_mem(14) <= data14;
	 din_mem(15) <= data15;


	wea(0) <= wen;
	gen: for i in 0 to 15 generate
		dataMem : dMem port map (
			clka => clk, wea => wea, addra => wAddr, clkb => eclk, addrb => rAddr,
			dina => din_mem(i) , enb => ren(i), doutb => dout_mem(i));
		udprReady(i) <= rReady_e;
	end generate;

-- CrossDomain signals
	rReady_e <= rReady;
	rDone <= udpStopTx_i;
------------------------
	
	
	datalength_e(15 downto 13)	<= "000";
	datalength_e(12 downto 1) <= datalength_out;
	datalength_e(0) <= '0';
	udpStopTx <= udpStopTx_i;
	
	Inst_udpEventBuild: udpEventBuild2 PORT MAP(
		clk => eclk,
		rstn => rstn,
		mode => udpBuildMode,
		rReady => udprReady,
		timestamp => timestamp,
		ren => ren,
		data0 => dout_mem(0),
		data1 => dout_mem(1),
		data2 => dout_mem(2),
		data3 => dout_mem(3),
		data4 => dout_mem(4),
		data5 => dout_mem(5),
		data6 => dout_mem(6),
		data7 => dout_mem(7),
		data8 => dout_mem(8),
		data9 => dout_mem(9),
		data10=> dout_mem(10),
		data11=> dout_mem(11),
		data12=> dout_mem(12),
		data13=> dout_mem(13),
		data14=> dout_mem(14),
		data15=> dout_mem(15),
		rAddr => rAddr,
		frameCounterOut => frameCounterOut,
		datalength => datalength_e,
		eventInfoType => eventInfoType,
		eventInfoData => eventInfoData_i,
		txreq => txreq,
		txdone => txdone,
		txack => txack,
		dataout => dataout,
		udpLength => udpLength,
		udpPauseData => udpPauseData,
		frameEndEvent => frameEndEvent,
		udpStartTx => udpStartTx,
		udpStopTx => udpStopTx_i,
		chmask => chmask
	);

--	process(eclk, rstn)
--	begin
--		if rstn = '0' then
--			rAddr <= (others => '0');
--		elsif eclk'event and eclk = '1' then
--			if (ren(0) or ren(1)) = '1' then
--				rAddr <= rAddr + 1;
--			else
--				rAddr <= (others => '0');
--			end if;
--		end if;
--	end process;


end Behavioral;

