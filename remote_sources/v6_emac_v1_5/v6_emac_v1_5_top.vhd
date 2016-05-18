-------------------------------------------------------------------------------
-- Title      : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper Example Design
-- Project    : Virtex-6 Embedded Tri-Mode Ethernet MAC Wrapper
-- File       : v6_emac_v1_5_example_design.vhd
-- Version    : 1.4
-------------------------------------------------------------------------------
--
-- (c) Copyright 2009-2010 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
-------------------------------------------------------------------------------
-- Description:  This is the Example Design wrapper for the Virtex-6
--               Embedded Tri-Mode Ethernet MAC. It is intended that this
--               example design can be quickly adapted and downloaded onto an
--               FPGA to provide a hardware test environment.
--
--               The Example Design wrapper:
--
--               * instantiates the EMAC LocalLink-level wrapper (the EMAC
--                 block-level wrapper with the RX and TX FIFOs and a
--                 LocalLink interface);
--
--               * instantiates a simple example design which provides an
--                 address swap and loopback function at the user interface;
--
--               * instantiates the fundamental clocking resources required
--                 by the core.
--
--               Please refer to the Datasheet, Getting Started Guide, and
--               the Virtex-6 Embedded Tri-Mode Ethernet MAC User Gude for
--               further information.
--
--    ---------------------------------------------------------------------
--    |EXAMPLE DESIGN WRAPPER                                             |
--    |           --------------------------------------------------------|
--    |           |LOCALLINK-LEVEL WRAPPER                                |
--    |           |              -----------------------------------------|
--    |           |              |BLOCK-LEVEL WRAPPER                     |
--    |           |              |    ---------------------               |
--    | --------  |  ----------  |    | INSTANCE-LEVEL    |               |
--    | |      |  |  |        |  |    | WRAPPER           |  ---------    |
--    | |      |->|->|        |->|--->| Tx            Tx  |->|       |--->|
--    | |      |  |  |        |  |    | client        PHY |  |       |    |
--    | | ADDR |  |  | LOCAL- |  |    | I/F           I/F |  |       |    |
--    | | SWAP |  |  | LINK   |  |    |                   |  | PHY   |    |
--    | |      |  |  | FIFO   |  |    |                   |  | I/F   |    |
--    | |      |  |  |        |  |    |                   |  |       |    |
--    | |      |  |  |        |  |    | Rx            Rx  |  |       |    |
--    | |      |  |  |        |  |    | client        PHY |  |       |    |
--    | |      |<-|<-|        |<-|<---| I/F           I/F |<-|       |<---|
--    | |      |  |  |        |  |    |                   |  ---------    |
--    | --------  |  ----------  |    ---------------------               |
--    |           |              -----------------------------------------|
--    |           --------------------------------------------------------|
--    ---------------------------------------------------------------------
--
-------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;

--library v6_emac_v1_5_lib;
--use v6_emac_v1_5_lib.all;

-------------------------------------------------------------------------------
-- Entity declaration for the example design
-------------------------------------------------------------------------------

entity v6_emac_v1_5_top is
   port(

      -- Client receiver interface
      EMACCLIENTRXDVLD         : out std_logic;
      EMACCLIENTRXFRAMEDROP    : out std_logic;
      EMACCLIENTRXSTATS        : out std_logic_vector(6 downto 0);
      EMACCLIENTRXSTATSVLD     : out std_logic;
      EMACCLIENTRXSTATSBYTEVLD : out std_logic;

      -- Client transmitter interface
      CLIENTEMACTXIFGDELAY     : in  std_logic_vector(7 downto 0);
      EMACCLIENTTXSTATS        : out std_logic;
      EMACCLIENTTXSTATSVLD     : out std_logic;
      EMACCLIENTTXSTATSBYTEVLD : out std_logic;

      -- MAC control interface
      CLIENTEMACPAUSEREQ       : in  std_logic;
      CLIENTEMACPAUSEVAL       : in  std_logic_vector(15 downto 0);

      --EMAC-transceiver link status
      EMACCLIENTSYNCACQSTATUS  : out std_logic;
      EMACANINTERRUPT          : out std_logic;

      -- 1000BASE-X PCS/PMA interface
      TXP                      : out std_logic;
      TXN                      : out std_logic;
      RXP                      : in  std_logic;
      RXN                      : in  std_logic;
      PHYAD                    : in  std_logic_vector(4 downto 0);

      -- 1000BASE-X PCS/PMA reference clock buffer input
      MGTCLK_P                 : in  std_logic;
      MGTCLK_N                 : in  std_logic;

      -- Asynchronous reset
      RESET                    : in  std_logic;
		
		-- LocalLink Interface
      RX_LL_DATA               : out std_logic_vector(7 downto 0);
      RX_LL_SOF_N              : out std_logic;
      RX_LL_EOF_N              : out std_logic;
      RX_LL_SRC_RDY_N          : out std_logic;
      RX_LL_DST_RDY_N          : in  std_logic;
		
      TX_LL_DATA               : in  std_logic_vector(7 downto 0);
      TX_LL_SOF_N              : in  std_logic;
      TX_LL_EOF_N              : in  std_logic;
      TX_LL_SRC_RDY_N          : in  std_logic;
      TX_LL_DST_RDY_N          : out std_logic;
		
      -- 125MHz clock output from transceiver
      CLK125_OUT               : out std_logic;
      RXRECCLK_OUT               : out std_logic;
      RST_OUT                  : out std_logic
		
   );

end v6_emac_v1_5_top;


architecture Behavioral of v6_emac_v1_5_top is

-------------------------------------------------------------------------------
-- Component declarations for lower hierarchial level entities
-------------------------------------------------------------------------------

  -- Component declaration for the LocalLink-level EMAC wrapper
  component v6_emac_v1_5_locallink is
   port(
      -- 125MHz clock output from transceiver
      CLK125_OUT               : out std_logic;
      RXRECCLK_OUT               : out std_logic;
      -- 125MHz clock input from BUFG
      CLK125                   : in  std_logic;

      -- LocalLink receiver interface
      RX_LL_CLOCK              : in  std_logic;
      RX_LL_RESET              : in  std_logic;
      RX_LL_DATA               : out std_logic_vector(7 downto 0);
      RX_LL_SOF_N              : out std_logic;
      RX_LL_EOF_N              : out std_logic;
      RX_LL_SRC_RDY_N          : out std_logic;
      RX_LL_DST_RDY_N          : in  std_logic;
      RX_LL_FIFO_STATUS        : out std_logic_vector(3 downto 0);

      -- LocalLink transmitter interface
      TX_LL_CLOCK              : in  std_logic;
      TX_LL_RESET              : in  std_logic;
      TX_LL_DATA               : in  std_logic_vector(7 downto 0);
      TX_LL_SOF_N              : in  std_logic;
      TX_LL_EOF_N              : in  std_logic;
      TX_LL_SRC_RDY_N          : in  std_logic;
      TX_LL_DST_RDY_N          : out std_logic;

      -- Client receiver interface
      EMACCLIENTRXDVLD         : out std_logic;
      EMACCLIENTRXFRAMEDROP    : out std_logic;
      EMACCLIENTRXSTATS        : out std_logic_vector(6 downto 0);
      EMACCLIENTRXSTATSVLD     : out std_logic;
      EMACCLIENTRXSTATSBYTEVLD : out std_logic;

      -- Client Transmitter Interface
      CLIENTEMACTXIFGDELAY     : in  std_logic_vector(7 downto 0);
      EMACCLIENTTXSTATS        : out std_logic;
      EMACCLIENTTXSTATSVLD     : out std_logic;
      EMACCLIENTTXSTATSBYTEVLD : out std_logic;

      -- MAC control interface
      CLIENTEMACPAUSEREQ       : in  std_logic;
      CLIENTEMACPAUSEVAL       : in  std_logic_vector(15 downto 0);

      -- EMAC-transceiver link status
      EMACCLIENTSYNCACQSTATUS  : out std_logic;
      EMACANINTERRUPT          : out std_logic;

      -- 1000BASE-X PCS/PMA interface
      TXP                      : out std_logic;
      TXN                      : out std_logic;
      RXP                      : in  std_logic;
      RXN                      : in  std_logic;
      PHYAD                    : in  std_logic_vector(4 downto 0);
      RESETDONE                : out std_logic;

      -- 1000BASE-X PCS/PMA clock buffer input
      CLK_DS                   : in  std_logic;

      -- Asynchronous reset
      RESET                    : in  std_logic
   );
  end component;


-----------------------------------------------------------------------
-- Signal declarations
-----------------------------------------------------------------------

    -- Global asynchronous reset
    signal reset_i             : std_logic;

    -- LocalLink interface clocking signal
    signal ll_clk_i            : std_logic;

    -- Synchronous reset registers in the LocalLink clock domain
    signal ll_pre_reset_i     : std_logic_vector(5 downto 0);
    signal ll_reset_i         : std_logic;

    attribute async_reg : string;
    attribute async_reg of ll_pre_reset_i : signal is "true";

    -- Reset signal from the transceiver
    signal resetdone_i         : std_logic;
    signal resetdone_r         : std_logic;
    
    attribute async_reg of resetdone_r : signal is "true";

    -- Transceiver output clock (REFCLKOUT at 125MHz)
    signal clk125_o            : std_logic;

    -- 125MHz clock input to wrappers
    signal clk125              : std_logic;

	attribute KEEP : boolean;
 --   attribute keep : boolean;
    attribute keep of clk125   : signal is true;

    -- Input 125MHz differential clock for transceiver
    signal clk_ds              : std_logic;


-------------------------------------------------------------------------------
-- Main body of code
-------------------------------------------------------------------------------
signal reset_ii: std_logic;
begin

	reset_ii <= RESET;
	reset_i <= not reset_ii;

    -- Generate the clock input to the transceiver
    -- (clk_ds can be shared between multiple EMAC instances, including
    --  multiple instantiations of the EMAC wrappers)
    clkingen : IBUFDS_GTXE1 port map (
      I     => MGTCLK_P,
      IB    => MGTCLK_N,
      CEB   => '0',
      O     => clk_ds,
      ODIV2 => open
    );

    -- The 125MHz clock from the transceiver is routed through a BUFG and
    -- input to the MAC wrappers
    -- (clk125 can be shared between multiple EMAC instances, including
    --  multiple instantiations of the EMAC wrappers)
    bufg_clk125 : BUFG port map (
      I => clk125_o,
      O => clk125
    );

    -- Clock the LocalLink interface with the globally-buffered 125MHz
    -- clock from the transceiver
    ll_clk_i <= clk125;
	 clk125_out <= clk125;
	 rst_out <= ll_reset_i;

    ------------------------------------------------------------------------
    -- Instantiate the LocalLink-level EMAC Wrapper (v6_emac_v1_5_locallink.vhd)
    ------------------------------------------------------------------------
    v6_emac_v1_5_locallink_inst : v6_emac_v1_5_locallink port map (
      -- 125MHz clock output from transceiver
      CLK125_OUT               => clk125_o,
      RXRECCLK_OUT               => RXRECCLK_OUT,
      -- 125MHz clock input from BUFG
      CLK125                   => clk125,

      -- LocalLink receiver interface
      RX_LL_CLOCK              => ll_clk_i,
      RX_LL_RESET              => ll_reset_i,
      RX_LL_DATA               => rx_ll_data,
      RX_LL_SOF_N              => rx_ll_sof_n,
      RX_LL_EOF_N              => rx_ll_eof_n,
      RX_LL_SRC_RDY_N          => rx_ll_src_rdy_n,
      RX_LL_DST_RDY_N          => rx_ll_dst_rdy_n,
      RX_LL_FIFO_STATUS        => open,

      -- Client receiver signals
      EMACCLIENTRXDVLD         => EMACCLIENTRXDVLD,
      EMACCLIENTRXFRAMEDROP    => EMACCLIENTRXFRAMEDROP,
      EMACCLIENTRXSTATS        => EMACCLIENTRXSTATS,
      EMACCLIENTRXSTATSVLD     => EMACCLIENTRXSTATSVLD,
      EMACCLIENTRXSTATSBYTEVLD => EMACCLIENTRXSTATSBYTEVLD,

      -- LocalLink transmitter interface
      TX_LL_CLOCK              => ll_clk_i,
      TX_LL_RESET              => ll_reset_i,
      TX_LL_DATA               => tx_ll_data,
      TX_LL_SOF_N              => tx_ll_sof_n,
      TX_LL_EOF_N              => tx_ll_eof_n,
      TX_LL_SRC_RDY_N          => tx_ll_src_rdy_n,
      TX_LL_DST_RDY_N          => tx_ll_dst_rdy_n,

      -- Client transmitter signals
      CLIENTEMACTXIFGDELAY     => CLIENTEMACTXIFGDELAY,
      EMACCLIENTTXSTATS        => EMACCLIENTTXSTATS,
      EMACCLIENTTXSTATSVLD     => EMACCLIENTTXSTATSVLD,
      EMACCLIENTTXSTATSBYTEVLD => EMACCLIENTTXSTATSBYTEVLD,

      -- MAC control interface
      CLIENTEMACPAUSEREQ       => CLIENTEMACPAUSEREQ,
      CLIENTEMACPAUSEVAL       => CLIENTEMACPAUSEVAL,

      -- EMAC-transceiver link status
      EMACCLIENTSYNCACQSTATUS  => EMACCLIENTSYNCACQSTATUS,
      EMACANINTERRUPT          => EMACANINTERRUPT,

      -- 1000BASE-X PCS/PMA interface
      TXP                      => TXP,
      TXN                      => TXN,
      RXP                      => RXP,
      RXN                      => RXN,
      PHYAD                    => PHYAD,
      RESETDONE                => resetdone_i,

      -- 1000BASE-X PCS/PMA reference clock buffer input
      CLK_DS                   => clk_ds,

      -- Asynchronous reset
      RESET                    => reset_i
    );
	 
		
		

    --Synchronize resetdone_i from the GT in the transmitter clock domain
    gen_resetdone_r : process(ll_clk_i, reset_i)
    begin
      if (reset_i = '1') then
        resetdone_r <= '0';
      elsif ll_clk_i'event and ll_clk_i = '1' then
        resetdone_r <= resetdone_i;
      end if;
    end process gen_resetdone_r;

    -- Create synchronous reset in the transmitter clock domain
    gen_ll_reset : process (ll_clk_i, reset_i)
    begin
      if reset_i = '1' then
        ll_pre_reset_i <= (others => '1');
        ll_reset_i     <= '1';
      elsif ll_clk_i'event and ll_clk_i = '1' then
      if resetdone_r = '1' then
        ll_pre_reset_i(0)          <= '0';
        ll_pre_reset_i(5 downto 1) <= ll_pre_reset_i(4 downto 0);
        ll_reset_i                 <= ll_pre_reset_i(5);
      end if;
      end if;
    end process gen_ll_reset;


end Behavioral;

--configuration v1_5_config of v6_emac_v1_5_top is
--	for Behavioral
--		for v6_emac_v1_5_block_inst.v6_gtxwizard_top_inst : v6_gtxwizard_top use entity v6_emac_v1_5_lib.v6_gtxwizard_top(wrapper);
--		end for;
--	end for;
--end v1_5_config;
