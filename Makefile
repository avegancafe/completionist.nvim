.PHONY: test lint clean

test:
	NVIM_APPNAME=completionist_test nvim --clean --headless -u tests/minimal.vim -c "PlenaryBustedDirectory tests" -c "qa"

test-file:
	NVIM_APPNAME=completionist_test nvim --clean --headless -u tests/minimal.vim -c "PlenaryBustedFile $(FILE)" -c "qa"

test-watch:
	NVIM_APPNAME=completionist_test nvim --clean --headless -u tests/minimal.vim -c "PlenaryBustedDirectory tests { sequential = true, keep_going = true }" -c "qa"

clean:
	rm -rf deps/ 
