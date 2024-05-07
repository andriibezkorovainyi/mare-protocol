import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages";
import "./jetton";
import "./jetton_default_wallet";

message Buy {
    mareAmount: Int;
    refCode: String; // currently not used
}

contract PublicSale with Deployable, Ownable {
    const minTonsForStorage: Int = ton("0.019");
    const gasConsumption: Int = ton("0.013");

    owner: Address;
    mareMaster: Address;
    isSaleLive: Bool = true;
    marePerTon: Int;

    init(mareMaster: Address, marePerTon: Int) {
        let ctx: Context = context();
        self.owner = ctx.sender;
        self.mareMaster = mareMaster;
        self.marePerTon = marePerTon;
    }

    receive(msg: Buy) {
        require(self.isSaleLive, "Sale is not live");
        let ctx: Context = context();
        let fee: Int = ctx.readForwardFee() * 2;
        let msg_value: Int = self.msg_value(ctx.value);
        let ownerTonAmount: Int = msg.mareAmount / self.marePerTon;
        let exceecesses: Int =  msg_value - ownerTonAmount - fee;
        require(exceecesses > 0, "Not enough TONs sent");

        send(SendParameters{
            to: self.owner,
            value: ownerTonAmount,
            bounce: true,
            mode: SendPayGasSeparately,
            body: beginCell().endCell()
        });

        send(SendParameters{
            to: contractAddress(initOf JettonDefaultWallet(myAddress(), self.mareMaster)),
            value: exceecesses,
            bounce: true,
            mode: SendPayGasSeparately,
            body: TokenTransfer {
                query_id: 2,
                amount: msg.mareAmount,
                sender: sender(),
                response_destination: sender(),
                forward_ton_amount: 0,
                forward_payload: beginCell().endCell().asSlice(),
                custom_payload: beginCell().endCell()
            }.toCell()
        });
    }

    fun msg_value(value: Int): Int {
        let msg_value: Int = value;
        let ton_balance_before_msg: Int = myBalance() - msg_value;
        let storage_fee: Int = self.minTonsForStorage - min(ton_balance_before_msg, self.minTonsForStorage);
        msg_value = msg_value - (storage_fee + self.gasConsumption);
        return msg_value;
    }

    get fun isSaleLive(): Bool {
        return self.isSaleLive;
    }

    get fun marePerTon(): Int {
        return self.marePerTon;
    }

    receive() {}
}
