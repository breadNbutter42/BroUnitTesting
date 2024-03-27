// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {MockERC721} from "forge-std/mocks/MockERC721.sol";

contract TestERC721 is MockERC721 {
    constructor() {
        initialize("TestERC721", "testNFT");
    }

    function mint(address to, uint256 id) public {
        _mint(to, id);
    }

    function burn(uint256 id) public {
        require(msg.sender == _ownerOf[id], "not owner");
        _burn(id);
    }

    function exists(uint256 id) public view returns(bool) {
        if (_ownerOf[id] != address(0))
            return true;
        else
            return false;
    }

    function transfer(address from, address to, uint256 tokenId) external {
        transferFrom(from, to, tokenId);
    }

    function safeTransfer(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId);
    }
}

