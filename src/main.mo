
import Timer "mo:base/Timer";
import Principal "mo:base/Principal";
import SWB "mo:swbstable/Stable";
import Reader "mo:devefi-icrc-ledger/reader";
import Nat "mo:base/Nat";
import Array "mo:base/Array";

actor this = {


    stable let blocks_mem = SWB.SlidingWindowBufferNewMem<Reader.Transaction>();
    let blocks = SWB.SlidingWindowBuffer<Reader.Transaction>(blocks_mem);

    stable let reader_mem = Reader.Mem();

    var errors : Text = "";

    let reader = Reader.Reader({
        mem = reader_mem;
        ledger_id = Principal.fromText("7pail-xaaaa-aaaas-aabmq-cai");
        start_from_block = #id(0);
        onError = func (_err) { 
            errors := errors # "\n" # _err;
        };
        onCycleEnd = func (_inst) {};
        onRead = func (txs, _) {
            for (tx in txs.vals()) {
                ignore blocks.add(tx);
            }
        };
        maxSimultaneousRequests = 1;
    });

    reader.start<system>();

    public query func get_errors() : async Text {
        errors;
    };

    public query func get_blocks({ start : Nat; length : Nat }) : async {total:Nat; entries:[?Reader.Transaction]} {
        let total = blocks.end();
        let real_len = Nat.min(length, if (start > total) 0 else total - start);

        let entries = Array.tabulate<?Reader.Transaction>(
        real_len,
        func(i) {
            let id = start + i;
            blocks.getOpt(id);
            },
        );
        {
        total;
        entries;
        };
  };
}