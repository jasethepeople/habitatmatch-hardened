defmodule HabitatMatchWeb do
  def controller do
    quote do
      use Phoenix.Controller, formats: [:json]
      import Plug.Conn
      alias HabitatMatch.Repo
    end
  end
  defmacro __using__(which) when which == :controller, do: controller()
end
