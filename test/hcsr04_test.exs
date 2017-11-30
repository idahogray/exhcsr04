defmodule Hcsr04Test do
  use ExUnit.Case
  doctest Hcsr04

  setup do
    {:ok, hcsr04_pid} = GenStateMachine.start_link(Hcsr04, {:idle, []})
    IO.puts("hcsr04 state machine started: #{inspect(hcsr04_pid)}")
    {:ok, hcsr04_pid: hcsr04_pid}
  end

  test "start hcsr04 state machine", %{hcsr04_pid: hcsr04_pid} do
    IO.puts("Sleeping for 10 secs")
    Process.sleep(10000)
  end
end
