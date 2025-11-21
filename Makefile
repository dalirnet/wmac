.PHONY: build
build:
	sh build.sh

.PHONY: run
run: build
	killall WMac 2>/dev/null || true
	sleep 0.5
	open build/WMac.app

.PHONY: clean
clean:
	rm -rf build
