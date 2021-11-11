//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libraries/Base64.sol";

import "hardhat/console.sol";


contract WarhammerGame is ERC721 {
        
    struct CharacterAttributes {
        uint characterIndex;
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        uint defense;
        uint attack;
        uint magic;
        uint faith;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    CharacterAttributes[] defaultCharacters;

    // We create a mapping from the nft's tokenId => that NFTs attributes;
    mapping(uint256 => CharacterAttributes) public nftHolderAttributes;

    struct BigBoss {
        string name;
        string imageURI;
        uint hp;
        uint maxHp;
        // uint defense;
        uint attack;
        // uint magic;
        // uint faith;
    }

    BigBoss public bigBoss;

    // A mapping from an anddress => the NFTs tokenId. Gives me an ez way
    // to sotre the owner of the NFT and reference it later.
    mapping(address => uint256) public nftHolders;

    event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
    event AttackComplete(uint newBossHp, uint newPlayerHp);

    // Data passed in to the contract when it's first created initializing the characters;
    // We're going to aftually pass these values in from run.js
    constructor(
        string[] memory characterNames,
        string[] memory characterImageURIs,
        uint[] memory characterHp,
        uint[] memory characterAttackPwr,
        uint[] memory characterDefense,
        uint[] memory characterMagic,
        uint[] memory characterFaith,
        string memory bossName,
        string memory bossImageURI,
        uint bossHp,
        // uint bossDefense,
        uint bossAttack
        // uint bossFaith,
        // uint bossMagic
    ) 
        ERC721("Warhammer Heroes", "WARH")
    {
        bigBoss = BigBoss({
            name: bossName,
            imageURI: bossImageURI,
            hp: bossHp,
            maxHp: bossHp,
            // defense: bossDefense,
            attack: bossAttack
            // magic: bossMagic,
            // faith: bossFaith
        });


        for(uint i = 0; i < characterNames.length; i += 1) {
            defaultCharacters.push(CharacterAttributes({
                characterIndex: i,
                name: characterNames[i],
                imageURI: characterImageURIs[i],
                hp: characterHp[i],
                maxHp: characterHp[i],
                attack: characterAttackPwr[i],
                defense: characterDefense[i],
                magic: characterMagic[i],
                faith: characterFaith[i]
            }));

            CharacterAttributes memory c = defaultCharacters[i];
            //Remember, Harhat's console.log allows up to 4 params in any order of type uint, string, bool, address
            console.log('Done initializing %s w/ HP %s, img %s', c.name, c.hp, c.imageURI);
        }

        _tokenIds.increment();
    }

    function mintCharacterNft(uint _characterIndex) external {

        uint newItemId = _tokenIds.current();

        // The magical function! Assigns the tokenId to the caller's wallet address.
        _safeMint(msg.sender, newItemId);

        // We map the tokenId => character attributes. More on this below.
        nftHolderAttributes[newItemId] = CharacterAttributes({
            characterIndex: _characterIndex,
            name: defaultCharacters[_characterIndex].name,
            imageURI: defaultCharacters[_characterIndex].imageURI,
            hp: defaultCharacters[_characterIndex].hp,
            maxHp: defaultCharacters[_characterIndex].hp,
            defense: defaultCharacters[_characterIndex].defense,
            attack: defaultCharacters[_characterIndex].attack,
            magic: defaultCharacters[_characterIndex].magic,
            faith: defaultCharacters[_characterIndex].faith

        });

        console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _characterIndex);

        nftHolders[msg.sender] = newItemId;

        _tokenIds.increment();
        emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

        string memory strHp = Strings.toString(charAttributes.hp);
        string memory strMaxHp = Strings.toString(charAttributes.maxHp);
        string memory strAttack = Strings.toString(charAttributes.attack);
        string memory strDefense = Strings.toString(charAttributes.defense);
        string memory strMagic = Strings.toString(charAttributes.magic);
        string memory strFaith = Strings.toString(charAttributes.faith);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        charAttributes.name,
                        ' -- NFT #: ',
                        Strings.toString(_tokenId),
                        '", "description": "This is an NFT of a Warhammer Hero ready to slay the forces of Chaos!", "image": "ipfs://',
                        charAttributes.imageURI,
                        '", "attributes": [{ "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'}, {"trait_type": "Attack Power", "value": ',strAttack,'}, {"trait_type": "Defense", "value": ',strDefense,'}, {"trait_type": "Magic", "value": ',strMagic,'}, {"trait_type": "Faith", "value": ',strFaith,'} ]}'
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return output;
    }

    function attackBoss() public {
        // Get the state of the player's NFT.
        uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
        CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];
        console.log("\nPlayer w/ character %s about to attack. Has %s HP and %s ATK", player.name, player.hp, player.attack);
        console.log("Boss %s has %s HP and %s ATK", bigBoss.name, bigBoss.hp, bigBoss.attack);
        // Make sure the player has more than 0 HP.
        require(player.hp > 0, "Error: Hero must be alive to continue demonic purging.");
        // Make sure the boss has more than 0 HP.
        require(bigBoss.hp > 0, "Error: boss must have HP to attack boss.");
        // Allow player to attack boss.
        if (bigBoss.hp < player.attack) {
            bigBoss.hp = 0;
        } else {
            bigBoss.hp = bigBoss.hp - player.attack;
        }
        // Allow boss to attack player.
        if (player.hp < bigBoss.attack) {
            player.hp = 0;
        } else {
            player.hp = player.hp - bigBoss.attack;
        }

        // Console updates for attack results.
        console.log("Player attacked boss. New boss hp: %s", bigBoss.hp);
        console.log("Boss attacked player. New player hp: %s\n", player.hp);
        emit AttackComplete(bigBoss.hp, player.hp);
    }

    function checkIfUserHasNFT() public view returns(CharacterAttributes memory) {
        // Get the tokenId of the user's character NFT
        uint256 userNftTokenId = nftHolders[msg.sender];
        // If the user has a tokenId in the map, return their character.
        if (userNftTokenId > 0) {
            return nftHolderAttributes[userNftTokenId];
        }
        // Else, return an empty character
        else {
            CharacterAttributes memory emptyStruct;
            return emptyStruct;
        }
    }

    // Retrieve default characters
    function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
        return defaultCharacters;
    }

    // Retrieve the Boss
    function getBigBoss() public view returns (BigBoss memory) {
        return bigBoss;
    }
    
}

