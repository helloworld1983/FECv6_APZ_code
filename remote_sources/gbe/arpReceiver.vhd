-------------------------------------------------------------------------------
-- Title: ARP Receiver
-- Project: Gigabit Ethernet Link
-------------------------------------------------------------------------------
-- File: arpReceiver.vhd
-- Author: Alfonso Tarazona Martinez (ATM)
-- Company: NEXT Experiment (Universidad Politecnica de Valencia)
-- Last update: 2010/02/10
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
use ieee.std_logic_arith.all;

library work;
use work.ethernet_pkg.all;

entity arpReceiver is
  port (
    clk              : in  std_logic;   										-- Clock (125 Mhz)
    rst              : in  std_logic;   										-- Asynchronous reset
	 fpga_mac: in std_logic_vector(47 downto 0);
	 fpga_ip: in std_logic_vector(31 downto 0);
    newFrame         : in  std_logic;   										-- From ethernet layer it indicates the arrival of a new frame
    frameType        : in  std_logic;   								  	-- Kind of frame, 0 for ARP and 1 for IP
    newByte          : in  std_logic;   										-- Indicates new byte
    frameByte        : in  std_logic_vector(7 downto 0);  	-- Frame byte
    endFrame         : in  std_logic;   										-- Indicates end of frame
    request			     : in  std_logic;							  	  		-- Signal indicates the IP layer wants look up a MAC associated an IP
		requestIP        : in  std_logic_vector(31 downto 0); 	-- Request IP to found the associated MAC to this IP
    startARPReply    : in  std_logic;										  	-- ARP sender asserts this signal when the reply ARP frame is sent
		genARPReply      : out std_logic;   								  	-- Tells ARP sender to generate reply
    receivedARPReply : out std_logic;                       -- Tells ARP sender the ARP reply has been received
		dstARPIP         : out std_logic_vector(31 downto 0); 	-- Tells ARP sender the destination IP to generate the reply
		OKRequest        : out std_logic;                       -- Indicates if requestIP is in the table
		lookupMAC        : out std_logic_vector(47 downto 0)	  -- If valid, MAC for requested IP  
  );
end arpReceiver;
                 
architecture arpReceiver_arch of arpReceiver is

-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------
  -- Counter signals
  signal cntBytes       : std_logic_vector(13 downto 0);
  
  signal sourceMAC      : std_logic_vector(47 downto 0);         -- stores source MAC
  signal sourceIP       : std_logic_vector(31 downto 0);         -- stores source IP
  signal opcodeLatch    : std_logic;    -- latched opccode (0 reply and 1 request)
	
	-- ARP table signals
  signal newIP          : std_logic_vector(31 downto 0);    -- stores the newest ARP entry IP
  signal newMAC         : std_logic_vector(47 downto 0);    -- stores the newest ARP entry MAC
  signal oldIP          : std_logic_vector(31 downto 0);    -- stores the oldest ARP entry IP
  signal oldMAC         : std_logic_vector(47 downto 0);    -- stores the oldest ARP entry MAC
  
  -- State signals
  type state is (s_idle, s_getARPBytes);
  signal currentState, nextState : state;

begin  -- arpReceiver_arch
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
  process (currentState, newFrame, frameType, newByte, cntBytes, frameByte, endFrame, fpga_ip)
  begin
    case currentState is
      when s_idle =>
			 -- waits for the arrival of a new frame
       if newFrame = '1' and frameType = '0' then
         nextState <= s_getARPBytes;
       else
         nextState <= s_idle;
       end if;

      when s_getARPBytes =>
        -- receives a new byte of the frame
        if newByte = '1' then
          -- checks the fields of the ARP frame
          -- if some fields are not correct the frame is ignored
          -- hardware type: 0x0001 (Ethernet). The MSB is checked in the previous process
          -- protocol type: 0x0800 (IP)
          -- hardware address length: 0x06
          -- protocol address length: 0x04
          -- opcode: 0x0001 (request) or 0x0002 (reply)
          -- destination hardware adddress: FPGA_MAC
          -- destination protocol address: FPGA_IP
          -- FPGA_MAC is not checked because it was checked in ethernet layer
          if ((cntBytes = 3 or cntBytes = 6)  and frameByte /= X"00") or
          (cntBytes = 1 and frameByte /= X"01") or
          (cntBytes = 2 and frameByte /= X"08") or
          (cntBytes = 4 and frameByte /= X"06") or
          (cntBytes = 5 and frameByte /= X"04") or
          (cntBytes = 7 and frameByte /= X"01" and frameByte /= X"02") or
          (cntBytes = 24 and frameByte /= FPGA_IP(31 downto 24)) or
          (cntBytes = 25 and frameByte /= FPGA_IP(23 downto 16)) or
          (cntBytes = 26 and frameByte /= FPGA_IP(15 downto 8)) or
          (cntBytes = 27 and frameByte /= FPGA_IP(7 downto 0)) then
            nextState <= s_idle;
					-- all data are received
					elsif endFrame = '1' then
						nextState <=s_idle;
          -- there are still data to be received
          else
            nextState <= s_getARPBytes;
          end if;
        else
          nextState <= s_getARPBytes;
        end if;
              
      when others =>                                            
        nextState <= s_idle;
    end case;
  end process;

  -- purpose: sets outputs of the module and internal signals 
  process (clk, rst)
  begin
    if rst = '1' then
      cntBytes         <= (others => '0');
			newIP            <= (others => '0');
      newMAC           <= (others => '0');
      oldIP            <= (others => '0');
      oldMAC           <= (others => '0');
			opcodeLatch      <= '0';
			sourceIP         <= (others => '0');
			sourceMAC        <= (others => '0');
			genARPReply      <= '0';
			receivedARPReply <= '0';
    elsif clk'event and clk = '1' then
      -- default siganls
			receivedARPReply <= '0';
			-- when ARP reply starts to be sent by arpSender the genARPReply
			-- is deactive, since the request to generate a ARP reply has been attended
			if startARPReply = '1' then
				genARPReply <= '0';
			end if;
			
      case currentState is
        when s_idle =>
          cntBytes <= (others => '0');
					if newFrame = '1' and frameType = '0' then
            -- cntBytes = 1 because the zero bit (first bit) has just been received
						cntBytes <= conv_std_logic_vector(1, 14);
          end if;
        
        when s_getARPBytes =>
					if newByte = '1' then
						-- increases the bytes counter
            cntBytes <= cntBytes + 1;
						if cntBytes = 7 then
							opcodeLatch <= frameByte(0);
						end if;
						if cntBytes = 8 or cntBytes = 9 or cntBytes = 10 or cntBytes = 11 or cntBytes = 12 or cntBytes = 13 then
							sourceMAC <= sourceMAC(39 downto 0) & frameByte;
						end if;
						if cntBytes = 14 or cntBytes = 15 or cntBytes = 16 or cntBytes = 17 then
							sourceIP <= sourceIP(23 downto 0) & frameByte;
						end if;
						if endFrame = '1' then  
							-- updates the ARP table with new data
							-- we have already this ARP, therefore we update newMAC with received MAC
							if sourceIP = newIP then
								newMAC <= sourceMAC;
							-- We have not this ARP, therefore we overwrite oldIP and oldMAC with
							-- the values of newIP and newMAC respectively, and we assign the
							-- values of the received IP and MAC to newIP and newMAC respectively
							else
								oldIP  <= newIP;
								oldMAC <= newMAC;
								newIP  <= sourceIP;
								newMAC <= sourceMAC;
							end if;
							-- generates a reply 
							if opcodeLatch = '1' then
								-- asserts generateARPReply for that ARP sender generates the reply
								genARPReply <= '1';
							-- indicates the ARP reply has been received
							else
								receivedARPReply <= '1'; 
							end if;
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
  
	-- purpose: handles requests for entries in the ARP table
  process (request, requestIP, newIP, newMAC, oldIP, oldMAC, sourceMAC)
  begin
    if (request = '0') then
			OKRequest <= '0';
			lookupMAC <= sourceMAC;
		else
			if requestIP = newIP then
				OKRequest <= '1';
				lookupMAC <= newMAC;
			elsif requestIP = oldIP then
				OKRequest <= '1';
				lookupMAC <= oldMAC;
			else
				OKRequest <= '0';
				lookupMAC <= (others => '1');
			end if;
		end if;
  end process;
	
	-- purpose: handles the destination IP
	-- the IP address can be got from two ways:
	-- 1.- ARP request ARP frame
	-- 2.- Other layer requests a MAC associated with an IP
	process (request, requestIP, sourceIP)
	begin
		-- it gets the IP from request ARP frame
		if request = '0' then
			dstARPIP <= sourceIP;
		-- it gets the IP from requestIP. This IP is necessary when
		-- the requested IP is not in the table. Then arpSender will send
		-- a request ARP frame to find the MAC associated with that IP
		else
			dstARPIP <= requestIP;
		end if;
	end process;

end arpReceiver_arch;



