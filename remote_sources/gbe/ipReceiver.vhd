-------------------------------------------------------------------------------
-- Title: IP Receiver
-- Project: Gigabit Ethernet Link
-------------------------------------------------------------------------------
-- File: ipReceiver.vhd
-- Author: Alfonso Tarazona Martinez (ATM)
-- Company: NEXT Experiment (Universidad Politecnica de Valencia)
-- Last update:
-- Description: 
-------------------------------------------------------------------------------
-- Revisions:
-- Date                	Version  	Author  	Description
-- 
-------------------------------------------------------------------------------
-- More Information:
-------------------------------------------------------------------------------
--
-- IP Header Format
-- 
--  0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 19 30 31
-- ---------------------------------------------------------------------------------------
-- |Version|  IHL  |    Diff Services    |                 Total Length                  |
-- ---------------------------------------------------------------------------------------
-- |           Identification            | Flags  |           Fragment Offset            |
-- ---------------------------------------------------------------------------------------
-- |      TTL      |      Protocol       |                Header Checksum                |
-- ---------------------------------------------------------------------------------------
-- |                             Source IP Address                                       |
-- ---------------------------------------------------------------------------------------
-- |                           Destination IP Address                                    |
-- ---------------------------------------------------------------------------------------
--
-- Data
--
-- ---------------------------------------------------------------------------------------
-- |                                Options and Padding                                  |
-- ---------------------------------------------------------------------------------------
--
-- Version (4 bits):                 Specifies the format of the IP packet header
--                                   4 IP, Internet Protocol
-- IHL (4 bits):                     Specifies the length of the IP packet header in 32 
--                                   bit words. The minimum value for a valid header is 5
-- Differentiated Services (8 bits): Not used (0x00)
-- Total Length (8 bits):            Contains the length of the datagram
-- Identification (16 bits):         Used to identify the fragments of one datagram from 
--                                   those of another. Not used (0x0000)
-- Flags (3 bits)
-- Fragment Offset (13 bits):        Used to direct the reassembly of a fragmented 
--                                   datagram. Flags + Fragment Offset = 0x4000
-- TTL, Time To Live (8 bits):       A timer field used to track the lifetime of the 
--                                   datagram. When the TTL field is decremented down to 
--                                   zero, the datagram is discarded
--                                   Ignored, set as 0x40
-- Protocol (8 bits):                This field specifies the next encapsulated protocol
--                                   This field is set as 0x01 (ICMP) or 0x11 (UDP)
-- Header Checksum (16 bits):        A 16 bit one's complement checksum of the IP header 
--                                   and IP options
-- Options and Padding:              Not used
--
-- More details see http://www.networksorcery.com/enp/protocol/ip.htm
                           
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;
use work.ethernet_pkg.all;

entity ipReceiver is
   generic ( g_rxram_depth : natural := 14 );
	port (
		clk          : in  std_logic; 										-- Global clock
		rst          : in  std_logic;  										-- Global reset
		newFrame     : in  std_logic; 										-- New frame received from the layer below
		frameType    : in  std_logic; 										-- '0' for ARP and '1' for IP
		newByte      : in  std_logic;		 									-- Indicates a new byte in the stream
		frameByte    : in  std_logic_vector(7 downto 0); 	-- Byte received 
		endFrame     : in  std_logic; 										-- End of frame
		protocol     : out std_logic_vector(7 downto 0); 	-- Inticates type of protocol
		datagramSize : out std_logic_vector(15 downto 0); -- Length of the received frame
		sourceIP, destIP     : out std_logic_vector(31 downto 0); -- Indicates the source and destination IP
		canRead      : out std_logic; 										-- Indicates the Rx RAM memory can be read
		wrRAM        : out std_logic; 										-- Write enable of the Tx RAM memory
		wrAddr       : out std_logic_vector(g_rxram_depth - 1 downto 0); -- Address bus of the Tx RAM memory
		wrData       : out std_logic_vector(7 downto 0) 	-- Data bus of the Tx RAM memory
	);
end ipReceiver;
                 
architecture ipReceiver_arch of ipReceiver is

-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------
  -- counter signals
  signal cntBytes 			: std_logic_vector(g_rxram_depth - 1 downto 0);

	-- internal signals
	signal protocol_i 		: std_logic_vector(7 downto 0);
	signal datagramSize_i : std_logic_vector(15 downto 0);
	signal sourceIP_i, destIP_i 		: std_logic_vector(31 downto 0);

	--signal receivedChecksum : std_logic_vector(15 downto 0);

  type state is (s_idle, s_getIPBytes);
  signal currentState, nextState : state;

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
  process (currentState, newFrame, frameType, endFrame)
  begin
    case currentState is
      when s_idle =>
       if newFrame = '1' and frameType = '1' then
         nextState <= s_getIPBytes;
       else
         nextState <= s_idle;
       end if;
			 
			when s_getIPBytes =>
				if endFrame = '1' then
					nextState <= s_idle;
				else
					nextState <= s_getIPBytes;
				end if;
               
      when others =>                                            
        nextState <= s_idle;
    end case;
  end process;

  -- purpose: set outputs of the module and internal signals
  process (clk, rst)
  begin
    if rst = '1' then                  		
			datagramSize_i <= (others => '0');
			protocol_i     <= (others => '0');
			sourceIP_i     <= (others => '0');
			destIP_i     <= (others => '0');
			canRead        <= '0';
			wrRAM          <= '0';
			wrData         <= (others => '0');
      wrAddr         <= (others => '0');
	
    elsif clk'event and clk = '1' then 
      -- default signals
			canRead <= '0';
			wrRAM   <= '0';

      case currentState is
        when s_idle =>
          cntBytes <= (others => '0');
					if newFrame = '1' and frameType = '1' then
            -- cntBytes = 1 because the zero bit (first bit) has just been received
						cntBytes <= conv_std_logic_vector(1, g_rxram_depth);
          end if;

        when s_getIPBytes =>
          if newByte = '1' then
            cntBytes <= cntBytes + 1;
					
						case conv_integer(cntBytes) is
							-- stores the length of the frame
							when 2 | 3=>
								datagramSize_i <= datagramSize_i(7 downto 0) & frameByte;
							-- stores the type of protocol: 
							-- 0x01 for ICMP and 0x17 for UDP 
							when 9 =>
								protocol_i <= frameByte;
							-- stores the checksum
							--when 10 | 11 =>
								--receivedChecksum <= receivedChecksum(7 downto 0) & frameByte;
							-- stores source IP
							when 12 | 13 | 14 | 15 =>
								sourceIP_i <= sourceIP_i(23 downto 0) & frameByte;
							when 16 | 17 | 18 | 19 =>
								destIP_i <= destIP_i(23 downto 0) & frameByte;
							when others =>
								-- nothing
						end case;
						
						-- stores the data field of the IP datagram into the RAM
						if cntBytes >= 20 then
							-- when the first data is stored into the RAM (dual port) a signal is
							-- activated to indicate into the RAM there is a data and it can be 
							-- read. From here the data that is being received are written into 
							-- the RAM and read (so there always are data into the RAM)
							if cntBytes = 21 then
								canRead <= '1';
							end if;
							wrRAM  <= '1';
							wrData <= frameByte;
							wrAddr <= cntBytes - 20;
						end if;
					end if;
          
        when others =>
          -- nothing
      end case;
      
    end if;
  end process;
-------------------------------------------------------------------------------
-- End of three-process FSM
-------------------------------------------------------------------------------
  
	-- sets outputs
	-- datagramSize does not includes the bytes of the IP header (20 bytes)
	datagramSize <= datagramSize_i - 20;
	protocol     <= protocol_i;
	sourceIP     <= sourceIP_i;
	destIP     <= destIP_i;
	
end ipReceiver_arch;



