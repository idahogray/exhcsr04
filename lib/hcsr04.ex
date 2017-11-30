defmodule Hcsr04 do
@moduledoc """
Documentation for Hcsr04.
"""
use GenStateMachine, callback_mode: [:state_functions, :state_enter]
alias ElixirALE.GPIO

  def init(_) do
    {:ok, trigger_pid} = GPIO.start_link(18, :output)
    {:ok, echo_pid} = GPIO.start_link(17, :input)
    GPIO.set_int(echo_pid, :both)
    {:ok, :idle, [trigger_pid, echo_pid], {:state_timeout, 1000, :make_measurement_timeout}}
  end
  
  @doc """
  """
  def idle(:enter, _old_state, [trigger_pid, echo_pid]) do
    IO.puts("Entered the idle state")
    :keep_state_and_data
  end
  
  def idle(:state_timeout, :make_measurement_timeout, [trigger_pid, echo_pid]) do
    IO.puts("Time to make a measurement")
    IO.puts("\tSET TRIG=TRUE")
    {:next_state, :triggering, [trigger_pid, echo_pid], [{:state_timeout, 1000, :trigger_true_timeout}]}
  end

  def idle(:info, {:gpio_interrupt, echo_pin, direction}, [trigger_pid, echo_pid]) do
    IO.puts("ECHO Pin Interrupt Received: #{inspect(direction)}")
    :keep_state_and_data
  end

  def triggering(:enter, _old_state, [trigger_pid, echo_pid]) do
    IO.puts("Entered the triggering state")
    :keep_state_and_data
  end
  
  def triggering(:state_timeout, :trigger_true_timeout, [trigger_pid, echo_pid]) do
    IO.puts("TRIG is TRUE timeout received")
    IO.puts("\tSET TRIG=FALSE")
    {:next_state, :start_measurement, [trigger_pid, echo_pid], {:timeout, 1000, :falling_echo_interrupt}}
  end
  
  def start_measurement(:enter, _old_state, [trigger_pid, echo_pid]) do
   IO.puts("Entered the start_measurement state")
   IO.puts("Waiting for falling edge interrupt on ECHO")
    :keep_state_and_data
  end
  
  def start_measurement(:timeout, :falling_echo_interrupt, [trigger_pid, echo_pid]) do
    IO.puts("Falling Edge of Echo Detected")
    start_time = Timex.now()
    IO.puts("Start Time: #{inspect(start_time)}")
    {:next_state, :end_measurement, [trigger_pid, echo_pid, start_time], {:timeout, 1000, :rising_echo_interrupt}}
  end
  
  def end_measurement(:enter, _old_state, [trigger_pid, echo_pid, start_time]) do
    IO.puts("Entered the end_measurement state")
    IO.puts("Waiting for rising edge interrupt on ECHO")
    :keep_state_and_data
  end

  def end_measurement(:timeout, :rising_echo_interrupt, [trigger_pid, echo_pid, start_time]) do
    IO.puts("Rising Edge of Echo Detected")
    end_time = Timex.now()
    IO.puts("End Time: #{inspect(start_time)}")
    echo_duration = Timex.diff(end_time, start_time, :milliseconds) / 1000
    IO.puts("Echo Duration: #{inspect(echo_duration)}")
    distance_cm = echo_duration * 17150
    distance_in = distance_cm * 0.393701
    IO.puts("Distance: #{inspect(distance_cm)} cm")
    IO.puts("Distance: #{inspect(distance_in)} in")
    {:next_state, :idle, [trigger_pid, echo_pid]}
  end

end
