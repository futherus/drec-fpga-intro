TARGET=uart
SRC=testbench.v clk_strobe.v uart_tx.v uart_rx.v

test: $(TARGET)
	./$(TARGET)

$(TARGET): $(SRC)
	iverilog $^ -o $@

clean:
	rm -f $(TARGET)

help:
	@echo "  test  - Run testbench"
	@echo "  clean - Remove most generated files"
	@echo "  help  - Display this text"

.PHONY: clean test help
