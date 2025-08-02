-include .env

build:; forge build;

deploy-sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url ${SEPOLIA_RPC_URL} 
	--account sepolia --broadcast --verify --vvvv