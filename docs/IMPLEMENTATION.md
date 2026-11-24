# Implementation and verification notes

## Relation to the course report

Report Figures 1, 18 and 19 define the visible TX interface, FIFO behavior and extended-system wiring. Figures 21-23 show word transfer and the final bytes B2 CA F0 0F. The release follows the documented WAIT/READ/LOAD/SHIFT/DONE/FINISH TX flow and the required separation between FIFO READ and RAM WRITE.

The FIFO's registered output requires two distinct cycles: READ consumes the head and updates dout at the edge; WRITE stores that updated byte in RAM at the next edge. Serial RX captures the first valid bit while leaving IDLE, so bit 0 is not lost. Pauses in tx_vld do not advance its bit counter.

The extension writes ROM data on inc_adrs_tx, NOT the shifted TBUF contents, which have already shifted out by that point. The transmitter is permanently ready in this four-word FIFO top level, as in Figure 19. Four emitted bytes fit the FIFO even with a delayed receiver. This is a bounded batch design; arbitrary-length streams need full-to-TX backpressure.

## Timing and initialization

All modules share one rising-edge clock. clr is asynchronous and active high. Serial data is sampled only when tx_vld is high. TX consults rx_rdy at word boundaries. ROM is combinational; rd_mem exposes the READ state for observation. Reset clears address/counters, receive buffers and RAM; FIFO storage need not clear because count=0 makes old contents invalid.

At full/empty, FIFO simultaneous requests use pre-edge acceptance, exactly as the case condition in Figure 18. No fall-through or same-cycle empty forwarding is implied. Fixed 2-bit addresses and a 3-bit count implement exactly 4 x 8 bits.

## Files

- rtl/tx.v: TX FSM, ROM, address and shift registers, block_TX.
- rtl/rx.v: RX RAM, serial block_RX and word block_RX_fifo.
- rtl/fifo.v: 4 x 8 synchronous queue.
- rtl/system.v: serial and FIFO top levels.
- tb/: self-checking tests with explicit timeouts and nonzero failure exits.

## Reproduce

Run `make test`; VCDs appear in build/. See verification.txt for tool output. These checks establish simulated behavior for the included test scenarios, not FPGA timing, hardware operation or exhaustive formal correctness.
