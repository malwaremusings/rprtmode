# rprtmode
An exercise in protected mode assembly language programming, aiming to get to 64-bit assembly language programming.

I wanted to relive an old uni assignment in protected mode assembly language programming, and a friend who hadn't done protected mode programming was keen to see it.

This project started out as a protected mode task switching assembly language program, ran as a .com file under MS-DOS in a virtual machine (affectionately known as 'dossy wossy', which will explain the name of the floppy image).

We then wanted to try 64-bit programming, which neither of us had tried before. After reading up on 64-bit programming, we figured that we should probably organise things in memory a bit better before attempting 64-bit. To do this, we figured that we should get rid of MS-DOS and load our protected mode code straight from boot code.

I managed to squeeze code in to less than 512 bytes of code, which searches through the root directory to find the file 'PLAN.A', and follow its FAT chain to load it in to memory and run it. Compare this to the MS-DOS boot code which requires 'IO.SYS' to be the first root directory entry, and contiguous. Having said that, my boot code doesn't have many error strings, and I had to leave the 'g' off 'loading' to fit the code in.

If running this in a qemu/kvm virtual machine, then you can use the monitor/gdb server to inspect the CPU registers and memory contents, which was something that I couldn't do on the physical machines that I was using for my uni assignment.

This is a work in progress.
