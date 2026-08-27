.PHONY: help update linux macbook clean

help:
	@echo "Available targets:"
	@echo "  make linux    # home-manager switch --flake .#linux"
	@echo "  make macbook  # home-manager switch --flake .#macbook"
	@echo "  make clean    # nix-collect-garbage -d"

linux:
	home-manager switch --flake .#linux

macbook:
	home-manager switch --flake .#macbook

clean:
	nix-collect-garbage -d
