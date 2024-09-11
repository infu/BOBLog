
import rechain "mo:rechain";
import Timer "mo:base/Timer";
import Principal "mo:base/Principal";
import reader "mo:rechain/readerDelta";

actor this = {

    public type ActionError = {ok:Nat; err:Text};

    stable let chain_mem  = rechain.Mem();

   
    var chain = rechain.Chain<rechain.Value, ActionError>({
        settings = ?{rechain.DEFAULT_SETTINGS with supportedBlocks = [];};
        mem = chain_mem;
        encodeBlock = func (b: rechain.Value): ?[rechain.ValueMap] {
            let #Map(v) = b else return null;
            ?v;
        };
        reducers = [];
    });
    

    stable let reader_mem = reader.Mem();


    let my_reader = reader.Reader({
        mem = reader_mem;
        ledger_id = Principal.fromText("7pail-xaaaa-aaaas-aabmq-cai");
        start_from_block = #id(0);
        onError = func(_) {};
        onCycleEnd = func (_) {}; 
        onRead = func (blocks) {
            label rec for (block in blocks.vals()) {
                let ?b = block.block else continue rec;
                ignore chain.dispatch(b);
            }
        }
    });


    ignore Timer.setTimer<system>(#seconds 0, func () : async () {
        await chain.start_timers<system>();
    });

    public shared({caller}) func start(): async () {
        assert(Principal.isController(caller));
        chain_mem.canister := ?Principal.fromActor(this);
        my_reader.start<system>();
    };

    public query func icrc3_get_blocks(args: rechain.GetBlocksArgs) : async rechain.GetBlocksResult{
        chain.get_blocks(args);
    };

    public query func icrc3_get_archives(args: rechain.GetArchivesArgs) : async rechain.GetArchivesResult{
        chain.get_archives(args);
    };
}