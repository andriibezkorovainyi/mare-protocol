import "@stdlib/deploy";
import "./jetton";

message Mint {
    amount: Int;
    receiver: Address;
}

contract MareJetton with Deployable, Jetton {
    owner: Address;
    total_supply: Int as coins;
    max_supply: Int as coins;
    content: Cell;
    mintable: Bool;

    init(owner: Address, content: Cell, max_supply: Int) {
        self.total_supply = 0;
        self.owner = owner;
        self.mintable = true;
        self.content = content;
        self.max_supply = max_supply;
    }

    receive(msg: Mint) { // 0xfc708bd2
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        require(self.mintable, "Not mintable");
        require(self.total_supply + msg.amount <= self.max_supply, "Max supply exceeded");
        self.mint(msg.receiver, msg.amount, self.owner); // (to, amount, response_destination)
    }

    receive("Mint: 100") { // Public Minting
        let ctx: Context = context();
        require(self.mintable, "Not mintable");
        require(self.total_supply + 100 <= self.max_supply, "Max supply exceeded");
        self.mint(ctx.sender, 100, self.owner); // 🔴
    }

    receive("Owner: MintClose") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        self.mintable = false;
    }

    receive("Owner: MintOpen") {
        let ctx: Context = context();
        require(ctx.sender == self.owner, "Not owner");
        self.mintable = true;
    }

    receive() {}
}
