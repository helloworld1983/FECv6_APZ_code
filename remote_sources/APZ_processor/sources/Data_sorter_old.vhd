----------------------------------------------------------------------------------
-- Company: Universita' di Napoli 'Federico II' and INFN Sez. Napoli
-- Engineer: Raffaele Giordano
-- email: rgiordano@na.infn.it
--
-- Create Date:    19:16:18 08/15/2011 
-- Design Name: 
-- Module Name:    Data_sorter - Behavioral 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.api_pack.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Data_sorter is
    Port ( clk : in  STD_LOGIC;
	        wclk : in  STD_LOGIC;
			  -- synch on wclk
			  reset : in  STD_LOGIC; -- need a reset each time n_samples is changed
			  trigger_in : in STD_LOGIC;
           data_in : in  STD_LOGIC_VECTOR (APV_WORD_SIZE-1 downto 0);
           dvalid_in : in  STD_LOGIC;
			  n_samples : in std_logic_vector(LOG2_MAX_SAMPLES-1 downto 0);
           chan_in : in  STD_LOGIC_VECTOR (APV_LOG2_CHANNELS-1 downto 0);
           -- synch on clk

			  buf_released_in : in std_logic;
			  buf_mode_in : in std_logic;
			  buf_addr_in : in std_logic_vector(APV_LOG2_CHANNELS + LOG2_MAX_SAMPLES - 1 downto 0);

			  data_out : out  STD_LOGIC_VECTOR (APV_WORD_SIZE-1 downto 0);
           sample_out : out  STD_LOGIC_VECTOR (LOG2_MAX_SAMPLES-1 downto 0);
			  chan_out : out  STD_LOGIC_VECTOR (APV_LOG2_CHANNELS-1 downto 0);
			  dvalid_out : out  STD_LOGIC);
end Data_sorter;

architecture Behavioral of Data_sorter is

	component dualport_ram is
	 generic(M: natural);
    Port ( we 		  : in std_logic;						 -- write enable
           datain	  : in std_logic_vector(11 downto 0);   -- data input
           wclk 	  : in std_logic;						 -- writing clock
           rclk 	  : in std_logic;						 -- read clock
           
           wr_addr  : in std_logic_vector(M-1 downto 0);   -- write address 
           rd_addr  : in std_logic_vector(M-1 downto 0);   -- read address 
           dataout  : out std_logic_vector(11 downto 0)   -- data out 
           ); -- data out B
	end component;

	COMPONENT syncronizer
	PORT(
		clk : IN std_logic;
		async_in : IN std_logic;          
		sync_out : OUT std_logic
		);
	END COMPONENT;

-- 2^13 words => 2 bufs x 0.6 us @ 40 MHz
constant LOG2_BUFFER_DEPTH : integer := 1+chan_in'length+sample_out'length;
	 
signal delta : std_logic_vector(15 downto 0);
signal rd_addr,wr_addr : std_logic_vector(LOG2_BUFFER_DEPTH-1 downto 0);
signal rd_bank, wr_bank : std_logic;

signal chan_out_i: std_logic_vector(chan_in'length-1 downto 0);
signal sample_in,sample_out_i : std_logic_vector(n_samples'length-1 downto 0);

signal read_enable : std_logic;
signal write_enable : std_logic;

-- internal reset
signal reset_q : std_logic;
signal reset_rd : std_logic;
--signal reset_wr : std_logic;

signal buf_released_s40 : std_logic;

begin

	-- assign IOs		
	write_enable <= dvalid_in;

   -- outputs latency compensators	
   outpipes : process(clk)
	begin
		if rising_edge(clk) then
			chan_out <= rd_addr(chan_in'length-1 downto 0); -- chan_out_i
			sample_out <= rd_addr(rd_addr'length - 2 downto chan_in'length); -- sample_out_i;
			dvalid_out <= read_enable;
	   end if;
	end process;
  
   -- double buffer, it is capable to store 2^13 12-bit words 
   -- 2^12 words per buffer => 2^5 samples x 128 channels
   data_buffer: dualport_ram
	generic map (LOG2_BUFFER_DEPTH)--, data_in'length)
   port map (we => write_enable,
				 datain => data_in,
				 wclk => wclk,
				 rclk => clk, 
				 wr_addr => wr_addr,
				 rd_addr => rd_addr,
				 dataout => data_out );
		
		
	-- must be registered on the clk clock domain
   -- will add a synchronizer
	-- only enables the reading when the previous buffer has been fully processed
	read_enable <= '0' when rd_bank = wr_bank else buf_released_in;	
	read_logic : process(clk)
	begin
		if rising_edge(clk) then
		
		   reset_q <= reset;
         reset_rd <= reset_q;
			
			if reset_rd = '1' then
				chan_out_i <= (others => '0');
				sample_out_i <= (others => '0');
				rd_bank <= '0';
				
			else
				 
				-- read ptr logic
				if read_enable='1' then
				   if sample_out_i < n_samples - 1 then
						sample_out_i <= sample_out_i + 1 ;
					else 
						sample_out_i <= (others =>'0');
						
						if chan_out_i < 127 then
							chan_out_i <= chan_out_i + 1;
						else
						   rd_bank <= not rd_bank;
							chan_out_i <= (others =>'0');
						end if;
					end if;
	         end if;
			end if;
		end if;
	end process;
	
	-- read/write address mixing
	rd_addr <= rd_bank & sample_out_i & chan_out_i when buf_mode_in = '0' else rd_bank & buf_addr_in;
	wr_addr <= wr_bank & sample_in & chan_in;
	

  	Inst_syncronizer: syncronizer PORT MAP(
		clk => wclk,
		async_in => buf_released_in,
		sync_out => buf_released_s40 
	);	
	
	
	wr_sample_counter : process(wclk)
	begin
		if rising_edge(wclk) then
			
			if reset = '1' then
	
				sample_in <=  (others => '0');
				wr_bank <= '0';
				
			else
			   -- on a trigger, change writing buffer, if the read_bank has been released
				if trigger_in = '1' then
					sample_in <= (others => '0');
					
					if buf_released_s40 = '1' then
							wr_bank <= not wr_bank;
					end if;
							
				else
					
					-- sample counter 
					if dvalid_in='1' and chan_in=127 then
						if sample_in < n_samples - 1 then
							sample_in  <= sample_in + 1 ;
						else 
							sample_in <= (others =>'0');
						end if;
					end if;
					
            end if;
				
			end if;
		end if;
	end process;
	
 end Behavioral;

