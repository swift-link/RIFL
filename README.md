# RIFL
A low latency lossless link layer protocol

How to launch an example design (tested in Vivado 2020.1):

1. Add the directory "ip_repo" as a Vivado user repository in Vivado IP Catalog.
2. Instantiate the IP "RIFL", configure it as you need.
3. In Vivado source panel, right click the RIFL instance, then click "Open IP Example Design".
4. A new Vivado window will pop up to run the example design scripts, wait the for the scripts to finish.
5. To launch a simulation : click "Run Simulation" in Vivado.
6. To build a bistream: modify the "example.xdc" file to what reflects your board's wiring setup. Then clock "Generate Bitstream" in Vivado.
