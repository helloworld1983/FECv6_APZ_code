----------------------------------------------------------------------------------
-- Company: Universita' di Napoli 'Federico II' and INFN Sez. Napoli
-- Engineer: Raffaele Giordano
-- email: rgiordano@na.infn.it
--
----------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.api_pack.all;

entity APV_Processor is
    Port ( 
	        -- clock at 40 MHz, for the front-end part 
	        clk : in  STD_LOGIC;    
			  
			  -- clock at 10 MHz, for slow operations, currently unused 
	        clk10 : in std_logic;    
			  
			  -- clock at 125 MHz, for the back-end part
	        clk125 : in  STD_LOGIC;  
			  
			  -- synhcronous reset for the APV_processor
           reset : in  STD_LOGIC;   
			  
			  -- configuration register:
			  --  bits  
			  --  7:2  fractional part of the  threshold, ignored if threshold_mode flag ='0'
			  --  13:8 integer part of the threshold, ignored if threshold_mode flag ='0'
	        --  16   peak_find_enable  peak find mode enable 
	        --  18   force_pedestal    force pedestal to 0 for all the channels
			  --  19   force_signal      do not suppress signals
	        --  20   threshold_mode    -- '0' basic : threshold = n_samples * 1, '1' advanced: threshold set by SC
           cfg_zs: in STD_LOGIC_VECTOR (31 downto 0) := x"00000000";
           
           -- apv 12-bit digitized data
			  apv_data : in  STD_LOGIC_VECTOR (11 downto 0);
           
			  -- system trigger, not the APV trigger
			  trigger_in : in std_logic;
			  
			  -- n.of time bins expected per trigger 
			  n_samples : in  STD_LOGIC_VECTOR (LOG2_MAX_SAMPLES-1 downto 0);
			  
			  -- zero suppressor output
			  -- enable read from the suppressor
	        read_in       : in   STD_LOGIC; 
			  
			  -- enable the output, read-out from the zero suppressor 
			  -- can be stopped on a per-cycle basis by driving this bit low.
			  output_enable : in std_logic;
			  
			  -- data from the suppressor, signed 16-bits as described in the 
			  -- SRS ZS Data Format
			  data_out      : out  STD_LOGIC_VECTOR (15 downto 0); 
			  
			  -- read out flag
			  ready_out     : out  STD_LOGIC; 
			  
			  -- data descriptor, flags how many words will be read trough the data_out
			  -- output upon a read_in request
           wordcount_out  : out  STD_LOGIC_VECTOR (15 downto 0); 
			  
           -- header threshold for the parser			  
           load_hdr_threshold : in std_logic;
			  hdr_threshold : in  STD_LOGIC_VECTOR (APV_WORD_SIZE-1 downto 0);
			  
			  -- debug info from the parser, discard this information
			  -- please do not connect these signals
			  parsed_data : OUT std_logic_vector(APV_WORD_SIZE-1 downto 0);
			  parsed_datavalid : OUT std_logic;
			  parsed_chan : OUT std_logic_vector(APV_LOG2_CHANNELS-1 downto 0);
			  address : OUT std_logic_vector(7 downto 0);
   		  error : OUT std_logic;
			  
			 -- Pedestal/sigma file register IO access
			 
			 -- load pedestal_in value into pedestal register at of channel pedestal_addr
			 load_pedestal : in  STD_LOGIC;                       
          -- channel to write to (or read from)
			 pedestal_addr : in  STD_LOGIC_VECTOR (6 downto 0);
			 -- pedestal value to write
			 pedestal_in   : in  STD_LOGIC_VECTOR (11 downto 0);   
			 -- pedestal value retrieved from the register file
          pedestal_out  : out  STD_LOGIC_VECTOR (11 downto 0);   
			 
          -- analogous meaning to the pedestal bus signals			 
			 load_sigma    : in  STD_LOGIC;
			 sigma_in      : in  STD_LOGIC_VECTOR (11 downto 0);
			 sigma_addr    : in  STD_LOGIC_VECTOR (6 downto 0);			  
			 sigma_out     : out  STD_LOGIC_VECTOR (11 downto 0);  
		  
			  -- debug signals, please do not connect 
			  dbg_sigma : out STD_LOGIC_VECTOR (11 downto 0);
			  dbg_pedestal : out STD_LOGIC_VECTOR (11 downto 0);
			  dbg_sample  : out STD_LOGIC_VECTOR (LOG2_MAX_SAMPLES-1 downto 0);
			  dbg_chan  : out STD_LOGIC_VECTOR (6 downto 0)
			  
			  );
end APV_Processor;

architecture beh of APV_Processor is

  	COMPONENT APV_parser
	PORT(
		clk : IN std_logic;
		reset : IN std_logic;
			  threshold: in  STD_LOGIC_VECTOR (11 downto 0);
		datain : IN std_logic_vector(11 downto 0);          
		address : OUT std_logic_vector(7 downto 0);
		error : OUT std_logic;
		dataout : OUT std_logic_vector(11 downto 0);
		channel : out  STD_LOGIC_VECTOR (6 downto 0);
		datavalid : OUT std_logic
		);
	END COMPONENT;
	
	
	 COMPONENT Zero_Suppressor is
	 GENERIC (APV_ID : integer := 0);
	 Port ( clk : in  STD_LOGIC;
	        slowclk : in  STD_LOGIC;
	        reset : in  STD_LOGIC;   
           -- data
			  data_in : in  STD_LOGIC_VECTOR (APV_WORD_SIZE-1 downto 0);
			  dvalid_in : in  STD_LOGIC;
			  sigma_in : in STD_LOGIC_VECTOR (11 downto 0);
			  pedestal_in : in  STD_LOGIC_VECTOR (11 downto 0);
			  n_samples : in std_logic_vector(LOG2_MAX_SAMPLES-1 downto 0);
           chan_in : in  STD_LOGIC_VECTOR (APV_LOG2_CHANNELS-1 downto 0);
			  sample_in : in  STD_LOGIC_VECTOR (LOG2_MAX_SAMPLES-1 downto 0);
			  -- commands
			  cfg_reg: in STD_LOGIC_VECTOR (31  downto 0) := x"00000000";
			  start_reading : in std_logic;
			  output_enable : in std_logic;
			  ready : out std_logic;
			  
			  -- outputs
			  data_out : out  STD_LOGIC_VECTOR (15  downto 0);
			  word_count : out std_logic_vector (15 downto 0);
			  -- buffer ctrl
			  buf_double : in std_logic;
			  buf_addr_out : out  STD_LOGIC_VECTOR (APV_LOG2_CHANNELS + LOG2_MAX_SAMPLES - 1 downto 0);
			  buf_read_out : out  STD_LOGIC;
			  buf_released_out : out  STD_LOGIC
           );
	end COMPONENT;
	
	COMPONENT Data_sorter is
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
			  
           buf_double : in std_logic;
			  buf_released_in : in std_logic;
			  buf_mode_in : in std_logic;
			  buf_addr_in : in std_logic_vector(APV_LOG2_CHANNELS + LOG2_MAX_SAMPLES - 1 downto 0);

			  data_out : out  STD_LOGIC_VECTOR (APV_WORD_SIZE-1 downto 0);
           sample_out : out  STD_LOGIC_VECTOR (LOG2_MAX_SAMPLES-1 downto 0);
			  chan_out : out  STD_LOGIC_VECTOR (APV_LOG2_CHANNELS-1 downto 0);
			  dvalid_out : out  STD_LOGIC);
	end COMPONENT;
	
	-- Parser signals
   signal   channel : STD_LOGIC_VECTOR (APV_LOG2_CHANNELS-1 downto 0);
	signal   parsed_data_i : std_logic_vector(APV_WORD_SIZE-1 downto 0);
	signal   parsed_datavalid_i : std_logic;
	signal   hdr_threshold_r : std_logic_vector(APV_WORD_SIZE-1 downto 0);
	
	-- Sorter signals
	signal   sorted_data : std_logic_vector(APV_WORD_SIZE-1 downto 0);
	signal   sorted_datavalid : std_logic;
	signal   sorted_channel : STD_LOGIC_VECTOR (APV_LOG2_CHANNELS-1 downto 0);
	signal   sorted_sample : STD_LOGIC_VECTOR (LOG2_MAX_SAMPLES-1 downto 0);

	-- Zero Suppressor signals  
	signal   suppression_threshold : std_logic_vector(17 downto 0);
	signal   suppressed_data : std_logic_vector(APV_WORD_SIZE downto 0);
	signal	suppressed_datavalid :  std_logic;
  
	-- filereg signals
	signal   sigma : std_logic_vector(11 downto 0);
	signal   pedestal : std_logic_vector(11 downto 0);
	
	-- buffer signals
	signal buf_double : std_logic;
	signal buf_released :  std_logic;
   signal buf_read :  std_logic;
	signal buf_addr :  std_logic_vector(APV_LOG2_CHANNELS + LOG2_MAX_SAMPLES - 1 downto 0);

	
	
begin

   -- debug signals
  dbg_sigma <= sigma;
  dbg_pedestal <= pedestal;
  dbg_sample <= sorted_sample;
  dbg_chan  <= sorted_channel;

   --IO
   parsed_data <= parsed_data_i;
	parsed_datavalid <= parsed_datavalid_i;
	parsed_chan <= channel;
	
	 header_threshold_register : process (clk, reset)
    begin
        if (CLK'event and CLK='1') then
          if (reset='1') then
            hdr_threshold_r <= conv_std_logic_vector(1500,hdr_threshold_r'length);
          elsif load_hdr_threshold = '1' then
            hdr_threshold_r <= hdr_threshold;
          end if;
        end if;
    end process;

   
	DataParse_unit: APV_parser PORT MAP(
		clk => clk,
		reset => reset,
		threshold => hdr_threshold_r,
		datain => apv_data,
		address => address,
		error => error,
		dataout => parsed_data_i,
		channel => channel, 
		datavalid => parsed_datavalid_i
	);


	Sort_unit: Data_sorter PORT MAP(
		clk => clk125,
		wclk => clk,
		reset => reset,
		trigger_in => trigger_in,
		data_in => parsed_data_i,
		dvalid_in => parsed_datavalid_i,
		n_samples => n_samples,
		chan_in => channel,
		buf_double => buf_double,
		buf_mode_in => buf_read, 
		buf_released_in => buf_released, 
		buf_addr_in => buf_addr, 
		data_out => sorted_data,
		chan_out => sorted_channel,
		sample_out => sorted_sample,
		dvalid_out => sorted_datavalid
	);
	
   --buf_double <= '0' when (n_samples > 15) else '1';
	-- automatic double buffering disabled
	buf_double <= '0';
	
    pedestal_freg: file_register
	generic map (APV_LOG2_CHANNELS, APV_WORD_SIZE)
    port map (we => load_pedestal,
		      dataIN => pedestal_in,
			  wclk => clk,
			  addrA => pedestal_addr,
			  addrB => sorted_channel,
			  dataA => pedestal_out,   -- 0 latency
			  dataB => pedestal);      -- 0 latency 	
	
	sigma_freg: file_register
	generic map (APV_LOG2_CHANNELS, APV_WORD_SIZE)
    port map (we => load_sigma,
		      dataIN => sigma_in,
			  wclk => clk,
			  addrA => sigma_addr,
			  addrB => sorted_channel,
			  dataA => sigma_out,   -- 0 latency
			  dataB => sigma);      -- 0 latency 			  
			  
	
	
	ZeroSuppression_unit: Zero_Suppressor PORT MAP(
		clk => clk125,
		slowclk => clk10,
		reset => reset,
		data_in => sorted_data,
		dvalid_in => sorted_datavalid,
		sigma_in => sigma,
		pedestal_in => pedestal,
		n_samples => n_samples,
		chan_in => sorted_channel, -- yes, needs a chan_in
		sample_in => sorted_sample,
		cfg_reg => cfg_zs,
		
		-- zs read interface 
		ready => ready_out,
		start_reading => read_in,
		output_enable => output_enable,
		data_out => data_out,
		word_count => wordcount_out,
		buf_double => buf_double,
		buf_addr_out => buf_addr,
		buf_read_out => buf_read,
		buf_released_out => buf_released
	);
   
	--data_out <= suppressed_data;
	--data_valid <= suppressed_datavalid;

end beh;

