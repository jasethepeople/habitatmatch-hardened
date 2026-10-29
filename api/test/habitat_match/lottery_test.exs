defmodule HabitatMatch.LotteryTest do
  use ExUnit.Case, async: true
  test "same seed and entries always produce the same ranking" do
    ids = for _ <- 1..500, do: :crypto.strong_rand_bytes(16)
    seed = :crypto.strong_rand_bytes(32)
    assert HabitatMatch.Lottery.rank(ids, seed) == HabitatMatch.Lottery.rank(ids, seed)
  end
  test "ranking has no duplicates and preserves all entries" do
    ids = for n <- 1..100, do: <<n::128>>
    ranked = HabitatMatch.Lottery.rank(ids, :crypto.strong_rand_bytes(32))
    assert length(ranked) == length(ids)
    assert MapSet.new(ranked) == MapSet.new(ids)
  end
end
