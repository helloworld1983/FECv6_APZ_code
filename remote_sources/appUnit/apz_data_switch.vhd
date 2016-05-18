----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:04:44 10/12/2011 
-- Design Name: 
-- Module Name:    apz_data_switch - Behavioral 
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
--use ieee.std_logic_arith.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
use work.api_pack.all;

entity apz_data_switch is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           bigendian : in  STD_LOGIC;
           chPointer : in  STD_LOGIC_VECTOR (3 downto 0);
           nextchPointer : in  STD_LOGIC_VECTOR (3 downto 0);
           nextchPointer_valid : in  STD_LOGIC;
           earlyStart : in  STD_LOGIC;
           data_in : in  STD_LOGIC_VECTOR (255 downto 0);
           wordcount_in : in  STD_LOGIC_VECTOR (255 downto 0);
           wordcount_out : out  STD_LOGIC_VECTOR (15 downto 0);
           data_out : out  STD_LOGIC_VECTOR (7 downto 0);
           read_to_apz : out  STD_LOGIC_VECTOR (15 downto 0);
           read_from_evbld : in  STD_LOGIC);
end apz_data_switch;

architecture Behavioral of apz_data_switch is
COMPONENT fifo32kx16x8s
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END COMPONENT;

signal wordcount_mux, wordcount_mux_prefetch, datain_mux, datain_mux_i, wordcount_i, count : STD_LOGIC_VECTOR (15 downto 0);
signal wordcount_a, datain_a : array16x16;
signal fifo_wr_en, fifo_rd_en, count_en, fifo_full, fifo_empty: STD_LOGIC;

attribute KEEP : string;
attribute KEEP of fifo_full: signal is "TRUE";
attribute KEEP of fifo_empty: signal is "TRUE";

begin

	
	genren: for i in 0 to 15 generate
		read_to_apz(i) <= earlyStart when chPointer = i else '0';
		wordcount_a(i) <= wordcount_in(16*i+15 downto 16*i);
		datain_a(i) <= data_in(16*i+15 downto 16*i);
	end generate;
	
	wordcount_mux <= wordcount_a(conv_integer(chPointer));
	wordcount_mux_prefetch <= wordcount_a(conv_integer(nextchPointer));
	datain_mux <= datain_a(conv_integer(chPointer));
	
	datain_mux_i <= datain_mux when bigendian = '1' else (datain_mux(7 downto 0) & datain_mux(15 downto 8));
	
	process(clk, reset)
	begin
		if reset = '1' then
			wordcount_out <= (others => '0');
			wordcount_i <= (others => '0');
			count <= (others => '0');
			count_en <= '0';
			fifo_wr_en <= '0';
		elsif clk'event and clk = '1' then
			if earlyStart = '1' then
				wordcount_out <= wordcount_mux(14 downto 0) & '0';
			elsif nextchPointer_valid = '1' then
				wordcount_out <= wordcount_mux_prefetch(14 downto 0) & '0';
			end if;
			if earlyStart = '1' then
				wordcount_i <= wordcount_mux;
			end if;
			if earlyStart = '1' then
				count_en <= '1';
			elsif count = wordcount_i - 1 then
				count_en <= '0';
			end if;
			if count_en = '1' then
				count <= count + 1;
			else
				count <= (others => '0');
			end if;
			fifo_wr_en <= count_en;
		end if;
	end process;
	
	fifo_rd_en <= read_from_evbld;
	
data_switch_fifo : fifo32kx16x8s
  PORT MAP (
    rst => reset,
    wr_clk => clk,
    rd_clk => clk,
    din => datain_mux_i,
    wr_en => fifo_wr_en,
    rd_en => fifo_rd_en,
    dout => data_out,
    full => fifo_full,
    empty => fifo_empty
  );
	

end Behavioral;

