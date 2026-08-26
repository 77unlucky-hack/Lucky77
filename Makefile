all: build/Lucky77.dylib

build/Lucky77.dylib: Sources/Lucky77Theme.m Sources/Lucky77Menu.mm Sources/MemoryUtils.m Sources/HooksManager.mm
	./build_ios_dylib.sh

clean:
	rm -rf build/

.PHONY: all clean
