-- TestBench Template 
-- Company: Universita' di Napoli 'Federico II' and INFN Sez. Napoli
-- Engineer: Raffaele Giordano
-- email: rgiordano@na.infn.it

  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;
  USE ieee.std_logic_arith.ALL;
  USE ieee.STD_LOGIC_TEXTIO.ALL;
  Library UNISIM;
  use UNISIM.vcomponents.all;

  ENTITY hardware_testbench IS
  	PORT(
		clk_prebufg : IN std_logic;
		reset : IN std_logic;
		dataout : OUT std_logic_vector(11 downto 0);
		channel : out  STD_LOGIC_VECTOR (6 downto 0);
		datavalid : OUT std_logic
		);	
  
  END hardware_testbench;

  ARCHITECTURE behavior OF hardware_testbench IS 

  
  	COMPONENT APV_parser
	PORT(
		clk : IN std_logic;
		reset : IN std_logic;
		threshold : in  STD_LOGIC_VECTOR (11 downto 0);
		datain : IN std_logic_vector(11 downto 0);          
		address : OUT std_logic_vector(7 downto 0);
		error : OUT std_logic;
		dataout : OUT std_logic_vector(11 downto 0);
		channel : out  STD_LOGIC_VECTOR (6 downto 0);
		datavalid : OUT std_logic
		);
	END COMPONENT;
	

	COMPONENT APVemu_synth 
    generic ( data_filename : string := "C:\giordano\APV_interface\sim\lab\ROM\cern_2011_03_30.prn"); 
    Port ( reset    : in   std_logic;
	        clk      : in   std_logic;
           apv_data : out  STD_LOGIC_VECTOR (11 downto 0));
	end COMPONENT;
	
	
	signal	address : std_logic_vector(7 downto 0);
	signal	error   : std_logic;
	signal  apv_data : std_logic_vector(11 downto 0) ;
   signal  clk : std_logic;
	
  BEGIN
 
  i_bufg : bufg port map ( i=> clk_prebufg, o => clk);
  
	Inst_APV_parser: APV_parser PORT MAP(
		clk => clk,
		reset => reset,
		datain => apv_data,
		threshold => conv_std_logic_vector(1200,12),
		address => address,
		error => error,
		dataout => dataout,
		channel => channel,
		datavalid => datavalid
	);

    APV_Emu : APVemu_synth  PORT MAP(
        clk => clk,
		reset => reset,
		apv_data => apv_data
	);
	
  END;
