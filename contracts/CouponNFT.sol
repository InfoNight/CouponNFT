// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@klaytn/contracts/KIP/token/KIP17/extensions/KIP17MetadataMintable.sol";
import "@klaytn/contracts/utils/Counters.sol";

contract CouponNFT is KIP17MetadataMintable {

    event UseCoupon(address indexed sender, address indexed recipient, uint256[] couponIds);

    event GetCouponURIs(address indexed sender);

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct UserRequests {
        address user;
        uint256[] couponIds;
    }

    // Mapping for Coupon issuing codes (String code -> user address -> tokenId)
    mapping(string => mapping(address => uint256)) private _couponCodes;

    // Recipient for new coupons
    mapping(uint256 => address) private _senderAddress;

    // mapping(address => address[]) private _requestingUsers;

    mapping(address => UserRequests[]) private _pendingCoupons;

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

        if (!_isApprovedOrOwner(recipient, newItemId)) {
            approve(recipient, newItemId);
        }

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
        // returns (bool)
    {
        for (uint i = 0; i < couponIds.length; i++) {
            require(msg.sender == ownerOf(couponIds[i]), "CouponNFT: transferring unowned coupons");
            // if (msg.sender != ownerOf(couponIds[i])) {
            //     return false;
            // }
        }
        _pendingCoupons[recipient].push(UserRequests(msg.sender, couponIds));

        // for (uint i = 0; i < couponIds.length; i++) {
        //     _requestingUsers[recipient].push(msg.sender);
        // }
        // _pendingCoupons[recipient][msg.sender] = couponIds;

        emit UseCoupon(msg.sender, recipient, couponIds);
        // return true;
    }

    /**
     * Validation of coupons called by store (사용 4 - 공급자자 유저가 보낸 쿠폰 확인 용도)
     */
    function getCoupons()
        public view
        returns (address[] memory)
    {
        // address[] memory userIds = _requestingUsers[msg.sender];
        // string[] memory couponURIs;

        // for (uint i = 0; i < userIds.length; i++) {
        //     uint256[] memory couponIds = _pendingCoupons[msg.sender][userIds[i]];

        //     for (uint j = 0; j < couponIds.length; j++) {
        //         couponURIs[i] = tokenURI(couponIds[i]);
        //     }
        // }

        // UserRequests[] memory userRequests = _pendingCoupons[msg.sender];
        address[] memory userIds;
        // string[] memory couponURIs;

        // for (uint i = 0; i < userRequests.length; i++) {
        //     for (uint j = 0; j < userRequests[i].couponIds.length; j++) {
        //         userIds[i] = userRequests[i].user;
        //         // couponURIs[i] = tokenURI(userRequests[i].couponIds[j]);
        //     }
        // }

        // emit GetCouponURIs(msg.sender);

        // userIds[0] = msg.sender;   // POINT OF ERROR
        // couponURIs[0] = "6";

        return userIds;
    }

    /**
     * Burn used coupons (사용 5)
     */
    function consumeCoupons(address user)
        public
        returns (bool)
    {
        UserRequests[] storage userRequests = _pendingCoupons[msg.sender];
        for (uint i = 0; i < userRequests.length; i++) {
            if (userRequests[i].user == user) {
                for (uint j = 0; j < userRequests[i].couponIds.length; j++) {
                    _burn(userRequests[i].couponIds[j]);
                }
                userRequests[i] = userRequests[userRequests.length - 1];
                userRequests.pop();

                _pendingCoupons[msg.sender] = userRequests;

                return true;
            }
        }
        // delete _requestingUsers[msg.sender]
        // delete _pendingCoupons[msg.sender][user];

        // for (uint i = 0; i < couponIds.length; i++) {
        //     _burn(couponIds[i]);
        // }

        return false;
    }
}