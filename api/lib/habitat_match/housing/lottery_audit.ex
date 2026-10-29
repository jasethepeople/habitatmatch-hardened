defmodule HabitatMatch.Housing.LotteryAudit do
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "lottery_audits" do
    belongs_to :building, HabitatMatch.Housing.Building, type: :binary_id
    field :commitment, :binary
    field :seed_ciphertext, :binary
    field :algorithm, :string
    field :drawn_at, :utc_datetime_usec
  end
end
