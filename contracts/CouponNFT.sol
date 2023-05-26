// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@klaytn/contracts/KIP/token/KIP17/extensions/KIP17MetadataMintable.sol";
import "@klaytn/contracts/utils/Counters.sol";

contract CouponNFT is KIP17MetadataMintable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Mapping for Coupon issuing codes (String code -> user address -> tokenId)
    mapping(string => mapping(address => uint256)) private _couponCodes;

    // Recipient for new coupons
    mapping(uint256 => address) private _senderAddress;

    mapping(address => mapping(address => uint256[])) private _pendingCoupons;

    constructor() KIP17("CouponNFT", "CPN") { }

    /**
     * Issue new coupon called by stores (생성 2)
     */
    function issueCoupon(address recipient, string memory couponCode, string memory tokenURI)
        public
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        approve(recipient, newItemId);

        _couponCodes[couponCode][recipient] = newItemId;
        _senderAddress[newItemId] = msg.sender;

        return newItemId;
    }

    /**
     * Claim coupon called by user (생성 4)
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
     * Use coupons called by user (사용 3)
     */
    function useCoupon(address recipient, uint256[] memory couponIds)
        public
    {
        _pendingCoupons[recipient][msg.sender] = couponIds;
    }

    /**
     * Validation of coupons called by store (사용 4 - 공급자자 유저가 보낸 쿠폰 확인 용도)
     */
    function getCouponURIs(address user)
        public view
        returns (string[] memory)
    {
        uint256[] memory couponIds = _pendingCoupons[msg.sender][user];
        // delete _pendingCoupons[msg.sender][user];

        string[] memory couponURIs;

        for (uint i = 0; i < couponIds.length; i++) {
            couponURIs[i] = tokenURI(couponIds[i]);
        }

        return couponURIs;
    }

    /**
     * Burn used coupons (사용 5)
     */
    function consumeCoupons(address user)
        public
    {
        uint256[] memory couponIds = _pendingCoupons[msg.sender][user];
        delete _pendingCoupons[msg.sender][user];

        for (uint i = 0; i < couponIds.length; i++) {
            _burn(couponIds[i]);
        }
    }
}