// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DragonToken} from "../src/DragonToken.sol";

contract CounterTest is Test {
    DragonToken public dragonToken;

    function setUp() public {
        dragonToken = new DragonToken();
    }

    function test() public {
        
    }
}
