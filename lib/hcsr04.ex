defmodule Hcsr04 do
@moduledoc """
Documentation for Hcsr04.
"""
use GenStateMachine, callback_mode: [:state_functions, :state_enter]
alias ElixirALE.GPIO

  def init(_) do
    IO.puts("init")
    {:ok, trigger_pid} = GPIO.start_link(23, :output)
    {:ok, echo_pid} = GPIO.start_link(24, :input)
    GPIO.set_int(echo_pid, :both)
    IO.puts("\tSetting TRIG Low")
    GPIO.write(trigger_pid, 0)
    {:ok, :idle, [trigger_pid, echo_pid], {:state_timeout, 10, :make_measurement_timeout}}
  end
  
  @doc """
  """
  def idle(:enter, _old_state, [trigger_pid, echo_pid]) do
    IO.puts("Entered the idle state")
    :keep_state_and_data
  end
  
  def idle(:state_timeout, :make_measurement_timeout, [trigger_pid, echo_pid]) do
    IO.puts("\tTime to make a measurement")
    IO.puts("\tSET TRIG High")
    GPIO.write(trigger_pid, 1)
    {:next_state, :triggering, [trigger_pid, echo_pid], [{:state_timeout, 1, :trigger_true_timeout}]}
  end

  def idle(:info, {:gpio_interrupt, echo_pin, direction}, [trigger_pid, echo_pid]) do
    IO.puts("\tECHO Pin Interrupt Received: #{inspect(direction)}")
    :keep_state_and_data
  end

  def triggering(:enter, _old_state, [trigger_pid, echo_pid]) do
    IO.puts("Entered the triggering state")
    :keep_state_and_data
  end
  
  def triggering(:state_timeout, :trigger_true_timeout, [trigger_pid, echo_pid]) do
    IO.puts("\tSET TRIG Low")
    GPIO.write(trigger_pid, 0)
    {:next_state, :start_measurement, [trigger_pid, echo_pid]}
  end
  
  def start_measurement(:enter, _old_state, [trigger_pid, echo_pid]) do
    IO.puts("Entered the start_measurement state")
    IO.puts("\tWaiting for rising edge interrupt on ECHO")
    :keep_state_and_data
  end
  
  def start_measurement(:info, {:gpio_interrupt, echo_pin, :rising}, [trigger_pid, echo_pid]) do
    IO.puts("\tRising Edge of Echo Detected")
    start_time = Timex.now()
    IO.puts("\tStart Time: #{inspect(start_time)}")
    {:next_state, :end_measurement, [trigger_pid, echo_pid, start_time]}
  end
  
  def end_measurement(:enter, _old_state, [trigger_pid, echo_pid, start_time]) do
    IO.puts("Entered the end_measurement state")
    IO.puts("\tWaiting for falling edge interrupt on ECHO")
    :keep_state_and_data
  end

  def end_measurement(:info, {:gpio_interrupt, echo_pin, :falling}, [trigger_pid, echo_pid, start_time]) do
    IO.puts("\tFalling Edge of Echo Detected")
    end_time = Timex.now()
    IO.puts("\tStart Time: #{inspect(start_time)}")
    IO.puts("\tEnd Time: #{inspect(end_time)}")
    echo_duration = Timex.diff(end_time, start_time, :microseconds) / 1000000
    IO.puts("\tEcho Duration: #{inspect(echo_duration)}")
    distance_cm = echo_duration * 17150
    distance_in = distance_cm * 0.393701
    IO.puts("Distance: #{inspect(distance_cm)} cm")
    IO.puts("Distance: #{inspect(distance_in)} in")
    {:next_state, :idle, [trigger_pid, echo_pid]}
  end

end
