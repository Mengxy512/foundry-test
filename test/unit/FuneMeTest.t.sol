// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {

    FundMe public fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant START_BALANCE = 1000 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
        vm.deal(USER, START_BALANCE);
    }

    function testMinimumUSD() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testVersion() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithourEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdate() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testAddsFunderToArray() public funded{
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded{
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testOwnerWithdrawSingleFunder() public funded{
        uint256 ownerBalance = fundMe.getOwner().balance;
        uint256 fundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 ownerAfterBalance = fundMe.getOwner().balance;

        assertEq(
            ownerBalance+fundMeBalance, 
            ownerAfterBalance
        );
    }

    function testOwnerWithdrawMultipleFunder() public funded{
        uint256 funderNumber = 10;
        for(uint160 funderIndex = 1; funderIndex < funderNumber; funderIndex++){
            hoax(address(funderIndex), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 ownerBalance = fundMe.getOwner().balance;
        uint256 fundMeBalance = address(fundMe).balance;

        // uint256 gasStart = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed);

        uint256 ownerAfterBalance = fundMe.getOwner().balance;

        assertEq(
            ownerBalance+fundMeBalance, 
            ownerAfterBalance
        );
    }
}
