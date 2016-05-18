-------------------------------------------------------------------------------
-- Title: ARP Sender
-- Project: Gigabit Ethernet Link
-------------------------------------------------------------------------------
-- File: arpSender.vhd
-- Author: Alfonso Tarazona Martinez (ATM)
-- Company: NEXT Experiment (Universidad Politecnica de Valencia)
-- Last update: 2010/03/30
-- Description: 
-------------------------------------------------------------------------------
-- Revisions:
-- Date                	Version  	Author  	Description
-- 
-------------------------------------------------------------------------------
-- More Information:
-------------------------------------------------------------------------------
--
-- ARP Header Format
--
--  0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 19 30 31
-- ---------------------------------------------------------------------------------------
-- |            Hardware Type            |                 Protocol Type                 |
-- ---------------------------------------------------------------------------------------
-- |Hw Addr Length |Protocol Addr Length |                    Opcode                     |
-- ---------------------------------------------------------------------------------------
--
-- Data
--
-- ---------------------------------------------------------------------------------------
-- |                      Source hardware address (variable length)                      |
-- ---------------------------------------------------------------------------------------
-- |                      Source protocol address (variable length)                      |
-- ---------------------------------------------------------------------------------------
-- |                    Destination hardware address (variable length)                   |
-- ---------------------------------------------------------------------------------------
-- |                    Destination protocol address (variable length)                   |
-- ---------------------------------------------------------------------------------------
--
-- Hardware Type (16 bits):          0x0001 (Ethernet)
-- Protocol Type (16 bits):          0x0800 (IP)
-- Hardware Address Length (8 bits): Length of the hardware address in bytes
-- Protocol Address Length (8 bits): Length of the protocol address in bytes
-- Opcode (16 bits):                 Used 0x0001 (Request) or 0x0002 (Reply)
--
-- More details see http://www.networksorcery.com/enp/protocol/arp.htm

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.ethernet_pkg.all;

entity arpSender is
  port (
    clk              : in  std_logic;   									-- Clock (125 Mhz)
    rst              : in  std_logic;   									-- Asynchronous reset
	 fpga_mac: in std_logic_vector(47 downto 0);
	 fpga_ip: in std_logic_vector(31 downto 0);
		sendingFrame     : in  std_logic;
		genARPReply      : in  std_logic;										  -- Input from arp receiver layer requesting an ARP reply
		receivedARPReply : in  std_logic;                     -- Input from arp receiver layer saying an ARP reply frame has been received
		dstARPIP         : in  std_logic_vector(31 downto 0); -- Input from arp receiver layer saying the IP where to send the reply
		OKRequest		     : in  std_logic;										  -- Input from arp reciver layer indicating it contains the requested MAC
		lookupMAC		     : in  std_logic_vector(47 downto 0); -- Input from arp receiver layer giving the requested MAC
		startARPReply    : out std_logic;											-- Tells the arp sender layer the ARP reply has started to send		
		wrRAM				     : out std_logic;										  -- Write RAM signal to the Tx RAM
		wrData			     : out std_logic_vector(7 downto 0);	-- Write data bus to the Tx RAM
		wrAddr			     : out std_logic_vector(13 downto 0);	-- Write address bus to the Tx RAM
		sendARP		       : out std_logic; 										-- Tells the ethernet layer to send a datagram
		dstMAC			     : out std_logic_vector(47 downto 0) 	-- Tells the ethernet layer the destination MAC where to send the reply
  );
end arpSender;
                 
architecture arpSender_arch of arpSender is
-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------
  -- Counter signals
  signal cntBytes : std_logic_vector(13 downto 0);

	-- Target signals
	signal dstIP_i  : std_logic_vector(31 downto 0);
	signal dstMAC_i : std_logic_vector(47 downto 0);
  
  -- State signals
  type state is (s_idle, s_ARPReply, s_sendARPReply, s_ARPRequest, s_waitOKMAC);
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

  -- purpose: sets next state 
  process (currentState, genARPReply, cntBytes, OKRequest, lookupMAC, receivedARPReply, sendingFrame)
  begin
    case currentState is
      when s_idle =>
				if genARPReply = '1' then
					nextState <= s_ARPReply;
				elsif OKRequest = '0' and lookupMAC = X"FFFFFFFFFFFF" then
					nextState <= s_ARPRequest;
				else
					nextState <= s_idle;
				end if;
       
			when s_ARPReply =>
				if cntBytes = 27 then
					nextState <= s_sendARPReply;
				else
					nextState <= s_ARPReply;
				end if;
				
			when s_sendARPReply =>
				nextState <= s_idle;
--				if sendingFrame = '0' then
--					nextState <= s_idle;
--				else
--					nextState <= s_sendARPReply;
--				end if;
			
			when s_ARPRequest =>
				if cntBytes = 27 then
					nextState <= s_waitOKMAC;
				else
					nextState <= s_ARPRequest;
				end if;
			
			when s_waitOKMAC =>
				if receivedARPReply = '1' then
					if OKRequest = '1' and lookupMAC /= X"FFFFFFFFFFFF" then
						nextState <= s_idle;
					else
						nextState <= s_ARPRequest;
					end if;
				else
					nextState <= s_waitOKMAC;
				end if;
               
      when others =>                                            
        nextState <= s_idle;
    end case;
  end process;

  -- purpose: sets outputs of the module and internal signals 
  process (clk, rst)
  begin
    if rst = '1' then
			dstIP_i       <= (others => '0');
			dstMAC_i      <= (others => '0');
      sendARP       <= '0';								
			dstMAC        <= (others => '0');
			startARPReply <= '0';
			wrRAM         <= '0';						  
			wrData        <= (others => '0'); 					  
			wrAddr        <= (others => '0');				  
    elsif clk'event and clk = '1' then
      -- default signals
			startARPReply <= '0';			
			sendARP       <= '0';	
			wrRAM         <= '0';						  
			wrData        <= (others => '0'); 					  
			wrAddr        <= (others => '0');
      
      case currentState is
        when s_idle =>
					cntBytes <= (others => '0');
					if genARPReply = '1' then
						dstIP_i       <= dstARPIP;
						dstMAC_i      <= lookupMAC;
						startARPReply <= '1';
					elsif OKRequest = '0' and lookupMAC = X"FFFFFFFFFFFF" then
						dstIP_i  <= dstARPIP;
						dstMAC_i <= X"FFFFFFFFFFFF";
					end if;
        
				when s_ARPReply =>
					cntBytes <= cntBytes + 1;
					wrRAM    <= '1';
					wrAddr   <= cntBytes;
					
					case conv_integer(cntBytes) is
							-- hardware type MSB
							when 0 =>
								wrData <= X"00";
							-- hardware type LSB
							when 1 =>
								wrData <= X"01";
							-- protocol type MSB
							when 2 =>
								wrData <= X"08";
							-- protocol type LSB
							when 3 =>
								wrData <= X"00";
							-- hardware address length (in bytes)
							when 4 =>
								wrData <= X"06";
							-- protocol address length (in bytes)
							when 5 =>
								wrData <= X"04";
							-- operation MSB
							when 6 =>
								wrData <= X"00";
							-- operation LSB
							when 7 =>
								wrData <= X"02";
							-- sender hardware address byte 0
							when 8 =>
								wrData <= FPGA_MAC(47 downto 40);
							-- sender hardware address byte 1
							when 9 =>
								wrData <= FPGA_MAC(39 downto 32);
							-- sender hardware address byte 2
							when 10 =>
								wrData <= FPGA_MAC(31 downto 24);
							-- sender hardware address byte 3
							when 11 =>
								wrData <= FPGA_MAC(23 downto 16);
							-- sender hardware address byte 4
							when 12 =>
								wrData <= FPGA_MAC(15 downto 8);
							-- sender hardware address byte 5
							when 13 =>
								wrData <= FPGA_MAC(7 downto 0);
							-- sender IP address byte 0
							when 14 =>
								wrData <= FPGA_IP(31 downto 24);
							-- sender IP address byte 1
							when 15 =>
								wrData <= FPGA_IP(23 downto 16);
							-- sender IP address byte 2
							when 16 =>
								wrData <= FPGA_IP(15 downto 8);
							-- sender IP address byte 3
							when 17 =>
								wrData <= FPGA_IP(7 downto 0);
							-- target hardware address byte 0
							when 18 =>
								wrData <= dstMAC_i(47 downto 40);
							-- target hardware address byte 1
							when 19 =>
								wrData <= dstMAC_i(39 downto 32);
							-- target hardware address byte 2
							when 20 =>
								wrData <= dstMAC_i(31 downto 24);
							-- target hardware address byte 3
							when 21 =>
								wrData <= dstMAC_i(23 downto 16);
							-- target hardware address byte 4
							when 22 =>
								wrData <= dstMAC_i(15 downto 8);
							-- target hardware address byte 5
							when 23 =>
								wrData <= dstMAC_i(7 downto 0);
							-- target IP address byte 0
							when 24 =>
								wrData <= dstIP_i(31 downto 24);
							-- target IP address byte 1
							when 25 =>
								wrData <= dstIP_i(23 downto 16);
							-- target IP address byte 2
							when 26 =>
								wrData <= dstIP_i(15 downto 8);
							-- target IP address byte 3
							when 27 =>
								wrData <= dstIP_i(7 downto 0);
							when others =>
								-- nothing
						end case;
				
				when s_sendARPReply =>
					sendARP <= '1';
					dstMAC <= dstMAC_i;
				
				when s_ARPRequest =>
					cntBytes <= cntBytes + 1;
					wrRAM    <= '1';
					wrAddr   <= cntBytes;
					
					case conv_integer(cntBytes) is
							-- hardware type MSB
							when 0 =>
								wrData <= X"00";
							-- hardware type LSB
							when 1 =>
								wrData <= X"01";
							-- protocol type MSB
							when 2 =>
								wrData <= X"08";
							-- protocol type LSB
							when 3 =>
								wrData <= X"00";
							-- hardware address length (in bytes)
							when 4 =>
								wrData <= X"06";
							-- protocol address length (in bytes)
							when 5 =>
								wrData <= X"04";
							-- operation MSB
							when 6 =>
								wrData <= X"00";
							-- operation LSB
							when 7 =>
								wrData <= X"01";
							-- sender hardware address byte 0
							when 8 =>
								wrData <= FPGA_MAC(47 downto 40);
							-- sender hardware address byte 1
							when 9 =>
								wrData <= FPGA_MAC(39 downto 32);
							-- sender hardware address byte 2
							when 10 =>
								wrData <= FPGA_MAC(31 downto 24);
							-- sender hardware address byte 3
							when 11 =>
								wrData <= FPGA_MAC(23 downto 16);
							-- sender hardware address byte 4
							when 12 =>
								wrData <= FPGA_MAC(15 downto 8);
							-- sender hardware address byte 5
							when 13 =>
								wrData <= FPGA_MAC(7 downto 0);
							-- sender IP address byte 0
							when 14 =>
								wrData <= FPGA_IP(31 downto 24);
							-- sender IP address byte 1
							when 15 =>
								wrData <= FPGA_IP(23 downto 16);
							-- sender IP address byte 2
							when 16 =>
								wrData <= FPGA_IP(15 downto 8);
							-- sender IP address byte 3
							when 17 =>
								wrData <= FPGA_IP(7 downto 0);
							-- target hardware address byte 0
							when 18 =>
								wrData <= X"00";
							-- target hardware address byte 1
							when 19 =>
								wrData <= X"00";
							-- target hardware address byte 2
							when 20 =>
								wrData <= X"00";
							-- target hardware address byte 3
							when 21 =>
								wrData <= X"00";
							-- target hardware address byte 4
							when 22 =>
								wrData <= X"00";
							-- target hardware address byte 5
							when 23 =>
								wrData <= X"00";
							-- target IP address byte 0
							when 24 =>
								wrData <= dstIP_i(31 downto 24);
							-- target IP address byte 1
							when 25 =>
								wrData <= dstIP_i(23 downto 16);
							-- target IP address byte 2
							when 26 =>
								wrData <= dstIP_i(15 downto 8);
							-- target IP address byte 3
							when 27 =>
								wrData  <= dstIP_i(7 downto 0);
								dstMAC  <= dstMAC_i;
								sendARP <= '1';
							when others =>
								-- nothing
						end case;
					
				when s_waitOKMAC =>
						-- nothing
        
				when others =>                                            
          -- nothing
      end case;
    end if;
  end process;
-------------------------------------------------------------------------------
-- End of three-process FSM
-------------------------------------------------------------------------------

end arpSender_arch;



