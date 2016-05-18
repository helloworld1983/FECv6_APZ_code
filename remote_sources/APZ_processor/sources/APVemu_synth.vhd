				----------------------------------------------------------------------------------
-- Company: Universita' di Napoli 'Federico II' and INFN Sez. Napoli
-- Engineer: Raffaele Giordano
-- 
-- Create Date:    16:35:38 03/18/2011 
-- Design Name: 
-- Module Name:    filereader - Behavioral 
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
  LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;
  USE ieee.std_logic_arith.ALL;

  
  library STD;
  use std.textio.all;

entity APVemu_synth is

    generic ( data_filename : string := "C:\giordano\APV_interface\sim\lab\ROM\cern_2011_03_30.prn"); 
	           --sync_filename : string );
	 Port ( reset    : in   std_logic;
	        clk      : in   std_logic;
           apv_data : out  STD_LOGIC_VECTOR (11 downto 0));
end APVemu_synth;

architecture Behavioral of APVemu_synth is
	

  type romtype is array(0 to 1023) of bit_vector(11 downto 0);    
  impure function read_rom ( filename : in string) return romtype is   
       file in_file : text is in filename;
		 variable L : line;
		 variable good_number : boolean;
		 variable rom : romtype;
		 variable i: integer := 0;
    begin                                                        
      for j in romtype'range loop
         readline(in_file, L);
			read(L, rom(j));
		 end loop;                                                    
       return rom;                                                  
    end function;   

    
    constant apv_rom : romtype := read_rom(data_filename); 
	 signal addr : integer;

begin
	 
	-- provide stimulus 
	main : process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				addr <= 0;
			   apv_data <= (others => '0');
			else	
				addr <= addr + 1;
				apv_data <=  to_stdlogicvector(apv_rom(addr)); 
			end if;
		end if;
		
	end process;


end Behavioral;

