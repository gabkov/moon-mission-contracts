// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./FuelToken.sol";


contract MasterChefV2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of FUEL
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accFuelPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accFuelPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. FUEL to distribute per block.
        uint256 lastRewardBlock;  // Last block number that FUEL distribution occurs.
        uint256 accFuelPerShare;   // Accumulated FUEL per share, times 1e24. See below.
        uint256 lpSupply;
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    uint256 public constant fuelMaximumSupply = 100000 * 1e18;  //100k

    // The FUEL TOKEN
    FuelToken public fuel;
    // FUEL tokens created per block.
    uint256 public fuelPerBlock = 1 * 1e17;  // 0.1 per block
    // Deposit Fee address
    address public feeAddress;

    IUniswapV2Router02 public constant pancakeswapRouter = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    address public PDOGE = 0x29E37b668F0aB680Ff140f9ffF30EF41E635EB05;
    address public BUSD = 0x92325A71cdacf88E45aD12597EE59E662342D03a;
    address public constant BUSD_PDOGE = 0xf141A066CA00309D5a89488D750e6EE2510A8faB;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when FUEL mining starts.
    uint256 public startBlock;
    // The block number when FUEL mining ends.
    uint256 public emmissionEndBlock = type(uint256).max;

    event AddPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint256 depositFeeBP);
    event SetPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint256 depositFeeBP);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event UpdateStartBlock(uint256 newStartBlock);
    event AddLiquidityPDogeBusd(uint256 pdogeAmount, uint256 busdAmount, uint256 lpAmount);
    event UpdateFuelPerBlock(uint256 fuelPerBlock);

    constructor(FuelToken _fuel, address _feeAddress, uint256 _startBlock) {
        require(_feeAddress != address(0));
        fuel = _fuel;
        feeAddress = _feeAddress;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) external onlyOwner nonDuplicated(_lpToken) {
        // Make sure the provided token is ERC20
        _lpToken.balanceOf(address(this));

        require(_depositFeeBP <= 401, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolExistence[_lpToken] = true;

        poolInfo.push(PoolInfo({
        lpToken : _lpToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accFuelPerShare : 0,
        depositFeeBP : _depositFeeBP,
        lpSupply: 0
        }));

        emit AddPool(poolInfo.length - 1, address(_lpToken), _allocPoint, _depositFeeBP);
    }

    // Update the given pool's FUEL allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 401, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        // subtract the old allocPoint from totalAlloc and add the updated value
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;

        emit SetPool(_pid, address(poolInfo[_pid].lpToken), _allocPoint, _depositFeeBP);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        // As we set the multiplier to 0 here after emmissionEndBlock
        // deposits aren't blocked after farming ends.
        if (_from > emmissionEndBlock){
            return 0;
        }
        if (_to > emmissionEndBlock){
            return emmissionEndBlock - _from;
        } else {
            return _to - _from;
        }
    }

    // View function to see pending FUEL on frontend.
    function pendingFuel(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accFuelPerShare = pool.accFuelPerShare;
        if (block.number > pool.lastRewardBlock && pool.lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 fuelReward = (multiplier * fuelPerBlock * pool.allocPoint) / totalAllocPoint;
            accFuelPerShare = accFuelPerShare + ((fuelReward * 1e24) / pool.lpSupply);
        }

        return ((user.amount * accFuelPerShare) /  1e24) - user.rewardDebt;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        if (pool.lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 fuelReward = (multiplier * fuelPerBlock * pool.allocPoint) / totalAllocPoint;

        // This shouldn't happen, but just in case we stop rewards.
        uint256 totalSupply = fuel.totalSupply();
        if (totalSupply > fuelMaximumSupply) {
            fuelReward = 0;
        } else if ((totalSupply + fuelReward) > fuelMaximumSupply){
            fuelReward = fuelMaximumSupply - totalSupply;
        }

        if (fuelReward > 0){
            fuel.mint(address(this), fuelReward);
        }

        // The first time we reach fuel max supply we solidify the end of farming.
        if (totalSupply >= fuelMaximumSupply && emmissionEndBlock == type(uint256).max){
            emmissionEndBlock = block.number;
        }

        pool.accFuelPerShare = pool.accFuelPerShare + ((fuelReward * 1e24) / pool.lpSupply);
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for FUEL allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = ((user.amount * pool.accFuelPerShare) / 1e24) - user.rewardDebt;
            if (pending > 0) {
                safeFuelTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)) - balanceBefore;
            require(_amount > 0, "we dont accept deposits of 0 size");

            if (pool.depositFeeBP > 0) {
                uint256 depositFee = (_amount * pool.depositFeeBP) / 10000;
                if(address(pool.lpToken) == PDOGE){
                    uint256 sellingAmount = depositFee / 2;
                    // sell half
                    uint[] memory amounts = swapTokensForBUSD(PDOGE, sellingAmount);
                    // create LP and burn
                    addLiquidityForPDoge(amounts[0], amounts[1]);
                } else if (address(pool.lpToken) == BUSD_PDOGE){
                    pool.lpToken.safeTransfer(burnAddress, depositFee);  // burn BUSD-PDOGE LP token deposits
                } else {
                    pool.lpToken.safeTransfer(feeAddress, depositFee);
                }
                user.amount = user.amount + _amount - depositFee;
                pool.lpSupply = pool.lpSupply + _amount - depositFee;
            } else {
                user.amount = user.amount + _amount;
                pool.lpSupply = pool.lpSupply + _amount;
            }
        }
        user.rewardDebt = (user.amount * pool.accFuelPerShare) / 1e24;

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good (too much)");
        updatePool(_pid);
        uint256 pending = ((user.amount * pool.accFuelPerShare) / 1e24) - user.rewardDebt;
        if (pending > 0) {
            safeFuelTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lpSupply = pool.lpSupply - _amount;
        }
        user.rewardDebt = (user.amount * pool.accFuelPerShare) / 1e24;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        // In the case of an accounting error, we choose to let the user emergency withdraw anyway
        if (pool.lpSupply >=  amount){
            pool.lpSupply = pool.lpSupply - amount;
        } else {
            pool.lpSupply = 0;
        }

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe fuel transfer function, just in case if rounding error causes pool to not have enough FUEL.
    function safeFuelTransfer(address _to, uint256 _amount) internal {
        uint256 fuelBal = fuel.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > fuelBal) {
            transferSuccess = fuel.transfer(_to, fuelBal);
        } else {
            transferSuccess = fuel.transfer(_to, _amount);
        }
        require(transferSuccess, "safeFuelTransfer: transfer failed");
    }

    function swapTokensForBUSD(address _saleTokenAddress, uint256 _tokenAmount) private returns (uint[] memory amounts) {
        require(IERC20(_saleTokenAddress).balanceOf(address(this)) >= _tokenAmount, "insufficient tokens provided!");
        require(_saleTokenAddress != address(0), "wanted token address can't be the zero address!");

        address[] memory path = new address[](2);
        path[0] = _saleTokenAddress;
        path[1] = BUSD;
        
        IERC20(_saleTokenAddress).approve(address(pancakeswapRouter), _tokenAmount);

        // make the swap
        return pancakeswapRouter.swapExactTokensForTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidityForPDoge(uint256 _pdogeAmount, uint256 _busdAmount) private {
        // approve token transfer
        IERC20(PDOGE).approve(address(pancakeswapRouter), _pdogeAmount);
        IERC20(BUSD).approve(address(pancakeswapRouter), _busdAmount);

        (uint amountA, uint amountB, uint liquidity) = pancakeswapRouter.addLiquidity(
            PDOGE,
            BUSD,
            _pdogeAmount,
            _busdAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            burnAddress, // burn it immediately
            block.timestamp
        );

        emit AddLiquidityPDogeBusd(amountA, amountB, liquidity);
    }

    function setFeeAddress(address _feeAddress) external {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "!nonzero");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    function setStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(poolInfo.length == 0, "no changing start block after pools have been added");
        require(block.number < startBlock, "cannot change start block if sale has already commenced");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        startBlock = _newStartBlock;

        emit UpdateStartBlock(startBlock);
    }

    // Update the emission rate of DragonEgg. Can only be called by the owner.
    function setFuelPerBlock( uint256 _fuelPerBlock ) external onlyOwner {
        require(_fuelPerBlock <= 1 * (10 ** 18), "emissions per block too high" );
        massUpdatePools();
        fuelPerBlock = _fuelPerBlock;
        emit UpdateFuelPerBlock(_fuelPerBlock);
    }
}
