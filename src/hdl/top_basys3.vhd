--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
-- TODO
        port (
            --Inputs
            btnU: in std_logic;
            btnC: in std_logic;
            clk: in std_logic;
            
            sw: in std_logic_vector(7 downto 0);
            
            --Outputs
            seg: out std_logic_vector(6 downto 0);
            
            led: out std_logic_vector(15 downto 0)
            
        );
        
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
        component TDM4 is
            generic ( constant k_WIDTH : natural  := 4);
            port(
                i_clk		: in  STD_LOGIC;
                i_reset		: in  STD_LOGIC; -- asynchronous
                i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		        i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		        i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		        i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		        o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		        o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
		        );
		end component TDM4;
		   
		component ALU is
		  port(
		        --Inputs
                i_A: in std_logic_vector(7 downto 0);
                 
                i_B: in std_logic_vector(7 downto 0);
                 
                i_op: in std_logic_vector(3 downto 0);
                     
                --Outputs
                o_flags: out std_logic_vector(2 downto 0);
                     
                o_result: out std_logic_vector(7 downto 0)
		  );
		end component ALU;
		  
		component clock_divider is
          generic ( constant k_DIV : natural := 2    ); -- How many clk cycles until slow clock toggles
                                                         -- Effectively, you divide the clk double this 
                                                         -- number (e.g., k_DIV := 2 --> clock divider of 4)
          port ( 
                i_clk    : in std_logic;
                i_reset  : in std_logic;           -- asynchronous
                o_clk    : out std_logic           -- divided (slow) clock
          );
        end component clock_divider;
        
        component twoscomp_decimal is
          port (
                i_binary: in std_logic_vector(7 downto 0);
                o_negative: out std_logic;
                o_hundreds: out std_logic_vector(3 downto 0);
                o_tens: out std_logic_vector(3 downto 0);
                o_ones: out std_logic_vector(3 downto 0)
          );
        end component twoscomp_decimal;
		  
		component sevenSegDecoder is
            Port ( 
                i_D : in STD_LOGIC_VECTOR (3 downto 0);
                o_S : out STD_LOGIC_VECTOR (6 downto 0)
                );
        end component sevenSegDecoder;
        
        component Controller_fsm is
          Port (
            --Inputs
            i_reset: in std_logic;
            
            i_adv: in std_logic;
            
            --Outputs
            o_cycle: out std_logic_vector(3 downto 0)
           );
        end component Controller_fsm;
        
		  --Signals
		  signal w_reset: std_logic; 
		  signal w_adv: std_logic;
		  signal w_clk: std_logic;
		  		  		  
		  signal w_flags: std_logic_vector(2 downto 0);
		  		  
		  signal w_hund: std_logic_vector(3 downto 0);
		  signal w_tens: std_logic_vector(3 downto 0);
		  signal w_ones: std_logic_vector(3 downto 0);
		  signal w_wire: std_logic_vector(3 downto 0);
		  signal w_gone: std_logic_vector(3 downto 0);
		  signal w_op: std_logic_vector(3 downto 0);
		  signal w_sign: std_logic;
		  signal w_cycle: std_logic_vector(3 downto 0);
		  
		  signal w_bin: std_logic_vector(7 downto 0);
		  signal w_result: std_logic_vector(7 downto 0);
		  signal w_regA: std_logic_vector(7 downto 0);
		  signal w_regB: std_logic_vector(7 downto 0);
		  signal w_A: std_logic_vector(7 downto 0);
		  signal w_B: std_logic_vector(7 downto 0);
		  
begin
	-- PORT MAPS ----------------------------------------
        ALU_inst: ALU
        port map(
            i_A => w_A,
            i_B => w_B,
            i_op => w_op,
            
            o_flags => w_flags,
            o_result => w_result
        );  
	
	    TDM4_inst: TDM4
	    port map(
	       i_clk => w_clk,
           i_reset => btnU,
           i_D3 => w_ones,
           i_D2 => w_tens,
           i_D1 => w_hund,
           i_D0 => w_sign,
           o_data => w_wire,
           o_sel => w_gone
	    );
	   
	   
	   clk_div_inst: clock_divider
            generic map(k_DIV => 50000000)
            port map (
                i_clk => clk,
                i_reset => btnU,
                o_clk => w_clk
            );
         
         
         twoscomp_decimal_inst: twoscomp_decimal
            port map (
                i_binary => w_bin,
                o_negative => w_sign,
                o_hundreds => w_hund,
                o_tens => w_tens,
                o_ones => w_ones
            );
            
          sevenSegDecoder_inst: sevenSegDecoder
                port map( 
                    i_D => w_wire,
                    o_S => seg
                );
                
          Controller_fsm_isnt: Controller_fsm
                Port map(
                    --Inputs
                    i_reset => btnU,
                            
                    i_adv => btnC,
                            
                    --Outputs
                    o_cycle => w_cycle
                );
            
	-- CONCURRENT STATEMENTS ----------------------------
	w_op <= sw(3 downto 0);
	
	w_A <= sw(7 downto 0) when w_cycle = "0010";
	
	w_B <= sw(7 downto 0) when w_cycle = "0100";
	
	w_bin <= w_A when w_cycle = "0001" else
	         w_B when w_cycle = "0010" else
	         w_result;
    
    led(3 downto 0) <= w_cycle;
    
    led(15 downto 13) <= w_flags;
	
	led(12 downto 4) <= (others => '0');
	
end top_basys3_arch;
