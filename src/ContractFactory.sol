// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

error NotHR();
error InitializationFailed();

contract ContractFactory {
    using Clones for address;

    address public implementation;
    address public hr;

    event ProxyCreated(address proxy, address director);

    constructor(address _implementation, address _hr) {
        implementation = _implementation;
        hr = _hr;
    }

    modifier onlyHR() {
        require(msg.sender == hr, NotHR());
        _;
    }

    function createProxy(address _director, address _priceFeed, string memory _departmentName)
        external
        onlyHR
        returns (address proxy)
    {
        proxy = implementation.clone();

        (bool success,) = proxy.call(
            abi.encodeWithSignature(
                "initialize(address,address,address,string)", hr, _director, _priceFeed, _departmentName
            )
        );
        require(success, InitializationFailed());

        emit ProxyCreated(proxy, _director);
    }
}
