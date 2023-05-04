// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "v2-periphery/IUniswapV2Router01.sol";
import "v2-core/IUniswapV2Factory.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./Token.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Dex is Ownable {
	uint256 public reserveWeth = 0;
	uint256 public reserveRpe = 0;
	address public SwapRouter;
	IUniswapV2Router01 swapRouter;
	address public tokenA;
	address public immutable tokenB;
	IERC20 token;
	address public Factory;

	mapping(address => uint256) LP;
	struct Traders {
		uint amountIn;
		//uint amountOut;
	}
	mapping(address => Traders) traders;

	using SafeMath for uint256;

	event LiquidityAdded(
		address lp,
		string,
		uint256 amountA,
		string,
		uint256 amountB,
		string,
		uint256 liquidity
	);

	constructor() {
		token = new Token();
		tokenB = address(token);
		Factory = msg.sender;
	}

	function provideSwapRouterAddress(address _swapRouter) public onlyOwner {
		SwapRouter = _swapRouter;
		swapRouter = IUniswapV2Router01(_swapRouter);
	}

	function provideWethAddress(address _weth) public onlyOwner {
		tokenA = _weth;
	}

	function setLiquidity(uint256 amountA, uint256 amountB) private {
		IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
		IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

		IERC20(tokenA).approve(SwapRouter, amountA);
		IERC20(tokenB).approve(SwapRouter, amountB);

		updateReserve(amountA, amountB);
	}

	function addLiquidity(
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		uint256 deadline
	) public {
		require(IERC20(tokenA).balanceOf(msg.sender) > amountADesired);
		require(IERC20(tokenB).balanceOf(msg.sender) > amountBDesired);
		IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
		IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);

		IERC20(tokenA).approve(SwapRouter, amountADesired);
		IERC20(tokenB).approve(SwapRouter, amountBDesired);

		(uint256 amountA, uint256 amountB, uint256 liquidity) = swapRouter
			.addLiquidity(
				tokenA,
				tokenB,
				amountADesired,
				amountBDesired,
				amountAMin,
				amountBMin,
				address(this),
				block.timestamp.add(1 minutes)
			);

		updateReserve(amountA, amountB);
		LP[msg.sender] = liquidity;

		emit LiquidityAdded(
			msg.sender,
			"added liquidity of",
			amountA,
			"and",
			amountB,
			"and liquidity is",
			liquidity
		);
	}

	function removeLiquidity(
		uint256 liquidity, // amount of liquidity token i want to get back
		uint256 amountAMin, // minimmum amount of tokenA i want to get back
		uint256 amountBMin, // minimum amount of tokenB i want to get back
		uint256 deadline
	) public {
		address pair = IUniswapV2Factory(Factory).getPair(tokenA, tokenB); // getting the balance of liquidity tokens that this contract holds, this pair contract manages the liquidity pool tokens
		//TransferHelper.safeApprove(pair, address(this), liquidity);
		IERC20(pair).approve(SwapRouter, liquidity);

		(uint256 amountA, uint256 amountB) = swapRouter.removeLiquidity(
			tokenA,
			tokenB,
			liquidity,
			amountAMin,
			amountBMin,
			address(this),
			deadline
		);
	}

	function swapWethToToken(
		uint256 amountIn, // the amounts of tokens we are trading in for
		uint256 amountOutMin, // the minimum amount of tokens we want out from this trade
		uint256 deadline,
		Traders memory _traders
	) public {
		require(IERC20(tokenA).balanceOf(msg.sender) > amountIn);
		address[] memory path = new address[](2);
		path[0] = tokenA;
		path[1] = tokenB;

		IERC20(tokenA).transferFrom(msg.sender, address(this), amountIn);
		IERC20(tokenA).approve(SwapRouter, amountIn);

		swapRouter.swapExactTokensForTokens(
			amountIn,
			amountOutMin,
			path,
			msg.sender,
			deadline
		); // to = sending the output tokens to
		_traders.amountIn = amountIn;

		traders[msg.sender] = _traders;
	}

	function swapTokenToWeth(
		uint256 amountIn,
		uint256 amountOutMin,
		uint256 deadline,
		Traders memory _traders
	) public {
		require(IERC20(tokenB).balanceOf(msg.sender) > amountIn);
		address[] memory path = new address[](2);
		path[0] = tokenB;
		path[1] = tokenA;

		IERC20(tokenB).transferFrom(msg.sender, address(this), amountIn);
		IERC20(tokenB).approve(SwapRouter, amountIn);

		swapRouter.swapExactTokensForTokens(
			amountIn,
			amountOutMin,
			path,
			msg.sender,
			deadline
		);

		_traders.amountIn = amountIn;
		traders[msg.sender] = _traders;
	}

	function updateReserve(uint256 amountA, uint256 amountB) private {
		reserveWeth += amountA;
		reserveRpe += amountB;
	}
}