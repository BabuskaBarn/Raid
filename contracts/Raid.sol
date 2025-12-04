// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title RaidBossRPG - minimal on-chain "raid boss" with proportional rewards
/// @notice Educational example: randomness is NOT secure for real money.
contract RaidBossRPG {
    // -------------------- Admin --------------------
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    // -------------------- Raid state --------------------
    struct Raid {
        uint256 hp;          // current boss HP
        uint256 maxHp;       // for UI display
        uint256 rewardPool;  // total points distributed for this raid
        uint256 totalDamage; // total damage dealt by all players
        bool active;         // true while boss alive
    }

    uint256 public raidId;                 // increments each reset
    mapping(uint256 => Raid) public raids; // raidId => Raid

    // Per-raid player accounting
    mapping(uint256 => mapping(address => uint256)) public damageDealt; // raidId => player => damage
    mapping(uint256 => mapping(address => bool)) public claimed;        // raidId => player => claimed?
    mapping(uint256 => mapping(address => uint256)) public lastAttackBlock; // cooldown per raid

    // "Reward points" ledger (like an internal token balance)
    mapping(address => uint256) public rewardPoints;

    // Tuning knobs
    uint256 public constant COOLDOWN_BLOCKS = 2;

    // -------------------- Events --------------------
    event BossReset(uint256 indexed raidId, uint256 hp, uint256 rewardPool);
    event AttackLanded(uint256 indexed raidId, address indexed player, uint8 moveType, uint256 damage, uint256 bossHpLeft);
    event BossDefeated(uint256 indexed raidId);
    event RewardClaimed(uint256 indexed raidId, address indexed player, uint256 payout);

    constructor() {
        owner = msg.sender;
    }

    /// @notice Start a new raid (resets boss + reward pool)
    /// @dev Increments raidId so old damage can't be reused.
    function resetBoss(uint256 newHp, uint256 rewardPool) external onlyOwner {
        require(newHp > 0, "hp=0");
        raidId += 1;

        raids[raidId] = Raid({
            hp: newHp,
            maxHp: newHp,
            rewardPool: rewardPool,
            totalDamage: 0,
            active: true
        });

        emit BossReset(raidId, newHp, rewardPool);
    }

    /// @notice Attack the boss with a move type (0..2)
    /// @dev Pseudo-randomness is for fun only; explain limitations in report/demo.
    function attack(uint8 moveType) external {
        Raid storage r = raids[raidId];
        require(r.active && r.hp > 0, "no active boss");
        require(block.number > lastAttackBlock[raidId][msg.sender] + COOLDOWN_BLOCKS, "cooldown");
        require(moveType <= 2, "bad move");

        lastAttackBlock[raidId][msg.sender] = block.number;

        // Move definitions (simple + easy to justify in a report)
        // 0 = Slash (steady)
        // 1 = Fireball (higher variance)
        // 2 = Smite (slow, big)
        uint256 base;
        uint256 variance;
        if (moveType == 0) { base = 10; variance = 6; }
        else if (moveType == 1) { base = 7; variance = 12; }
        else { base = 14; variance = 4; }

        // Pseudo-random roll (NOT secure vs manipulation; fine for a uni toy)
        uint256 roll = uint256(keccak256(abi.encodePacked(
            block.prevrandao,
            blockhash(block.number - 1),
            msg.sender,
            raidId,
            damageDealt[raidId][msg.sender]
        ))) % (variance + 1);

        uint256 dmg = base + roll;

        // Cap damage to remaining HP
        if (dmg > r.hp) dmg = r.hp;

        r.hp -= dmg;
        r.totalDamage += dmg;
        damageDealt[raidId][msg.sender] += dmg;

        emit AttackLanded(raidId, msg.sender, moveType, dmg, r.hp);

        if (r.hp == 0) {
            r.active = false;
            emit BossDefeated(raidId);
        }
    }

    /// @notice Claim your share of reward points after the boss is defeated
    function claim() external {
        Raid storage r = raids[raidId];
        require(!r.active && r.hp == 0, "boss not defeated");
        require(!claimed[raidId][msg.sender], "already claimed");

        uint256 playerDamage = damageDealt[raidId][msg.sender];
        require(playerDamage > 0, "no contribution");
        require(r.totalDamage > 0, "no total");

        claimed[raidId][msg.sender] = true;

        // Proportional payout
        uint256 payout = (r.rewardPool * playerDamage) / r.totalDamage;
        rewardPoints[msg.sender] += payout;

        emit RewardClaimed(raidId, msg.sender, payout);
    }
}
