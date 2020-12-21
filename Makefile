
RED=\033[1;31m
NC=\033[0m # No Color


all:
	@echo "======================"
	@echo "Building clamh-cpp:"
	@echo "======================"
	@make -C clamh-cpp || echo "Build of clamh-cpp ${RED}FAILED${NC}"
	@echo ""
	@echo "============================================"
	@echo "Building JMH benchmark project directory:"
	@echo "============================================"
	@make -C jmh || echo "Build of JMH benchmark project directory ${RED}FAILED${NC}"

