import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure users can submit new trends and receive rewards",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("trend-pulse", "submit-trend", 
        [types.ascii("NFT Market Surge"), types.ascii("Crypto")],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    block.receipts[0].result.expectOk().expectUint(0);
    
    // Check rewards
    let pointsBlock = chain.mineBlock([
      Tx.contractCall("trend-rewards", "get-points-balance",
        [types.principal(wallet_1.address)],
        wallet_1.address
      )
    ]);
    
    pointsBlock.receipts[0].result.expectOk().expectUint(10);
  }
});

Clarinet.test({
  name: "Ensure users can vote on trends and receive rewards",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("trend-pulse", "submit-trend",
        [types.ascii("Web3 Gaming"), types.ascii("Gaming")],
        wallet_1.address
      ),
      Tx.contractCall("trend-pulse", "vote-trend",
        [types.uint(0)],
        wallet_2.address
      )
    ]);
    
    assertEquals(block.receipts.length, 2);
    block.receipts[1].result.expectOk().expectBool(true);
    
    // Check voter rewards
    let pointsBlock = chain.mineBlock([
      Tx.contractCall("trend-rewards", "get-points-balance",
        [types.principal(wallet_2.address)],
        wallet_2.address
      )
    ]);
    
    pointsBlock.receipts[0].result.expectOk().expectUint(1);
  }
});

Clarinet.test({
  name: "Test category-based trend querying",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall("trend-pulse", "submit-trend",
        [types.ascii("DeFi Trend"), types.ascii("Crypto")],
        wallet_1.address
      ),
      Tx.contractCall("trend-pulse", "get-trends-by-category",
        [types.ascii("Crypto"), types.uint(10)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 2);
    block.receipts[1].result.expectOk();
  }
});
