library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;  




-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Nexys4DdrUserDemo is
   port(
      clk_i          : in  std_logic;
      --rstn_i         : in  std_logic;
		-- Temperature sensor
		tmp_scl        : inout std_logic;
		tmp_sda        : inout std_logic;
--		tmp_int        : in std_logic; -- Not used in this project
--		tmp_ct         : in std_logic; -- Not used in this project
     -- led_o : out std_logic_vector (12 downto 0)
     grados : in std_logic;
     rst_lcd, rst_temp : in std_logic;
     rw, rs, e : out std_logic;
     lcd_data :  out std_logic_vector(7 downto 0);
     pwm_out :  out std_logic;
    led_o : out unsigned(12 downto 0);
    rgb1_red_o : out std_logic;
    rgb1_green_o : out std_logic;
    rgb1_blue_o: out std_logic
   );
end Nexys4DdrUserDemo;

architecture Behavioral of Nexys4DdrUserDemo is

----------------------------------------------------------------------------------
-- Component Declarations
----------------------------------------------------------------------------------  

-- 200 MHz Clock Generator
--component ClkGen
--port
-- (-- Clock in ports
--  clk_100MHz_i           : in     std_logic;
--  -- Clock out ports
--  clk_100MHz_o          : out    std_logic;
--  clk_200MHz_o          : out    std_logic;
--  -- Status and control signals
--  reset_i             : in     std_logic;
--  locked_o            : out    std_logic
-- );
--end component;

constant f1   : real := 1.8;        -- Clock frequency in Hz (20 ns)
constant f2   : real := 32.0;
 signal TEMPF    : unsigned(25 DOWNTO 0);
 signal fahrenheit  : STD_LOGIC_VECTOR(12 DOWNTO 0);

component main_pwm is  
port (
    clk100m : in std_logic;
    temp    : in std_logic_vector (12 downto 0);
    pwm_out : out std_logic;
    rgb1_red_o : out std_logic;
    rgb1_green_o : out std_logic;
    rgb1_blue_o: out std_logic
);
end component;

--component lcd_example is
--  PORT(
--      clk       : IN  STD_LOGIC;  --system clock
--      reset		: IN  STD_LOGIC;  --Active Low
--      bcd_temp  : in std_logic_vector(7 downto 0);
--      rw, rs, e : OUT STD_LOGIC;  --read/write, setup/data, and enable for lcd
--      lcd_data  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)); --data signals for lcd
--end component;

component bin2bcd is
    port ( 
        input:      in   std_logic_vector (15 downto 0);
        ones:       out  std_logic_vector (3 downto 0);
        tens:       out  std_logic_vector (3 downto 0);
        hundreds:   out  std_logic_vector (3 downto 0);
        thousands:  out  std_logic_vector (3 downto 0)
    );
end component;

component TempSensorCtl is
	Generic (CLOCKFREQ : natural := 100); -- input CLK frequency in MHz
	Port (
		TMP_SCL : inout STD_LOGIC;
		TMP_SDA : inout STD_LOGIC;
      -- The Interrupt and Critical Temperature Signals
      -- from the ADT7420 Temperature Sensor are not used in this design
--		TMP_INT : in STD_LOGIC;
--		TMP_CT : in STD_LOGIC;		
		TEMP_O : out STD_LOGIC_VECTOR(12 downto 0); --12-bit two's complement temperature with sign bit
		RDY_O : out STD_LOGIC;	--'1' when there is a valid temperature reading on TEMP_O
		ERR_O : out STD_LOGIC; --'1' if communication error
		CLK_I : in STD_LOGIC;
		SRST_I : in STD_LOGIC
		--led_o : out std_logic_vector(7 downto 0)
	);
end component;

component clk_wiz_100 is 
    port (-- Clock in ports
  -- Clock out ports
  clk_100          : out    std_logic;
  -- Status and control signals
  reset             : in     std_logic;
  locked            : out    std_logic;
  clk_in1           : in     std_logic
 );
end component;

component lib_lcd_intesc_revd is

GENERIC(
			FPGA_CLK : INTEGER := 100_000_000
);
PORT(
      CLK: IN STD_LOGIC;
-----------------------------------------------------
------------------PUERTOS DE LA LCD------------------
	  RS 		  : OUT STD_LOGIC;							--
	  RW		  : OUT STD_LOGIC;							--
	  ENA 	  : OUT STD_LOGIC;							--
	  DATA_LCD : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);   --
-----------------------------------------------------------
--------------ABAJO ESCRIBE TUS PUERTOS--------------------	
     -- ONES, TENS : in std_logic_vector(3 downto 0)
      onesC, tensC, onesF, tensF : std_logic_vector(3 downto 0);
      grados : in std_logic
-----------------------------------------------------------
-----------------------------------------------------------
	  );
end component;

----------------------------------------------------------------------------------
-- Signal Declarations
----------------------------------------------------------------------------------  

-- Inverted input reset signal
signal rst        : std_logic;
-- Reset signal conditioned by the PLL lock
signal reset      : std_logic;
signal locked     : std_logic;

-- 100 MHz buffered clock signal
signal clk_100MHz_buf : std_logic;
-- 200 MHz buffered clock signal
signal clk_200MHz_buf : std_logic;

-- ADT7420 Temperature Sensor raw Data Signal
signal tempValue : std_logic_vector(12 downto 0);
signal tempValueAux,tempValueF : std_logic_vector(15 downto 0);
signal tempRdy, tempErr : std_logic;
signal busy : std_logic;
signal c2f : std_logic;
signal bcd_tempC, bcd_tempF : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal bin_temp : std_logic_vector(12 downto 0);


begin
   
   -- The Reset Button on the Nexys4 board is active-low,
   -- however many components need an active-high reset
   --rst <= not rstn_i;
   -- Assign reset signals conditioned by the PLL lock
   --reset <= rst or (not locked);


----------------------------------------------------------------------------------
-- 200MHz Clock Generator
----------------------------------------------------------------------------------
--   Inst_ClkGen: ClkGen
--   port map (
--      clk_100MHz_i   => clk_i,
--      clk_100MHz_o   => clk_100MHz_buf,
--      clk_200MHz_o   => clk_200MHz_buf,
--      reset_i        => rst,
--      locked_o       => locked
--      );
      
      clock_instance : clk_wiz_100 port map ( 
        -- Clock out ports  
         clk_100 => clk_100MHz_buf,
        -- Status and control signals                
         reset => rst,
         locked => locked,
         -- Clock in ports
         clk_in1 => clk_i );
----------------------------------------------------------------------------------
-- Bin - BCD
----------------------------------------------------------------------------------

tempValueAux <= "000" & bin_temp;
tempValueF <= "000" & fahrenheit;

inst_bin2bcdF : bin2bcd port map(
        input => tempValueF,
        ones => bcd_tempF(3 downto 0),
        tens => bcd_tempF(7 downto 4));

inst_bin2bcdC : bin2bcd port map(
        input => tempValueAux,
        ones => bcd_tempC(3 downto 0),
        tens => bcd_tempC(7 downto 4));

----------------------------------------------------------------------------------
-- LCD
----------------------------------------------------------------------------------

--inst_lcd : lcd_example port map(
--        clk => clk_100MHz_buf,
--        reset => rst_lcd,
--        bcd_temp => bcd_temp,
--        rw => rw,
--        rs => rs,
--        e => e,
--        lcd_data => lcd_data);
        
        
inst_lcd_prueba : LIB_LCD_INTESC_REVD 
        GENERIC MAP (FPGA_CLK => 100_000_000)
PORT MAP(
      CLK => clk_100MHz_buf,
-----------------------------------------------------
------------------PUERTOS DE LA LCD------------------
	  RS => rs,						--
	  RW => rw,					--
	  ENA => e,							--
	  DATA_LCD => lcd_data,   --
-----------------------------------------------------------
--------------ABAJO ESCRIBE TUS PUERTOS--------------------	
      onesC => bcd_tempC(3 downto 0),
      tensC => bcd_tempC(7 downto 4),
      onesF => bcd_tempF(3 downto 0),
      tensF => bcd_tempF(7 downto 4),
      grados => grados);

----------------------------------------------------------------------------------
-- Servo
----------------------------------------------------------------------------------

inst_servo : main_pwm port map(
        clk100m => clk_100MHz_buf,
        temp => bin_temp,
        rgb1_red_o => rgb1_red_o,
        rgb1_green_o => rgb1_green_o,
        rgb1_blue_o => rgb1_blue_o,
        pwm_out => pwm_out);

----------------------------------------------------------------------------------
-- Temperature Sensor Controller
----------------------------------------------------------------------------------
	Inst_TempSensorCtl: TempSensorCtl
	GENERIC MAP (CLOCKFREQ => 100)
	PORT MAP(
		TMP_SCL        => TMP_SCL,
		TMP_SDA        => TMP_SDA,
--		TMP_INT        => TMP_INT,
--		TMP_CT         => TMP_CT,		
		TEMP_O         => tempValue,
		RDY_O          => tempRdy,
		ERR_O          => tempErr,
		
		CLK_I          => clk_100MHz_buf,
		SRST_I         => rst_temp
	);
    
	TEMPF <= (unsigned(bin_temp)*to_unsigned(integer(f1),13))+to_unsigned(integer(f2),13);
	
	fahrenheit <= STD_LOGIC_VECTOR(TEMPF(12 DOWNTO 0));
		
    led_o <= unsigned(tempValue) srl 4;
    bin_temp <= std_logic_vector(unsigned(tempValue) srl 4);

end Behavioral;