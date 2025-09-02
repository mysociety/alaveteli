
# requires lix built from main (as of sept 1, 2025) to have self.submodules support
# once 2.94 is released, it should be ok to revert to stable
build_tests:
	nix -L build  --no-pure-eval --extra-experimental-features flake-self-attrs .#serverTests.driverInteractive

run_tests:
	./result/bin/nixos-test-driver --interactive

# not directly alaveteli related, but helpful :)
zz_build_lix_from_master:
	sudo -i -H --preserve-env=SSH_AUTH_SOCK nix --experimental-features 'nix-command flakes' profile install --profile /nix/var/nix/profiles/default git+https://git.lix.systems/lix-project/lix --priority 3
