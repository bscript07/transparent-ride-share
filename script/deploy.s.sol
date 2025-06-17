// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {RideShareTreasury} from "../src/RideShareTreasury.sol";

contract DeployScript is Script {
    function run() public {
        vm.startBroadcast(); // Start broadcasting the transaction

        // Load deployer's environment variables
        address owner = vm.envAddress("OWNER_ADDRESS"); // Dispatcher / signer
        address admin = vm.envAddress("ADMIN_ADDRESS"); // Proxy admin / upgrade authority

        // Chainlink ETH/USD price feed address on Sepolia
        address priceFeed = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

        // Deploy TransparentUpgradeableProxy + initialize it
        address proxy = Upgrades.deployTransparentProxy(
            "RideShareTreasury.sol", // Contract to proxy
            admin, // Proxy admin
            abi.encodeCall(RideShareTreasury.initialize, (admin, owner, priceFeed)) // Initialization call
        );

        // Retrieve the logic contract (implementation) address
        address implementation = Upgrades.getImplementationAddress(proxy);

        // Log deployed addresses
        console.log("Proxy: ", proxy);
        console.log("Implementation: ", implementation);

        vm.stopBroadcast(); // Stop broadcasting
    }
}

//                     COMMAND FOR DEPLOY AND VERIFY SMART CONTRACTS ON SEPOLIA CHAIN
// forge script script/deploy.s.sol:DeployScript --rpc-url sepolia --broadcast --verify -vv --private-key <ADMIN_PRIVATE_KEY>
