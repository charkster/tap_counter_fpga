// this file created 100% by Copilot
// "write a systemverilog code to debounce and count button taps 
//  with a 1 second timeout and a 1 clock cycle done signal"

//-----------------------------------------------------------------------------
// Module:  debounced tap-counter
// Description:
//   - Debounces an async push-button.
//   - Detects rising edges of the debounced signal.
//   - Starts (and restarts) a 1 s timeout on each tap.
//   - Accumulates tap count until 1 s of inactivity.
//   - Pulses `done` for exactly one clk cycle when the timeout expires.
// Parameters:
//   TIMEOUT_CYCLES   : number of clk cycles in 1 second
//   DEBOUNCE_CYCLES  : number of clk cycles for a stable button sample
//   COUNT_WIDTH      : width of the tap counter
//-----------------------------------------------------------------------------

module tap_counter_debounced #(
  parameter int TIMEOUT_CYCLES  = 50_000_000,   // e.g. 50 MHz → 1 s
  parameter int DEBOUNCE_CYCLES = 1_000_000,    // e.g. 50 MHz → 20 ms
  parameter int COUNT_WIDTH     = 8
) (
  input  logic                   clk,
  input  logic                   rst_n,        // active-low sync reset
  input  logic                   button_raw,   // async, bouncing input
  output logic [COUNT_WIDTH-1:0] count,        // total taps counted
  output logic                   done          // one-clk pulse on timeout
);

  //-------------------------------------------------------------------------
  // 1) Synchronize the raw button to our clk domain
  //-------------------------------------------------------------------------
  logic btn_sync1, btn_sync2;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      btn_sync1 <= 1'b0;
      btn_sync2 <= 1'b0;
    end else begin
      btn_sync1 <= button_raw;
      btn_sync2 <= btn_sync1;
    end
  end

  //-------------------------------------------------------------------------
  // 2) Debounce: require the sync'd input to remain stable
  //    for DEBOUNCE_CYCLES before accepting a change
  //-------------------------------------------------------------------------
  localparam int DBW = $clog2(DEBOUNCE_CYCLES);
  logic                btn_db;       // debounced output
  logic [DBW-1:0]      db_cnt;       // debounce timer
  logic                btn_last;     // last stable input

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      btn_db   <= 1'b0;
      btn_last <= 1'b0;
      db_cnt   <= '0;
    end else begin
      if (btn_sync2 != btn_last) begin
        // input changed: reset debounce counter
        db_cnt   <= '0;
        btn_last <= btn_sync2;
      end else if (db_cnt < DEBOUNCE_CYCLES-1) begin
        // still counting towards stability
        db_cnt <= db_cnt + 1;
      end else begin
        // stable long enough → update debounced output
        btn_db <= btn_last;
      end
    end
  end

  //-------------------------------------------------------------------------
  // 3) Edge detection on debounced signal
  //-------------------------------------------------------------------------
  logic btn_db_prev;
  logic btn_rising;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      btn_db_prev <= 1'b0;
    end else begin
      btn_db_prev <= btn_db;
    end
  end
  assign btn_rising = btn_db & ~btn_db_prev;

  //-------------------------------------------------------------------------
  // 4) FSM: count taps with 1 s timeout
  //-------------------------------------------------------------------------
  typedef enum logic { IDLE, COUNTING } state_t;
  state_t state;
  logic [$clog2(TIMEOUT_CYCLES)-1:0] timer;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      timer <= '0;
      count <= '0;
      done  <= 1'b0;
    end else begin
      // default: no done
      done <= 1'b0;

      case (state)
        //-------------------------------------------------------------------
        IDLE: begin
          if (btn_rising) begin
            // first tap → init count & start timer
            count <= 1;
            timer <= '0;
            state <= COUNTING;
          end
        end

        //-------------------------------------------------------------------
        COUNTING: begin
          if (btn_rising) begin
            // new tap within window → inc & restart timer
            count <= count + 1;
            timer <= '0;
          end
          else if (timer < TIMEOUT_CYCLES-1) begin
            // still inside timeout
            timer <= timer + 1;
          end
          else begin
            // timeout expired → pulse done, go back to IDLE
            done  <= 1'b1;
            state <= IDLE;
          end
        end

      endcase
    end
  end

endmodule