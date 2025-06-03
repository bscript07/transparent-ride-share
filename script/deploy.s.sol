// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {ContractImplementation} from "../src/ContractImplementation.sol";
import {ContractFactory} from "../src/ContractFactory.sol";

error InvalidDirectorAddress();
error InvalidHRAddress();

contract DeployScript is Script {
    function run() public {
        vm.startBroadcast();

        address director = vm.envAddress("DIRECTOR_ADDRESS");
        require(director != address(0), InvalidDirectorAddress());

        address hr = vm.envAddress("HR_ADDRESS");
        require(hr != address(0), InvalidHRAddress());

        // Deploy PayrollImplementation (logic contract)
        ContractImplementation implementation = new ContractImplementation();
        console.log("Contract Implementation: ", address(implementation));

        // Deploy PayrollFactory (factory contract)
        ContractFactory factory = new ContractFactory(address(implementation), hr);
        console.log("Contract Factory: ", address(factory));

        // Add on Clone (director, priceFeed, department)
        address priceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306; // ETH/USD Sepolia
        string memory department = "Administration";

        address clone = factory.createProxy(director, priceFeed, department);
        console.log("Contract Clone:", clone);

        vm.stopBroadcast();
    }
}

// forge script script/deploy.s.sol:DeployScript --rpc-url sepolia --broadcast --verify --private-key <HR_PRIVATE_KEY> -vv
