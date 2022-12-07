<Set interrupt occur time : 1200 in external_device>
[1] An external device sends an interrupt to a CPU. (ed_interrupt_in is raised from External Device.)
	<In waveform> at 120250ns, ed_interrupt_in : 0 -> 1 

[2] The CPU sends a dma_length(d12), and dma_base_address(h17) to dma_controller 

[3] DMA_controller raises a BR(Bus Request) signal. (BR is raised from DMA_controller)
	<In waveform> at 120250ns, BR signal : 0 -> 1

[4] The CPU receives the BR signal, then wait until the use of bus is complete.
	It means that, waitCache signal is 0 or dataReady is 1 for both ICache and DCache.
	<In waveform> at 120400ns, ICache : waitCache is 1, but dataReady is 1.	  
							   DCache : waitCache is 0, and dataReady is also 1.

[5] The CPU raises a BG (Bus Granted) signal
	<In waveform> at 120400ns, BG signal : 0 -> 1

[6] The dma_controller receives BG signal, then the external_device writes 12 words of data at the designated memory address
	<In waveform>
	at 120450ns, dma_offset : 00 -> 01, ed_block : [x x x x] -> [4 3 2 1], ed_write : 0 -> 1	(bus_data and bus_address also changed)
	at 120550ns,														   ed_write : 1 -> 0
	at 121050ns, dma_offset : 01 -> 10, ed_block : [4 3 2 1] -> [8 7 6 5], ed_write : 0 -> 1	(bus_data and bus_address also changed)
	at 121150ns,														   ed_write : 1 -> 0
	at 121650ns, dma_offset : 10 -> 11, ed_block : [8 7 6 5] -> [c b a 9], ed_write : 0 -> 1	(bus_data and bus_address also changed)
	at 121750ns,														   ed_write : 1 -> 0
	at 122250ns, dma_offset : 11 -> 00, ed_block : [c b a 9] -> [x x x x], ed_write : 0 -> 1
	at 122350ns,														   ed_write : 1 -> 0

[7] While the transfer is going on, the CPU can only access the cache.
	It means that, if cache miss occurs then cache counter should not be work.
	But in this case, ICache and DCache is always cache hit during BG is 1

	+)	To see how it works when cache miss occurs, set the interrupt time 1200 -> 600.
		then the BG signal is changed to 0 between blocks (at 61200ns)
		and the it stalled during cache miss resolution, and after dataReady BG is 1 again. (at 61700ns)

[8] When the DMA_controller finishes its work, it clears the BR signal.
	<In waveform> at 122250ns, BR signal : 1 -> 0

[9] The CPU clears the BG signal and enables the usage of memory buses.
	<In waveform> at 122250ns, BG signal : 1 -> 0

[10] The DMA_controller raises an interrupt. and the CPU handles the interrupt.
	<In waveform> at 122250ns, dma_interrupt_in : 0 -> 1

---------------------------------------------------------------------------------------------------------
Additionally, We changed testbench to check memory is changed
memory[16'had] <= 16'h90c7;			//JMP c7 (originally, HLT : 16'hf01d so this is where it ends)

memory[16'hc7] <= 16'h6000; // LHI 0 0			(but jump to here, and changed data to check memory)
memory[16'hc8] <= 16'h7017; // LWD $0 $0 17 
memory[16'hc9] <= 16'hf01c; // WWD $0
memory[16'hca] <= 16'hf01d; // HLT

if external device worked well, then memory[16'h17] should have a value of 1.
so, we make new test to check that values. and our code passed that test.