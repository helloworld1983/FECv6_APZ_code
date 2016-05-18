library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.ethernet_pkg.all;

entity gbe_top is
  generic ( g_rxram_depth : natural := 14 );
  port (
		clk           : in  std_logic;   									-- Clock (125 Mhz)
		rst           : in  std_logic;   									-- Asynchronous reset (active high)
--    OnTx				  : in  std_logic;
		-- RX signals
		data_in       : in  std_logic_vector(7 downto 0);	-- Input data
		sof_in_n      : in  std_logic;   									-- Indicates the beginning of a frame an the data_in bus
		eof_in_n      : in  std_logic;   									-- Indicates the end of a frame transfer an data_in bus
		src_rdy_in_n  : in  std_logic;   									-- Input source ready
		dst_rdy_out_n : out std_logic;										-- Output destination ready
		-- TX signals
		data_out			: out std_logic_vector(7 downto 0);	-- Output data
		sof_out_n     : out std_logic;   									-- Indicates the beginning of a frame an the data_out bus
		eof_out_n     : out std_logic;   									-- Indicates the end of a frame transfer an data_out bus
		src_rdy_out_n : out std_logic;   									-- Output source ready
		dst_rdy_in_n  : in  std_logic; 										-- Input destination ready 
		-- Application Interface
		fpga_mac: in std_logic_vector(47 downto 0);
		fpga_ip: in std_logic_vector(31 downto 0);
		tx_busy : out std_logic;
		forceEthCanSend	: in std_logic;
		txdata				: in std_logic_vector(7 downto 0);
		tx_length			: in std_logic_vector(15 downto 0);
		tx_start, tx_stop	: in std_logic;
		txdata_rdy, frameEndEvent			: out std_logic;
		udptx_numFramesEvent : in std_logic_vector(6 downto 0);
		udptx_srcPort, udptx_dstPort, udptx_frameDly : in std_logic_vector(15 downto 0);
		udptx_daqtotFrames	    : in  std_logic_vector(15 downto 0);  -- 
		udptx_dstIP : in std_logic_vector(31 downto 0);
		udprx_srcIP: out std_logic_vector(31 downto 0);
		udprx_dstPortOut, udprx_checksum : out std_logic_vector(15 downto 0);
		udprx_portAckIn : in std_logic;
		udprx_dataout : out std_logic_vector(7 downto 0);
		udprx_datavalid : out std_logic
  );                                                                    
end gbe_top;


architecture gbe_top_arch of gbe_top is 
-------------------------------------------------------------------------------
-- Components
-------------------------------------------------------------------------------
	component ethernetReceiver is
		port (
			clk           : in  std_logic;   									-- Clock (125 Mhz)
			rst           : in  std_logic;   									-- Asynchronous reset
	 fpga_mac: in std_logic_vector(47 downto 0);
			data_in       : in  std_logic_vector(7 downto 0);	-- Input data
			sof_in_n      : in  std_logic;   									-- Indicates the beginning of a frame an the data_in bus
			eof_in_n      : in  std_logic;   									-- Indicates the end of a frame transfer an data_in bus
			src_rdy_in_n  : in  std_logic;   									-- Input source ready
			dst_rdy_out_n : out std_logic;   									-- Output destination ready
			frameType     : out std_logic;   									-- Indicates kind of frame, 1 for IP and 0 for ARP
			newByte       : out std_logic;   									-- Signal to write data to the IP layer
			frameByte     : out std_logic_vector(7 downto 0);	-- Byte to write to the IP layer
			newFrame      : out std_logic;   									-- New frame signal to the next layer
			endFrame      : out std_logic    								  -- End of frame signal to the next layer
		);                                                                    
	end component; 
	
	component ethernetSender is
		port (
			clk           : in  std_logic;   								  	-- Clock (125 Mhz)
			rst           : in  std_logic;   								 		-- Asynchronous reset
	 fpga_mac: in std_logic_vector(47 downto 0);
			canSend       : in  std_logic;
			sentEvent 		: in  std_logic;
			newFrame			: in  std_logic;											-- Frame ready to send
			frameType			: in	std_logic;										  -- Indicates type of frame, 1 for IP and 0 for ARP
			frameSize			: in  std_logic_vector(15 downto 0);	-- Length of the frame to send
			dstMAC        : in  std_logic_vector(47 downto 0); 	-- Target MAC of the frame
			rdData				: in  std_logic_vector(7 downto 0);  	-- Read data bus from the RAM
			
			totFrames     : in  std_logic_vector(11 downto 0);
			
			dst_rdy_in_n  : in  std_logic;   										-- Input destination ready
			synRdWrTxRAM  : out std_logic;											-- Asserts to synchronize the reading and writting operations in the Tx RAM
			sendingFrame  : out std_logic;                      -- Indicates upper layers that a frame is being sent
			sof_out_n     : out std_logic;   										-- Indicates the beginning of a frame an the data_out bus
			eof_out_n     : out std_logic;   										-- Indicates the end of a frame transfer an data_out bus
			src_rdy_out_n : out std_logic;   										-- Output source ready
			data_out      : out std_logic_vector(7 downto 0);		-- Output data
			rdRAM					: out std_logic;											-- Read RAM signal
			rdAddr				: out std_logic_vector(13 downto 0)		-- Read address bus to the RAM
		);                                                                    
	end component;

	component arpReceiver is
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
	end component;
	
	component arpSender is
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
	end component;
	
	component ipReceiver is
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
			sourceIP, destIP     : out std_logic_vector(31 downto 0); -- Indicates the source IP
			canRead      : out std_logic; 										-- Indicates the RAM memory can be read
			wrRAM        : out std_logic; 										-- Write enable of the RAM memory
			wrAddr       : out std_logic_vector(g_rxram_depth - 1 downto 0); -- Address bus of the RAM memory
			wrData       : out std_logic_vector(7 downto 0) 	-- Data bus of the RAM memory
		);
	end component;
	
	component ipSender is
		port (
		clk          : in  std_logic; 										-- Global clock
		rst          : in  std_logic;  										-- Global reset
	 fpga_ip: in std_logic_vector(31 downto 0);
		sendingFrame : in  std_logic;                     -- From ethernet sender layer is indicated a frame is being sent
		sendDatagram : in  std_logic;											-- Signal to send a datagram
		protocol		 : in  std_logic_vector(7 downto 0); 	-- Protocol of the datagram to be sent
		datagramSize : in  std_logic_vector(15 downto 0); -- Size of the datagram to transmit
		dstIP		     : in  std_logic_vector(31 downto 0);	-- IP to transmit datagram to
		OKRequest		 : in  std_logic;										  -- Input from arp reciver layer indicating it contains the requested MAC
		lookupMAC		 : in  std_logic_vector(47 downto 0); -- Input from arp receiver layer giving the requested MAC
		
		totFrames_in : in  std_logic_vector(11 downto 0);
		
		busyIPSender : out std_logic;											-- Tells upper layers ip sender laeyr cannot attend their request 
		request			 : out std_logic;                     -- Signal to request a MAC associated an IP of arp receiver layer
		requestIP		 : out std_logic_vector(31 downto 0);	-- IP that the arp receiver layer must look up
		wrRAM				 : out std_logic;											-- Asserted to tell the Tx RAM to write
		wrData			 : out std_logic_vector(7 downto 0); 	-- Write data bus to the Tx RAM
		wrAddr			 : out std_logic_vector(13 downto 0); -- Write addres bus to the Tx RAM
		sendIP			 : out std_logic; 									  -- Tells the ethernet sender layer to send a datagram
		ICMPUDPFrame : out std_logic;
		lengthIP		 : out std_logic_vector(15 downto 0); -- Tells the ethernet sender layer how long the frame is
		dstMAC			 : out std_logic_vector(47 downto 0);	-- MAC to transmit datagram to
		totFrames_out : out std_logic_vector(11 downto 0)
	);
	end component;
	
	component icmp is
		generic ( g_rxram_depth : natural := 14 );
		port (
			clk          : in  std_logic; 										-- Global clock
			rst          : in  std_logic;  										-- Global reset
			canRead			 : in  std_logic;											-- Indicates you can read data from the IP RAM
			datagramSize : in  std_logic_vector(15 downto 0);	-- Size of the arrived datagram
			protocol  	 : in  std_logic_vector(7 downto 0); 	-- Protocol type of the datagram
			sourceIP		 : in  std_logic_vector(31 downto 0); -- IP address that sent the frame
			rdData			 : in  std_logic_vector(7 downto 0); 	-- Read data bus from the IP RAM
			rdRAM				 : out std_logic;											-- Asserteds to tell the IP RAM to read
			rdAddr			 : out std_logic_vector(g_rxram_depth - 1 downto 0); -- Read address bus to the IP RAM
			wrRAM				 : out std_logic;											-- Asserteds to tell the RAM to write
			wrData			 : out std_logic_vector(7 downto 0); 	-- Write data bus to the RAM
			wrAddr			 : out std_logic_vector(13 downto 0); -- Write addres bus to the RAM
			sendICMP, abortICMP		 : out std_logic;											-- Tells the IP layer to send a datagram
			lengthICMP	 : out std_logic_vector(15 downto 0); -- Size of the ping to reply
			dstIP			   : out std_logic_vector(31 downto 0)	-- Target IP of the datagram
		);
	end component;
	
	component udpReceiver is
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
			sourceIP, destIP     : in std_logic_vector(31 downto 0); -- Indicates the source IP
			-- Backend
		sourceIP_out : out std_logic_vector(31 downto 0); 
		checksum_out : out std_logic_vector(15 downto 0);
		dstPort : out std_logic_vector(15 downto 0);
		portAck : in std_logic;
		startTx, datavalid			 : out std_logic;
		dataout: out std_logic_vector(7 downto 0)
		);
	end component;
	
	component udpSender is
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
			framedly				    : in  std_logic_vector(15 downto 0);  -- frame delay
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
	end component;
	
	component dualRAM is
		generic (
			RAM_STYLE_ATTRIBUTE : string := "AUTO";
			DATA_WIDTH : integer := 8;
			ADDR_WIDTH : integer := 14
		);
		port (
			clk   : in  std_logic;  															-- Global clock
			ena   : in  std_logic;  															-- Primary global enable
			enb   : in  std_logic;  															-- Dual global enable
			wea   : in  std_logic;  															-- Primary synchronous write enable
			addra : in  std_logic_vector(ADDR_WIDTH-1 downto 0);	-- Write address/Primary read address
			addrb : in  std_logic_vector(ADDR_WIDTH-1 downto 0); 	-- Dual read address
			dia   : in  std_logic_vector(DATA_WIDTH-1 downto 0); 	-- Primary data input
			doa   : out std_logic_vector(DATA_WIDTH-1 downto 0); 	-- Primary output port
			dob   : out std_logic_vector(DATA_WIDTH-1 downto 0)  	-- Dual output port
		);
	end component;

-------------------------------------------------------------------------------
-- Signals
-------------------------------------------------------------------------------
	-- signals from ethernet receiver layer to arp receiver and ip receiver layers
	signal frameType               : std_logic;
	signal newByte                 : std_logic;
	signal newFrame                : std_logic;
	signal endFrame                : std_logic;
	signal frameByte               : std_logic_vector(7 downto 0);
	
	-- signals from ip sender layer to arp receiver layer
	signal request                 : std_logic;
	signal requestIP               : std_logic_vector(31 downto 0);
	
	-- signal from arp sender layer to arp receiver layer
	signal startARPReply           : std_logic;
	
	-- signal from arp receiver layer to arp sender layer
	-- OKrequest and lookupMAC signal to ip sender layer also
	signal genARPReply             : std_logic;
	signal receivedARPReply        : std_logic;
	signal OKrequest               : std_logic;
	signal dstARPIP                : std_logic_vector(31 downto 0);
	signal lookupMAC               : std_logic_vector(47 downto 0);
	
	
	-- signal from ip receiver layer to icmp and udp receiver layer
	signal canRead                 : std_logic;
	signal protocol                : std_logic_vector(7 downto 0); 	
	signal datagramSize            : std_logic_vector(15 downto 0); 
	signal sourceIP, destIP                : std_logic_vector(31 downto 0);
	
	-- signal from icmp layer to flow control    
	signal sendICMP, abortICMP                : std_logic; 	
	signal lengthICMP              : std_logic_vector(15 downto 0); 
	signal dstIPICMP               : std_logic_vector(31 downto 0);
	
	-- signal from udp sender layer to flow control
	signal startTx                 : std_logic;
	signal pauseData               : std_logic;
	signal stopTx                  : std_logic;
	signal data                    : std_logic_vector(7 downto 0);
	signal data_i                  : std_logic_vector(7 downto 0);
	signal sendUDP                 : std_logic; 	
	signal lengthUDP               : std_logic_vector(15 downto 0); 
	signal dstIPUDP                : std_logic_vector(31 downto 0);
	
	-- signal from flow control to ip sender layer
	signal sendTransLayer      : std_logic;
	signal protocolTransLayer  : std_logic_vector(7 downto 0); 	
	signal lengthTransLayer        : std_logic_vector(15 downto 0); 
	signal dstIPTransLayer         : std_logic_vector(31 downto 0);
	
	-- signal from ip sender layer to udp sender layer
	signal busyIPSender            : std_logic;
	
	-- signal from ethernet sender layer to udp sender layer
	signal synRdWrTxRAM            : std_logic;
	
	-- signal from ethernet sender layer to ip sender layer
	signal sendingFrame            : std_logic;
	
	-- signal from arp sender layer to flow control  to ip sender layer		
	signal sendARP                 : std_logic;
	signal dstMACARP               : std_logic_vector(47 downto 0);

	-- signal from ip sender layer to flow control
	signal sendIP                  : std_logic;
	signal lengthIP                : std_logic_vector(15 downto 0);
	signal dstMACIP     					 : std_logic_vector(47 downto 0);
	
	-- signal from flow control to ethernet sender layer
	signal sendIntLayer        : std_logic;
	signal typeIntLayer        : std_logic;
	signal lengthIntLayer      : std_logic_vector(15 downto 0);
	signal dstMACIntLayer      : std_logic_vector(47 downto 0);
	
	-- signal from udp sender layer to flow control
	signal offsetAddr     				 : std_logic_vector(13 downto 0);
	--signal offsetAddr_i     			 : std_logic_vector(13 downto 0);

  -- signals to connect RX RAM
	signal wrRAM_Rx              : std_logic;
	signal wrData_Rx             : std_logic_vector(7 downto 0);
	signal wrAddr_Rx             : std_logic_vector(g_rxram_depth - 1 downto 0);
	signal rdRAM_Rx              : std_logic;
	signal rdData_Rx             : std_logic_vector(7 downto 0);
	signal rdAddr_Rx             : std_logic_vector(g_rxram_depth - 1 downto 0);
	
	-- signals to connect ARP TX RAM
	signal wrRAM_ARPTx             : std_logic;
	signal wrData_ARPTx            : std_logic_vector(7 downto 0);
	signal wrAddr_ARPTx            : std_logic_vector(13 downto 0);
	signal wrRAM_ARPTx_i             : std_logic;
	signal wrData_ARPTx_i            : std_logic_vector(7 downto 0);
	signal wrAddr_ARPTx_i            : std_logic_vector(13 downto 0);
	signal rdRAM_ARPTx             : std_logic;
	signal rdData_ARPTx            : std_logic_vector(7 downto 0);
	signal rdAddr_ARPTx            : std_logic_vector(13 downto 0);
	
	-- signals to connect IP TX RAM
--	signal wrRAM_TxRAM             : std_logic;
--	signal wrData_TxRAM            : std_logic_vector(7 downto 0);
--	signal wrAddr_TxRAM            : std_logic_vector(13 downto 0);
	
	-- signals from/to icmp layer to/from arbitration memories section
	signal rdRAM_ICMPRx            : std_logic;
	signal rdData_ICMPRx           : std_logic_vector(7 downto 0);
	signal rdAddr_ICMPRx           : std_logic_vector(g_rxram_depth - 1 downto 0);
	
	-- signals from/to udp receiver layer to/from arbitration memories section
	signal rdRAM_UDPRx             : std_logic;
	signal rdData_UDPRx            : std_logic_vector(7 downto 0);
	signal rdAddr_UDPRx            : std_logic_vector(g_rxram_depth - 1 downto 0);
	
	-- signals from icmp layer to arbitration memories section
	signal wrRAM_ICMPTx            : std_logic;
	signal wrData_ICMPTx           : std_logic_vector(7 downto 0);
	signal wrAddr_ICMPTx           : std_logic_vector(13 downto 0);
	signal wrRAM_ICMPTx_i            : std_logic;
	signal wrData_ICMPTx_i           : std_logic_vector(7 downto 0);
	signal wrAddr_ICMPTx_i           : std_logic_vector(13 downto 0);
	signal rdRAM_ICMPTx            : std_logic;
	signal rdData_ICMPTx           : std_logic_vector(7 downto 0);
	signal rdAddr_ICMPTx           : std_logic_vector(13 downto 0);
	
	-- signals from udp sender layer to arbitration memories section
	signal wrRAM_UDPTx             : std_logic;
	signal wrData_UDPTx            : std_logic_vector(7 downto 0);
	signal wrAddr_UDPTx            : std_logic_vector(13 downto 0);
	signal wrRAM_UDPTx_i             : std_logic;
	signal wrData_UDPTx_i            : std_logic_vector(7 downto 0);
	signal wrAddr_UDPTx_i            : std_logic_vector(13 downto 0);
	signal rdRAM_UDPTx             : std_logic;
	signal rdData_UDPTx            : std_logic_vector(7 downto 0);
	signal rdAddr_UDPTx            : std_logic_vector(13 downto 0);
	
	-- signals from ip sender layer to arbitration memories section
	signal wrRAM_IPTx              : std_logic;
	signal wrData_IPTx             : std_logic_vector(7 downto 0);
	signal wrAddr_IPTx             : std_logic_vector(13 downto 0);
	
	-- signals from/to ethernet sender layer to/from arbitration memories section
	signal rdRAM_TxRAM             : std_logic;
	signal rdData_TxRAM            : std_logic_vector(7 downto 0);
	signal rdAddr_TxRAM            : std_logic_vector(13 downto 0);
	
	signal sof_n : std_logic;
	signal eof_n : std_logic;
	
	signal OKUDP_i, OKUDP_ii : std_logic;
	signal sentEvent : std_logic;
	signal ICMPUDPFrame : std_logic;
	
	signal totFrames_in : std_logic_vector(11 downto 0);
	signal totFrames_out : std_logic_vector(11 downto 0);
	
	signal udptx_daqresume : std_logic;

begin
-------------------------------------------------------------------------------
-- Hook up components
-------------------------------------------------------------------------------
	
	-- Network Layer
	-----------------------------------------------------------------------------
	ETH_RX : component ethernetReceiver
		port map (
			clk           => clk,
			rst           => rst,
		fpga_mac => fpga_mac,
			data_in       => data_in,
			sof_in_n      => sof_in_n,
			eof_in_n      => eof_in_n,
			src_rdy_in_n  => src_rdy_in_n,
			dst_rdy_out_n => dst_rdy_out_n,
			frameType     => frameType,
			newByte       => newByte,
			frameByte     => frameByte,
			newFrame      => newFrame,
			endFrame      => endFrame
		);                                                                     
	
	OKUDP_ii <= OKUDP_i or forceEthCanSend;
	ETH_TX : component ethernetSender
		port map (
			clk           => clk,
			rst           => rst,
		fpga_mac => fpga_mac,
			canSend       => OKUDP_ii,
			sentEvent	    => sentEvent,
			newFrame			=> sendIntLayer,
			frameType			=> typeIntLayer,
			frameSize			=> lengthIntLayer,
			dstMAC        => dstMACIntLayer,
			rdData				=> rdData_TxRAM,
			
			totFrames     => totFrames_out,
			
			dst_rdy_in_n  => dst_rdy_in_n,
			synRdWrTxRAM  => synRdWrTxRAM,
			sendingFrame  => sendingFrame,
			sof_out_n     => sof_n,
			eof_out_n     => eof_n,
			src_rdy_out_n => src_rdy_out_n,
			data_out      => data_out,
			rdRAM					=> rdRAM_TxRAM,
			rdAddr				=> rdAddr_TxRAM
		);

	sof_out_n <= sof_n;
	eof_out_n <= eof_n;

	-- Internet Layer
	-----------------------------------------------------------------------------
	ARP_RX : component arpReceiver
		port map (
			clk              => clk,
			rst              => rst,
		fpga_mac => fpga_mac,
		fpga_ip => fpga_ip,
			newFrame         => newFrame,
			frameType        => frameType,
			newByte          => newByte,
			frameByte        => frameByte,
			endFrame         => endFrame,
			request			     => request,
			requestIP        => requestIP,
			startARPReply    => startARPReply,
			genARPReply      => genARPReply,
			receivedARPReply => receivedARPReply,
			dstARPIP         => dstARPIP,
			OKRequest        => OKRequest,
			lookupMAC        => lookupMAC
		);
	
	ARP_TX : component arpSender
		port map (
			clk              => clk,
			rst              => rst,
		fpga_mac => fpga_mac,
		fpga_ip => fpga_ip,
			sendingFrame     => sof_n,
			genARPReply      => genARPReply,
			receivedARPReply => receivedARPReply,
			dstARPIP         => dstARPIP,
			OKRequest		     => OKRequest,
			lookupMAC		     => lookupMAC,
			startARPReply    => startARPReply,
			wrRAM				     => wrRAM_ARPTx,
			wrData			     => wrData_ARPTx,
			wrAddr			     => wrAddr_ARPTx,
			sendARP		       => sendARP,
			dstMAC			     => dstMACARP
		);
	
	IP_RX : component ipReceiver
		generic map ( g_rxram_depth => g_rxram_depth )
		port map (
			clk          => clk,
			rst          => rst,
			newFrame     => newFrame, 
			frameType    => frameType,
			newByte      => newByte,
			frameByte    => frameByte,
			endFrame     => endFrame,
			protocol     => protocol,
			datagramSize => datagramSize,
			sourceIP     => sourceIP,
			destIP     	 => destIP,
			canRead      => canRead,
			wrRAM        => wrRAM_Rx,
			wrAddr       => wrAddr_Rx,
			wrData       => wrData_Rx
		);
	
	IP_TX : component ipSender
		port map (
			clk          => clk,
			rst          => rst,
		fpga_ip => fpga_ip,
			sendingFrame => sendingFrame,
			sendDatagram => sendTransLayer,
			protocol		 => protocolTransLayer,
			datagramSize => lengthTransLayer,
			dstIP   		 => dstIPTransLayer,
			OKRequest		 => OKRequest,
			lookupMAC		 => lookupMAC,
			totFrames_in => totFrames_in,
			busyIPSender => busyIPSender,
			request			 => request,
			requestIP		 => requestIP,
			wrRAM				 => wrRAM_IPTx,
			wrData			 => wrData_IPTx,
			wrAddr			 => wrAddr_IPTx,
			sendIP			 => sendIP,
			ICMPUDPFrame => ICMPUDPFrame,
			lengthIP		 => lengthIP,
			dstMAC			 => dstMACIP,
			totFrames_out => totFrames_out
		);	
		
	-- Transport Layer
	-----------------------------------------------------------------------------
	ICMP_RXTX : component icmp
		generic map ( g_rxram_depth => g_rxram_depth )
		port map (
			clk          => clk,
			rst          => rst,
			canRead			 => canRead,
			datagramSize => datagramSize,
			protocol  	 => protocol,
			sourceIP		 => sourceIP,
			rdData			 => rdData_ICMPRx,
			rdRAM				 => rdRAM_ICMPRx,
			rdAddr			 => rdAddr_ICMPRx,
			wrRAM				 => wrRAM_ICMPTx,
			wrData			 => wrData_ICMPTx,
			wrAddr			 => wrAddr_ICMPTx,
			sendICMP		 => sendICMP,
			abortICMP	 => abortICMP,
			lengthICMP	 => lengthICMP,
			dstIP			   => dstIPICMP
		);
		
	UDP_RX : component udpReceiver
		generic map ( g_rxram_depth => g_rxram_depth )
		port map (
			clk          => clk,
			rst          => rst,
			canRead			 => canRead,
			datagramSize => datagramSize,
			protocol  	 => protocol,
			rdData			 => rdData_UDPRx,
			rdRAM				 => rdRAM_UDPRx,
			rdAddr			 => rdAddr_UDPRx,
			sourceIP		 => sourceIP,
			destIP => destIP,		
			startTx			 => OKUDP_i,
			sourceIP_out => udprx_srcIP,
			dstPort => udprx_dstPortOut,
			checksum_out => udprx_checksum,
			portAck => udprx_portAckIn,
			dataout => udprx_dataout,
			datavalid => udprx_datavalid
		);
	
	stopTx <= tx_stop;
	startTx <= tx_start;
	data <= txdata;
	txdata_rdy <= not pauseData;
	udptx_daqresume <= OKUDP_i;
	
--	data_process : process (clk, rst)
--	begin
--		if rst = '1' then
--			data_i <= (others => '0');
--		elsif clk'event and clk = '1' then
--			if pauseData = '0' then
--				data_i <= data_i + 1;
--				data <= data_i;
--			end if;
--		end if;
--	end process;
	
	UDP_TX : component udpSender
		port map (
			clk             => clk,
			rst             => rst,
		fpga_ip => fpga_ip,
			synRdWrTxRAM    => synRdWrTxRAM,
			busyIPSender    => busyIPSender,
			startTx         => startTx,
			stopTx          => stopTx,
			enChecksum	    => '0',
			numFramesEvent  => udptx_numFramesEvent(6 downto 0),--"0111100",
			srcPort			 => udptx_srcPort,
			dstPort			 => udptx_dstPort,--X"1776",
			lengthUDP_in    => tx_length,
--			lengthUDP_in    => X"2314",--X"2328",--X"176C",--X"1384",--X"1130", --X"2300",--X"05D9",
			dstIP_in		    => udptx_dstIP,--X"0A000003",
			framedly			 => udptx_frameDly,
			daqtotFrames => udptx_daqtotFrames,
			daqresume => udptx_daqresume,
			data				    => data,
			pauseData       => pauseData,
			frameEndEventOut => frameEndEvent,
			sentData        => open,
			sentEvent       => sentEvent,
			offsetAddr      => offsetAddr,
			wrRAM				    => wrRAM_UDPTx,
			wrData			    => wrData_UDPTx,
			wrAddr			    => wrAddr_UDPTx,
			sendUDP         => sendUDP,
			lengthUDP_out   => lengthUDP,
			dstIP_out       => dstIPUDP,
			totFrames       => totFrames_in
		);
	-- Memories
	-----------------------------------------------------------------------------
	-- One RAM only is necessary, since when the frame have fully been received
	-- by the IP Receiver module, also this has practically been processed by
	-- the ICMP or UDP Receiver module (several cycles later). We must know if
	-- the data must be driven to ICMP or UDP Receiver module
	IP_RX_RAM : component dualRAM
		generic map (
			RAM_STYLE_ATTRIBUTE => "auto",
			DATA_WIDTH => 8,
			ADDR_WIDTH => g_rxram_depth
		)
		port map (
			clk   => clk,
			ena   => wrRAM_Rx,
			enb   => rdRAM_Rx,
			wea   => wrRAM_Rx,
			addra => wrAddr_Rx,
			addrb => rdAddr_Rx,
			dia   => wrData_Rx,
			doa   => open,
			dob   => rdData_Rx
		);
	
	UDP_TX_RAM : component dualRAM
		generic map (
			RAM_STYLE_ATTRIBUTE => "auto",
			DATA_WIDTH => 8,
			ADDR_WIDTH => 14
		)
		port map (
			clk   => clk,
			ena   => wrRAM_UDPTx_i,
			enb   => rdRAM_UDPTx,
			wea   => wrRAM_UDPTx_i,
			addra => wrAddr_UDPTx_i,
			addrb => rdAddr_UDPTx,
			dia   => wrData_UDPTx_i,
			doa   => open,
			dob   => rdData_UDPTx 
		);
	
	ICMP_TX_RAM : component dualRAM
		generic map (
			RAM_STYLE_ATTRIBUTE => "auto",
			DATA_WIDTH => 8,
			ADDR_WIDTH => 10
		)
		port map (
			clk   => clk,
			ena   => wrRAM_ICMPTx_i,
			enb   => rdRAM_ICMPTx,
			wea   => wrRAM_ICMPTx_i,
			addra => wrAddr_ICMPTx_i(9 downto 0),
			addrb => rdAddr_ICMPTx(9 downto 0),
			dia   => wrData_ICMPTx_i,
			doa   => open,
			dob   => rdData_ICMPTx
		);
	
	ARP_TX_RAM : component dualRAM
		generic map (
			RAM_STYLE_ATTRIBUTE => "auto",
			DATA_WIDTH => 8,
			ADDR_WIDTH => 10
		)
		port map (
			clk   => clk,
			ena   => wrRAM_ARPTx_i,
			enb   => rdRAM_ARPTx,
			wea   => wrRAM_ARPTx_i,
			addra => wrAddr_ARPTx_i(9 downto 0),
			addrb => rdAddr_ARPTx(9 downto 0),
			dia   => wrData_ARPTx_i,
			doa   => open,
			dob   => rdData_ARPTx
		);
			
	-----------------------------------------------------------------------------	
	-- Arbitration RAMs
	-----------------------------------------------------------------------------
	FSM_RD_RX_RAM : block
		type state is (s_idle, s_readingICMP, s_readingUDP);
		signal currentState, nextState : state;
		
	begin
		---------------------------------------------------------------------------
		-- Two-process FSM
		---------------------------------------------------------------------------
		-- purpose: state machine driver
		process (clk, rst)
		begin 
			if rst = '1' then                   
				currentState <= s_idle;
			elsif clk'event and clk = '1' then 
				currentState <= nextState;
			end if;
		end process;

		-- purpose: sets next state and signals
		process (currentState, rdData_Rx, rdRAM_ICMPRx, rdAddr_ICMPRx, rdRAM_UDPRx,
		         rdAddr_UDPRx)
		begin
			case currentState is
				when s_idle =>
					-- arp sender layer has priority over the rest layers
					if rdRAM_ICMPRx = '1' then
						nextState     <= s_readingICMP;
						rdRAM_Rx      <= rdRAM_ICMPRx;
						rdAddr_Rx     <= rdAddr_ICMPRx;
						rdData_ICMPRx <= rdData_Rx;
						rdData_UDPRx  <= (others => '0');
					elsif rdRAM_UDPRx = '1' then
						nextState     <= s_readingUDP;
						rdRAM_Rx      <= rdRAM_UDPRx;
						rdAddr_Rx     <= rdAddr_UDPRx;
						rdData_UDPRx  <= rdData_Rx;
						rdData_ICMPRx <= (others => '0');
					else
						nextState <= s_idle;
						-- default signals
						rdRAM_Rx      <= '0';
						rdAddr_Rx     <= (others => '0');
						rdData_ICMPRx <= (others => '0');
						rdData_UDPRx  <= (others => '0');
					end if;
					
				when s_readingICMP =>
					if rdRAM_ICMPRx = '0' then
						nextState <= s_idle;
					else
						nextState <= s_readingICMP;
					end if;
					
--					nextState     <= s_readingICMP;
					rdRAM_Rx      <= rdRAM_ICMPRx;
					rdAddr_Rx     <= rdAddr_ICMPRx;
					rdData_ICMPRx <= rdData_Rx;
					rdData_UDPRx  <= (others => '0');
				
				when s_readingUDP =>
					if rdRAM_UDPRx = '0' then
						nextState <= s_idle;
					else
						nextState <= s_readingUDP;
					end if;
					
					rdRAM_Rx      <= rdRAM_UDPRx;
					rdAddr_Rx     <= rdAddr_UDPRx;
					rdData_UDPRx  <= rdData_Rx;
					rdData_ICMPRx <= (others => '0');
						
				when others =>                                            
					nextState     <= s_idle;
					rdRAM_Rx      <= '0';
					rdAddr_Rx     <= (others => '0');
					rdData_ICMPRx <= (others => '0');
					rdData_UDPRx  <= (others => '0');
			end case;
		end process;
		---------------------------------------------------------------------------
		-- End of two-process FSM
		---------------------------------------------------------------------------
	end block FSM_RD_RX_RAM;
	
	FSM_WR_TX_RAM : block
		type state is (s_idle, s_writtingARP, s_writtingICMP, s_writtingUDP, s_writtingIP);
		signal currentState, nextState : state;
		
	begin
		---------------------------------------------------------------------------
		-- Two-process FSM
		---------------------------------------------------------------------------
		-- purpose: state machine driver
		process (clk, rst)
		begin 
			if rst = '1' then                   
				currentState <= s_idle;
			elsif clk'event and clk = '1' then 
				currentState <= nextState;
			end if;
		end process;

		-- purpose: sets next state and signals
		process (currentState, sendARP, sendICMP, abortICMP, sendIP, wrRAM_ARPTx, wrData_ARPTx,
         		 wrAddr_ARPTx, wrRAM_ICMPTx, wrData_ICMPTx, wrAddr_ICMPTx, wrRAM_IPTx, 
						 wrData_IPTx, wrAddr_IPTx, OKRequest, lookupMAC, wrRAM_UDPTx, 
						 wrData_UDPTx, wrAddr_UDPTx, sendUDP, stopTx, offsetAddr, ICMPUDPFrame)
		begin
			case currentState is
				when s_idle =>
					-- arp sender layer has priority over the rest layers
					if wrRAM_ARPTx = '1' then
						nextState       <= s_writtingARP;
						wrRAM_ARPTx_i   <= '1'; --wrRAM_ARPTx;
						wrData_ARPTx_i  <= wrData_ARPTx;
						wrAddr_ARPTx_i  <= wrAddr_ARPTx;
						--
						wrRAM_ICMPTx_i  <= '0';
						wrData_ICMPTx_i <= (others => '0');
						wrAddr_ICMPTx_i <= (others => '0');
						wrRAM_UDPTx_i   <= '0';
						wrData_UDPTx_i  <= (others => '0');
						wrAddr_UDPTx_i  <= (others => '0');
					elsif wrRAM_ICMPTx = '1' then
						nextState <= s_writtingICMP;
						wrRAM_ICMPTx_i  <= wrRAM_ICMPTx;
						wrData_ICMPTx_i <= wrData_ICMPTx;
						wrAddr_ICMPTx_i <= wrAddr_ICMPTx;
						--
						wrRAM_ARPTx_i   <= '0';
						wrData_ARPTx_i  <= (others => '0');
						wrAddr_ARPTx_i  <= (others => '0');
						wrRAM_UDPTx_i   <= '0';
						wrData_UDPTx_i  <= (others => '0');
						wrAddr_UDPTx_i  <= (others => '0');
					elsif wrRAM_UDPTx = '1' then
						nextState <= s_writtingUDP;
						wrRAM_UDPTx_i  <= wrRAM_UDPTx;
						wrData_UDPTx_i <= wrData_UDPTx;
						wrAddr_UDPTx_i <= wrAddr_UDPTx;
						--
						wrRAM_ARPTx_i   <= '0';
						wrData_ARPTx_i  <= (others => '0');
						wrAddr_ARPTx_i  <= (others => '0');
						wrRAM_ICMPTx_i  <= '0';
						wrData_ICMPTx_i <= (others => '0');
						wrAddr_ICMPTx_i <= (others => '0');
					else
						nextState <= s_idle;
						-- default signals
						wrRAM_ARPTx_i   <= '0';
						wrData_ARPTx_i  <= (others => '0');
						wrAddr_ARPTx_i  <= (others => '0');
						wrRAM_ICMPTx_i  <= '0';
						wrData_ICMPTx_i <= (others => '0');
						wrAddr_ICMPTx_i <= (others => '0');
						wrRAM_UDPTx_i   <= '0';
						wrData_UDPTx_i  <= (others => '0');
						wrAddr_UDPTx_i  <= (others => '0');
					end if;
					
				when s_writtingARP =>
					if sendARP = '1' then
						nextState <= s_idle;
					else
						nextState <= s_writtingARP;
					end if;
					
					wrRAM_ARPTx_i  <= wrRAM_ARPTx;
					wrData_ARPTx_i <= wrData_ARPTx;
					wrAddr_ARPTx_i <= wrAddr_ARPTx;
					--
					wrRAM_ICMPTx_i  <= '0';
					wrData_ICMPTx_i <= (others => '0');
					wrAddr_ICMPTx_i <= (others => '0');
					wrRAM_UDPTx_i   <= '0';
					wrData_UDPTx_i  <= (others => '0');
					wrAddr_UDPTx_i  <= (others => '0');
				
				when s_writtingICMP =>
					if abortICMP = '1' then
						nextState <= s_idle;
					elsif sendICMP = '1' then
						nextState <= s_writtingIP;
					else
						nextState <= s_writtingICMP;
					end if;
					
					wrRAM_ICMPTx_i  <= wrRAM_ICMPTx;
					wrData_ICMPTx_i <= wrData_ICMPTx;
					wrAddr_ICMPTx_i <= wrAddr_ICMPTx;
					--
					wrRAM_ARPTx_i   <= '0';
					wrData_ARPTx_i  <= (others => '0');
					wrAddr_ARPTx_i  <= (others => '0');
					wrRAM_UDPTx_i   <= '0';
					wrData_UDPTx_i  <= (others => '0');
					wrAddr_UDPTx_i  <= (others => '0');
				
				when s_writtingUDP =>
					if sendUDP = '1' then
						nextState <= s_writtingIP;
					else
						nextState <= s_writtingUDP;
					end if;
					
					wrRAM_UDPTx_i  <= wrRAM_UDPTx;
					wrData_UDPTx_i <= wrData_UDPTx;
					wrAddr_UDPTx_i <= wrAddr_UDPTx;
					--
					wrRAM_ARPTx_i   <= '0';
					wrData_ARPTx_i  <= (others => '0');
					wrAddr_ARPTx_i  <= (others => '0');
					wrRAM_ICMPTx_i  <= '0';
					wrData_ICMPTx_i <= (others => '0');
					wrAddr_ICMPTx_i <= (others => '0');
												
				when s_writtingIP =>
--					if sendIP = '1' or (OKRequest = '0' and lookupMAC = X"FFFFFFFFFFFF") then
--						if protocolTransLayer = X"11" and stopTx = '0' then
--							nextState <= s_writtingUDP;
--						else
--							nextState <= s_idle;
--						end if;
--					else
--						nextState <= s_writtingIP;
--					end if;
					if  OKRequest = '0' and lookupMAC = X"FFFFFFFFFFFF" then
						nextState <= s_idle;
					elsif sendIP = '1' then
						if stopTx = '0' and ICMPUDPFrame = '0' then
							nextState <= s_writtingUDP;
						else
							nextState <= s_idle;
						end if;
					else
						nextState <= s_writtingIP;
					end if;
					
					if ICMPUDPFrame = '1' then
						wrRAM_ICMPTx_i  <= wrRAM_IPTx;
						wrData_ICMPTx_i <= wrData_IPTx;
						wrAddr_ICMPTx_i <= wrAddr_IPTx;
						--
						wrRAM_ARPTx_i   <= '0';
						wrData_ARPTx_i  <= (others => '0');
						wrAddr_ARPTx_i  <= (others => '0');
						wrRAM_UDPTx_i   <= '0';
						wrData_UDPTx_i  <= (others => '0');
						wrAddr_UDPTx_i  <= (others => '0');
					else
						wrRAM_UDPTx_i  <= wrRAM_IPTx;
						wrData_UDPTx_i <= wrData_IPTx;
						wrAddr_UDPTx_i <= offsetAddr + wrAddr_IPTx;
						--
						wrRAM_ARPTx_i   <= '0';
						wrData_ARPTx_i  <= (others => '0');
						wrAddr_ARPTx_i  <= (others => '0');
						wrRAM_ICMPTx_i  <= '0';
						wrData_ICMPTx_i <= (others => '0');
						wrAddr_ICMPTx_i <= (others => '0');
					end if;
						
				when others =>                                            
					nextState    <= s_idle;
					wrRAM_ARPTx_i   <= '0';
					wrData_ARPTx_i  <= (others => '0');
					wrAddr_ARPTx_i  <= (others => '0');
					wrRAM_ICMPTx_i  <= '0';
					wrData_ICMPTx_i <= (others => '0');
					wrAddr_ICMPTx_i <= (others => '0');
					wrRAM_UDPTx_i   <= '0';
					wrData_UDPTx_i  <= (others => '0');
					wrAddr_UDPTx_i  <= (others => '0');
			end case;
		end process;
		---------------------------------------------------------------------------
		-- End of two-process FSM
		---------------------------------------------------------------------------
	end block FSM_WR_TX_RAM;
	-----------------------------------------------------------------------------	
	-- End of arbitration RAMs
	-----------------------------------------------------------------------------
		
	-----------------------------------------------------------------------------	
	-- Flow control
	-----------------------------------------------------------------------------
	FSM_INT_TX_LAYER : block
		type state is (s_idle, s_arpTxLayer, s_ipTxLayerForICMP, s_ipTxLayerForUDP);
		signal currentState, nextState : state;
		signal offsetAddr_i : std_logic_vector(13 downto 0);
		
	begin
		---------------------------------------------------------------------------
		-- Two-process FSM
		---------------------------------------------------------------------------
		-- purpose: state machine driver
		process (clk, rst)
		begin 
			if rst = '1' then                   
				currentState <= s_idle;
				tx_busy <= '1';
				offsetAddr_i <= (others => '0');
			elsif clk'event and clk = '1' then 
				currentState <= nextState;
				if currentState = s_idle then
					tx_busy <= '0';
				else
					tx_busy <= '1';
				end if;
				if (currentState = s_idle) and (sendIP = '1') then
					offsetAddr_i <= offsetAddr;
				end if;
			end if;
		end process;

		-- purpose: sets next state and signals
		process (currentState, sendARP, sendIP, dstMACARP, lengthIP, 
		         dstMACIP, sendingFrame, offsetAddr_i, ICMPUDPFrame,
						 rdRAM_TxRAM, rdAddr_TxRAM, rdData_ARPTx, rdData_ICMPTx, rdData_UDPTx)
		
--			variable offsetAddr_i : std_logic_vector(13 downto 0);
		
		begin
			case currentState is
				when s_idle =>
					-- arp sender layer takes priority over ip sender layer
					if sendARP = '1' then
						nextState      <= s_arpTxLayer;
						sendIntLayer   <= '1';     
						typeIntLayer   <= '0';    
						lengthIntLayer <= X"001C";    
						dstMACIntLayer <= dstMACARP;
					elsif sendIP = '1' then
--						offsetAddr_i   := offsetAddr;
						sendIntLayer   <= '1';     
						typeIntLayer   <= '1';    
						lengthIntLayer <= lengthIP;    
						dstMACIntLayer <= dstMACIP;
						if ICMPUDPFrame = '1' then
							nextState <= s_ipTxLayerForICMP;
						else
							nextState <= s_ipTxLayerForUDP;
						end if;
					else
						-- default signals
						nextState      <= s_idle;
						sendIntLayer   <= '0';     
						typeIntLayer   <= '0';    
						lengthIntLayer <= (others => '0');    
						dstMACIntLayer <= (others => '0');
					end if;
					
					-- default signals
					rdRAM_ARPTx    <= '0';     
					rdAddr_ARPTx   <= (others => '0');
					rdRAM_ICMPTx   <= '0';
					rdAddr_ICMPTx  <= (others => '0');
					rdRAM_UDPTx    <= '0';    
					rdAddr_UDPTx   <= (others => '0');
					rdData_TxRAM	 <= (others => '0');
					
				when s_arpTxLayer =>
					if sendingFrame = '0' then
						nextState <= s_idle;
					else
						nextState <= s_arpTxLayer;
					end if;
					
					rdRAM_ARPTx    <= rdRAM_TxRAM;
					rdAddr_ARPTx   <= rdAddr_TxRAM;
					rdData_TxRAM   <= rdData_ARPTx;
					--
					sendIntLayer   <= '0';     
					typeIntLayer   <= '0';    
					lengthIntLayer <= (others => '0');    
					dstMACIntLayer <= (others => '0');
					rdRAM_ICMPTx   <= '0';
					rdAddr_ICMPTx  <= (others => '0');
					rdRAM_UDPTx    <= '0';    
					rdAddr_UDPTx   <= (others => '0');
					
				when s_ipTxLayerForICMP =>
					if sendingFrame = '0' then
						nextState <= s_idle;
					else
						nextState <= s_ipTxLayerForICMP;
					end if;
					
					rdRAM_ICMPTx  <= rdRAM_TxRAM;
					rdAddr_ICMPTx <= rdAddr_TxRAM;
					rdData_TxRAM  <= rdData_ICMPTx;
					--
					sendIntLayer   <= '0';     
					typeIntLayer   <= '0';    
					lengthIntLayer <= (others => '0');    
					dstMACIntLayer <= (others => '0');
					rdRAM_ARPTx    <= '0';     
					rdAddr_ARPTx   <= (others => '0');
					rdRAM_UDPTx    <= '0';    
					rdAddr_UDPTx   <= (others => '0');
					
				when s_ipTxLayerForUDP =>
					if sendingFrame = '0' then
						nextState <= s_idle;
					else
						nextState <= s_ipTxLayerForUDP;
					end if;
					
					rdRAM_UDPTx   <= rdRAM_TxRAM;
					rdAddr_UDPTx  <= offsetAddr_i + rdAddr_TxRAM;
					rdData_TxRAM  <= rdData_UDPTx;
					--
					sendIntLayer   <= '0';     
					typeIntLayer   <= '0';    
					lengthIntLayer <= (others => '0');    
					dstMACIntLayer <= (others => '0');
					rdRAM_ARPTx    <= '0';     
					rdAddr_ARPTx   <= (others => '0');
					rdRAM_ICMPTx   <= '0';
					rdAddr_ICMPTx  <= (others => '0');					
				
				when others =>                                            
					nextState      <= s_idle;
					sendIntLayer   <= '0';     
					typeIntLayer   <= '0';    
					lengthIntLayer <= (others => '0');    
					dstMACIntLayer <= (others => '0');
					rdRAM_ARPTx    <= '0';     
					rdAddr_ARPTx   <= (others => '0');
					rdRAM_ICMPTx   <= '0';
					rdAddr_ICMPTx  <= (others => '0');
					rdRAM_UDPTx    <= '0';    
					rdAddr_UDPTx   <= (others => '0');
					rdData_TxRAM	 <= (others => '0'); 
			end case;
		end process;
		---------------------------------------------------------------------------
		-- End of two-process FSM
		---------------------------------------------------------------------------
	end block FSM_INT_TX_LAYER;
	
	FSM_TRANS_TX_LAYER : block
		type state is (s_idle, s_icmpTxLayer, s_udpTxLayer);
		signal currentState, nextState : state;
		
	begin
		---------------------------------------------------------------------------
		-- Two-process FSM
		---------------------------------------------------------------------------
		-- purpose: state machine driver
		process (clk, rst)
		begin 
			if rst = '1' then                   
				currentState <= s_idle;
			elsif clk'event and clk = '1' then 
				currentState <= nextState;
			end if;
		end process;

		-- purpose: sets next state and signals
		process (currentState, sendICMP, lengthICMP, dstIPICMP,  sendUDP, lengthUDP, 
		         dstIPUDP, sendIP)
		begin
			case currentState is
				when s_idle =>
					-- icmp layer takes priority over udp sender layer
					if sendICMP = '1' then
						nextState          <= s_icmpTxLayer;
						sendTransLayer     <= sendICMP;
						protocolTransLayer <= X"01";
						lengthTransLayer   <= lengthICMP;
						dstIPTransLayer    <= dstIPICMP;
					elsif sendUDP = '1' then
						nextState          <= s_udpTxLayer;
						sendTransLayer     <= sendUDP;
						protocolTransLayer <= X"11";
						lengthTransLayer   <= lengthUDP;
						dstIPTransLayer    <= dstIPUDP;
					else
						-- default signals
						nextState          <= s_idle;
						sendTransLayer     <= '0';
						protocolTransLayer <= (others => '0');
						lengthTransLayer   <= (others => '0');
						dstIPTransLayer    <= (others => '0');
					end if;
					
				when s_icmpTxLayer =>
					if sendIP = '1' then
						nextState <= s_idle;
					else
						nextState <= s_icmpTxLayer;
					end if;
					
					sendTransLayer     <= '0';
					protocolTransLayer <= X"01";
					lengthTransLayer   <= lengthICMP;
					dstIPTransLayer    <= dstIPICMP;
						
				when s_udpTxLayer =>
					if sendIP = '1' then
						nextState <= s_idle;
					else
						nextState <= s_udpTxLayer;
					end if;
					
					sendTransLayer     <= '0';
					protocolTransLayer <= X"11";
					lengthTransLayer   <= lengthUDP;
					dstIPTransLayer    <= dstIPUDP;
					
				when others =>                                            
					nextState          <= s_idle;
					sendTransLayer     <= '0';
					protocolTransLayer <= (others => '0');
					lengthTransLayer   <= (others => '0');
					dstIPTransLayer    <= (others => '0'); 
			end case;
		end process;
		---------------------------------------------------------------------------
		-- End of two-process FSM
		---------------------------------------------------------------------------
	end block FSM_TRANS_TX_LAYER;
	
end gbe_top_arch;