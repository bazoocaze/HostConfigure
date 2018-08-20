
TARGET:=zramswap.run
SRCDIR:=files
SETUPFILE:=./setup.sh
PKGLABEL:="The ZRAM-Swap Package"

all: $(TARGET)

$(TARGET): $(SRCDIR)/*
	makeself $(SRCDIR) $(TARGET) $(PKGLABEL) $(SETUPFILE)

clean:
	rm -f "$(TARGET)"

install: $(TARGET)
	sudo ./$(TARGET) install

remove: $(TARGET)
	sudo ./$(TARGET) remove

help:
	@echo "Targets: all $(TARGET) clean install remove help"

	

