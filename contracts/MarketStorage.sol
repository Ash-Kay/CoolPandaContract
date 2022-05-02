// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./utils/Ownable.sol";

contract MarketStorage is Ownable {
    enum MarketState {
        BiddingOpen, // After specific timestamp
        BiddingClosed, // After specific timestamp
        Halted // Incase of emergency
    }

    enum MarketType {
        Binary,
        MultipleChoice // Only one correct
    }

    struct Bidder {
        address bidderAddress;
        uint128 optionSelected;
        uint256 amount;
    }

    struct Market {
        uint256 marketId; // Index in the array
        string question;
        string description;
        MarketType marketType;
        string[] options; // use key for stuff
        string resolverUrl; // Url to website maybe that tells about how market will be resolved
        // mapping(address => uint256) winnersBalance;
        // mapping(string => uint256) optionBalance; // Total amount deposited in each option
        // Creator
        address createdBy;
        string creatorImageHash;
        // Timestamps
        uint256 marketCreatedTimestamp;
        uint256 bidEndTimestamp;
    }

    mapping(uint256 => mapping(address => Bidder)) public bidders; //marketId -> bidders

    // mapping(uint256 => mapping(int128 => Bidder)) public bidderMap;

    // mapping(uint256 => address[]) public winnersAddress; // marketId->list winners

    mapping(uint256 => Market) public markets;
    mapping(uint256 => MarketState) public marketStates;
    uint256[] public marketIds;
    uint256 private latestMarketIndex = 0;

    constructor() {
        string[] memory option = new string[](2);
        option[0] = "am i right";
        option[1] = "or am i right";

        createMarket(
            1,
            "test q",
            "test d",
            MarketType.Binary,
            option,
            "xyz.abc",
            "0x123",
            123123
        );
    }

    function createMarket(
        uint256 _marketId,
        string memory _question,
        string memory _description,
        MarketType _marketType,
        string[] memory _options,
        string memory _resolverUrl,
        string memory _creatorImageHash,
        uint256 _endTimestamp
    ) public onlyOwner returns (uint256 marketId) {
        latestMarketIndex++;

        markets[latestMarketIndex] = Market(
            _marketId,
            _question,
            _description,
            _marketType,
            _options,
            _resolverUrl,
            msg.sender,
            _creatorImageHash,
            block.timestamp,
            _endTimestamp
        );
        marketStates[latestMarketIndex] = MarketState.BiddingOpen;
        marketIds.push(latestMarketIndex);
        return latestMarketIndex;
    }

    function getTotalMarkets() public view returns (uint256 totalMarkets) {
        return marketIds.length;
    }

    function addBet(uint256 _marketId, uint128 _optionSelected) public payable {
        //ADD CHECKS like is _optionSelected in range
        Market memory market = markets[_marketId];

        if (_optionSelected >= market.options.length) {
            revert("overflow option");
        }
        if (msg.value == 0) {
            revert("Kuch to paise bhej bhai");
        }

        bidders[_marketId][msg.sender] = Bidder(
            msg.sender,
            _optionSelected,
            msg.value
        );
    }
}
