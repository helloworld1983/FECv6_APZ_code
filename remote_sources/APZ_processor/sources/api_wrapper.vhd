----------------------------------------------------------------------------------
-- Company: Universita' di Napoli 'Federico II' and INFN Sez. Napoli
-- Engineer: Raffaele Giordano
-- email: rgiordano@na.infn.it
-- 
-- Create Date:    12:58:11 01/13/2012 
-- Design Name: 
-- Module Name:    api_wrapper2 - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
use work.api_pack.all;

entity APV_Interface_multi_wrap is
Port (     clk : in  STD_LOGIC; 
           clk125 : in  STD_LOGIC;
			  clk10 : in  STD_LOGIC; 
           reset : in  STD_LOGIC;
           
			  cfg_zs: in STD_LOGIC_VECTOR (31 downto 0) := x"00000000";

           apv_select : in std_logic_vector(3 downto 0);
			  apv_mask : in std_logic_vector(15 downto 0);
           -- apv_data : in  array16x12;
           apv_data : in  std_logic_vector(191 downto 0);
			  
			  -- system trigger, not the APV trigger
			  trigger_in : in std_logic;
			  
			  -- n.of time bins per trigger 
			  n_samples : in  STD_LOGIC_VECTOR (LOG2_MAX_SAMPLES-1 downto 0);
			  
			  -- processed data out
			  read_in        : in   STD_LOGIC_VECTOR (15 downto 0);  
			  output_enable  : in   STD_LOGIC_VECTOR (15 downto 0); 
			  data_out       : out  std_logic_vector(255 downto 0); 
			  ready_out      : out  STD_LOGIC_VECTOR (15 downto 0);  
           wordcount_out  : out  std_logic_vector(255 downto 0); 
			  			  
			  -- pedestal calculation
			  start_calib : in  STD_LOGIC;                     -- set high for 1 clock cycle, to start autoset    
			  busy : out  STD_LOGIC; 
			  pedestal_wd_flag : out std_logic;
			  
			  -- pedestal filereg access, meant to be driven by Slow Control
			 filereg_apvselect : in  STD_LOGIC_VECTOR (3 downto 0);
			 load_pedestal : in  STD_LOGIC;                        -- load pedestal_in value into pedestal reg 
          pedestal_addr : in  STD_LOGIC_VECTOR (6 downto 0);
			 pedestal_in   : in  STD_LOGIC_VECTOR (11 downto 0);   -- external pedestal input 
          pedestal_out  : out  STD_LOGIC_VECTOR (11 downto 0);   -- current pedestal setting
			  
			 load_sigma    : in  STD_LOGIC;
			 sigma_in      : in  STD_LOGIC_VECTOR (11 downto 0);
			 sigma_addr    : in  STD_LOGIC_VECTOR (6 downto 0);			  
			 sigma_out     : out  STD_LOGIC_VECTOR (11 downto 0);   -- pedestal st.dev

  		    random_trigger : out  STD_LOGIC;
			  
			  
			  -- TPLL phase manging signals
			  resync: in  STD_LOGIC;
			  trigger_inhibit : out  STD_LOGIC;      
           phase_aligned : out  STD_LOGIC; 
			  I2C_request : out  STD_LOGIC;
           I2C_done : in  STD_LOGIC;
           I2C_ctr2 : out  STD_LOGIC_VECTOR (4 downto 0)
			  
			  );
end APV_Interface_multi_wrap;

architecture Behavioral of APV_Interface_multi_wrap is
	COMPONENT APV_Interface_multi
Port (     clk : in  STD_LOGIC; 
           clk125 : in  STD_LOGIC;
			  clk10 : in  STD_LOGIC; 
           reset : in  STD_LOGIC;
           
			  cfg_zs: in STD_LOGIC_VECTOR (31 downto 0) := x"00000000";

           apv_select : in std_logic_vector(3 downto 0);
			  apv_mask : in std_logic_vector(15 downto 0);
           apv_data : in  array16x12;
			  
			  -- system trigger, not the APV trigger
			  trigger_in : in std_logic;
			  
			  -- n.of time bins per trigger 
			  n_samples : in  STD_LOGIC_VECTOR (LOG2_MAX_SAMPLES-1 downto 0);
			  
			  -- processed data out
			  read_in        : in   STD_LOGIC_VECTOR (15 downto 0);  
			  output_enable  : in   STD_LOGIC_VECTOR (15 downto 0); 
			  data_out       : out  array16x16; 
			  ready_out      : out  STD_LOGIC_VECTOR (15 downto 0);  
           wordcount_out  : out  array16x16; 
			  			  
			  -- pedestal calculation
			  start_calib : in  STD_LOGIC;                     -- set high for 1 clock cycle, to start autoset    
			  busy : out  STD_LOGIC; 
			  pedestal_wd_flag : out std_logic;
			  
			  -- pedestal filereg access, meant to be driven by Slow Control
			 filereg_apvselect : in  STD_LOGIC_VECTOR (3 downto 0);
			 load_pedestal : in  STD_LOGIC;                        -- load pedestal_in value into pedestal reg 
          pedestal_addr : in  STD_LOGIC_VECTOR (6 downto 0);
			 pedestal_in   : in  STD_LOGIC_VECTOR (11 downto 0);   -- external pedestal input 
          pedestal_out  : out  STD_LOGIC_VECTOR (11 downto 0);   -- current pedestal setting
			  
			 load_sigma    : in  STD_LOGIC;
			 sigma_in      : in  STD_LOGIC_VECTOR (11 downto 0);
			 sigma_addr    : in  STD_LOGIC_VECTOR (6 downto 0);			  
			 sigma_out     : out  STD_LOGIC_VECTOR (11 downto 0);   -- pedestal st.dev

  		    random_trigger : out  STD_LOGIC;
			  
			  
			  -- TPLL phase manging signals
			  resync: in  STD_LOGIC;
			  trigger_inhibit : out  STD_LOGIC;      
           phase_aligned : out  STD_LOGIC; 
			  I2C_request : out  STD_LOGIC;
           I2C_done : in  STD_LOGIC;
           I2C_ctr2 : out  STD_LOGIC_VECTOR (4 downto 0)
			  
			  );
	END COMPONENT;
signal apv_data_a: array16x12;
signal data_out_a, wordcount_out_a: array16x16;

begin
	uu: for i in 0 to 15 generate
		apv_data_a(i) <= apv_data(12*i+11 downto 12*i);
		data_out(16*i+15 downto 16*i) <= data_out_a(i);
		wordcount_out(16*i+15 downto 16*i) <= wordcount_out_a(i);
	end generate;

	Inst_APV_Interface_multi: APV_Interface_multi PORT MAP(
		clk => clk,
		clk125 => clk125,
		clk10 => clk10,
		reset => reset,
		cfg_zs => cfg_zs,
		apv_select => apv_select,
		apv_mask => apv_mask,
		apv_data => apv_data_a,
		trigger_in => trigger_in,
		n_samples => n_samples,
		read_in => read_in,
		output_enable => output_enable,
		data_out => data_out_a,
		ready_out => ready_out,
		wordcount_out => wordcount_out_a,
		start_calib => start_calib,
		busy => busy,
		pedestal_wd_flag => pedestal_wd_flag,
		
		filereg_apvselect => filereg_apvselect,
		load_pedestal => load_pedestal,
		pedestal_addr => pedestal_addr,
		pedestal_in => pedestal_in,
		pedestal_out => pedestal_out,
		load_sigma => load_sigma,
		sigma_in => sigma_in,
		sigma_addr => sigma_addr,
		sigma_out => sigma_out,
		random_trigger => random_trigger,
		resync => resync,
		trigger_inhibit => trigger_inhibit,
		phase_aligned => phase_aligned,
		I2C_request => I2C_request,
		I2C_done => I2C_done,
		I2C_ctr2 => I2C_ctr2
	);

end Behavioral;

