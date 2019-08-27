defmodule Explorer.Chain.Cache.BlockNumberTest do
  use Explorer.DataCase

  alias Explorer.Chain.Cache.BlockNumber

  describe "max_number/0" do
    setup :cache_without_ttl

    on_exit(fn ->
      Application.put_env(:explorer, Explorer.Chain.Cache.BlockNumber, enabled: false)
    end)
  end

  describe "get_max/1" do
    test "returns max number" do
      insert(:block, number: 5)

      assert BlockNumber.get_max() == 5
    end
  end

  describe "get_min/1" do
    test "returns min number" do
      insert(:block, number: 2)

      assert BlockNumber.get_min() == 2
    end
  end

  describe "get_all/1" do
    test "returns min and max number" do
      insert(:block, number: 6)

      assert BlockNumber.get_all() == %{min: 6, max: 6}
    end
  end

  describe "update_all/1" do
    test "updates max number" do
      insert(:block, number: 2)

      assert BlockNumber.get_max() == 2

      assert BlockNumber.update_all(3)

      assert BlockNumber.get_max() == 3
    end

    test "updates min number" do
      insert(:block, number: 2)

      assert BlockNumber.get_min() == 2

      assert BlockNumber.update_all(1)

      assert BlockNumber.get_min() == 1
    end

    test "updates min and number" do
      insert(:block, number: 2)

      assert BlockNumber.get_all() == %{min: 2, max: 2}

      assert BlockNumber.update_all(1)

      assert BlockNumber.get_all() == %{min: 1, max: 2}

      assert BlockNumber.update_all(6)

      assert BlockNumber.get_all() == %{min: 1, max: 6}
    end
  end

  describe "with ttl" do
    setup :cache_with_ttl

    test "min_number/0" do
      insert(:block, number: 5)

      assert BlockNumber.min_number() == 5

      insert(:block, number: 3)

      assert BlockNumber.min_number() == 5

      Process.sleep(1_000)

      assert BlockNumber.min_number() == 3
    end

    test "max_number/0" do
      insert(:block, number: 3)

      assert BlockNumber.max_number() == 3

      insert(:block, number: 5)

      assert BlockNumber.max_number() == 3

      Process.sleep(1_000)

      assert BlockNumber.max_number() == 5
    end
  end

  defp cache_without_ttl(_) do
    Application.put_env(:explorer, BlockNumber, enabled: true)
    Supervisor.start_child(Explorer.Supervisor, BlockNumber.child_spec([]))

    on_exit(fn ->
      Supervisor.terminate_child(Explorer.Supervisor, {ConCache, :block_number_cache})
      Supervisor.delete_child(Explorer.Supervisor, {ConCache, :block_number_cache})
      Application.put_env(:explorer, BlockNumber, enabled: false)
    end)
  end

  defp cache_with_ttl(_) do
    Application.put_env(:explorer, BlockNumber, enabled: true, ttl_check_interval: 200, global_ttl: 200)
    Supervisor.start_child(Explorer.Supervisor, BlockNumber.child_spec([]))

    on_exit(fn ->
      Supervisor.terminate_child(Explorer.Supervisor, {ConCache, :block_number_cache})
      Supervisor.delete_child(Explorer.Supervisor, {ConCache, :block_number_cache})
      Application.put_env(:explorer, BlockNumber, enabled: false)
    end)
  end
end
