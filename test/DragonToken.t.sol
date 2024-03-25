// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DragonFire} from "../src/DragonToken.sol";

contract CounterTest is Test {
    DragonFire public dragonFire;

    function setUp() public {
        dragonFire = new DragonFire();
    }

    function test() public {
        
    }
}
