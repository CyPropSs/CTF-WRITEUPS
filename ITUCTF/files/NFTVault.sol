// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTVault is IERC721Receiver, Ownable, ReentrancyGuard {
    struct VaultItem {
        address nftContract;
        uint256 tokenId;
        address owner;
        uint256 lockTime;
        bool isLocked;
    }

    mapping(uint256 => VaultItem) public vaultItems;
    uint256 public itemCount;
    string private flag;
    bool private initialized;

    event ItemLocked(uint256 indexed itemId, address indexed owner, address nftContract, uint256 tokenId);
    event ItemUnlocked(uint256 indexed itemId, address indexed owner, address nftContract, uint256 tokenId);

    constructor() {
        flag = "ITUCTF{nft_reentrancy_exploit}";
        initialized = true;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function lockNFT(address _nftContract, uint256 _tokenId) external nonReentrant {
        require(initialized, "Contract not initialized");
        require(IERC721(_nftContract).ownerOf(_tokenId) == msg.sender, "Not token owner");
        
        IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);
        
        vaultItems[itemCount] = VaultItem({
            nftContract: _nftContract,
            tokenId: _tokenId,
            owner: msg.sender,
            lockTime: block.timestamp,
            isLocked: true
        });

        emit ItemLocked(itemCount, msg.sender, _nftContract, _tokenId);
        itemCount++;
    }

    function unlockNFT(uint256 _itemId) external nonReentrant {
        require(initialized, "Contract not initialized");
        VaultItem storage item = vaultItems[_itemId];
        require(item.owner == msg.sender, "Not item owner");
        require(item.isLocked, "Item not locked");
        require(block.timestamp >= item.lockTime + 1 days, "Lock period not ended");

        item.isLocked = false;
        IERC721(item.nftContract).safeTransferFrom(address(this), msg.sender, item.tokenId);
        
        emit ItemUnlocked(_itemId, msg.sender, item.nftContract, item.tokenId);
    }

    function getFlag() external view returns (string memory) {
        require(initialized, "Contract not initialized");
        require(msg.sender == owner(), "Not owner");
        return flag;
    }

    function initialize() external {
        require(!initialized, "Already initialized");
        initialized = true;
    }
} 