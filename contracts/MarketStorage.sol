// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketStorage is Ownable {
    enum MarketState {
        BiddingOpen, // After specific timestamp
        BiddingClosed, // After specific timestamp, can withdraw
        Halted // Incase of emergency, no transactions
    }

    enum MarketType {
        Binary,
        MultipleChoice // Multiple choice but Only one correct
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
        // Creator
        address createdBy;
        string creatorImageHash;
        // Timestamps
        uint256 marketCreatedTimestamp;
        uint256 bidEndTimestamp;
    }

    mapping(uint256 => mapping(address => Bidder)) public bidders; //marketId -> bidders
    mapping(uint256 => mapping(uint128 => address[]))
        public biddersAddressByOption; //marketId -> option -> bidderaddress
    mapping(uint256 => mapping(uint128 => uint256))
        public biddersTotalBalanceByOption; //marketId -> option -> total amount deposit for that option
    mapping(address => uint256) public redeemableAmount; //bidderaddress => amount
    // mapping(uint256 => mapping(int128 => Bidder)) public bidderMap;

    // mapping(uint256 => address[]) public winnersAddress; // marketId->list winners

    mapping(uint256 => Market) public markets;
    mapping(uint256 => MarketState) public marketStates;
    uint256[] public marketIds;
    uint256 private latestMarketIndex = 0;

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

        //chjeck market end > block.timestamp

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

        if (marketStates[_marketId] != MarketState.BiddingOpen) {
            revert("Market not open");
        }

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
        biddersAddressByOption[_marketId][_optionSelected].push(msg.sender);
        biddersTotalBalanceByOption[_marketId][_optionSelected] += msg.value;
    }

    function endMarket(uint256 _marketId, uint128 outcomeOption)
        public
        onlyOwner
    {
        Market memory market = markets[_marketId];
        if (marketStates[_marketId] == MarketState.BiddingClosed) {
            revert("Already closed, ended");
        }
        if (outcomeOption >= market.options.length) {
            revert("overflow option");
        }

        marketStates[_marketId] = MarketState.BiddingClosed;
        uint256 totalWinningAmountOfOther = 0;
        uint256 totalWinningAmountOfYour = 0;

        for (uint128 option = 0; option < market.options.length; option++) {
            if (outcomeOption != option) {
                totalWinningAmountOfOther += biddersTotalBalanceByOption[
                    _marketId
                ][option];
            } else {
                totalWinningAmountOfYour = biddersTotalBalanceByOption[
                    _marketId
                ][option];
            }
        }

        console.log("totalWinningAmountOfOther", totalWinningAmountOfOther);
        console.log("totalWinningAmountOfYour", totalWinningAmountOfYour);

        address[] memory winnersAddresses = biddersAddressByOption[_marketId][
            outcomeOption
        ];

        for (uint256 i = 0; i < winnersAddresses.length; i++) {
            Bidder memory bidder = bidders[_marketId][winnersAddresses[i]];
            console.log("winnersAddresses[]", winnersAddresses[i]);

            uint256 rem = (bidder.amount * totalWinningAmountOfOther) %
                totalWinningAmountOfYour;

            console.log("rem", rem);

            console.log("bidder.amount", bidder.amount);

            console.log(
                "bidder.amount * totalWinningAmountOfOther",
                bidder.amount * totalWinningAmountOfOther
            );

            console.log(
                "(bidder.amount * totalWinningAmountOfOther) /totalWinningAmountOfYour",
                (bidder.amount * totalWinningAmountOfOther) /
                    totalWinningAmountOfYour
            );

            console.log(
                "(bidder.amount * totalWinningAmountOfOther) /totalWinningAmountOfYour + bidder.amount",
                (bidder.amount * totalWinningAmountOfOther) /
                    totalWinningAmountOfYour +
                    bidder.amount
            );

            uint256 total = (bidder.amount * totalWinningAmountOfOther) /
                totalWinningAmountOfYour +
                bidder.amount;

            console.log("total winning", total);

            redeemableAmount[winnersAddresses[i]] = total;
        }
    }

    function getTotalBidderForOption(uint256 _marketId, uint128 option)
        public
        view
        returns (uint256 totalBidderForOption)
    {
        return biddersAddressByOption[_marketId][option].length;
    }

    function redeemAmount() public payable {
        require(redeemableAmount[msg.sender] != 0, "No Funds");
        redeemableAmount[msg.sender] = 0;
        payable(msg.sender).transfer(redeemableAmount[msg.sender]);
    }
}
