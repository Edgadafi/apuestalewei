// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract PredictionMarketXOC {
    
    enum Outcome { Undecided, Yes, No }

    IERC20 public XOC;
    address public oracle;
    string public question;
    uint public resolutionTime;
    Outcome public resolvedOutcome;


    mapping(address => uint) public yesShares;
    mapping(address => uint) public noShares;
    uint public totalYes;
    uint public totalNo;

    constructor(
        address _xocAddress,
        string memory _question,
        uint _resolutionTime
    ) {
        XOC = IERC20(_xocAddress);
        oracle = msg.sender;
        question = _question;
        resolutionTime = _resolutionTime;
        resolvedOutcome = Outcome.Undecided;
    }

    function bet(bool betYes, uint amount) external payable {
        require(block.timestamp < resolutionTime, "Market closed");
        require(amount > 0, "Zero amount");
        uint256 oneDollar = amount * 10 ** 18;
        require(XOC.transferFrom(msg.sender, address(this), oneDollar), "Transfer failed");

        if (betYes) {
            yesShares[msg.sender] += amount;
            totalYes += amount;
        } else {
            noShares[msg.sender] += amount;
            totalNo += amount;
        }
    }

    function resolveMarket(bool outcomeYes) external {
        require(msg.sender == oracle, "Only oracle");
        require(block.timestamp >= resolutionTime, "Too early");
        require(resolvedOutcome == Outcome.Undecided, "Already resolved");

        resolvedOutcome = outcomeYes ? Outcome.Yes : Outcome.No;
    }

    function claimWinnings() external {
        require(resolvedOutcome != Outcome.Undecided, "Not resolved");

        uint payout;
        if (resolvedOutcome == Outcome.Yes) {
            uint userShare = yesShares[msg.sender];
            require(userShare > 0, "No winnings");
            payout = (XOC.balanceOf(address(this)) * userShare) / totalYes;
            yesShares[msg.sender] = 0;
        } else {
            uint userShare = noShares[msg.sender];
            require(userShare > 0, "No winnings");
            payout = (XOC.balanceOf(address(this)) * userShare) / totalNo;
            noShares[msg.sender] = 0;
        }

        require(XOC.transfer(msg.sender, payout), "Transfer failed");
    }
}
