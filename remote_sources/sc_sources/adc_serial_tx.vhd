-- $Id: adc_serial_tx.vhd 176 2012-04-07 22:37:48Z smartoiu $
-------------------------------------------------------------------------------
-- Title      : ADC Serial Transmitter
-- Project    : TRU
-------------------------------------------------------------------------------
-- File       : adc_serial_tx.vhd
-- Author     : 
-- Company    : 
-- Created    : 2008-08-18
-- Last update: 2008-10-15
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2008 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2008-08-18  1.0      jschamba        Created
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
LIBRARY UNISIM;
USE UNISIM.vcomponents.ALL;


-------------------------------------------------------------------------------

ENTITY adc_serial_tx IS


  PORT (
    RESET : IN  std_logic;              -- reset (active high)
    SCLK  : IN  std_logic;
    SDATA : OUT std_logic;
    CS_n  : OUT std_logic;
    PDATA : IN  std_logic_vector(15 DOWNTO 0);
    ADDR  : IN  std_logic_vector (7 DOWNTO 0);
    LOAD  : IN  std_logic;
    READY : OUT std_logic
    );

END ENTITY adc_serial_tx;

-------------------------------------------------------------------------------

ARCHITECTURE str OF adc_serial_tx IS

  -----------------------------------------------------------------------------
  -- Component Declarations
  -----------------------------------------------------------------------------

  -----------------------------------------------------------------------------
  -- Internal signal declarations
  -----------------------------------------------------------------------------
  TYPE TxState_type IS (
    SIdle,
    SLatchData,
    SStartTx,
    SSendData,
    SFinish
    );
  SIGNAL TxState : TxState_type;

  SIGNAL s_shiftreg : std_logic_vector(23 DOWNTO 0);
  signal dataCtr: std_logic_vector(5 DOWNTO 0);

BEGIN  -- ARCHITECTURE str

  SDATA <= s_shiftreg(23);

  -- use a state machine to control the serial data TX
  txControl : PROCESS (SCLK, RESET) IS
--    VARIABLE dataCtr : integer RANGE 0 TO 23 := 0;
  BEGIN
    IF RESET = '1' THEN                 -- asynchronous reset (active high)
      TxState    <= SIdle;
      dataCtr    <= (others => '0');
      CS_n       <= '1';
      READY      <= '1';
      s_shiftreg <= (OTHERS => '0');
      
    ELSIF SCLK'event AND SCLK = '0' THEN  -- falling clock edge
      CS_n  <= '1';                       -- default is high (disabled)
      READY <= '0';                       -- default is not ready

      CASE TxState IS
        WHEN SIdle =>

          s_shiftreg <= (OTHERS => '0');
			 dataCtr    <= (others => '0');
          READY      <= '1';

          IF LOAD = '1' THEN
            TxState <= SLatchData;
          END IF;


        WHEN SLatchData =>
          dataCtr    <= (others => '0');
          s_shiftreg <= ADDR & PDATA;

          TxState <= SStartTx;

        WHEN SStartTx =>
          CS_n <= '0';

          TxState <= SSendData;
          
        WHEN SSendData =>
          CS_n       <= '0';
          s_shiftreg <= s_shiftreg(22 DOWNTO 0) & '0';
          dataCtr    <= dataCtr + 1;

          IF dataCtr >= 23 THEN
            TxState <= SFinish;
          END IF;

        WHEN SFinish =>
			 if LOAD = '0' then
				TxState <= SIdle;
          end if;
			 
        WHEN OTHERS =>
          TxState <= SIdle;
          
      END CASE;

    END IF;
  END PROCESS txControl;


END ARCHITECTURE str;
