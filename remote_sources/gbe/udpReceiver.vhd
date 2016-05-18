-------------------------------------------------------------------------------
-- Title: UDP Receiver
-- Project: Gigabit Ethernet Link
-------------------------------------------------------------------------------
-- File: udpReceiver.vhd
-- Author: Alfonso Tarazona Martinez (ATM)
-- Company: NEXT Experiment (Universidad Politecnica de Valencia)
-- Last update: 2010/05/25
-- Description: 
-------------------------------------------------------------------------------
-- Revisions:
-- Date                	Version  	Author  	Description
-- 
-------------------------------------------------------------------------------
-- More Information:
-------------------------------------------------------------------------------
--
-- UDP Header Format
--
--  0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 19 30 31
-- ---------------------------------------------------------------------------------------
-- |             Source Port             |               Destination Port                |
-- ---------------------------------------------------------------------------------------
-- |               Length                |                   Checksum                    |
-- ---------------------------------------------------------------------------------------
--
-- Data
--
-- ---------------------------------------------------------------------------------------
-- |                                       Data...                                       |
-- ---------------------------------------------------------------------------------------
--
-- Source Port (16 bits):      The port number of the sender. Cleared to zero if not used
-- Destination Port (16 bits): The port this packet is addressed to
-- Length (16 bits):           The length in bytes of the UDP header and the encapsulated 
--                             data. The minimum value for this field is 8
-- Checksum (16 bits):         Computed as the 16-bit one's complement of the one's 
--                             complement sum of a pseudo header of information from the 
--                             IP header, the UDP header, and the data, padded as needed 
--                             with zero bytes at the end to make a multiple of two bytes 
--                             If the checksum is cleared to zero, then checksuming is 
--                             disabled. If the computed checksum is zero, then this field 
--                             must be set to 0xFFFF
-- Data (variable length)
--
-- More details see http://www.networksorcery.com/enp/protocol/udp.htm

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;
use work.ethernet_pkg.all;

entity udpReceiver is
   generic ( g_rxram_depth : natural := 14 );
	port (
		clk          : in  std_logic; 										-- Global clock
		rst          : in  std_logic;  										-- Global reset 
		canRead			 : in  std_logic;											-- Indicates you can read data from the Rx RAM
		datagramSize : in  std_logic_vector(15 downto 0);	-- Size of the arrived datagram
		protocol  	 : in  std_logic_vector(7 downto 0); 	-- Protocol type of the datagram
		rdData			 : in  std_logic_vector(7 downto 0); 	-- Read data bus from the Rx RAM
		rdRAM				 : out std_logic;											-- Asserteds to tell the Rx RAM to read
		rdAddr			 : out std_logic_vector(g_rxram_depth - 1 downto 0); -- Read address bus to the Rx RAM	
		sourceIP, destIP : in std_logic_vector(31 downto 0);
			-- Backend
		sourceIP_out : out std_logic_vector(31 downto 0); 
		dstPort : out std_logic_vector(15 downto 0);
		checksum_out : out std_logic_vector(15 downto 0);
		portAck : in std_logic;
		startTx, datavalid			 : out std_logic;
		dataout: out std_logic_vector(7 downto 0)
	);
end udpReceiver;
                 
architecture udpReceiver_arch of udpReceiver is
-------------------------------------------------------------------------------
-- Components
-------------------------------------------------------------------------------
	component calculateChecksum is
		port (
			clk         : in  std_logic;           					 -- Clock
			rst         : in  std_logic;           					 -- Asynchronous reset
			iniChecksum : in  std_logic_vector(15 downto 0); -- Default checksum
			newChecksum : in  std_logic;           					 -- Indicates new checksum
			newByte     : in  std_logic;           					 -- Indicates new byte
			inByte      : in  std_logic_vector(7 downto 0);  -- Byte to calculate
			checksum    : out std_logic_vector(15 downto 0)  -- Current checksum
		);
	end component;

-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------
	-- counter signals
  signal cntBytes      : std_logic_vector(g_rxram_depth - 1 downto 0);
	
	-- signals to calculate the checksum
	signal newChecksum_i : std_logic;
	signal newByte_i     : std_logic;
	signal inByte_i      : std_logic_vector(7 downto 0);
	signal checksum_i    : std_logic_vector(15 downto 0);
  signal pseudoheader1Sum: std_logic_vector(18 downto 0);
  signal pseudoheader: std_logic_vector(15 downto 0);

attribute KEEP : string;
attribute KEEP of checksum_i: signal is "TRUE";
	
	-- store the length (in bytes) of the IP datagram
	signal datagramSize_i : std_logic_vector(15 downto 0);
	
  type state is (s_idle, s_waitDataFromRxRAM, s_rdUDPByteFromRxRAM);
  signal currentState, nextState : state;

	signal word, header0, header1 : std_logic_vector(31 downto 0);

	signal datavalid_i: std_logic;
	signal dataout_i : std_logic_vector(7 downto 0);
	signal dstPort_i : std_logic_vector(15 downto 0);
begin
-------------------------------------------------------------------------------
-- Three-process FSM
-------------------------------------------------------------------------------
  -- purpose: state machine driver
  process (clk, rst)
  begin 
    if rst = '1' then                   
      currentState <= s_idle;
    elsif clk'event and clk = '1' then 
      currentState <= nextState;
    end if;
  end process;

  -- purpose: set next state 
  process (currentState, canRead, protocol, cntBytes, rdData, datagramSize_i, portAck)
  begin
    case currentState is
      when s_idle =>
				if canRead = '1' and protocol = X"11" then
					nextState <= s_waitDataFromRxRAM;
				else
					nextState <= s_idle;
				end if;
			
			when s_waitDataFromRxRAM =>
				nextState <= s_rdUDPByteFromRxRAM;
				
			when s_rdUDPByteFromRxRAM =>
				if (cntBytes = datagramSize_i) or ((portAck = '0') and (cntBytes > 13)) then
					nextState <= s_idle;
				else
					nextState <= s_rdUDPByteFromRxRAM;
				end if;
					
      when others =>                                            
        nextState <= s_idle;
    end case;
  end process;

  -- purpose: set outputs of the module and internal signals
  process (clk, rst)
  begin
    if rst = '1' then                  
			newChecksum_i <= '0';
			newByte_i     <= '0';
			checksum_out      <= (others => '0');
			word <= (others => '0');
			cntBytes <= (others => '0');
			rdRAM         <= '0';
			rdAddr        <= (others => '0');
			dstPort_i       <= (others => '0'); 
			sourceIP_out  <= (others => '0'); 
			
			dataout_i <= (others => '0');
			datavalid_i <= '0';
			
			dataout <= (others => '0');
			datavalid <= '0';
			
    elsif clk'event and clk = '1' then 
		-- delay dataout signals
			dataout <= dataout_i;
			datavalid <= datavalid_i;
			--
			checksum_out <= not checksum_i;
      -- default signals
			newChecksum_i <= '0';
			newByte_i     <= '0';
--			inByte_i      <= (others => '0');
			--startTx <= '0';
			
      case currentState is
        when s_idle =>
					cntBytes <= (others => '0');
					rdRAM <= '0';
					rdAddr <= (others => '0');
					dstPort_i <= (others => '0'); 
					sourceIP_out  <= (others => '0'); 
						dataout_i <= x"CA";
						datavalid_i <= '0';
					if canRead = '1' and protocol = X"11" then
						sourceIP_out <= sourceIP;
						rdRAM <= '1';
						newChecksum_i <= '1';
						-- size of the header ICMP + data
						datagramSize_i <= datagramSize;
					end if;
				
				when s_waitDataFromRxRAM =>
					-- increases bytes counter
					cntBytes <= cntBytes + 1;
					rdAddr <= cntBytes + 1;
						dataout_i <= x"CA";
						datavalid_i <= '0';
						newByte_i <= '1';
				
				when s_rdUDPByteFromRxRAM =>
						newByte_i <= '1';
					-- increases bytes counter
					cntBytes <= cntBytes + 1;
					rdAddr <= cntBytes + 1;
					if cntBytes = 3 then
						dstPort_i(15 downto 8) <= rdData;
					end if;
					if cntBytes = 4 then
						dstPort_i(7 downto 0) <= rdData;
					end if;
					if cntBytes = 9 or cntBytes = 10 or cntBytes = 11 or cntBytes = 12 then
						word <= word(23 downto 0) & rdData;
					end if;
					if cntBytes >= 1 then
						dataout_i <= rdData;
						datavalid_i <= '1';
					else
						dataout_i <= x"CA";
						datavalid_i <= '0';
					end if;
					
--					if word = X"61616161" then
--						startTx <= '1';
--					end if;
				
				when others =>
						dataout_i <= x"CA";
						datavalid_i <= '0';
					-- nothing
			end case;
    end if;
  end process;
-------------------------------------------------------------------------------
-- End of three-process FSM
-------------------------------------------------------------------------------
	pseudoheader1Sum <= 	("000"&sourceIP(31 downto 16)) + 
								("000"&sourceIP(15 downto 0)) + 
								("000"&destIP(31 downto 16)) + 
								("000"&destIP(15 downto 0)) +
								("000"&X"0011") + 
								("000"&datagramSize);
	pseudoheader <= pseudoheader1Sum(15 downto 0) + ("0000000000000"&pseudoheader1Sum(18 downto 16));
	inByte_i <= rdData;

	CHECKSUM : component calculateChecksum port map (
		clk         => clk,
		rst         => rst,
		iniChecksum => pseudoheader,
		newChecksum => newChecksum_i,
		newByte     => newByte_i,
		inByte      => inByte_i,
		checksum    => checksum_i
	);

	startTx <= '1' when (word = X"61616161") and (dstPort_i = x"1776") and (cntBytes = 13) else '0';

	dstPort <= dstPort_i;

end udpReceiver_arch;