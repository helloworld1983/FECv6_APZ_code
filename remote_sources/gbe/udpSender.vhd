-------------------------------------------------------------------------------
-- Title: UDP Sender
-- Project: Gigabit Ethernet Link
-------------------------------------------------------------------------------
-- File: udpSender.vhd
-- Author: Alfonso Tarazona Martinez (ATM)
-- Company: NEXT Experiment (Universidad Politecnica de Valencia)
-- Last update: 2010/05/04
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

entity udpSender is
	port (
		clk             : in  std_logic; 										 -- Global clock
		rst             : in  std_logic;  									 -- Global reset
	 fpga_ip: in std_logic_vector(31 downto 0);
		synRdWrTxRAM    : in  std_logic;										 -- Signal to synchronize the reading and writting operations in the Tx RAM
		busyIPSender    : in  std_logic;							       -- Signal to indicate ipSender is busy
		startTx         : in  std_logic;                     -- Starts to read the data that want to be sent
		stopTx          : in  std_logic;										 -- Stops the reading of data
		enChecksum	    : in  std_logic;										 -- Enables UDP checksum
		numFramesEvent  : in  std_logic_vector(6 downto 0);  -- Number of frames by event
		srcPort			    : in  std_logic_vector(15 downto 0); -- Source port
		dstPort			    : in  std_logic_vector(15 downto 0); -- Destination port
		lengthUDP_in    : in  std_logic_vector(15 downto 0); -- Length UDP datagram
		dstIP_in		    : in  std_logic_vector(31 downto 0); -- Destination IP
		data				    : in  std_logic_vector(7 downto 0);  -- Input data (byte-by-byte)
		framedly			    : in  std_logic_vector(15 downto 0);  -- frame delay parameter
		daqtotFrames	    : in  std_logic_vector(15 downto 0);  -- 
		daqresume 	    : in  std_logic;
		pauseData, frameEndEventOut       : out std_logic;                     -- Signals to pause the data input 
		sentData        : out std_logic;                     -- Indicates upper layers that data have been sent
		sentEvent       : out std_logic;  									 -- Tells etherner sender layer that the event has been sent
		offsetAddr      : out std_logic_vector(13 downto 0); -- Tells ipSender layer when it has to write/read into the memory
		wrRAM				    : out std_logic;										 -- Asserteds to tell the RAM to write
		wrData			    : out std_logic_vector(7 downto 0);  -- Write data bus to the RAM
		wrAddr			    : out std_logic_vector(13 downto 0); -- Write addres bus to the RAM
		sendUDP         : out std_logic;										 -- Tells the IP layer to send a datagram
		lengthUDP_out   : out std_logic_vector(15 downto 0); -- Length IP datagram
		dstIP_out       : out std_logic_vector(31 downto 0); -- Target IP of the datagram
		totFrames       : out std_logic_vector(11 downto 0)
	);
end udpSender;
                 
architecture udpSender_arch of udpSender is
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
  signal cntFramesEvent : std_logic_vector(6 downto 0); 
	signal cntBytes       : std_logic_vector(13 downto 0);
	signal cntRAM         : std_logic_vector(13 downto 0);
	
	signal cntTotFrames         : std_logic_vector(11 downto 0);
	
	signal frameEndEvent  : std_logic;
	
	-- signals to calculate the checksum
	signal newChecksum_i  : std_logic;
	signal newByte_i      : std_logic;
	signal inByte_i       : std_logic_vector(7 downto 0);
	signal iniChecksum_i  : std_logic_vector(15 downto 0);
	signal checksum_i     : std_logic_vector(15 downto 0);
	
	-- stores the source and destination port respetively
	signal srcPort_i      : std_logic_vector(15 downto 0);
	signal dstPort_i      : std_logic_vector(15 downto 0);
	
	-- stores the length (in bytes) of the IP datagram
	signal lengthUDP_i    : std_logic_vector(15 downto 0);
	
	-- address to indicate ipSender the start of the frame into the RAM
	signal offsetAddr_i   : std_logic_vector(13 downto 0);
	
	type state is (s_idle, s_parametersUDPFrame, s_parametersUDPFrame2, s_parametersUDPFrameEndEvent, 
	               s_wrUDPDatagram, s_wrChecksumUpperByte, s_wrChecksumLowerByte, 
								 s_checkTxCh, s_synRdWrTxRAM, s_waitFrameDly);
  signal currentState, nextState : state;
  
  -- frame delay counter
  signal framedlycnt : std_logic_vector(19 downto 0);
  signal framedlyexp : std_logic;
  
  signal daqEvent : std_logic;
  signal daqframecnt : std_logic_vector(15 downto 0);

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

	frameEndEventOut <= frameEndEvent;

  -- purpose: set next state 
  process (currentState, startTx, cntBytes, stopTx, busyIPSender, synRdWrTxRAM, 
	         lengthUDP_i, cntFramesEvent, numFramesEvent, frameEndEvent, framedlyexp,
				daqresume, daqEvent, daqframecnt, daqtotFrames)
  begin
    case currentState is
      when s_idle =>
				if startTx = '1' then
					nextState <= s_parametersUDPFrame;
				else
					nextState <= s_idle;
				end if;
			
			when s_parametersUDPFrame =>
				nextState <= s_wrUDPDatagram;

			when s_parametersUDPFrame2 =>
				nextState <= s_wrUDPDatagram;
			
			when s_parametersUDPFrameEndEvent =>
				nextState <= s_wrUDPDatagram;
			
			when s_wrUDPDatagram =>
				if cntBytes = lengthUDP_i then
					nextState <= s_wrChecksumUpperByte;
				-- there still are bytes to be sent of the current frame
				else
					nextState <= s_wrUDPDatagram;
				end if;
			
			when s_wrChecksumUpperByte =>
				nextState <= s_wrChecksumLowerByte;
			
			when s_wrChecksumLowerByte =>
				if busyIPSender = '0' then
					-- all frames have been sent
--					if stopTx = '1' then
--						nextState <= s_idle;
--					-- there still are frames to be sent
--					else
						nextState <= s_checkTxCh;
--					end if;
				-- cannot send out the frame to ipSender (ipSender is busy), so it
				-- waits until ipSender is free
				else
					nextState <= s_wrChecksumLowerByte;
				end if;
			
			when s_checkTxCh =>
				if busyIPSender = '0' then
					nextState <= s_synRdWrTxRAM;
				else
					nextState <= s_checkTxCh;
				end if;
			
			when s_synRdWrTxRAM =>
				if synRdWrTxRAM = '1' then
					nextState <= s_waitFrameDly;
--					if cntFramesEvent /= numFramesEvent then
--						nextState <= s_wrUDPDatagram;
--					else
--					-- check frame delay counter
--						if framedlyexp = '1' then
--							if frameEndEvent = '0' then
--								nextState <= s_parametersUDPFrameEndEvent;
--							else
--								nextState <= s_parametersUDPFrame;
--							end if;
--						else
--							nextState <= s_waitFrameDly;
--						end if;
--					end if;
				else
					nextState <= s_synRdWrTxRAM;
				end if;
			when 	s_waitFrameDly =>
				if daqEvent = '1' and daqframecnt > daqtotFrames and daqresume = '0' then
					nextState <= s_waitFrameDly;
				elsif stopTx = '1' then
					nextState <= s_idle;
				-- there still are frames to be sent
				elsif framedlyexp = '1' then
					if cntFramesEvent /= numFramesEvent then
--						nextState <= s_wrUDPDatagram;
						-- reads udp parameters again (SM)
						nextState <= s_parametersUDPFrame2;
					else
						if frameEndEvent = '0' then
							nextState <= s_parametersUDPFrameEndEvent;
						else
							nextState <= s_parametersUDPFrame;
						end if;
					end if;
				else
					nextState <= s_waitFrameDly;
				end if;
				
      when others =>                                            
        nextState <= s_idle;
    end case;
  end process;
	
	totFrames <= (others => '0');
	
  -- purpose: set outputs of the module and internal signals
  process (clk, rst)
	
		variable seudoheader : std_logic_vector(19 downto 0);
	
  begin
    if rst = '1' then                  
			frameEndEvent   <= '0';
			cntFramesEvent  <= (others => '0');
			cntBytes        <= (others => '0');
			cntRAM          <= conv_std_logic_vector(20, 14);
			newChecksum_i   <= '0';
			newByte_i       <= '0';
			inByte_i        <= (others => '0');
			offsetAddr_i    <= (others => '0');
			lengthUDP_i     <= (others => '0');
			pauseData       <= '1';
			sentData        <= '0';
			sentEvent 			<= '0';
			offsetAddr      <= (others => '0');
			wrRAM           <= '0';
			wrData          <= (others => '0');
			wrAddr          <= (others => '0');
			sendUDP         <= '0';
			lengthUDP_out   <= (others => '0');
			dstIP_out       <= (others => '0');
			
			cntTotFrames <= (others => '0');
			framedlycnt <= (others => '0');
			daqEvent		  <= '0';
			daqframecnt      <= (others => '0'); 
			
    elsif clk'event and clk = '1' then 
      -- default signals
			newChecksum_i <= '0';
			newByte_i     <= '0';
			inByte_i      <= (others => '0');
			pauseData     <= '1';
			sentData      <= '0';
			wrRAM         <= '0';
			sendUDP       <= '0';
			
      case currentState is
        when s_idle =>
					frameEndEvent   <= '0';
					cntFramesEvent  <= (others => '0');
					cntBytes        <= (others => '0');
					cntRAM          <= conv_std_logic_vector(20, 14);
					sentEvent       <= '0';
					
					cntTotFrames <= (others => '0');
					framedlycnt <= (others => '0');
					if (startTx = '1') and (stopTx = '0') and (daqtotFrames /= 0) then
						daqEvent <= '1';
					else
						daqEvent <= '0';
					end if;
--					totFrames    <= (others => '0');
				
				when s_parametersUDPFrame =>
					if cntTotFrames = 3728 then
						cntTotFrames <= conv_std_logic_vector(1, 12);
					else
						cntTotFrames <= cntTotFrames + 1;
					end if;
					frameEndEvent  <= '0';
					cntFramesEvent <= (others => '0');
					newChecksum_i  <= '1';
					srcPort_i      <= srcPort;
					dstPort_i      <= dstPort;
					lengthUDP_i    <= lengthUDP_in;
					-- calculates the one's complement sum of the pseudo header
					seudoheader    := X"00000" + FPGA_IP(31 downto 16) + FPGA_IP(15 downto 0) + 
							              dstIP_in(31 downto 16) + dstIP_in(15 downto 0) + X"0011" + 
												    lengthUDP_in;
					seudoheader    := X"00000" + seudoheader(19 downto 16) + seudoheader(15 downto 0);
					-- calculates the one's complement sum of the pseudo header and UDP header
					seudoheader    := seudoheader + srcPort + dstPort + lengthUDP_in;
					iniChecksum_i  <= seudoheader(15 downto 0);
					lengthUDP_out  <= lengthUDP_in;
					dstIP_out      <= dstIP_in;
					-- reset frame delay counter
					framedlycnt <= (others => '0');
				
				
				when s_parametersUDPFrame2 =>
					if cntTotFrames = 3728 then
						cntTotFrames <= conv_std_logic_vector(1, 12);
					else
						cntTotFrames <= cntTotFrames + 1;
					end if;
					frameEndEvent  <= '0';
					--cntFramesEvent <= (others => '0');
					newChecksum_i  <= '1';
					srcPort_i      <= srcPort;
					dstPort_i      <= dstPort;
					lengthUDP_i    <= lengthUDP_in;
					-- calculates the one's complement sum of the pseudo header
					seudoheader    := X"00000" + FPGA_IP(31 downto 16) + FPGA_IP(15 downto 0) + 
							              dstIP_in(31 downto 16) + dstIP_in(15 downto 0) + X"0011" + 
												    lengthUDP_in;
					seudoheader    := X"00000" + seudoheader(19 downto 16) + seudoheader(15 downto 0);
					-- calculates the one's complement sum of the pseudo header and UDP header
					seudoheader    := seudoheader + srcPort + dstPort + lengthUDP_in;
					iniChecksum_i  <= seudoheader(15 downto 0);
					lengthUDP_out  <= lengthUDP_in;
					dstIP_out      <= dstIP_in;
					-- reset frame delay counter
					framedlycnt <= (others => '0');
				
				when s_parametersUDPFrameEndEvent =>
					if cntTotFrames = 3728 then
						cntTotFrames <= (others => '0');
					end if;
					frameEndEvent <= '1';
					newChecksum_i <= '1';
					srcPort_i     <= srcPort;
					dstPort_i     <= dstPort;
					lengthUDP_i   <= X"000C";
					-- calculates the one's complement sum of the pseudo header
					seudoheader   := X"00000" + FPGA_IP(31 downto 16) + FPGA_IP(15 downto 0) + 
							             dstIP_in(31 downto 16) + dstIP_in(15 downto 0) + X"0011" + 
												   X"000C";
					seudoheader   := X"00000" + seudoheader(19 downto 16) + seudoheader(15 downto 0);
					-- calculates the one's complement sum of the pseudo header and UDP header
					seudoheader    := seudoheader + srcPort + dstPort + X"000C";
					iniChecksum_i <= seudoheader(15 downto 0);
					lengthUDP_out <= X"000C";
					dstIP_out     <= dstIP_in;
					-- reset frame delay counter
					framedlycnt <= (others => '0');
				
				when s_wrUDPDatagram =>
					framedlycnt <= (others => '0');
					sentEvent <= '0';
					-- data input control
--					if cntBytes >= 6 and cntBytes <= lengthUDP_i-3 and frameEndEvent = '0' then
--						pauseData <= '0';
--					end if;
					if cntBytes >= 4 and cntBytes <= lengthUDP_i-5 and frameEndEvent = '0' then	-- signal anticipated (2 clk) to allow FF insertion for timing
						pauseData <= '0';
					end if;
					-- indicates new bytes to the module that caultales the checksum
					-- of the IP header
					newByte_i <= '1';
					-- increases the counters
					if cntBytes <= lengthUDP_i-1 then
						cntBytes <= cntBytes + 1;
						cntRAM <= cntRAM + 1;
					end if;
					-- sets the signals to write data into the tx IP RAM
					if cntBytes = lengthUDP_i then
						wrRAM  <= '0';
					else
						wrRAM  <= '1';
					end if;
					wrAddr <= cntRAM;
					-- writes one IP byte into the RAM according the value of the bytes counter
					case conv_integer(cntBytes) is
						-- source port upper byte
						when 0 =>
							wrData <= srcPort_i(15 downto 8);
							offsetAddr_i <= cntRAM - 20;
						-- source port lower byte
						when 1 =>
							wrData <= srcPort_i(7 downto 0);
						-- destination port upper byte
						when 2 =>
							wrData <= dstPort_i(15 downto 8);
						-- destination port lower byte
						when 3 =>
							wrData <= dstPort_i(7 downto 0);
						-- length upper byte
						when 4 =>
							wrData <= lengthUDP_i(15 downto 8);
						-- length port lower byte
						when 5 =>
							wrData <= lengthUDP_i(7 downto 0);
						-- checksum upper byte, writes 0's for now
						when 6 =>
							wrData <= X"00";
						-- checksum port lower byte, writes 0's for now
						when 7 =>
							wrData <= X"00";
						when others =>
							-- indicates new bytes to the module that caultales the checksum
							-- of the UDP header
							newByte_i <= '1';
							if frameEndEvent = '0' then
								wrData    <= data;
								inByte_i  <= data;
							else
								wrData    <= X"FA";
								inByte_i  <= X"FA";
							end if;
					end case;
					
				when s_wrChecksumUpperByte =>
					wrRAM <= '1';
					wrAddr <= conv_std_logic_vector(conv_integer(offsetAddr_i) + 26, 14);
					if enChecksum = '1' then
						wrData <= checksum_i(15 downto 8);
					else
						wrData <= (others => '0');
					end if;
					
				when s_wrChecksumLowerByte =>
					if busyIPSender = '0' then
						-- sets counters
						cntBytes <= (others => '0');
						cntRAM <= cntRAM + 20;
						wrRAM <= '1';
						wrAddr <= conv_std_logic_vector(conv_integer(offsetAddr_i) + 27, 14);
						if enChecksum = '1' then
							wrData <= checksum_i(7 downto 0);
						else
							wrData <= (others => '0');
						end if;
						-- counts the sent frames of the event and activates the sentEvent signal
						-- when the cntFramesEvent = numFramesEvent and the end of event frame 
						-- has been sent
						if frameEndEvent = '0' then
							cntFramesEvent   <= cntFramesEvent + 1;
							if cntFramesevent = 0 then
								sentEvent <= '1';
							end if;
						end if;
						offsetAddr <= offsetAddr_i;
						sendUDP <= '1';
--						totFrames <= cntTotFrames;
						-- all data have been sent
						if stopTx = '1' then
							sentData <= '1';
						end if;
					end if;
				
				-- if the sendUDP and sendICMP signals of udpSender and icmp layer coincide,
				-- the UDP frame would be discarded, since icmp layer has priority over
				-- udpSender layer. So that does not happen if the tx channel was taken by 
				-- icmp layer. If the tx channel was token by icmp layer, udpSender layer
				-- waits until the tx channel is released
				when s_checkTxCh =>
					if busyIPSender = '0' then
						sendUDP <= '1';
					end if;
					-- reset frame delay counter
				when s_synRdWrTxRAM =>
					-- nothing
					if nextstate = s_waitFrameDly and daqEvent = '1' then
						daqframecnt <= daqframecnt + 1;
					end if;
				when s_waitFrameDly =>
					if daqEvent = '1' and daqframecnt > daqtotFrames then
						if daqresume = '1' then
							daqframecnt <= (others => '0');
						end if;
					end if;
					-- frame delay counter
					if framedlyexp = '0' then
						framedlycnt <= framedlycnt + 1;
					end if;
				when others =>
					-- nothing
			end case;
    end if;
  end process;
-------------------------------------------------------------------------------
-- End of three-process FSM
-------------------------------------------------------------------------------
	
	framedlyexp <= '1' when framedlycnt(19 downto 4) >= framedly else '0';
	
	CHECKSUM : component calculateChecksum 
		port map (
			clk         => clk,
			rst         => rst,
			iniChecksum => iniChecksum_i,
			newChecksum => newChecksum_i,
			newByte     => newByte_i,
			inByte      => inByte_i,
			checksum    => checksum_i
		);
	
end udpSender_arch;