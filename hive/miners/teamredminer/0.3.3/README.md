# teamredminer v0.3.3 (formerly known as tdxminer)

This software is in a beta stage and may be unstable on some hardware.

Download is available in the [releases section](https://github.com/todxx/teamredminer/releases).

GPUs supported and tested:
- RX 580/570/480/470 on windows and linux with rocm or amdgpu-pro drivers
- RX Vega 64/56, Vega FE on windows and linux with rocm or amdgpu-pro/PAL drivers

GPUs supported but untested:
- RX 560/550 on windows and linux with rocm or amdgpu-pro drivers

Software Requirements:
- A supported driver version (see GPUs Supported above)

This miner currently supports the lyra2z and phi2 algorithms.  Its only configuration is via command line to set the basic parameters for connecting to a stratum pool and selecting which platforms/devices to use.  Invoking the miner with the --help option will print a short help message for how to use the options.

The miner includes a read-only api based on the sgminer-5.5 API.  Both the json and text formats are supported.  For more details, we refer to the sgminer api documentation.  

NOTE: This miner does NOT monitor GPU temperatures.  It is up to the user to ensure that GPU(s) are functioning within safe power and temperature limits.  Support for monitoring fans and temperatures will be added in a later version.

This miner includes a 3% dev fee.

The miner reports user hash rates every 30 seconds.  These are the hash rates after dev fee deduction. I.E. the hash rates reported should be the average hash rate that your pool reports.)

Rough performance numbers with this version:

| GPU           | SCLK (MHz) | MCLK (MHz) | Lyra2z (Mh/s) | Phi2 (Mh/s) |
|---------------|-----------:|-----------:|--------------:|------------:|
| RX 580        | 1366       | 2000       | 3.74          | 5.92        |
| RX Vega 64 LC | 1560       | 945        | 7.57          | 11.56       |


For reporting bugs and/or for features requests, please open an issue on this project's github [issue tracker](https://github.com/todxx/teamredminer/issues).

Happy hashing ;)

-----------
Changes in v0.3.3
- ROCm support reintroduced
- API support based on the sgminer API
- Improved GPU platform detection
- PCIe bus id printed on startup and is available over API
- Added option for periodic stats interval

Changes in v0.3.2
- Added windows support/build
- Added vega PAL driver support
- Removed ROCm support (temporarily)
- Removed libjansson dependency

Changes in v0.3.1
- Fixed phi2 issues causing rejected shares and low pool-side hashrate.
