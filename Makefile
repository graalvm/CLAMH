
RED=\033[1;31m
NC=\033[0m # No Color


all:
	@echo "======================"
	@echo "Building lath-cpp:"
	@echo "======================"
	@make -C lath-cpp || echo "Build of lath-cpp ${RED}FAILED${NC}"
	@echo ""
	@echo "============================================"
	@echo "Building JMH benchmark project directory:"
	@echo "============================================"
	@make -C jmh || echo "Build of JMH benchmark project directory ${RED}FAILED${NC}"

