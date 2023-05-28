// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@klaytn/contracts/KIP/token/KIP17/extensions/KIP17URIStorage.sol";
import "@klaytn/contracts/KIP/token/KIP17/extensions/KIP17Enumerable.sol";
import "@klaytn/contracts/utils/Counters.sol";

contract CouponNFT is KIP17URIStorage, KIP17Enumerable {

    event RedeemCoupon(address indexed sender, address indexed recipient, uint256[] couponIds);

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct UserRequest {
        address user;
        uint256[] couponIds;
        uint256 couponCount;
    }

    // Mapping for Coupon issuing codes (String code -> user address -> tokenId)
    mapping(string => mapping(address => uint256)) private _couponCodes;

    // Recipient for new coupons
    mapping(uint256 => address) private _senderAddress;

    mapping(address => UserRequest[]) private _pendingCoupons;

    constructor() KIP17("CouponNFT", "CPN") { }

    /**
     * @dev See {IKIP13-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(KIP17, KIP17Enumerable) returns (bool) {
        return KIP17Enumerable.supportsInterface(interfaceId);
    }

    /**
     * Issue new coupon called by stores (Issue #2)
     */
    function issueCoupon(address recipient, string memory couponCode, string memory _tokenURI)
        public
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        if (!_isApprovedOrOwner(recipient, newItemId)) {
            approve(recipient, newItemId);
        }

        _couponCodes[couponCode][recipient] = newItemId;
        _senderAddress[newItemId] = msg.sender;

        return newItemId;
    }

    /**
     * Claim coupon called by user (Issue #4)
     */
    function claimCoupon(string memory couponCode)
        public
        returns (uint256)
    {
        uint256 tokenId = _couponCodes[couponCode][msg.sender];
        address sender = _senderAddress[tokenId];

        delete _couponCodes[couponCode][msg.sender];
        delete _senderAddress[tokenId];
        
        transferFrom(sender, msg.sender, tokenId);

        return tokenId;
    }

    /**
     * Use coupons called by user (Redeem #3)
     */
    function redeemCoupon(address recipient, uint256[] memory couponIds)
        public
    {
        for (uint i = 0; i < couponIds.length; i++) {
            require(msg.sender == ownerOf(couponIds[i]), "CouponNFT: transferring unowned coupons");
        }
        _pendingCoupons[recipient].push(UserRequest(msg.sender, couponIds, couponIds.length));

        emit RedeemCoupon(msg.sender, recipient, couponIds);
    }

    /**
     * Validation of coupons called by store (Redeem #4)
     */
    function getPendingCoupons()
        public view
        returns (address[] memory, string[] memory)
    {
        UserRequest[] memory userRequests = _pendingCoupons[msg.sender];
        uint256 requestCount = getPendingCount(userRequests);

        address[] memory userIds = new address[](requestCount);
        string[] memory couponURIs = new string[](requestCount);

        uint256 index = 0;
        for (uint i = 0; i < userRequests.length; i++) {
            for (uint j = 0; j < userRequests[i].couponIds.length; j++) {
                userIds[index] = userRequests[i].user;
                couponURIs[index] = tokenURI(userRequests[i].couponIds[j]);
                index++;
            }
        }

        return (userIds, couponURIs);
    }

    function getPendingCount(UserRequest[] memory userRequests)
        internal pure
        returns (uint256)
    {
        uint256 count = 0;
        for (uint i = 0; i < userRequests.length; i++) {
            count += userRequests[i].couponCount;
        }
        return count;
    }

    /**
     * Returns NFT coupons 
     */
    function getUserCoupons()
        public view
        returns (uint256[] memory, string[] memory)
    {
        uint256 tokenCount = balanceOf(msg.sender);
        uint256[] memory tokens = new uint256[](tokenCount);
        string[] memory tokenURIs = new string[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokens[i] = tokenOfOwnerByIndex(msg.sender, i);
            tokenURIs[i] = tokenURI(tokens[i]);
        }
        return (tokens, tokenURIs);
    }

    /**
     * Burn used coupons (Redeem #5)
     */
    function consumeCoupons(address user)
        public
    {
        UserRequest[] storage userRequests = _pendingCoupons[msg.sender];
        for (uint i = 0; i < userRequests.length; i++) {
            uint index = userRequests.length - i - 1;
            if (userRequests[index].user == user) {
                for (uint j = 0; j < userRequests[index].couponIds.length; j++) {
                    _burn(userRequests[index].couponIds[j]);
                }
                if (index != userRequests.length - 1) {
                    userRequests[index] = userRequests[userRequests.length - 1];
                }
                userRequests.pop();
            }
        }
        _pendingCoupons[msg.sender] = userRequests;
    }

    function tokenURI(uint256 tokenId) public view virtual override(KIP17, KIP17URIStorage) returns (string memory) {
        return KIP17URIStorage.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(KIP17, KIP17Enumerable) {
        KIP17Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(KIP17, KIP17URIStorage) {
        KIP17URIStorage._burn(tokenId);
    }
}