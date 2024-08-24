# FakeErrorHandler
This silly little script creates a fake diagnostic box before dropping and installing an msi payload such as an RMM for persistence on a machine. In this example I used Action1 as the RMM of choice. 

You will need to use ps2exe to compile the powershell script into an executable binary with your icon and name of choice. 
- https://github.com/MScholtes/PS2EXE

Optionally you can also digitally self-sign the binary to evade some detection mechanisms. 
- https://github.com/jfmaes/LazySign
