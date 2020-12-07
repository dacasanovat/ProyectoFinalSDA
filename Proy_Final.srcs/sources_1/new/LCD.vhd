LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY lcd_example IS
  PORT(
      clk       : IN  STD_LOGIC;  --system clock
      reset		: IN  STD_LOGIC;  --Active Low
      bcd_temp  : in std_logic_vector(7 downto 0);
      rw, rs, e : OUT STD_LOGIC;  --read/write, setup/data, and enable for lcd
      lcd_data  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)); --data signals for lcd
END lcd_example;

ARCHITECTURE behavior OF lcd_example IS
  SIGNAL   lcd_enable : STD_LOGIC;
  SIGNAL   lcd_bus    : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL   lcd_busy   : STD_LOGIC;
  signal   ones       : std_logic_vector(9 downto 0);
  signal   tens       : std_logic_vector(9 downto 0);
  COMPONENT lcd_controller IS
    PORT(
       clk        : IN  STD_LOGIC; --system clock
       reset_n    : IN  STD_LOGIC; --active low reinitializes lcd
       lcd_enable : IN  STD_LOGIC; --latches data into lcd controller
       lcd_bus    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0); --data and control signals
       busy       : OUT STD_LOGIC; --lcd controller busy/idle feedback
       rw, rs, e  : OUT STD_LOGIC; --read/write, setup/data, and enable for lcd
       lcd_data   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)); --data signals for lcd
  END COMPONENT;
BEGIN

  --instantiate the lcd controller
  dut: lcd_controller
    PORT MAP(clk => clk, reset_n => reset, lcd_enable => lcd_enable, lcd_bus => lcd_bus, 
             busy => lcd_busy, rw => rw, rs => rs, e => e, lcd_data => lcd_data);
             
             
  bin_to_ascii : process(bcd_temp)
  begin
    case bcd_temp(3 downto 0) is
        when "0000" => ones <= "1000110000";
        when "0001" => ones <= "1000110001";
        when "0010" => ones <= "1000110010";
        when "0011" => ones <= "1000110011";
        when "0100" => ones <= "1000110100";
        when "0101" => ones <= "1000110101";
        when "0110" => ones <= "1000110110";
        when "0111" => ones <= "1000110111";
        when "1000" => ones <= "1000111000";
        when "1001" => ones <= "1000111001";
        when others => ones <= "1000111111";
    end case;
    
    case bcd_temp(7 downto 4) is
            when "0000" => tens <= "1000110000";
            when "0001" => tens <= "1000110001";
            when "0010" => tens <= "1000110010";
            when "0011" => tens <= "1000110011";
            when "0100" => tens <= "1000110100";
            when "0101" => tens <= "1000110101";
            when "0110" => tens <= "1000110110";
            when "0111" => tens <= "1000110111";
            when "1000" => tens <= "1000111000";
            when "1001" => tens <= "1000111001";
            when others => tens <= "1000111111";
        end case;
  end process;
  
  PROCESS(clk)
    VARIABLE char  :  INTEGER RANGE 0 TO 20 := 0;
  BEGIN
    if(clk'EVENT AND clk = '1') THEN
      IF(lcd_busy = '0' AND lcd_enable = '0') THEN
        lcd_enable <= '1';

                IF(char < 20) THEN
				char := char + 1;
				END IF;
				CASE char IS            --RS,RW,D
				    WHEN 1 => lcd_bus <= ones; --ones
                    WHEN 2 => lcd_bus <= tens; --tens
--					WHEN 1 => lcd_bus <= "1001000100"; --D
--					WHEN 2 => lcd_bus <= "1001100001"; --a
--					WHEN 3 => lcd_bus <= "1001110110"; --v
--					WHEN 4 => lcd_bus <= "1001101001"; --i
--					WHEN 5 => lcd_bus <= "1001100100"; --d
--					WHEN 6 => lcd_bus <= "0011000000"; --Ir a direccion 64
--					WHEN 7 => lcd_bus <= "1001000101"; --E
--					WHEN 8 => lcd_bus <= "1001100100"; --d
--					WHEN 9 => lcd_bus <= "1001110101"; --u
--					WHEN 10 => lcd_bus <= "1001100001"; --a
--					WHEN 11 => lcd_bus <= "1001110010"; --r
--                    WHEN 12 => lcd_bus <= "1001100100"; --d
--                    WHEN 13 => lcd_bus <= "1001101111"; --o

					WHEN OTHERS => lcd_enable <= '0';
				END CASE;
      ELSE
        lcd_enable <= '0';
        END IF;
      END IF;
   
  END PROCESS;
  
END behavior;