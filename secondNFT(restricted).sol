//instructions for contract use:
// - Only send ETH to payable functions (createDark, createLight, etc.)
// - Read comments to get info on function utility
// - Head to twitter.com/Cayenne361 or cayenneplatforms.com for more info on the project!



pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract CayenneV2 is ERC721 {
    using Address for address payable;

    uint256 public totalTokenSupply;
    uint256 public tokenCounterDark;
    string private _collectionLogoURI;
    address private contractOwner;
    
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) private _tokenPrices;
    mapping(uint256 => TokenTraits) private tokenTraits;
    mapping(uint256 => bool) private darkTokens;
    
    mapping(address => bool) private _hasDarkNFT;
    mapping(address => bool) private _hasLightNFT;
    
    constructor() ERC721("Cayenne Genesis", "CYN") {
        contractOwner = msg.sender;
        totalTokenSupply = 0;
        tokenCounterDark = 0;
        setCollectionLogoURI("https://cayenneplatforms.com/URIs/logo.png");
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the contract owner can call this function");
        _;
    }

    event NFTMinted(address indexed owner, uint256 indexed tokenId, string tokenURI, string trait);
    event URISet(uint256 indexed tokenId, string newURI);


    function transferFunds(address payable recipient) external {
        recipient.transfer(address(this).balance);
    }

    function createLight(string memory URI, uint256 quantity) public payable returns (uint256[] memory) {
        require(bytes(URI).length > 0, "Invalid token URI");
        require(quantity > 0, "Invalid initial supply");
        require(!_hasLightNFT[msg.sender], "Only one Light NFT is allowed per Wallet");
        require(!_hasDarkNFT[msg.sender], "You already minted a Dark NFT!");
        
        uint256 newAssetID = totalTokenSupply;
        uint256[] memory mintedIds = new uint256[](quantity);

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = newAssetID + i;

            _safeMint(msg.sender, tokenId);

            _tokenURIs[tokenId] = URI;
            _tokenPrices[tokenId] = 0;
            tokenTraits[tokenId] = TokenTraits("light");

            mintedIds[i] = tokenId;
        }

        totalTokenSupply = totalTokenSupply + quantity;
        _hasLightNFT[msg.sender] = true;

        return mintedIds;
    }

    function createDark(string memory URI, uint256 quantity) public payable returns (uint256[] memory) {
        uint256 pricePerToken = msg.value/quantity;
        require(pricePerToken >= 0.02 ether, "Insufficient Ether sent");
        require(bytes(URI).length > 0, "Invalid token URI");
        require(quantity > 0, "Invalid initial supply");
        require(!_hasLightNFT[msg.sender], "You already minted a Light NFT!");
        
        uint256 newAssetID = totalTokenSupply;
        uint256[] memory mintedIds = new uint256[](quantity);

        if (tokenCounterDark + quantity < 500) {
            for (uint256 i = 0; i < quantity; i++) {
                uint256 tokenId = newAssetID + i;

                _safeMint(msg.sender, tokenId);

                _tokenURIs[tokenId] = URI;
                _tokenPrices[tokenId] = pricePerToken * 100; 
                tokenTraits[tokenId] = TokenTraits("dark");

                mintedIds[i] = tokenId;
                updateDarkTrait(tokenId);
            }
            
            tokenCounterDark = tokenCounterDark + quantity;
            totalTokenSupply = totalTokenSupply + quantity;
        } else {
            revert("Maximum supply reached for Dark tokens. Lower quantity or mint a light NFT instead.");
        }

        _hasDarkNFT[msg.sender] = true;

        return mintedIds;
    }

//URI
    function setURI(uint256 tokenId, string memory newURI) public onlyOwner {
        require(_exists(tokenId), "ERC1155URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = newURI;
    }

    function updateDarkTrait(uint256 tokenId) private {
        if (keccak256(bytes(tokenTraits[tokenId].tier)) == keccak256(bytes("dark"))) {
            darkTokens[tokenId] = true;
        }
    }

    function massSetURI(string memory newURI, uint256[] memory tokenIds) public onlyOwner {
        require(bytes(newURI).length > 0, "Invalid token URI");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_exists(tokenId), "Invalid token ID");
            if (darkTokens[tokenId]) {
                _tokenURIs[tokenId] = newURI;
            }
        }
    }

    function setCollectionLogoURI(string memory uri) public onlyOwner {
        require(bytes(uri).length > 0, "Invalid Logo URI");
        _collectionLogoURI = uri;
    }

//GET requests
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function getTokenTraits(uint256 tokenId) public view returns (string memory) {
        return tokenTraits[tokenId].tier;
    }

    function getPrice(uint256 tokenId) public onlyOwner view returns (uint256) {
        require(_exists(tokenId), "ERC721: Invalid token ID");
        return _tokenPrices[tokenId] / 100;
    }


//STRUCTS
    struct TokenTraits {
        string tier;
    }
}
