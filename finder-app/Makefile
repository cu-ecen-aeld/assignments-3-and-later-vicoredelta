writer: writer.c
	export PATH=${PATH}:/home/emil/x-tools/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/bin

ifdef CROSS_COMPILE
ifeq (${CROSS_COMPILE}, aarch64-none-linux-gnu-)
	aarch64-none-linux-gnu-gcc writer.c -o writer
else
	echo "Unsupported toolchain."
endif
else
	gcc writer.c -o writer
endif

all: writer.c
	aarch64-buildroot-linux-gnu-gcc writer.c -o writer

clean:
	rm -f *.o *.out writer
